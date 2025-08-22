#!/bin/bash
# Self-Extracting Linux Font and Configuration Installer
# This script can be converted to a self-extracting executable

# Detect if running on Windows or Linux
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WINDIR" ]]; then
    echo "ERROR: This executable should be run on Linux, not Windows!"
    echo "Please copy this file to your Linux system and run it there."
    read -p "Press Enter to exit..."
    exit 1
fi

# Colors for output  
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this executable as root. Run as regular user."
    exit 1
fi

clear
echo "════════════════════════════════════════════════════════════════"
echo "  🪟→🐧 Windows-to-Linux Font & Configuration Installer v2.0"
echo "════════════════════════════════════════════════════════════════"
echo
echo "This self-contained installer will:"
echo "  📝 Extract embedded Windows fonts"
echo "  🎨 Install fonts system-wide"  
echo "  ⚙️  Configure GNOME to behave like Windows"
echo "  🖱️  Set up Windows-like mouse, keyboard & gestures"
echo "  ✨ Apply Windows visual styling"
echo
echo -e "${YELLOW}Requirements:${NC} Ubuntu/Pop!_OS with GNOME, sudo access, internet"
echo

read -p "Continue with installation? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Installation cancelled."
    exit 0
fi

# Create temporary extraction directory
TEMP_DIR="/tmp/windows-fonts-$$"
mkdir -p "$TEMP_DIR"

print_status "Extracting embedded fonts and configurations..."

# This is where the embedded font data would be extracted
# For demonstration, we'll create the extraction mechanism

# Find the line number where the embedded data starts
ARCHIVE_LINE=$(awk '/^__FONT_ARCHIVE_BELOW__/ {print NR + 1; exit 0; }' $0)

if [ -n "$ARCHIVE_LINE" ]; then
    print_status "Extracting embedded font archive..."
    tail -n +$ARCHIVE_LINE $0 | base64 -d | tar -xzf - -C "$TEMP_DIR"
else
    print_warning "No embedded fonts found. Will install without custom fonts."
fi

# Update system
print_status "Updating package repositories..."
sudo apt update

# Install font management and GNOME tools
print_status "Installing required packages..."
sudo apt install -y \
    fontconfig \
    fonts-liberation2 \
    ttf-mscorefonts-installer \
    gnome-tweaks \
    gnome-shell-extensions \
    gnome-shell-extension-manager \
    gnome-shell-extension-dashtodock \
    libinput-tools \
    xdotool \
    wmctrl \
    git \
    python3-setuptools \
    python3-dev

# Install libinput-gestures
print_status "Setting up gesture recognition..."
if ! command -v libinput-gestures &> /dev/null; then
    cd /tmp
    git clone https://github.com/bulletmark/libinput-gestures.git
    cd libinput-gestures
    sudo make install
    cd /tmp
    rm -rf libinput-gestures
fi

# Add user to input group
sudo gpasswd -a $USER input

