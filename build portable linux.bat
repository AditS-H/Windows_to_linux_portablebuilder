@echo off
REM Build Portable Linux Font and Configuration Installer
REM Run this on Windows to create a portable Linux executable

setlocal EnableDelayedExpansion

echo ================================================================
echo   Windows-to-Linux Portable Installer Builder v2.0
echo ================================================================
echo.
echo This will create a self-contained Linux executable that includes:
echo - All Windows fonts from this system
echo - Complete GNOME configuration script
echo - Everything needed to make Linux look/feel like Windows
echo.

REM Check admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Administrator privileges required to access all fonts.
    echo Please run as administrator.
    pause
    exit /b 1
)

set "BUILD_DIR=%~dp0LinuxInstaller"
set "FONTS_DIR=%BUILD_DIR%\fonts"
set "OUTPUT_FILE=%~dp0windows-to-linux-installer"

REM Clean and create build directory
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
mkdir "%BUILD_DIR%"
mkdir "%FONTS_DIR%"

echo [INFO] Collecting Windows fonts...

REM Copy all Windows fonts
echo Copying system fonts...
xcopy "%WINDIR%\Fonts\*.ttf" "%FONTS_DIR%\" /Y /Q 2>nul
xcopy "%WINDIR%\Fonts\*.TTF" "%FONTS_DIR%\" /Y /Q 2>nul  
xcopy "%WINDIR%\Fonts\*.otf" "%FONTS_DIR%\" /Y /Q 2>nul
xcopy "%WINDIR%\Fonts\*.OTF" "%FONTS_DIR%\" /Y /Q 2>nul

REM Copy user fonts if available
if exist "%LOCALAPPDATA%\Microsoft\Windows\Fonts\" (
    echo Copying user fonts...
    xcopy "%LOCALAPPDATA%\Microsoft\Windows\Fonts\*.ttf" "%FONTS_DIR%\" /Y /Q 2>nul
    xcopy "%LOCALAPPDATA%\Microsoft\Windows\Fonts\*.TTF" "%FONTS_DIR%\" /Y /Q 2>nul
    xcopy "%LOCALAPPDATA%\Microsoft\Windows\Fonts\*.otf" "%FONTS_DIR%\" /Y /Q 2>nul
    xcopy "%LOCALAPPDATA%\Microsoft\Windows\Fonts\*.OTF" "%FONTS_DIR%\" /Y /Q 2>nul
)

REM Count fonts
for /f %%i in ('dir /b "%FONTS_DIR%" ^| find /c /v ""') do set FONT_COUNT=%%i
echo [SUCCESS] Collected %FONT_COUNT% font files

echo [INFO] Creating font archive...

REM Create compressed font archive
cd /d "%BUILD_DIR%"
tar -czf fonts.tar.gz fonts/
if not exist fonts.tar.gz (
    echo [ERROR] Failed to create font archive. Make sure tar is available.
    echo You can install tar via: winget install GnuWin32.Tar
    pause
    exit /b 1
)

REM Encode archive to base64
echo [INFO] Encoding font archive...
certutil -encode fonts.tar.gz fonts.b64 >nul
if not exist fonts.b64 (
    echo [ERROR] Failed to encode font archive.
    pause
    exit /b 1
)

echo [INFO] Building self-extracting Linux installer...

