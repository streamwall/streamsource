# StreamSource Color Reference

## Makefile Color Scheme

The updated Makefile uses the following color scheme for better readability:

### Color Meanings

- **Blue (Bold)**: Headers and titles
- **Green (Bold)**: Section headers and success messages
- **Cyan**: Command names
- **Yellow**: Parameters, URLs, and warnings
- **Red**: Errors and important notices
- **Purple**: Credentials and sensitive info
- **White**: Regular text

### Examples

```bash
# View colorized help
make help

# See success messages in green
make dev
# Output: ✓ StreamSource is running! (in green)

# Error messages in red
make spec
# Output: Error: No file specified (in red)

# Parameters highlighted in yellow
make spec file=spec/models/stream_spec.rb
```

## Terminal Setup Summary

### Quick Setup (macOS with Homebrew)

```bash
# Install syntax highlighting
brew install zsh-syntax-highlighting zsh-autosuggestions

# Add to ~/.zshrc
echo 'source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> ~/.zshrc
echo 'source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh' >> ~/.zshrc

# Install better CLI tools
brew install bat exa delta jq

# Add aliases to ~/.zshrc
echo "alias cat='bat'" >> ~/.zshrc
echo "alias ls='exa --icons'" >> ~/.zshrc
echo "export CLICOLOR=1" >> ~/.zshrc

# Reload shell
source ~/.zshrc
```

### Test Your Colors

```bash
# Run the color test script
./scripts/test-colors.sh

# Test Makefile colors
make help

# Test Rails console colors
make console
# Then run: model_stats
```

## Customization

### Adjusting Makefile Colors

If you want to customize the colors, edit the color definitions at the top of the Makefile:

```make
# Color definitions
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
WHITE := \033[0;37m
BOLD := \033[1m
RESET := \033[0m
```

### ANSI Color Codes Reference

Basic colors:
- `\033[0;30m` - Black
- `\033[0;31m` - Red
- `\033[0;32m` - Green
- `\033[0;33m` - Yellow
- `\033[0;34m` - Blue
- `\033[0;35m` - Purple
- `\033[0;36m` - Cyan
- `\033[0;37m` - White

Add `1;` for bold: `\033[1;31m` - Bold Red

## Troubleshooting

### Colors Not Working?

1. Check terminal color support:
   ```bash
   echo $TERM
   tput colors
   ```

2. Force 256-color mode:
   ```bash
   export TERM=xterm-256color
   ```

3. In iTerm2, check:
   - Preferences → Profiles → Terminal → Report Terminal Type: `xterm-256color`

### Docker Compose Colors

Ensure Docker uses colors:
```bash
# Add to ~/.zshrc
export DOCKER_CLI_HINTS=false
export COMPOSE_DOCKER_CLI_BUILD=1
export DOCKER_BUILDKIT=1
```

### VS Code Integration

If using VS Code's terminal, add to settings.json:
```json
{
  "terminal.integrated.env.osx": {
    "CLICOLOR": "1"
  }
}
```