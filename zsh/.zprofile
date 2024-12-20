# ~/.zprofile
BREW_BIN="/usr/local/bin"
if [[ $(uname -m) == "arm64" ]]; then
  BREW_BIN="/opt/homebrew/bin"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if [[ "$TERM_PROGRAM" == @(vscode) ]]; then
  eval "$($BREW_BIN/mise activate zsh --shims)"
else
  eval "$($BREW_BIN/mise activate zsh)"
fi
