#!/bin/bash
# NUT Web GUI Installation Script for Raspberry Pi

set -e

echo "======================================"
echo "NUT Web GUI Installation Script"
echo "======================================"
echo ""

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "Error: This script is designed for Linux systems (Raspberry Pi)"
    exit 1
fi

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "Error: Do not run this script as root. Run as normal user (pi)."
   exit 1
fi

echo "Step 1: Installing NUT (Network UPS Tools)..."
sudo apt-get update
sudo apt-get install -y nut nut-client nut-server

echo ""
echo "Step 2: Installing Python dependencies..."
pip3 install --user -r requirements.txt

echo ""
echo "Step 3: Setting up permissions..."

# Add user to nut group
sudo usermod -a -G nut $USER

# Create sudoers file for service control
sudo tee /etc/sudoers.d/nut-web-gui > /dev/null <<EOF
$USER ALL=(ALL) NOPASSWD: /bin/systemctl start nut-server
$USER ALL=(ALL) NOPASSWD: /bin/systemctl stop nut-server
$USER ALL=(ALL) NOPASSWD: /bin/systemctl restart nut-server
$USER ALL=(ALL) NOPASSWD: /bin/systemctl start nut-client
$USER ALL=(ALL) NOPASSWD: /bin/systemctl stop nut-client
$USER ALL=(ALL) NOPASSWD: /bin/systemctl restart nut-client
$USER ALL=(ALL) NOPASSWD: /usr/bin/journalctl -u nut-server *
EOF

sudo chmod 0440 /etc/sudoers.d/nut-web-gui

# Set proper permissions for config files
sudo chmod 644 /etc/nut/*.conf 2>/dev/null || true

echo ""
echo "Step 4: Creating systemd service..."

INSTALL_DIR=$(pwd)
GUNICORN_PATH=$(which gunicorn || echo "$HOME/.local/bin/gunicorn")

sudo tee /etc/systemd/system/nut-web-gui.service > /dev/null <<EOF
[Unit]
Description=NUT Web GUI
After=network.target nut-server.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR
Environment="PATH=$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=$GUNICORN_PATH --bind 0.0.0.0:5000 --workers 2 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo ""
echo "Step 5: Enabling and starting service..."
sudo systemctl daemon-reload
sudo systemctl enable nut-web-gui
sudo systemctl start nut-web-gui

echo ""
echo "======================================"
echo "Installation Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Configure your UPS in /etc/nut/ups.conf"
echo "2. Set NUT mode in /etc/nut/nut.conf (standalone or netserver)"
echo "3. Restart NUT: sudo systemctl restart nut-server"
echo "4. Access web interface at: http://$(hostname -I | awk '{print $1}'):5000"
echo ""
echo "You may need to log out and back in for group permissions to take effect."
echo ""
echo "Check service status: sudo systemctl status nut-web-gui"
echo "View logs: sudo journalctl -u nut-web-gui -f"
echo ""