REM Create the complete installer script
(
echo #!/bin/bash
echo # Self-Extracting Windows-to-Linux Installer
echo # Generated on %date% %time%
echo # Contains %FONT_COUNT% Windows fonts
echo.
echo # Detect if running on Windows
echo if [[ "$OSTYPE" == "msys" ]] ^|^| [[ "$OSTYPE" == "cygwin" ]] ^|^| [[ -n "$WINDIR" ]]; then
echo     echo "ERROR: This installer is for Linux systems only!"
echo     echo "Please copy this file to your Linux system and run it there."
echo     echo "Usage: chmod +x windows-to-linux-installer && ./windows-to-linux-installer"
echo     exit 1
echo fi
echo.
echo # Colors for output  
echo RED='^033[0;31m'
echo GREEN='^033[0;32m'
echo YELLOW='^033[1;33m'
echo BLUE='^033[0;34m'
echo PURPLE='^033[0;35m'
echo CYAN='^033[0;36m'
echo NC='^033[0m'
echo.
echo print_status^(^) { echo -e "${BLUE}[INFO]${NC} $1"; }
echo print_success^(^) { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
echo print_warning^(^) { echo -e "${YELLOW}[WARNING]${NC} $1"; }
echo print_error^(^) { echo -e "${RED}[ERROR]${NC} $1"; }
echo print_header^(^) { echo -e "${PURPLE}$1${NC}"; }
echo.
echo # Check if running as root
echo if [ "$EUID" -eq 0 ]; then
echo     print_error "Please run as regular user, not root!"
echo     exit 1
echo fi
echo.
echo clear
echo print_header "================================================================"
echo print_header "  🪟→🐧 Windows-to-Linux Complete System Transformer"
echo print_header "================================================================"
echo echo
echo echo -e "${CYAN}This installer will completely transform your Linux system:${NC}"
echo echo "  📦 Extract and install %FONT_COUNT% Windows fonts"
echo echo "  🎨 Configure GNOME to look and feel like Windows 11"
echo echo "  🖱️  Set up Windows-like mouse, touchpad, and gestures"
echo echo "  ⌨️  Install Windows keyboard shortcuts"
echo echo "  📍 Configure bottom taskbar with Windows behavior"
echo echo "  🔧 Apply comprehensive Windows-style system settings"
echo echo
echo echo -e "${YELLOW}Requirements:${NC} Ubuntu/Pop!_OS with GNOME, sudo access, internet"
echo echo -e "${YELLOW}Generated:${NC} %date% from Windows %COMPUTERNAME%"
echo echo
echo read -p "Continue with complete transformation? (y/N): " -n 1 -r
echo echo
echo if [[ ! $REPLY =~ ^[Yy]$ ]]; then
echo     print_status "Installation cancelled."
echo     exit 0
echo fi
echo.
echo # Create temp directory
echo TEMP_DIR="/tmp/win-to-linux-$"
echo mkdir -p "$TEMP_DIR"
echo cd "$TEMP_DIR"
echo.
echo print_status "Extracting embedded Windows fonts archive..."
echo.
echo # Extract embedded font archive
echo SCRIPT_PATH="$(readlink -f "$0")"
echo ARCHIVE_LINE=$(awk '/^__FONT_ARCHIVE_BELOW__/ {print NR + 1; exit 0; }' "$SCRIPT_PATH")
echo.
echo if [ -n "$ARCHIVE_LINE" ]; then
echo     tail -n +$ARCHIVE_LINE "$SCRIPT_PATH" ^| base64 -d ^| tar -xzf - 2^>/dev/null
echo     if [ $? -eq 0 ] && [ -d "fonts" ]; then
echo         FONT_FILES=$(find fonts -name "*.ttf" -o -name "*.TTF" -o -name "*.otf" -o -name "*.OTF" ^| wc -l)
echo         print_success "Extracted $FONT_FILES Windows fonts successfully!"
echo     else
echo         print_warning "Font extraction failed, continuing without custom fonts."
echo         FONT_FILES=0
echo     fi
echo else
echo     print_warning "No embedded font archive found."
echo     FONT_FILES=0
echo fi
echo.
echo # System update
echo print_status "Updating system packages..."
echo sudo apt update ^&^& sudo apt upgrade -y
echo.
echo # Install core dependencies
echo print_status "Installing essential packages..."
echo sudo apt install -y \
echo     fontconfig \
echo     fonts-liberation2 \
echo     ttf-mscorefonts-installer \
echo     gnome-tweaks \
echo     gnome-shell-extensions \
echo     gnome-shell-extension-manager \
echo     libinput-tools \
echo     xdotool \
echo     wmctrl \
echo     git \
echo     curl \
echo     wget \
echo     python3-setuptools \
echo     python3-dev \
echo     python3-pip \
echo     dconf-editor
echo.
echo # Install Dash to Dock extension
echo print_status "Installing Dash to Dock extension..."
echo sudo apt install -y gnome-shell-extension-dashtodock ^|^| {
echo     print_warning "Could not install Dash to Dock via package manager."
echo     print_status "Attempting manual installation..."
echo     
echo     # Manual extension installation
echo     EXT_UUID="dash-to-dock@micxgx.gmail.com"
echo     EXT_DIR="$HOME/.local/share/gnome-shell/extensions/$EXT_UUID"
echo     
echo     if [ ! -d "$EXT_DIR" ]; then
echo         mkdir -p "$HOME/.local/share/gnome-shell/extensions"
echo         cd /tmp
echo         git clone https://github.com/micheleg/dash-to-dock.git
echo         cd dash-to-dock
echo         make install
echo         cd "$TEMP_DIR"
echo     fi
echo }
echo.
echo # Install libinput-gestures for touchpad gestures
echo print_status "Setting up advanced touchpad gestures..."
echo if ! command -v libinput-gestures ^&^> /dev/null; then
echo     cd /tmp
echo     git clone https://github.com/bulletmark/libinput-gestures.git
echo     cd libinput-gestures
echo     sudo make install
echo     cd "$TEMP_DIR"
echo fi
echo sudo gpasswd -a $USER input
echo.
echo # Install Windows fonts if extracted
echo if [ $FONT_FILES -gt 0 ]; then
echo     print_status "Installing $FONT_FILES Windows fonts system-wide..."
echo     
echo     sudo mkdir -p /usr/local/share/fonts/windows-imported
echo     sudo cp fonts/*.ttf /usr/local/share/fonts/windows-imported/ 2^>/dev/null ^|^| true
echo     sudo cp fonts/*.TTF /usr/local/share/fonts/windows-imported/ 2^>/dev/null ^|^| true
echo     sudo cp fonts/*.otf /usr/local/share/fonts/windows-imported/ 2^>/dev/null ^|^| true
echo     sudo cp fonts/*.OTF /usr/local/share/fonts/windows-imported/ 2^>/dev/null ^|^| true
echo     
echo     sudo chmod 644 /usr/local/share/fonts/windows-imported/*
echo     sudo chown root:root /usr/local/share/fonts/windows-imported/*
echo     
echo     print_status "Rebuilding font cache..."
echo     sudo fc-cache -f -v ^> /dev/null
echo     
echo     print_success "Windows fonts installed and activated!"
echo fi
echo.
echo # Configure GNOME interface
echo print_status "Configuring GNOME interface for Windows-like behavior..."
echo.
echo # Mouse and touchpad - Windows-style
echo print_status "• Configuring mouse and touchpad..."
echo gsettings set org.gnome.desktop.peripherals.mouse left-handed false
echo gsettings set org.gnome.desktop.peripherals.mouse natural-scroll false
echo gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false
echo gsettings set org.gnome.desktop.peripherals.mouse speed 0.0
echo gsettings set org.gnome.desktop.peripherals.touchpad speed 0.3
echo gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
echo gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true
echo gsettings set org.gnome.desktop.peripherals.touchpad edge-scrolling-enabled false
echo gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing true
echo.
echo # Dock/Taskbar configuration - Windows 11 style
echo print_status "• Setting up Windows-style taskbar..."
echo gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
echo gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48
echo gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
echo gsettings set org.gnome.shell.extensions.dash-to-dock autohide false
echo gsettings set org.gnome.shell.extensions.dash-to-dock intellihide false
echo gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
echo gsettings set org.gnome.shell.extensions.dash-to-dock show-show-apps-button true
echo gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'cycle-windows'
echo gsettings set org.gnome.shell.extensions.dash-to-dock scroll-action 'cycle-windows'
echo gsettings set org.gnome.shell.extensions.dash-to-dock multi-monitor true
echo gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false
echo gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts false
echo.
echo # Window management - Windows style
echo print_status "• Configuring Windows-style window management..."
echo gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
echo gsettings set org.gnome.desktop.wm.preferences focus-mode 'click'
echo gsettings set org.gnome.desktop.wm.preferences action-double-click-titlebar 'toggle-maximize'
echo gsettings set org.gnome.desktop.wm.preferences action-middle-click-titlebar 'minimize'
echo gsettings set org.gnome.desktop.wm.preferences resize-with-right-button true
echo gsettings set org.gnome.mutter edge-tiling true
echo gsettings set org.gnome.mutter dynamic-workspaces false
echo gsettings set org.gnome.desktop.wm.preferences num-workspaces 4
echo gsettings set org.gnome.shell.overrides edge-tiling true
echo.
echo # Keyboard shortcuts - Windows mapping
echo print_status "• Setting up Windows keyboard shortcuts..."
echo gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"
echo gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Super>d']"
echo gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Alt>Tab']"
echo gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Alt>Tab']"
echo gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>grave']"
echo gsettings set org.gnome.desktop.wm.keybindings close "['<Alt>F4']"
echo gsettings set org.gnome.desktop.wm.keybindings toggle-maximized "['<Super>Up']"
echo gsettings set org.gnome.desktop.wm.keybindings minimize "['<Super>Down']"
echo gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left "['<Super><Shift>Left']"
echo gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right "['<Super><Shift>Right']"
echo.
echo # Custom shortcut for System Monitor ^(Ctrl+Alt+Del^)
echo gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'System Monitor'
echo gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'gnome-system-monitor'
echo gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Ctrl><Alt>Delete'
echo gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
echo.
echo # Interface and appearance
echo print_status "• Applying Windows visual styling..."
echo gsettings set org.gnome.desktop.interface clock-format '12h'
echo gsettings set org.gnome.desktop.interface clock-show-seconds false
echo gsettings set org.gnome.desktop.interface clock-show-weekday true
echo gsettings set org.gnome.desktop.interface show-battery-percentage true
echo gsettings set org.gnome.desktop.interface enable-hot-corners false
echo gsettings set org.gnome.desktop.interface enable-animations true
echo gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
echo gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'
echo gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
echo.
echo # Apply Windows fonts if available
echo if fc-list ^| grep -q "Segoe UI"; then
echo     print_status "• Applying Windows fonts as system defaults..."
echo     gsettings set org.gnome.desktop.interface font-name 'Segoe UI 11'
echo     gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Segoe UI Bold 11'
echo fi
echo.
echo if fc-list ^| grep -q "Calibri"; then
echo     gsettings set org.gnome.desktop.interface document-font-name 'Calibri 11'
echo fi
echo.
echo if fc-list ^| grep -q "Consolas"; then
echo     gsettings set org.gnome.desktop.interface monospace-font-name 'Consolas 10'
echo fi
echo.
echo # File manager ^(Nautilus^) - Windows Explorer style
echo print_status "• Configuring file manager..."
echo gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
echo gsettings set org.gnome.nautilus.preferences show-hidden-files false
echo gsettings set org.gnome.nautilus.list-view use-tree-view true
echo gsettings set org.gnome.nautilus.list-view default-zoom-level 'standard'
echo gsettings set org.gnome.nautilus.preferences executable-text-activation 'ask'
echo gsettings set org.gnome.nautilus.preferences show-create-link true
echo gsettings set org.gnome.nautilus.preferences show-delete-permanently true
echo.
echo # Touchpad gestures - Windows 11 style
echo print_status "• Configuring Windows-style touchpad gestures..."
echo mkdir -p ~/.config
echo cat ^> ~/.config/libinput-gestures.conf ^<^< 'EOF'
echo # Windows 11 style touchpad gestures
echo.
echo # 3-finger gestures
echo gesture swipe up 3 xdotool key super        # Task View
echo gesture swipe down 3 xdotool key super+d    # Show Desktop
echo gesture swipe left 3 xdotool key super+Page_Up   # Previous Desktop
echo gesture swipe right 3 xdotool key super+Page_Down # Next Desktop
echo.
echo # 4-finger gestures
echo gesture swipe up 4 xdotool key super        # Activities Overview
echo gesture swipe down 4 xdotool key super+d    # Show Desktop
echo gesture swipe left 4 xdotool key alt+Left   # Back in applications
echo gesture swipe right 4 xdotool key alt+Right # Forward in applications
echo.
echo # Pinch gestures
echo gesture pinch in xdotool key ctrl+minus     # Zoom out
echo gesture pinch out xdotool key ctrl+plus     # Zoom in
echo EOF
echo.
echo # Start gesture recognition
echo libinput-gestures-setup autostart
echo libinput-gestures-setup start
echo.
echo # Enable GNOME extensions
echo print_status "• Enabling GNOME extensions..."
echo gnome-extensions enable dash-to-dock@micxgx.gmail.com 2^>/dev/null ^|^| print_warning "Enable Dash to Dock manually"
echo.
echo # Create Windows-style desktop shortcuts
echo print_status "• Creating desktop shortcuts..."
echo mkdir -p ~/Desktop
echo.
echo cat ^> ~/Desktop/This\ PC.desktop ^<^< EOF
echo [Desktop Entry]
echo Name=This PC
echo Comment=Browse system drives and devices
echo Exec=nautilus computer:///
echo Icon=computer
echo Type=Application
echo EOF
echo chmod +x ~/Desktop/This\ PC.desktop
echo.
echo cat ^> ~/Desktop/Control\ Panel.desktop ^<^< EOF
echo [Desktop Entry]
echo Name=Control Panel
echo Comment=System settings and configuration
echo Exec=gnome-control-center
echo Icon=preferences-system
echo Type=Application
echo EOF
echo chmod +x ~/Desktop/Control\ Panel.desktop
echo.
echo # Final system configuration
echo print_status "• Applying final system optimizations..."
echo.
echo # Update file associations for Windows-like behavior
echo xdg-mime default org.gnome.Nautilus.desktop inode/directory
echo.
echo # Set up automatic login screen theme
echo sudo update-alternatives --set gdm3.css /usr/share/gnome-shell/theme/Adwaita/gnome-shell.css 2^>/dev/null ^|^| true
echo.
echo # Cleanup
echo cd /
echo rm -rf "$TEMP_DIR"
echo.
echo # Success message
echo clear
echo print_header "================================================================"
echo print_header "  🎉 Windows-to-Linux Transformation Complete! 🎉"
echo print_header "================================================================"
echo echo
echo print_success "Your Linux system has been completely transformed!"
echo echo
echo echo -e "${GREEN}✅ What was configured:${NC}"
echo echo "   🔤 $FONT_FILES Windows fonts installed ^(Segoe UI, Calibri, Arial, etc.^)"
echo echo "   🖱️  Windows-like mouse and touchpad behavior"
echo echo "   📍 Bottom taskbar with Windows 11 styling"
echo echo "   ⌨️  Complete Windows keyboard shortcuts:"
echo echo "      • Super+E → File Manager"
echo echo "      • Super+D → Show Desktop"
echo echo "      • Alt+Tab → App Switcher"
echo echo "      • Ctrl+Alt+Del → System Monitor"
echo echo "      • Alt+F4 → Close Window"
echo echo "   👆 Windows 11 touchpad gestures:"
echo echo "      • 3-finger up → Task View"
echo echo "      • 3-finger down → Show Desktop"
echo echo "      • 3-finger left/right → Switch desktops"
echo echo "   🎨 Windows visual styling and fonts"
echo echo "   📁 Windows Explorer-style file manager"
echo echo "   🖥️  Desktop shortcuts ^(This PC, Control Panel^)"
echo echo
echo echo -e "${YELLOW}Next steps:${NC}"
echo echo "1. ${CYAN}Log out and log back in${NC} ^(or reboot for best results^)"
echo echo "2. Verify Dash to Dock is enabled in Extensions app"
echo echo "3. Use gnome-tweaks for additional customizations"
echo echo "4. Install Chrome/Edge for complete Windows experience"
echo echo
echo echo -e "${BLUE}Your Linux system now looks and feels like Windows 11! 🪟→🐧${NC}"
echo echo -e "${PURPLE}Generated from Windows system: %COMPUTERNAME% on %date%${NC}"
echo echo
echo read -p "Press Enter to finish and reboot..."
echo echo
echo print_status "Rebooting system to apply all changes..."
echo sleep 3
echo sudo reboot
echo.
echo exit 0
echo.
echo # Embedded font archive marker
echo __FONT_ARCHIVE_BELOW__
) > "%OUTPUT_FILE%.sh"

REM Append the base64 encoded font archive
type fonts.b64 >> "%OUTPUT_FILE%.sh"

REM Make the script executable (Linux-style shebang already included)
echo [INFO] Creating portable executables...

REM Create Windows batch launcher
(
echo @echo off
echo echo This installer is for Linux systems only!
echo echo Please copy "%OUTPUT_FILE%.sh" to your Linux system
echo echo and run: chmod +x %OUTPUT_FILE%.sh ^&^& ./%OUTPUT_FILE%.sh
echo echo.
echo pause
) > "%OUTPUT_FILE%.bat"

REM Create instructions file
(
echo ================================================================
echo    Windows-to-Linux Complete System Transformer
echo ================================================================
echo.
echo WHAT THIS PACKAGE CONTAINS:
echo - %FONT_COUNT% Windows fonts from %COMPUTERNAME%
echo - Complete GNOME-to-Windows configuration
echo - Self-extracting installer script
echo.
echo INSTALLATION INSTRUCTIONS:
echo.
echo 1. Copy "%OUTPUT_FILE%.sh" to your Linux system
echo    ^(USB drive, network transfer, etc.^)
echo.
echo 2. On Linux, open terminal and run:
echo    chmod +x %OUTPUT_FILE%.sh
echo    ./%OUTPUT_FILE%.sh
echo.
echo 3. Follow the installer prompts
echo.
echo 4. Log out and back in when complete
echo.
echo WHAT GETS INSTALLED:
echo ✅ All Windows fonts ^(Segoe UI, Calibri, Arial, Times New Roman, etc.^)
echo ✅ Windows 11-style taskbar at bottom
echo ✅ Windows keyboard shortcuts ^(Super+E, Super+D, Ctrl+Alt+Del^)
echo ✅ Windows-like mouse and touchpad behavior  
echo ✅ Windows 11 touchpad gestures
echo ✅ Windows Explorer-style file manager
echo ✅ Windows fonts as system defaults
echo ✅ Desktop shortcuts ^(This PC, Control Panel^)
echo ✅ Complete visual transformation
echo.
echo REQUIREMENTS:
echo - Ubuntu 20.04+ or Pop!_OS with GNOME
echo - Internet connection
echo - User account with sudo privileges
echo.
echo Created: %date% %time%
echo Source: Windows %COMPUTERNAME%
echo.
echo After installation, your Linux system will look and feel
echo exactly like Windows 11!
) > "%OUTPUT_FILE%-README.txt"

REM Cleanup build files
del fonts.tar.gz
del fonts.b64
rmdir /s /q "%BUILD_DIR%"

echo.
echo ================================================================
echo                    BUILD COMPLETED SUCCESSFULLY!
echo ================================================================
echo.
echo Created files:
echo   📦 %OUTPUT_FILE%.sh          - Linux installer ^(MAIN FILE^)
echo   📝 %OUTPUT_FILE%-README.txt  - Instructions
echo   🚫 %OUTPUT_FILE%.bat         - Windows warning
echo.
echo NEXT STEPS:
echo 1. Copy "%OUTPUT_FILE%.sh" to your Linux system
echo 2. Run: chmod +x %OUTPUT_FILE%.sh ^&^& ./%OUTPUT_FILE%.sh
echo 3. Enjoy your Windows-like Linux system!
echo.
echo The installer contains %FONT_COUNT% fonts and complete configuration.
echo File size: 
for %%A in ("%OUTPUT_FILE%.sh") do echo   📊 %%~zA bytes
echo.
echo 🎉 Your portable Windows-to-Linux transformer is ready!
echo.
pause 