# NUT Web GUI

A modern, responsive web interface for configuring and monitoring Network UPS Tools (NUT) on Raspberry Pi.

## Features

- **Dashboard**: Real-time monitoring of UPS devices and system status
- **UPS Devices**: Detailed view of all connected UPS devices with comprehensive status information
- **Configuration**: Edit NUT configuration files directly from the web interface
- **Service Control**: Start, stop, and restart NUT services
- **System Logs**: View recent NUT service logs
- **Responsive Design**: Works on desktop, tablet, and mobile devices
- **Beautiful UI**: Modern gradient design with smooth animations

## Screenshots

The interface includes:
- Real-time battery charge and runtime monitoring
- Service status indicators
- Configuration file editor
- Available drivers list
- System information panel
- Log viewer with auto-refresh

## Requirements

- Raspberry Pi (any model with Raspberry Pi OS)
- Python 3.7+
- Network UPS Tools (NUT) installed
- Web browser (Chrome, Firefox, Safari, or Edge)

## Installation

### 1. Install NUT (if not already installed)

```bash
sudo apt-get update
sudo apt-get install -y nut nut-client nut-server
```

### 2. Clone or download this repository

```bash
cd ~
git clone <repository-url> nut-web-gui
cd nut-web-gui
```

Or if you have the files locally:
```bash
cd nut-web-gui
```

### 3. Install Python dependencies

```bash
pip3 install -r requirements.txt
```

### 4. Set up permissions

The web interface needs to read NUT configuration files and control services:

```bash
# Add your user to the nut group
sudo usermod -a -G nut $USER

# Allow the user to restart NUT services without password
echo "$USER ALL=(ALL) NOPASSWD: /bin/systemctl start nut-server" | sudo tee -a /etc/sudoers.d/nut-web-gui
echo "$USER ALL=(ALL) NOPASSWD: /bin/systemctl stop nut-server" | sudo tee -a /etc/sudoers.d/nut-web-gui
echo "$USER ALL=(ALL) NOPASSWD: /bin/systemctl restart nut-server" | sudo tee -a /etc/sudoers.d/nut-web-gui
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/journalctl -u nut-server *" | sudo tee -a /etc/sudoers.d/nut-web-gui
sudo chmod 0440 /etc/sudoers.d/nut-web-gui

# Set proper permissions for config files
sudo chmod 644 /etc/nut/*.conf
```

## Usage

### Development Mode

For testing and development:

```bash
python3 app.py
```

The application will be available at `http://localhost:5000` or `http://<raspberry-pi-ip>:5000`

### Production Mode (Recommended)

For production use with better performance and stability:

```bash
gunicorn --bind 0.0.0.0:5000 --workers 2 app:app
```

### Run as a System Service

Create a systemd service for automatic startup:

```bash
sudo nano /etc/systemd/system/nut-web-gui.service
```

Add the following content (adjust paths as needed):

```ini
[Unit]
Description=NUT Web GUI
After=network.target nut-server.service

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/nut-web-gui
Environment="PATH=/home/pi/.local/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=/usr/local/bin/gunicorn --bind 0.0.0.0:5000 --workers 2 app:app
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable nut-web-gui
sudo systemctl start nut-web-gui
```

Check status:

```bash
sudo systemctl status nut-web-gui
```

## Configuration

### NUT Configuration

Before using the web interface, you need to configure NUT. Here's a basic example:

#### 1. Edit `/etc/nut/ups.conf`

```ini
# Example for a USB-connected UPS
[myups]
    driver = usbhid-ups
    port = auto
    desc = "Main UPS"

# Example for a network UPS
[remoteups]
    driver = netxml-ups
    port = http://192.168.1.100
    desc = "Remote UPS"
```

#### 2. Edit `/etc/nut/nut.conf`

```ini
MODE=standalone
```

For netserver mode (to share UPS data on network):
```ini
MODE=netserver
```

#### 3. Edit `/etc/nut/upsd.conf`

```ini
LISTEN 0.0.0.0 3493
```

#### 4. Edit `/etc/nut/upsd.users`

```ini
[admin]
    password = your_password_here
    actions = SET
    instcmds = ALL
```

#### 5. Start NUT services

```bash
sudo systemctl restart nut-server
sudo systemctl restart nut-client
```

### Web Interface Configuration

The web interface will automatically detect your NUT configuration. You can also edit configuration files directly through the web interface.

## Accessing the Interface

### Local Access
- Open browser to: `http://localhost:5000`

### Network Access
- Find your Raspberry Pi's IP address: `hostname -I`
- Open browser to: `http://<raspberry-pi-ip>:5000`
- Example: `http://192.168.1.100:5000`

### Remote Access (Optional)

For secure remote access, consider setting up:
1. **SSH Tunnel**: `ssh -L 5000:localhost:5000 pi@raspberry-pi-ip`
2. **VPN**: Use WireGuard or OpenVPN
3. **Reverse Proxy**: Use Nginx with HTTPS and authentication

## Security Considerations

**IMPORTANT**: This is a basic implementation. For production use, consider:

1. **Add Authentication**: Implement user login system
2. **Use HTTPS**: Set up SSL/TLS certificates
3. **Firewall**: Restrict access to trusted networks
4. **Strong Passwords**: Use strong passwords in NUT configuration
5. **Regular Updates**: Keep system and dependencies updated

Example: Add basic HTTP authentication with Nginx:

```nginx
server {
    listen 80;
    server_name ups.local;

    auth_basic "NUT Web GUI";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Troubleshooting

### NUT services not running
```bash
sudo systemctl status nut-server
sudo journalctl -u nut-server -n 50
```

### Cannot access web interface
- Check if service is running: `sudo systemctl status nut-web-gui`
- Check firewall: `sudo ufw status`
- Verify port is listening: `sudo netstat -tulpn | grep 5000`

### Permission errors
- Ensure user is in nut group: `groups $USER`
- Check sudoers configuration: `sudo visudo -f /etc/sudoers.d/nut-web-gui`
- Verify config file permissions: `ls -l /etc/nut/`

### UPS not detected
```bash
# List USB devices
lsusb

# Test UPS driver
sudo upsdrvctl start

# Check UPS status
upsc myups
```

## API Endpoints

The application provides a REST API:

- `GET /api/ups/list` - List all UPS devices
- `GET /api/ups/status/<ups_name>` - Get UPS status
- `GET /api/ups/config` - Get UPS configuration
- `POST /api/ups/config` - Save UPS configuration
- `GET /api/drivers/list` - List available drivers
- `GET /api/service/status` - Get service status
- `POST /api/service/<action>` - Control services (start/stop/restart)
- `GET /api/logs` - Get recent logs
- `GET /api/system/info` - Get system information

## Development

To contribute or modify:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on Raspberry Pi
5. Submit a pull request

## License

© 2025 Curtis Netterville. All rights reserved.

## Support

For issues, questions, or feature requests, please open an issue on the GitHub repository.

## Acknowledgments

- Network UPS Tools (NUT) project
- Flask web framework
- Font Awesome for icons
