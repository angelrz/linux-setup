#!/bin/sh
# Remove snap packages (some need to be removed prior certain packages)
sudo snap remove --purge firefox
sudo snap remove --purge gnome-42-2204
sudo snap remove --purge gtk-common-themes
sudo snap remove --purge firmware-updater
sudo snap remove --purge bare
sudo snap remove --purge snapd-desktop-integration
sudo snap remove --purge core22
sudo snap remove --purge snapd

# Disable running services (this can be masked further)
sudo systemctl disable snapd.socket
sudo systemctl disable snapd.service
sudo systemctl disable snapd.seeded.service
sudo systemctl disable snapd
sudo systemctl mask snapd

# Wipe some of the remnants
sudo rm -rf /var/cache/snapd/
rm -rf ~/snap

# Purge snap and mask it 
sudo apt autoremove snapd --purge -y
sudo apt-mark hold snapd

echo "\e[1;32m\nSnapd is successfully removed.\n"
