# Terminal Setup for StreamSource Development

This guide provides recommendations for setting up your macOS terminal with iTerm2 and zsh for optimal syntax highlighting and development experience.

## iTerm2 Configuration

### Color Scheme
For best results with the colorized Makefile output, use a dark theme:

1. Open iTerm2 Preferences (`⌘,`)
2. Go to **Profiles** → **Colors**
3. Recommended color presets:
   - **Solarized Dark**
   - **Tomorrow Night**
   - **Dracula**
   - **One Dark**

### Font Settings
Use a monospace font with ligature support:

1. Go to **Profiles** → **Text**
2. Recommended fonts:
   - **JetBrains Mono** (with ligatures)
   - **Fira Code**
   - **Cascadia Code**
   - **SF Mono** (macOS default)

## Zsh Configuration

Add these configurations to your `~/.zshrc` file:

### 1. Enable Syntax Highlighting

```bash
# Install zsh-syntax-highlighting
brew install zsh-syntax-highlighting

# Add to ~/.zshrc
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```

### 2. Enable Auto-suggestions

```bash
# Install zsh-autosuggestions
brew install zsh-autosuggestions

# Add to ~/.zshrc
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
```

### 3. Install Oh My Zsh (Optional but Recommended)

```bash
# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Use a theme with good color support
# Add to ~/.zshrc
ZSH_THEME="agnoster"  # or "powerlevel10k/powerlevel10k"
```

### 4. Add Helpful Aliases

Add these to your `~/.zshrc`:

```bash
# StreamSource Development Aliases
alias ss='cd ~/dev/streamsource'
alias ssm='make'
alias ssd='make dev'
alias ssc='make console'
alias sst='make test'
alias ssl='make logs'

# Docker shortcuts
alias dc='docker compose'
alias dce='docker compose exec'
alias dcr='docker compose run --rm'
alias dclogs='docker compose logs -f'

# Rails shortcuts (within container)
alias dcr-console='docker compose exec web bin/rails console'
alias dcr-migrate='docker compose exec web bin/rails db:migrate'
alias dcr-test='docker compose exec web bin/test'

# Color support for common commands
alias ls='ls -G'
alias grep='grep --color=auto'
alias diff='diff --color=auto'

# Better command output
export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad
```

### 5. Enhanced Prompt with Git Info

```bash
# Add to ~/.zshrc for git branch in prompt
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%b'
setopt PROMPT_SUBST
PROMPT='%F{blue}%~%f %F{green}${vcs_info_msg_0_}%f %# '
```

### 6. Better History Settings

```bash
# Add to ~/.zshrc
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
```

## Colorized Output Tools

Install these tools for better colorized output:

```bash
# Better 'cat' with syntax highlighting
brew install bat
alias cat='bat'

# Better 'ls' with icons and colors
brew install exa
alias ls='exa --icons'
alias ll='exa -la --icons'
alias tree='exa --tree --icons'

# Better 'diff'
brew install delta
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"

# JSON highlighting
brew install jq

# YAML highlighting
brew install yq
```

## Docker and Rails Output Colors

### Enable Docker BuildKit for Better Output

```bash
# Add to ~/.zshrc
export DOCKER_BUILDKIT=1
export BUILDKIT_PROGRESS=plain
```

### Rails Colorized Logs

The Rails logs in the Docker container are already configured for color output. To ensure they display properly:

```bash
# When running logs
make logs  # Already colorized
docker compose logs -f web  # Also colorized

# For Rails console with colors
make console  # Will have colorized output
```

## VSCode Terminal Integration (If Using)

If you also use VSCode's integrated terminal:

```json
// Add to VSCode settings.json
{
  "terminal.integrated.fontFamily": "JetBrains Mono, Menlo, Monaco, 'Courier New', monospace",
  "terminal.integrated.fontSize": 14,
  "terminal.integrated.lineHeight": 1.2,
  "terminal.integrated.cursorBlinking": true,
  "terminal.integrated.cursorStyle": "line",
  "workbench.colorTheme": "One Dark Pro"
}
```

## Testing Your Setup

After applying these configurations:

1. Reload your terminal or run: `source ~/.zshrc`
2. Test the colorized Makefile: `make help`
3. Test syntax highlighting: `ls -la`
4. Test Docker colors: `docker compose ps`

## Troubleshooting

### Colors Not Showing

1. Ensure your terminal supports 256 colors:
   ```bash
   echo $TERM  # Should show "xterm-256color" or similar
   ```

2. If not, add to ~/.zshrc:
   ```bash
   export TERM="xterm-256color"
   ```

### Makefile Colors Look Wrong

Make sure your iTerm2 profile has "Minimum contrast" set to a low value:
- iTerm2 → Preferences → Profiles → Colors → Minimum contrast: 0

### Performance Issues

If syntax highlighting slows down your terminal:
```bash
# Disable for large files
zstyle ':bracketed-paste-magic' active-widgets '.self-*'
```

## Project-Specific Configuration

For StreamSource development, you can create a `.envrc` file (requires direnv):

```bash
# Install direnv
brew install direnv

# Add to ~/.zshrc
eval "$(direnv hook zsh)"

# Create .envrc in project root
echo 'export RAILS_ENV=development' > .envrc
echo 'export DOCKER_BUILDKIT=1' >> .envrc
direnv allow
```

This will automatically set environment variables when you enter the project directory.