# Zen Browser Linux Tarball Guide

This guide covers how to manually install and completely uninstall Zen Browser from a `.tar` archive on Linux.

---

## Part 1: Installation Steps

### 1. Download and Extract the Files
Open your terminal and run the following commands to download the latest release and extract it to the `/opt` directory for system-wide access:

```bash
# Download the latest tarball
wget https://github.com

# Create the target directory and extract the files
sudo mkdir -p /opt/zen-browser
sudo tar -xjf zen.linux-x86_64.tar.bz2 -C /opt/zen-browser
```

### 2. Create a Desktop Shortcut
Create a launcher file so Zen Browser appears in your system's application menu:

```bash
sudo nano /usr/share/applications/zen.desktop
```

Paste the following configuration into the file, then save and exit (in `nano`, press `Ctrl+O`, `Enter`, then `Ctrl+X`):

```ini
[Desktop Entry]
Version=1.0
Name=Zen Browser
Comment=Experience tranquillity while browsing the web
Exec=/opt/zen-browser/zen/zen
Icon=/opt/zen-browser/zen/browser/chrome/icons/default/default128.png
Terminal=false
Type=Application
Categories=Network;WebBrowser;
```

### 3. Update Application Cache
Force your system to recognize the new shortcut immediately:

```bash
sudo update-desktop-database /usr/share/applications
```

---

## Part 2: Uninstallation Steps

### 1. Remove the Browser Files
Delete the extracted program files from your system:

```bash
sudo rm -rf /opt/zen-browser
```

### 2. Remove the Desktop Shortcut
Delete the menu shortcut file:

```bash
sudo rm /usr/share/applications/zen.desktop
```

### 3. Update the Application Cache
Refresh your desktop database to remove Zen Browser from your app menu:

```bash
sudo update-desktop-database /usr/share/applications
```

### 4. (Optional) Clear User Data and Cache
To completely wipe your browsing history, bookmarks, and local settings, delete these hidden folders from your home directory:

```bash
rm -rf ~/.zen
rm -rf ~/.cache/zen
```
