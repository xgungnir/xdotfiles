#!/usr/bin/env bash

pushKarabinerConfig() {
    # Create necessary directories if they don't exist
    mkdir -p ~/.config/karabiner

    # Copy all files and subdirectories from source to destination
    cp -R ./karabiner/.config/karabiner/* ~/.config/karabiner/
}

pullKarabinerConfig() {
    # Copy main config file
    cp -f ~/.config/karabiner/karabiner.json ./karabiner/.config/karabiner/
}

pullAlttabConfig() {
    defaults export com.lwouis.alt-tab-macos ./alttab/Library/Preferences/com.lwouis.alt-tab-macos.plist
}

pushAlttabConfig() {
    defaults delete com.lwouis.alt-tab-macos
    defaults import com.lwouis.alt-tab-macos ./alttab/Library/Preferences/com.lwouis.alt-tab-macos.plist
}