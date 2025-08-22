#!/bin/bash

# GNOME to Windows Configurator Script
# Makes GNOME behave more like Windows in terms of usability, mouse, gestures, and shortcuts
# Compatible with Pop!_OS and Ubuntu GNOME

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root (we don't want that)
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root (sudo). Run as regular user."
    exit 1
fi

# Check if we're on a GNOME desktop
if [ "$XDG_CURRENT_DESKTOP" != "GNOME" ] && [ "$XDG_CURRENT_DESKTOP" != "ubuntu:GNOME" ] && [ "$XDG_CURRENT_DESKTOP" != "pop:GNOME" ]; then
    print_warning "This script is designed for GNOME desktop. Current desktop: $XDG_CURRENT_DESKTOP"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

print_status "Starting GNOME to Windows configuration..."

# Update package list
print_status "Updating package list..."
sudo apt update

# Install required dependencies
print_status "Installing required dependencies..."
sudo apt install -y \
    gnome-tweaks \
    gnome-shell-extensions \
    gnome-shell-extension-manager \
    libinput-tools \
    xdotool \
    wmctrl \
    git \
    python3-setuptools \
    python3-dev \
    python3-pip

# Install libinput-gestures
print_status "Installing libinput-gestures..."
if ! command -v libinput-gestures &> /dev/null; then
    cd /tmp
    git clone https://github.com/bulletmark/libinput-gestures.git
    cd libinput-gestures
    sudo make install
    cd ..
    rm -rf libinput-gestures
fi

# Add user to input group for libinput-gestures
sudo gpasswd -a $USER input

# Install Dash to Dock extension if not present
print_status "Checking for Dash to Dock extension..."
DASH_TO_DOCK_DIR="$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com"
if [ ! -d "$DASH_TO_DOCK_DIR" ]; then
    print_status "Installing Dash to Dock extension..."
    # Try to install via package manager first
    sudo apt install -y gnome-shell-extension-dashtodock || {
        print_warning "Could not install via package manager. Please install Dash to Dock manually from extensions.gnome.org"
    }
fi

# Configure Mouse Settings
print_status "Configuring mouse settings..."
# Set left button as primary (disable left-handed mode)
gsettings set org.gnome.desktop.peripherals.mouse left-handed false
# Natural scrolling off (Windows-like)
gsettings set org.gnome.desktop.peripherals.mouse natural-scroll false
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false
# Set reasonable mouse speed
gsettings set org.gnome.desktop.peripherals.mouse speed 0.0
# Touchpad settings
gsettings set org.gnome.desktop.peripherals.touchpad speed 0.0
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true
gsettings set org.gnome.desktop.peripherals.touchpad edge-scrolling-enabled false

print_success "Mouse settings configured"

# Configure Dock/Taskbar (Dash to Dock)
print_status "Configuring dock settings..."
# Move dock to bottom
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
# Set icon size to 48px
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48
# Always visible (no auto-hide)
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
gsettings set org.gnome.shell.extensions.dash-to-dock autohide false
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide false
# Don't extend to edges (like Windows taskbar)
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
# Show applications button
gsettings set org.gnome.shell.extensions.dash-to-dock show-show-apps-button true
# Click action - minimize or show
gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'cycle-windows'
# Multi-monitor support
gsettings set org.gnome.shell.extensions.dash-to-dock multi-monitor true

print_success "Dock configured to behave like Windows taskbar"

# Configure Keyboard Shortcuts
print_status "Configuring keyboard shortcuts..."

# Super+E for File Manager
gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"

# Super+D for Show Desktop
gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Super>d']"

# Ctrl+Alt+Del for System Monitor
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'System Monitor'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'gnome-system-monitor'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Ctrl><Alt>Delete'
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"

print_success "Keyboard shortcuts configured"

# Configure Touchpad Gestures
print_status "Configuring touchpad gestures..."

# Create libinput-gestures config
mkdir -p ~/.config
cat > ~/.config/libinput-gestures.conf << 'EOF'
# GNOME to Windows Gestures Configuration
# 3-finger gestures

# Swipe up with 3 fingers - Show Activities Overview
gesture swipe up 3 xdotool key super

# Swipe down with 3 fingers - Show Desktop (minimize all)
gesture swipe down 3 xdotool key super+d

# Swipe left with 3 fingers - Previous workspace
gesture swipe left 3 xdotool key super+Page_Up

# Swipe right with 3 fingers - Next workspace  
gesture swipe right 3 xdotool key super+Page_Down

# 4-finger gestures (optional)
# Swipe up with 4 fingers - Activities Overview
gesture swipe up 4 xdotool key super

# Swipe down with 4 fingers - Show Desktop
gesture swipe down 4 xdotool key super+d
EOF

# Enable and start libinput-gestures
libinput-gestures-setup autostart start

print_success "Touchpad gestures configured"

# Additional GNOME Settings for Windows-like behavior
print_status "Applying additional Windows-like settings..."

# Window management
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
gsettings set org.gnome.desktop.wm.preferences focus-mode 'click'
gsettings set org.gnome.desktop.wm.preferences action-double-click-titlebar 'toggle-maximize'

# Enable minimize and maximize buttons
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'

# Set Alt+Tab to switch between windows (should already be default)
gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Alt>Tab']"

# Workspaces
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 4

# Hot corner (disable it for Windows-like experience)
gsettings set org.gnome.desktop.interface enable-hot-corners false

# Files (Nautilus) settings
gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
gsettings set org.gnome.nautilus.list-view use-tree-view true

print_success "Additional Windows-like settings applied"

# Enable extensions
print_status "Enabling GNOME extensions..."
gnome-extensions enable dash-to-dock@micxgx.gmail.com 2>/dev/null || print_warning "Could not enable Dash to Dock extension automatically"

# Create a desktop entry for easy access to settings
print_status "Creating quick settings launcher..."
cat > ~/.local/share/applications/windows-like-settings.desktop << EOF
[Desktop Entry]
Name=Windows-like Settings
Comment=Quick access to GNOME settings for Windows-like behavior
Exec=gnome-tweaks
Icon=preferences-system
Type=Application
Categories=Settings;
EOF

# Final message
print_success "Configuration completed successfully!"
echo
echo -e "${GREEN}✅ GNOME has been configured for Windows-like behavior!${NC}"
echo
echo -e "${YELLOW}Configured features:${NC}"
echo "  🖱️  Mouse: Left-click primary, Windows-like scrolling"
echo "  📍 Dock: Bottom position, 48px icons, always visible"
echo "  ⌨️  Shortcuts:"
echo "     • Super+E → File Manager"
echo "     • Super+D → Show Desktop"  
echo "     • Ctrl+Alt+Del → System Monitor"
echo "  👆 Gestures (3-finger):"
echo "     • Swipe Up → Activities Overview"
echo "     • Swipe Down → Show Desktop"
echo "     • Swipe Left → Previous Workspace"
echo "     • Swipe Right → Next Workspace"
echo
echo -e "${BLUE}Please log out and log back in (or reboot) for all changes to take effect.${NC}"
echo -e "${BLUE}You may need to enable the Dash to Dock extension manually in Extensions app.${NC}"
echo
echo -e "${YELLOW}If you want to fine-tune settings, use: gnome-tweaks${NC}"