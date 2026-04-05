# Discord Notifier for Klipper - Lightweight Edition
# Installation:
# 1. Copy this file to ~/klipper/klippy/extras/discord_notifier.py
# 2. Add [discord_notifier] section to printer.cfg
# 3. Restart Klipper

import logging

class DiscordNotifier:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.reactor = self.printer.get_reactor()
        self.webhook_url = config.get('webhook_url')
        self.printer_name = config.get('printer_name', 'Klipper')
        self.print_stats = None
        self.state_timer = None
        self.last_state = None
        self.last_filename = None
        
        # Simplified event tracking - only what's enabled
        self.events = {
            'start': config.getboolean('enable_print_start', True),
            'complete': config.getboolean('enable_print_complete', True),
            'pause': config.getboolean('enable_print_pause', True),
            'cancel': config.getboolean('enable_print_cancel', True),
            'error': config.getboolean('enable_error', True)
        }
        
        # Register only necessary handlers
        self.printer.register_event_handler("klippy:ready", self._handle_ready)
        if self.events['error']:
            self.printer.register_event_handler("klippy:shutdown", self._handle_shutdown)
        
        # G-code command for manual notifications
        self.gcode = self.printer.lookup_object('gcode')
        self.gcode.register_command('DISCORD_NOTIFY', 
                                    self.cmd_DISCORD_NOTIFY,
                                    desc=self.cmd_DISCORD_NOTIFY_help)
        
    cmd_DISCORD_NOTIFY_help = 'Send a Discord notification: DISCORD_NOTIFY MESSAGE="text"'
    
    def cmd_DISCORD_NOTIFY(self, gcmd):
        msg = gcmd.get('MESSAGE', None)
        if msg:
            self._send(msg)
    
    def _handle_ready(self):
        # Poll print_stats because it does not emit a state_changed event.
        if not any(self.events.values()):
            return
        try:
            self.print_stats = self.printer.lookup_object('print_stats')
            status = self.print_stats.get_status(self.reactor.monotonic())
            self.last_state = status.get('state')
            self.last_filename = status.get('filename', 'file')
            if self.state_timer is not None:
                self.reactor.unregister_timer(self.state_timer)
            self.state_timer = self.reactor.register_timer(
                self._poll_state, self.reactor.monotonic() + 1.0)
        except Exception:
            logging.info("discord_notifier: print tracking not available")
    
    def _handle_shutdown(self):
        try:
            if self.print_stats is None:
                return
            state = self.print_stats.get_status(self.reactor.monotonic())['state']
            if state == 'printing':
                self._send("⚠️ Printer shutdown during print")
        except Exception:
            pass
    
    def _poll_state(self, eventtime):
        try:
            if self.print_stats is None:
                return self.reactor.NEVER
            stats = self.print_stats.get_status(eventtime)
            state = stats.get('state')
            prev_state = self.last_state
            filename = stats.get('filename', 'file')
            
            # Simple state notifications - no calculations
            if state == 'printing' and prev_state in ['standby', 'ready'] and self.events['start']:
                self._send(f"🖨️ Started: {filename}")
            
            elif state == 'complete' and prev_state != 'complete' and self.events['complete']:
                self._send(f"✅ Complete: {filename}")
            
            elif state == 'paused' and prev_state != 'paused' and self.events['pause']:
                self._send(f"⏸️ Paused: {filename}")
            
            elif state == 'cancelled' and prev_state != 'cancelled' and self.events['cancel']:
                self._send(f"🛑 Cancelled: {filename}")
            
            elif state == 'error' and prev_state != 'error' and self.events['error']:
                self._send(f"❌ Error: {filename}")
            self.last_state = state
            self.last_filename = filename
        except Exception:
            logging.exception("discord_notifier: state poll failed")
        return eventtime + 1.0
    
    def _send(self, message):
        # Minimal payload - just text, no embeds
        import json
        try:
            # Use shell command for minimal overhead
            cmd = f'curl -X POST -H "Content-Type: application/json" -d \'{{"content":"{self.printer_name}: {message}"}}\' "{self.webhook_url}" >/dev/null 2>&1 &'
            import os
            os.system(cmd)
        except:
            pass

def load_config(config):
    return DiscordNotifier(config)
