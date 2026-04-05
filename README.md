# Klipper Discord Notifier (Lightweight)

Super simple Discord notifications for your Klipper 3D printer. Uses minimal CPU and memory.

## ⚡ Quick Install (30 seconds)

### Step 1: Get Discord Webhook URL
1. Open Discord → Server Settings → Integrations → Webhooks
2. Click "New Webhook"  
3. Copy the webhook URL

### Step 2: Install
```bash
cd ~
# Download files (or upload them to your Pi)
bash install.sh YOUR_WEBHOOK_URL_HERE
```

**Done!** You'll now get notifications for prints starting, completing, pausing, and errors.

The config will be added at the top of your `printer.cfg` right after any `[include]` lines.

---

## 🗑️ Uninstall

```bash
cd ~
bash uninstall.sh
```

This removes the plugin file, removes the config from `printer.cfg`, and restarts Klipper. A backup is saved automatically.

---

## 📋 What You Get

- 🖨️ **Print started** - "Started: filename.gcode"
- ✅ **Print complete** - "Complete: filename.gcode"  
- ⏸️ **Print paused** - "Paused: filename.gcode"
- 🛑 **Print cancelled** - "Cancelled: filename.gcode"
- ❌ **Errors** - "Error: filename.gcode"
- 💬 **Custom messages** - Send from G-code macros

---

## 🎮 Usage

### Automatic Notifications
Just print normally - notifications happen automatically!

### Manual Notifications from G-code
```gcode
DISCORD_NOTIFY MESSAGE="First layer looks good!"

DISCORD_NOTIFY MESSAGE="Filament change needed"
```

### Add to Your Macros
```gcode
[gcode_macro FILAMENT_CHANGE]
gcode:
    PAUSE
    DISCORD_NOTIFY MESSAGE="Please load new filament"
```

---

## ⚙️ Configuration

Your `printer.cfg` will have this added:

```ini
[discord_notifier]
webhook_url: https://discord.com/api/webhooks/...
printer_name: Klipper
```

### Optional Settings
Turn notifications on/off:
```ini
[discord_notifier]
webhook_url: https://discord.com/api/webhooks/...
printer_name: My Ender 3
enable_print_start: True
enable_print_complete: True
enable_print_pause: True
enable_print_cancel: True
enable_error: True
```

After changing config: `sudo systemctl restart klipper`

---

## 🔧 Manual Installation

If you prefer to install manually:

1. **Copy plugin:**
   ```bash
   cp discord_notifier.py ~/klipper/klippy/extras/
   ```

2. **Edit printer.cfg:**
   ```ini
   [discord_notifier]
   webhook_url: https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE
   printer_name: Klipper
   ```

3. **Restart:**
   ```bash
   sudo systemctl restart klipper
   ```

---

## 💡 Why This Version?

- **Lightweight:** Uses `curl` instead of Python libraries
- **Minimal CPU:** No progress tracking, no timers, no calculations
- **Low Memory:** Simple event handlers only
- **Fast:** Background webhook calls don't block Klipper
- **Reliable:** Fewer dependencies = fewer things to break

Perfect for Raspberry Pi Zero or older boards!

---

## ❓ Troubleshooting

**No notifications?**
```bash
# Check Klipper log
tail -f ~/printer_data/logs/klippy.log

# Test curl manually
curl -X POST -H "Content-Type: application/json" \
  -d '{"content":"Test"}' \
  YOUR_WEBHOOK_URL
```

**Plugin not loading?**
- Verify file is at `~/klipper/klippy/extras/discord_notifier.py`
- Check `printer.cfg` has `[discord_notifier]` section
- Restart Klipper: `sudo systemctl restart klipper`

---

## 🎯 Examples

### Minimal (default)
```ini
[discord_notifier]
webhook_url: https://discord.com/api/webhooks/1234/abcd
```

### Named Printer
```ini
[discord_notifier]
webhook_url: https://discord.com/api/webhooks/1234/abcd
printer_name: Ender 3 V2
```

### Errors Only
```ini
[discord_notifier]
webhook_url: https://discord.com/api/webhooks/1234/abcd
enable_print_start: False
enable_print_complete: False
enable_print_pause: False
enable_print_cancel: False
enable_error: True
```

---

## 📝 License

MIT - Use it however you want!
# klipper-notify-
