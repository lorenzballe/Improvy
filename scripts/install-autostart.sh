#!/bin/bash

# Install Auto-Startup (macOS/Linux)
# Run this ONCE to setup automatic startup of AI toolkit

echo "🚀 Installing Auto-Startup for Improvy AI Toolkit"
echo "=================================================="
echo ""

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="Linux"
else
    echo "❌ Unsupported OS: $OSTYPE"
    exit 1
fi

# Get project path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_PATH="$(cd "$SCRIPT_DIR/.." && pwd)"
HEALTH_CHECK="$SCRIPT_DIR/health-check.py"

echo "OS: $OS"
echo "Project Path: $PROJECT_PATH"
echo "Health Check Script: $HEALTH_CHECK"
echo ""

# Check if script exists
if [ ! -f "$HEALTH_CHECK" ]; then
    echo "❌ health-check.py not found at $HEALTH_CHECK"
    exit 1
fi

echo "✓ health-check.py found"
echo ""

if [ "$OS" == "macOS" ]; then
    # macOS launchd setup
    echo "Setting up macOS launchd agent..."
    echo ""

    PLIST_DIR="$HOME/Library/LaunchAgents"
    PLIST_FILE="$PLIST_DIR/com.improvy.ai-toolkit.plist"

    mkdir -p "$PLIST_DIR"

    # Create plist file
    cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.improvy.ai-toolkit</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>$HEALTH_CHECK</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartInterval</key>
    <integer>300</integer>
    <key>StandardOutPath</key>
    <string>$HOME/.improvy-ai-toolkit.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/.improvy-ai-toolkit-error.log</string>
</dict>
</plist>
EOF

    echo "✅ Created $PLIST_FILE"
    echo ""

    # Load the plist
    launchctl load "$PLIST_FILE"
    echo "✅ Loaded launchd agent"
    echo ""

    echo "macOS Setup Complete:"
    echo "  • Runs at login"
    echo "  • Checks every 5 minutes"
    echo ""
    echo "To manage:"
    echo "  • View status:   launchctl list | grep ai-toolkit"
    echo "  • View logs:     tail -f ~/.improvy-ai-toolkit.log"
    echo "  • Unload:        launchctl unload ~/Library/LaunchAgents/com.improvy.ai-toolkit.plist"
    echo ""

elif [ "$OS" == "Linux" ]; then
    # Linux systemd setup
    echo "Setting up Linux systemd timer..."
    echo ""

    SERVICE_DIR="$HOME/.config/systemd/user"
    SERVICE_FILE="$SERVICE_DIR/improvy-ai-toolkit.service"
    TIMER_FILE="$SERVICE_DIR/improvy-ai-toolkit.timer"

    mkdir -p "$SERVICE_DIR"

    # Create service file
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Improvy AI Toolkit Auto-Start
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/python3 $HEALTH_CHECK
StandardOutput=journal
StandardError=journal
EOF

    echo "✓ Created $SERVICE_FILE"

    # Create timer file
    cat > "$TIMER_FILE" << EOF
[Unit]
Description=Improvy AI Toolkit Auto-Start Timer
Requires=improvy-ai-toolkit.service

[Timer]
OnBootSec=30s
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
EOF

    echo "✓ Created $TIMER_FILE"
    echo ""

    # Reload and enable
    systemctl --user daemon-reload
    systemctl --user enable improvy-ai-toolkit.timer
    systemctl --user start improvy-ai-toolkit.timer

    echo "✅ Installed systemd timer"
    echo ""

    echo "Linux Setup Complete:"
    echo "  • Runs at boot (30s delay)"
    echo "  • Checks every 5 minutes"
    echo ""
    echo "To manage:"
    echo "  • View status:   systemctl --user status improvy-ai-toolkit.timer"
    echo "  • View logs:     journalctl --user -u improvy-ai-toolkit.service"
    echo "  • Disable:       systemctl --user disable improvy-ai-toolkit.timer"
    echo ""
fi

# Optionally run now
echo ""
read -p "Run health check now? (Y/n) " -n 1 -r
echo ""

if [[ $REPLY != "n" && $REPLY != "N" ]]; then
    echo ""
    echo "Running health check..."
    echo ""
    python3 "$HEALTH_CHECK"
    echo ""
fi

echo "✅ Auto-startup installed!"
echo ""
echo "Your AI toolkit will now start automatically."
echo ""