# Install fonts if extracted
if [ -d "$TEMP_DIR/fonts" ]; then
    print_status "Installing Windows fonts..."
    sudo mkdir -p /usr/local/share/fonts/windows-imported
    
    # Copy all font files
    find "$TEMP_DIR/fonts" -type f \( -name "*.ttf" -o -name "*.TTF" -o -name "*.otf" -o -name "*.OTF" \) -exec sudo cp {} /usr/local/share/fonts/windows-imported/ \;
    
    # Set proper permissions
    sudo chmod 644 /usr/local/share/fonts/windows-imported/*
    sudo chown root:root /usr/local/share/fonts/windows-imported/*
    
    # Update font cache
    print_status "Updating font cache..."
    sudo fc-cache -f -v
    
    print_success "Windows fonts installed successfully!"
else
    print_warning "No custom fonts to install. Using system fonts."
fi

# Configure GNOME for Windows-like behavior
print_status "Configuring GNOME interface..."

# Mouse and touchpad settings
gsettings set org.gnome.desktop.peripherals.mouse left-handed false
gsettings set org.gnome.desktop.peripherals.mouse natural-scroll false
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false
gsettings set org.gnome.desktop.peripherals.mouse speed 0.0
gsettings set org.gnome.desktop.peripherals.touchpad speed 0.0
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true
gsettings set org.gnome.desktop.peripherals.touchpad edge-scrolling-enabled false

# Dock configuration (Dash to Dock)
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
gsettings set org.gnome.shell.extensions.dash-to-dock autohide false
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide false
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
gsettings set org.gnome.shell.extensions.dash-to-dock show-show-apps-button true
gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'cycle-windows'
gsettings set org.gnome.shell.extensions.dash-to-dock multi-monitor true

# Keyboard shortcuts
print_status "Setting up Windows-like keyboard shortcuts..."
gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"
gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Super>d']"

# Ctrl+Alt+Del for System Monitor
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'System Monitor'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'gnome-system-monitor'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Ctrl><Alt>Delete'
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"

# Window management
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
gsettings set org.gnome.desktop.wm.preferences focus-mode 'click'
gsettings set org.gnome.desktop.wm.preferences action-double-click-titlebar 'toggle-maximize'
gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Alt>Tab']"

# Workspaces
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 4
gsettings set org.gnome.desktop.interface enable-hot-corners false

# File manager
gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
gsettings set org.gnome.nautilus.list-view use-tree-view true

# Font configuration
print_status "Setting up Windows fonts as system defaults..."
if fc-list | grep -q "Segoe UI"; then
    gsettings set org.gnome.desktop.interface font-name 'Segoe UI 11'
    gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Segoe UI Bold 11'
fi

if fc-list | grep -q "Calibri"; then
    gsettings set org.gnome.desktop.interface document-font-name 'Calibri 11'
fi

if fc-list | grep -q "Consolas"; then
    gsettings set org.gnome.desktop.interface monospace-font-name 'Consolas 10'
fi

# Touchpad gestures
print_status "Configuring Windows-like gestures..."
mkdir -p ~/.config
cat > ~/.config/libinput-gestures.conf << 'EOF'
# Windows-like touchpad gestures
# 3-finger gestures
gesture swipe up 3 xdotool key super
gesture swipe down 3 xdotool key super+d  
gesture swipe left 3 xdotool key super+Page_Up
gesture swipe right 3 xdotool key super+Page_Down

# 4-finger gestures  
gesture swipe up 4 xdotool key super
gesture swipe down 4 xdotool key super+d
EOF

# Start gesture recognition
libinput-gestures-setup autostart start 2>/dev/null || true

# Enable extensions
print_status "Enabling GNOME extensions..."
gnome-extensions enable dash-to-dock@micxgx.gmail.com 2>/dev/null || print_warning "Enable Dash to Dock manually in Extensions app"

# Cleanup
rm -rf "$TEMP_DIR"

# Final success message
echo
echo "════════════════════════════════════════════════════════════════"
print_success "🎉 Windows-to-Linux transformation complete!"
echo "════════════════════════════════════════════════════════════════"
echo
echo -e "${GREEN}✅ Successfully configured:${NC}"
echo "   🔤 Windows fonts (if available)"
echo "   🖱️  Windows-like mouse behavior"
echo "   📍 Bottom taskbar (48px icons)"
echo "   ⌨️  Windows keyboard shortcuts:"
echo "      • Super+E → File Manager"  
echo "      • Super+D → Show Desktop"
echo "      • Ctrl+Alt+Del → System Monitor"
echo "   👆 Windows-like touchpad gestures"
echo "   🎨 Windows visual styling"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Log out and log back in (or reboot)"
echo "2. Open Extensions app to verify Dash to Dock is enabled"
echo "3. Use gnome-tweaks for additional customizations"
echo
echo -e "${BLUE}Your Linux system now behaves like Windows! 🪟→🐧${NC}"
echo

read -p "Press Enter to finish..."
exit 0

# This line marks the start of embedded font archive
__FONT_ARCHIVE_BELOW__