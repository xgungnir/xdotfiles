#! /bin/sh

pushd $DOTFILES
for folder in $(echo $STOW_FOLDERS | sed "s/,/ /g")
do
    stow -t ~ -D $folder
    stow -t ~ $folder
done
popd
