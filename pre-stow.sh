#! /bin/sh
if [[ -z $STOW_FOLDERS ]]; then
    STOW_FOLDERS="custom,ssh,wezterm,zsh,hammerspoon,git,mise,iterm2,alttab,nvim-astro,clash"
fi

if [[ -z $DOTFILES ]]; then
    DOTFILES=~/xdotfiles
fi

## zsh
ZSH_FILES=(~/.zprofile ~/.zshrc ~/.zshenv ~/.p10k.zsh)
ZSH_BACKUP_DIR=~/.zshrc-backup
mkdir -p "$ZSH_BACKUP_DIR"
for FILE in "${ZSH_FILES[@]}"; do
    if [ -f "$FILE" ]; then
        BACKUP_FILE="${ZSH_BACKUP_DIR}/$(basename "$FILE")"
        mv -f "$FILE" "$BACKUP_FILE"
    fi
done

## git
GIT_FILES=(~/.gitconfig ~/.gitignore_global)
GIT_BACKUP_DIR=~/.gitconfig-backup
mkdir -p "$GIT_BACKUP_DIR"
for FILE in "${GIT_FILES[@]}"; do
    if [ -f "$FILE" ]; then
        BACKUP_FILE="${GIT_BACKUP_DIR}/$(basename "$FILE")"
        mv -f "$FILE" "$BACKUP_FILE"
    fi
done
