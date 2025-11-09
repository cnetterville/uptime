# NUT Web GUI - Quick Start Guide

Get up and running in 5 minutes on your Raspberry Pi!

## Prerequisites

- Raspberry Pi with Raspberry Pi OS installed
- UPS connected to Raspberry Pi (USB or network)
- Internet connection for initial setup

## Installation

### Option 1: Automated Installation (Recommended)

```bash
cd nut-web-gui
./install.sh
```

The script will:
- Install NUT and dependencies
- Set up permissions
- Create and start the systemd service
- Configure everything automatically

### Option 2: Manual Installation

```bash
# Install NUT
sudo apt-get update
sudo apt-get install -y nut nut-client nut-server python3-venv

# Create virtual environment
python3 -m venv venv

# Install Python dependencies in venv
./venv/bin/pip install -r requirements.txt

# Run the app
./venv/bin/python app.py
```

## First-Time Configuration

### 1. Find Your UPS

```bash
# Scan for USB UPS devices
sudo nut-scanner -U

# Or scan everything
sudo nut-scanner
```

This will show something like:
```
[nutdev1]
    driver = "usbhid-ups"
    port = "auto"
    vendorid = "051D"
    productid = "0002"
```

### 2. Configure NUT

Edit `/etc/nut/ups.conf`:
```bash
sudo nano /etc/nut/ups.conf
```

Add your UPS configuration:
```ini
[myups]
    driver = usbhid-ups
    port = auto
    desc = "My UPS"
```

### 3. Set NUT Mode

Edit `/etc/nut/nut.conf`:
```bash
sudo nano /etc/nut/nut.conf
```

Set the mode:
```ini
MODE=standalone
```

### 4. Configure Access (Optional)

Edit `/etc/nut/upsd.users`:
```bash
sudo nano /etc/nut/upsd.users
```

Add an admin user:
```ini
[admin]
    password = mypassword
    actions = SET
    instcmds = ALL
```

### 5. Start NUT Services

```bash
sudo systemctl restart nut-server
sudo systemctl enable nut-server
```

### 6. Test NUT

```bash
# Start the driver
sudo upsdrvctl start

# Check status
upsc myups
```

You should see output like:
```
battery.charge: 100
battery.runtime: 1234
ups.status: OL
```

## Access the Web Interface

### Find Your Raspberry Pi's IP Address

```bash
hostname -I
```

Example output: `192.168.1.100`

### Open Your Browser

Navigate to: `http://192.168.1.100:5000`

You should see the NUT Web GUI dashboard!

## Common Use Cases

### Monitor UPS from Any Device

1. Access the web interface from any device on your network
2. View real-time battery status, load, and runtime
3. Check system health at a glance

### Edit Configuration

1. Go to **Configuration** tab
2. Edit `ups.conf` directly in the browser
3. Click **Save Configuration**
4. Service automatically restarts

### View Logs

1. Go to **Logs** tab
2. See recent NUT service events
3. Click **Refresh** for latest logs

### Control Services

1. Go to **System** tab
2. Start, stop, or restart NUT services
3. View service status in real-time

## Troubleshooting

### Can't find UPS?

```bash
# List USB devices
lsusb

# Check USB permissions
ls -l /dev/bus/usb/
```

### Service won't start?

```bash
# Check service status
sudo systemctl status nut-server

# View detailed logs
sudo journalctl -u nut-server -n 50
```

### Can't access web interface?

```bash
# Check if service is running
sudo systemctl status nut-web-gui

# Check if port is open
sudo netstat -tulpn | grep 5000

# Check firewall
sudo ufw status
```

### Permission denied errors?

```bash
# Log out and back in to apply group membership
# Or force it with:
newgrp nut

# Check if you're in the nut group
groups
```

## Security Tips

**IMPORTANT**: The web interface has no authentication by default!

For production use:

1. **Add a reverse proxy** with authentication (Nginx + basic auth)
2. **Use a VPN** for remote access
3. **Enable firewall** and restrict access:
   ```bash
   sudo ufw allow from 192.168.1.0/24 to any port 5000
   ```
4. **Change default passwords** in NUT configuration

## Next Steps

- Set up email notifications for UPS events
- Configure automatic shutdown on low battery
- Monitor multiple UPS devices
- Integrate with home automation systems

## Getting Help

- Check the full README.md for detailed documentation
- View NUT documentation: https://networkupstools.org/docs/
- Check system logs: `sudo journalctl -xe`

Enjoy your new NUT Web GUI! 🔋⚡
