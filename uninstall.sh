#!/bin/bash
# Klipper Discord Notifier - Uninstaller

set -e

echo "Uninstalling Klipper Discord Notifier..."

# Find Klipper directory
if [ -d ~/klipper ]; then
    KLIPPER_DIR=~/klipper
elif [ -d ~/klipper_py3 ]; then
    KLIPPER_DIR=~/klipper_py3
else
    echo "Error: Could not find Klipper directory"
    exit 1
fi

# Find printer.cfg
if [ -f ~/printer_data/config/printer.cfg ]; then
    PRINTER_CFG=~/printer_data/config/printer.cfg
elif [ -f ~/klipper_config/printer.cfg ]; then
    PRINTER_CFG=~/klipper_config/printer.cfg
elif [ -f ~/.config/printer.cfg ]; then
    PRINTER_CFG=~/.config/printer.cfg
else
    echo "Error: Could not find printer.cfg"
    echo "Please specify location:"
    read -p "Path to printer.cfg: " PRINTER_CFG
fi

# Remove plugin file
if [ -f "$KLIPPER_DIR/klippy/extras/discord_notifier.py" ]; then
    echo "Removing plugin file..."
    rm "$KLIPPER_DIR/klippy/extras/discord_notifier.py"
    echo "✓ Plugin file removed"
else
    echo "Plugin file not found (already removed?)"
fi

# Remove configuration from printer.cfg
if grep -q "\[discord_notifier\]" "$PRINTER_CFG"; then
    echo "Removing configuration from printer.cfg..."
    
    # Backup original
    cp "$PRINTER_CFG" "${PRINTER_CFG}.uninstall_backup"
    
    # Remove the discord_notifier section
    # This removes the comment, section header, and all lines until the next section or end
    sed -i '/^# Discord Notifications$/,/^\[discord_notifier\]$/d' "$PRINTER_CFG"
    sed -i '/^\[discord_notifier\]/,/^$/d' "$PRINTER_CFG"
    sed -i '/^webhook_url:/d' "$PRINTER_CFG"
    sed -i '/^printer_name: Klipper$/d' "$PRINTER_CFG"
    
    # Clean up extra blank lines
    sed -i '/^$/N;/^\n$/d' "$PRINTER_CFG"
    
    echo "✓ Configuration removed (backup: ${PRINTER_CFG}.uninstall_backup)"
else
    echo "Configuration not found in printer.cfg (already removed?)"
fi

# Restart Klipper
echo ""
echo "Restarting Klipper..."
sudo systemctl restart klipper

echo ""
echo "✅ Uninstall complete!"
echo ""
echo "If you have any issues, restore from backup:"
echo "  cp ${PRINTER_CFG}.uninstall_backup $PRINTER_CFG"
echo "  sudo systemctl restart klipper"
