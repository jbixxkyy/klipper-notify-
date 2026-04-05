#!/bin/bash
# Klipper Discord Notifier - One-Command Installer
# Usage: bash install.sh YOUR_WEBHOOK_URL

set -e

WEBHOOK_URL="$1"

if [ -z "$WEBHOOK_URL" ]; then
    echo "Usage: bash install.sh YOUR_DISCORD_WEBHOOK_URL"
    echo ""
    echo "Get your webhook URL from Discord:"
    echo "1. Open Discord → Server Settings → Integrations → Webhooks"
    echo "2. Click 'New Webhook'"
    echo "3. Copy the webhook URL"
    exit 1
fi

echo "Installing Klipper Discord Notifier..."

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

# Copy plugin
echo "Installing plugin..."
cp discord_notifier.py "$KLIPPER_DIR/klippy/extras/"

# Check if already configured
if grep -q "\[discord_notifier\]" "$PRINTER_CFG"; then
    echo ""
    echo "⚠️  discord_notifier already exists in printer.cfg"
    echo "Skipping configuration. Update manually if needed."
else
    # Add configuration at top after [include] sections
    # Create temp file with new config
    cat > /tmp/discord_config.tmp << EOF
# Discord Notifications
[discord_notifier]
webhook_url: $WEBHOOK_URL
printer_name: Klipper

EOF

    # Find where to insert (after last [include] line, or at top if no includes)
    if grep -q "^\[include " "$PRINTER_CFG"; then
        # Find last include line number
        LAST_INCLUDE=$(grep -n "^\[include " "$PRINTER_CFG" | tail -1 | cut -d: -f1)
        # Insert after last include
        head -n $LAST_INCLUDE "$PRINTER_CFG" > /tmp/printer_new.cfg
        cat /tmp/discord_config.tmp >> /tmp/printer_new.cfg
        tail -n +$((LAST_INCLUDE + 1)) "$PRINTER_CFG" >> /tmp/printer_new.cfg
    else
        # No includes found, add at very top
        cat /tmp/discord_config.tmp > /tmp/printer_new.cfg
        cat "$PRINTER_CFG" >> /tmp/printer_new.cfg
    fi
    
    # Backup original and replace
    cp "$PRINTER_CFG" "${PRINTER_CFG}.backup"
    mv /tmp/printer_new.cfg "$PRINTER_CFG"
    rm -f /tmp/discord_config.tmp
    
    echo "Configuration added to printer.cfg (backup saved as printer.cfg.backup)"
fi

# Restart Klipper
echo ""
echo "Restarting Klipper..."
sudo systemctl restart klipper

echo ""
echo "✅ Installation complete!"
echo ""
echo 'Test with: DISCORD_NOTIFY MESSAGE="Hello from Klipper!"'
echo ""
echo "To customize, edit the [discord_notifier] section in printer.cfg"
echo "Options:"
echo "  enable_print_start: True/False"
echo "  enable_print_complete: True/False"
echo "  enable_print_pause: True/False"
echo "  enable_print_cancel: True/False"
echo "  enable_error: True/False"
