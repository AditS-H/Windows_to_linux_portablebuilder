@echo off
REM Windows Font and Configuration Collector
REM Run this script on Windows to collect fonts and create portable Linux installer

setlocal EnableDelayedExpansion

echo ================================================
echo    Windows Font and Config Collector v1.0
echo ================================================
echo.
echo This script will:
echo - Copy all Windows fonts
echo - Create a portable Linux installer
echo - Package everything for easy Linux deployment
echo.

REM Check for admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] This script requires administrator privileges.
    echo Please run as administrator.
    pause
    exit /b 1
)

REM Create output directory
set "OUTPUT_DIR=%~dp0LinuxFontPack"
if exist "%OUTPUT_DIR%" rmdir /s /q "%OUTPUT_DIR%"
mkdir "%OUTPUT_DIR%"
mkdir "%OUTPUT_DIR%\fonts"
mkdir "%OUTPUT_DIR%\config"

echo [INFO] Creating font collection...

REM Copy Windows fonts
echo Copying fonts from Windows\Fonts...
xcopy "%WINDIR%\Fonts\*" "%OUTPUT_DIR%\fonts\" /E /H /Y /Q

REM Copy fonts from user profile (if any)
if exist "%LOCALAPPDATA%\Microsoft\Windows\Fonts\" (
    echo Copying user fonts...
    xcopy "%LOCALAPPDATA%\Microsoft\Windows\Fonts\*" "%OUTPUT_DIR%\fonts\" /E /H /Y /Q
)

echo [SUCCESS] Fonts copied successfully!
echo Total fonts collected: 
dir /b "%OUTPUT_DIR%\fonts" | find /c /v "" 

REM Create the Linux installer script
echo [INFO] Creating Linux installer script...

