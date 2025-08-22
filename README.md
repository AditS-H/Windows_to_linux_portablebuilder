# Windows-to-Linux Portable Installer Builder

## Overview

This script creates a self-contained Linux installer that transforms a GNOME-based Linux system to look and feel like Windows 11. It collects all Windows fonts from your system, packages them, and generates a Linux shell script with embedded fonts and configuration steps.

## Features

- Collects all Windows system and user fonts (`.ttf`, `.otf`)
- Creates a compressed font archive and encodes it for embedding
- Generates a Linux shell installer with:
  - Windows fonts installation
  - GNOME configuration for Windows-like appearance and behavior
  - Windows-style keyboard shortcuts, mouse, and touchpad settings
  - Dash to Dock extension setup
  - Windows-style desktop shortcuts
  - Touchpad gesture configuration
  - Final system optimizations

## Requirements

- **Windows**: Run this script as Administrator to access all fonts.
- **Linux Target**: Ubuntu 20.04+ or Pop!_OS with GNOME, internet connection, sudo privileges.

## Usage

1. **Run the script on Windows**  
   Double-click or run `build portable linux.bat` in a command prompt with admin rights.

2. **Transfer the output files**  
   - `windows-to-linux-installer.sh`: Main Linux installer
   - `windows-to-linux-installer-README.txt`: Instructions
   - `windows-to-linux-installer.bat`: Windows warning launcher

3. **On your Linux system**  
   - Copy `windows-to-linux-installer.sh` to your Linux machine.
   - Run:
     ```bash
     chmod +x windows-to-linux-installer.sh
     ./windows-to-linux-installer.sh
     ```
   - Follow the prompts to complete the transformation.

## What Gets Installed

- All Windows fonts (Segoe UI, Calibri, Arial, etc.)
- Windows 11-style taskbar (Dash to Dock)
- Windows keyboard shortcuts (Super+E, Super+D, Ctrl+Alt+Del, etc.)
- Windows-like mouse and touchpad behavior
- Windows 11 touchpad gestures
- Windows Explorer-style file manager
- Windows fonts as system defaults
- Desktop shortcuts (This PC, Control Panel)
- Complete visual transformation

## After Installation

- Log out and back in (or reboot) for best results.
- Verify Dash to Dock is enabled.
- Use GNOME Tweaks for further customization.
- Optionally install Chrome/Edge for a complete Windows experience.

## Notes

- The installer is for Linux systems only. Do not run the generated `.sh` file on Windows.
- The script requires `tar` and `certutil` on Windows. Install with:
  ```
  winget install GnuWin32.Tar
  ```

---
