#!/bin/bash

# set -e

source ./functions.sh

caffeinate -s -w $$ &


if test -f ./custom/.custom/proxy.sh; then
  echo "Setting proxy ..."
  source ./custom/.custom/proxy.sh
fi


if ! brew_available; then
  load_brew_shellenv
fi

if brew_available; then
  echo "OSX is brewing ..."
  source ./osx.sh
fi

echo "Deleting all .DS_Store files ..."
find . -name ".DS_Store" -type f -delete

echo "Preparing stow ..."
source ./pre-stow.sh

echo "Stowing ..."
source ./stow.sh

echo "Hardcopying ..."
source ./hardcopy.sh
pushKarabinerConfig

echo "Kill affected applications"
for app in Safari Finder Dock Mail SystemUIServer; do killall "$app" >/dev/null 2>&1; done

echo "Done. Note that some of these changes require a logout/restart to take effect."

