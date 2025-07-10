# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.3.6
FROM ruby:$RUBY_VERSION-slim as base

# Rails app lives here
WORKDIR /rails

# Set environment
ENV BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_APP_CONFIG="/usr/local/bundle" \
    GEM_HOME="/usr/local/bundle" \
    PATH="/usr/local/bundle/bin:${PATH}"

# Throw-away build stage to reduce size of final image
FROM base as build

# Install packages needed to build gems and Node.js for asset compilation
# Also include packages needed for testing when building test image
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libvips pkg-config curl jq && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn

# Install application gems
COPY Gemfile ./
COPY Gemfile.lock* ./
# Remove any existing bundle config and set proper configuration
RUN rm -rf .bundle ~/.bundle && \
    bundle config unset frozen && \
    bundle config set --global path "${BUNDLE_PATH}" && \
    bundle config set --global without "" && \
    bundle config unset with && \
    bundle lock --add-platform aarch64-linux --add-platform x86_64-linux && \
    bundle install --jobs 4 --retry 3 && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Install JavaScript dependencies
RUN if [ -f "package.json" ]; then \
      yarn install; \
    fi

# Build assets (CSS and JavaScript)
RUN if [ -f "package.json" ]; then \
      yarn build:css && \
      yarn build; \
    fi

# Precompile assets with Propshaft
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Final stage for app image
FROM base

# Install packages needed for deployment including Node.js for runtime JavaScript
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libvips postgresql-client jq && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Remove any host bundle config that might have been copied
RUN rm -rf /rails/.bundle

# Run and own only the runtime files as a non-root user for security
RUN useradd rails --create-home --shell /bin/bash && \
    mkdir -p db log storage tmp && \
    chown -R rails:rails db log storage tmp && \
    chown -R rails:rails /usr/local/bundle
USER rails:rails

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]

# Test stage - can be targeted with --target test
FROM build as test

# Install packages needed for testing
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y postgresql-client jq && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set test environment
ENV RAILS_ENV=test

# Default command for test stage
CMD ["bundle", "exec", "rspec"]