(
echo #!/bin/bash
echo # Portable Linux Font and GNOME Configurator
echo # Auto-generated from Windows system
echo.
echo set -e
echo.
echo # Colors for output
echo RED='^033[0;31m'
echo GREEN='^033[0;32m'
echo YELLOW='^033[1;33m'
echo BLUE='^033[0;34m'
echo NC='^033[0m'
echo.
echo print_status^(^) {
echo     echo -e "${BLUE}[INFO]${NC} $1"
echo }
echo.
echo print_success^(^) {
echo     echo -e "${GREEN}[SUCCESS]${NC} $1"
echo }
echo.
echo print_warning^(^) {
echo     echo -e "${YELLOW}[WARNING]${NC} $1"
echo }
echo.
echo print_error^(^) {
echo     echo -e "${RED}[ERROR]${NC} $1"
echo }
echo.
echo # Get script directory
echo SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo FONT_DIR="$SCRIPT_DIR/fonts"
echo.
echo if [ "$EUID" -eq 0 ]; then
echo     print_error "Please do not run this script as root. Run as regular user."
echo     exit 1
echo fi
echo.
echo echo "=================================================="
echo echo "    Portable Linux Font and GNOME Configurator"
echo echo "=================================================="
echo echo
echo echo "This installer will:"
echo echo "- Install Windows fonts for perfect compatibility"
echo echo "- Configure GNOME to behave like Windows"
echo echo "- Set up gestures, shortcuts, and appearance"
echo echo
echo.
echo # Check if fonts directory exists
echo if [ ! -d "$FONT_DIR" ]; then
echo     print_error "Fonts directory not found. Make sure fonts/ folder is in the same directory as this script."
echo     exit 1
echo fi
echo.
echo print_status "Starting installation..."
echo.
echo # Update system
echo print_status "Updating package list..."
echo sudo apt update
echo.
echo # Install font management tools
echo print_status "Installing font management tools..."
echo sudo apt install -y fontconfig fonts-liberation2 ttf-mscorefonts-installer
echo.
echo # Create fonts directory
echo print_status "Installing Windows fonts..."
echo sudo mkdir -p /usr/local/share/fonts/windows-fonts
echo.
echo # Copy fonts
echo sudo cp "$FONT_DIR"/*.ttf /usr/local/share/fonts/windows-fonts/ 2^>/dev/null ^|^| true
echo sudo cp "$FONT_DIR"/*.TTF /usr/local/share/fonts/windows-fonts/ 2^>/dev/null ^|^| true
echo sudo cp "$FONT_DIR"/*.otf /usr/local/share/fonts/windows-fonts/ 2^>/dev/null ^|^| true
echo sudo cp "$FONT_DIR"/*.OTF /usr/local/share/fonts/windows-fonts/ 2^>/dev/null ^|^| true
echo.
echo # Set permissions
echo sudo chmod 644 /usr/local/share/fonts/windows-fonts/*
echo sudo chown root:root /usr/local/share/fonts/windows-fonts/*
echo.
echo # Update font cache
echo print_status "Updating font cache..."
echo sudo fc-cache -f -v
echo.
echo print_success "Windows fonts installed successfully!"
echo.
echo # Install GNOME configuration dependencies
echo print_status "Installing GNOME configuration tools..."
echo sudo apt install -y \
echo     gnome-tweaks \
echo     gnome-shell-extensions \
echo     gnome-shell-extension-manager \
echo     libinput-tools \
echo     xdotool \
echo     wmctrl \
echo     git \
echo     python3-setuptools \
echo     python3-dev \
echo     python3-pip
echo.
echo # Install libinput-gestures
echo print_status "Installing libinput-gestures..."
echo if ! command -v libinput-gestures ^&^> /dev/null; then
echo     cd /tmp
echo     git clone https://github.com/bulletmark/libinput-gestures.git
echo     cd libinput-gestures
echo     sudo make install
echo     cd ..
echo     rm -rf libinput-gestures
echo fi
echo.
echo sudo gpasswd -a $USER input
echo.
echo # Install Dash to Dock
echo print_status "Installing Dash to Dock extension..."
echo sudo apt install -y gnome-shell-extension-dashtodock ^|^| print_warning "Install Dash to Dock manually"
echo.
echo # Configure mouse settings
echo print_status "Configuring mouse settings..."
echo gsettings set org.gnome.desktop.peripherals.mouse left-handed false
echo gsettings set org.gnome.desktop.peripherals.mouse natural-scroll false
echo gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false
echo gsettings set org.gnome.desktop.peripherals.mouse speed 0.0
echo gsettings set org.gnome.desktop.peripherals.touchpad speed 0.0
echo gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
echo gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true
echo gsettings set org.gnome.desktop.peripherals.touchpad edge-scrolling-enabled false
echo.
echo # Configure dock
echo print_status "Configuring dock..."
echo gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
echo gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48
echo gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
echo gsettings set org.gnome.shell.extensions.dash-to-dock autohide false
echo gsettings set org.gnome.shell.extensions.dash-to-dock intellihide false
echo gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
echo gsettings set org.gnome.shell.extensions.dash-to-dock show-show-apps-button true
echo gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'cycle-windows'
echo gsettings set org.gnome.shell.extensions.dash-to-dock multi-monitor true
echo.
echo # Configure keyboard shortcuts
echo print_status "Configuring keyboard shortcuts..."
echo gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"
echo gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Super>d']"
echo gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'System Monitor'
echo gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'gnome-system-monitor'
echo gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Ctrl><Alt>Delete'
echo gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
echo.
echo # Configure gestures
echo print_status "Configuring touchpad gestures..."
echo mkdir -p ~/.config
echo cat ^> ~/.config/libinput-gestures.conf ^<^< 'EOF'
echo # Windows-like gestures
echo gesture swipe up 3 xdotool key super
echo gesture swipe down 3 xdotool key super+d
echo gesture swipe left 3 xdotool key super+Page_Up
echo gesture swipe right 3 xdotool key super+Page_Down
echo gesture swipe up 4 xdotool key super
echo gesture swipe down 4 xdotool key super+d
echo EOF
echo libinput-gestures-setup autostart start
echo.
echo # Configure fonts in GNOME
echo print_status "Configuring system fonts..."
echo gsettings set org.gnome.desktop.interface font-name 'Segoe UI 11'
echo gsettings set org.gnome.desktop.interface document-font-name 'Calibri 11'
echo gsettings set org.gnome.desktop.interface monospace-font-name 'Consolas 10'
echo gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Segoe UI Bold 11'
echo.
echo # Additional Windows-like settings
echo print_status "Applying Windows-like settings..."
echo gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
echo gsettings set org.gnome.desktop.wm.preferences focus-mode 'click'
echo gsettings set org.gnome.desktop.wm.preferences action-double-click-titlebar 'toggle-maximize'
echo gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Alt>Tab']"
echo gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Alt>Tab']"
echo gsettings set org.gnome.mutter dynamic-workspaces false
echo gsettings set org.gnome.desktop.wm.preferences num-workspaces 4
echo gsettings set org.gnome.desktop.interface enable-hot-corners false
echo gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
echo gsettings set org.gnome.nautilus.list-view use-tree-view true
echo.
echo # Enable extensions
echo gnome-extensions enable dash-to-dock@micxgx.gmail.com 2^>/dev/null ^|^| print_warning "Enable Dash to Dock manually"
echo.
echo echo
echo print_success "Installation completed successfully!"
echo echo
echo echo -e "${GREEN}✅ Your Linux system now has Windows fonts and Windows-like behavior!${NC}"
echo echo
echo echo -e "${YELLOW}What was installed:${NC}"
echo echo "  🔤 Windows fonts ^(Segoe UI, Calibri, Consolas, etc.^)"
echo echo "  🖱️  Windows-like mouse behavior"
echo echo "  📍 Bottom taskbar with Windows-style dock"
echo echo "  ⌨️  Windows keyboard shortcuts"
echo echo "  👆 Windows-like touchpad gestures"
echo echo "  🎨 Windows fonts as system defaults"
echo echo
echo echo -e "${BLUE}Please log out and log back in for all changes to take effect.${NC}"
echo echo -e "${YELLOW}Available fonts: Segoe UI, Calibri, Consolas, Times New Roman, Arial, and many more!${NC}"
echo echo
echo read -p "Press Enter to exit..."
) > "%OUTPUT_DIR%\install-linux-config.sh"

REM Create README file
echo [INFO] Creating README file...
(
echo Windows Font and Linux Configuration Package
echo ==========================================
echo.
echo This package contains:
echo - All Windows fonts from your system
echo - Automated Linux installer script
echo.
echo USAGE:
echo 1. Copy this entire LinuxFontPack folder to your Linux system
echo 2. Open terminal in the LinuxFontPack directory
echo 3. Run: chmod +x install-linux-config.sh
echo 4. Run: ./install-linux-config.sh
echo.
echo The installer will:
echo - Install all Windows fonts system-wide
echo - Configure GNOME to behave like Windows
echo - Set up proper keyboard shortcuts and gestures
echo - Apply Windows fonts as system defaults
echo.
echo REQUIREMENTS:
echo - Ubuntu/Pop!_OS with GNOME desktop
echo - Internet connection for package installation
echo - User account with sudo privileges
echo.
echo After installation, log out and back in to see all changes.
) > "%OUTPUT_DIR%\README.txt"

REM Create Windows executable wrapper script
echo [INFO] Creating Windows executable wrapper...
(
echo @echo off
echo cd /d "%%~dp0"
echo echo Starting Linux Font and Configuration Installer...
echo echo.
echo if not exist install-linux-config.sh ^(
echo     echo ERROR: install-linux-config.sh not found!
echo     echo Make sure all files are in the same directory.
echo     pause
echo     exit /b 1
echo ^)
echo.
echo echo This will launch the Linux installer script.
echo echo Make sure you're running this on a Linux system!
echo echo.
echo pause
echo.
echo REM Try to detect if we're in WSL or similar
echo bash install-linux-config.sh
echo.
echo pause
) > "%OUTPUT_DIR%\install-linux-config.bat"

echo.
echo [SUCCESS] Package created successfully!
echo.
echo Output directory: %OUTPUT_DIR%
echo.
echo Package contents:
echo - fonts/          : All Windows fonts
echo - install-linux-config.sh : Linux installer script  
echo - install-linux-config.bat: Windows launcher
echo - README.txt      : Instructions
echo.
echo NEXT STEPS:
echo 1. Copy the entire LinuxFontPack folder to a USB drive
echo 2. Boot your Linux system
echo 3. Copy LinuxFontPack folder to Linux desktop
echo 4. Open terminal and run: ./install-linux-config.sh
echo.
echo The installer will set up everything automatically!
echo.
pause