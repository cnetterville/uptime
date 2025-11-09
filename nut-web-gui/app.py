#!/usr/bin/env python3
"""
NUT Web GUI - Network UPS Tools Configuration Interface
A Flask-based web application for configuring and monitoring NUT on Raspberry Pi
"""

from flask import Flask, render_template, jsonify, request, session
import subprocess
import os
import json
import re
from functools import wraps

app = Flask(__name__)
app.secret_key = os.urandom(24)  # Change this in production

# Configuration file paths
NUT_CONFIG_DIR = '/etc/nut'
UPS_CONF = f'{NUT_CONFIG_DIR}/ups.conf'
UPSD_CONF = f'{NUT_CONFIG_DIR}/upsd.conf'
UPSD_USERS = f'{NUT_CONFIG_DIR}/upsd.users'
UPS_MON = f'{NUT_CONFIG_DIR}/upsmon.conf'
NUT_CONF = f'{NUT_CONFIG_DIR}/nut.conf'


def run_command(cmd, check=True):
    """Execute shell command and return output"""
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            check=check
        )
        return {
            'success': True,
            'stdout': result.stdout,
            'stderr': result.stderr,
            'returncode': result.returncode
        }
    except subprocess.CalledProcessError as e:
        return {
            'success': False,
            'stdout': e.stdout,
            'stderr': e.stderr,
            'returncode': e.returncode
        }


def require_auth(f):
    """Simple authentication decorator (extend for production)"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Add authentication logic here
        return f(*args, **kwargs)
    return decorated_function


@app.route('/')
def index():
    """Main dashboard"""
    return render_template('index.html')


@app.route('/api/ups/list')
def list_ups():
    """Get list of configured UPS devices"""
    result = run_command('upsc -l', check=False)
    if result['success']:
        ups_list = [line.strip() for line in result['stdout'].split('\n') if line.strip()]
        return jsonify({'success': True, 'devices': ups_list})
    return jsonify({'success': False, 'error': result['stderr']})


@app.route('/api/ups/status/<ups_name>')
def ups_status(ups_name):
    """Get detailed status of a specific UPS"""
    result = run_command(f'upsc {ups_name}', check=False)
    if result['success']:
        # Parse upsc output into key-value pairs
        status = {}
        for line in result['stdout'].split('\n'):
            if ':' in line:
                key, value = line.split(':', 1)
                status[key.strip()] = value.strip()
        return jsonify({'success': True, 'status': status})
    return jsonify({'success': False, 'error': result['stderr']})


@app.route('/api/ups/config')
def get_ups_config():
    """Read UPS configuration"""
    try:
        if os.path.exists(UPS_CONF):
            with open(UPS_CONF, 'r') as f:
                config = f.read()
            return jsonify({'success': True, 'config': config})
        return jsonify({'success': False, 'error': 'Configuration file not found'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@app.route('/api/ups/config', methods=['POST'])
@require_auth
def save_ups_config():
    """Save UPS configuration"""
    try:
        config_data = request.json.get('config')
        if not config_data:
            return jsonify({'success': False, 'error': 'No configuration provided'})

        # Backup existing config
        if os.path.exists(UPS_CONF):
            run_command(f'sudo cp {UPS_CONF} {UPS_CONF}.backup')

        # Write new config
        with open(f'{UPS_CONF}.tmp', 'w') as f:
            f.write(config_data)

        run_command(f'sudo mv {UPS_CONF}.tmp {UPS_CONF}')
        run_command('sudo systemctl restart nut-server')

        return jsonify({'success': True, 'message': 'Configuration saved and service restarted'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@app.route('/api/drivers/list')
def list_drivers():
    """Get list of available NUT drivers"""
    result = run_command('ls /lib/nut/ | grep -v "^lib"', check=False)
    if result['success']:
        drivers = [line.strip() for line in result['stdout'].split('\n') if line.strip()]
        return jsonify({'success': True, 'drivers': drivers})
    return jsonify({'success': False, 'error': 'Could not list drivers'})


@app.route('/api/service/status')
def service_status():
    """Get NUT service status"""
    services = ['nut-server', 'nut-client', 'nut-monitor']
    status = {}

    for service in services:
        result = run_command(f'systemctl is-active {service}', check=False)
        status[service] = {
            'active': result['stdout'].strip() == 'active',
            'status': result['stdout'].strip()
        }

    return jsonify({'success': True, 'services': status})


@app.route('/api/service/<action>', methods=['POST'])
@require_auth
def service_action(action):
    """Control NUT services (start/stop/restart)"""
    allowed_actions = ['start', 'stop', 'restart']
    if action not in allowed_actions:
        return jsonify({'success': False, 'error': 'Invalid action'})

    service = request.json.get('service', 'nut-server')
    result = run_command(f'sudo systemctl {action} {service}')

    return jsonify({
        'success': result['success'],
        'message': f'Service {service} {action}ed successfully' if result['success'] else result['stderr']
    })


@app.route('/api/logs')
def get_logs():
    """Get recent NUT logs"""
    result = run_command('sudo journalctl -u nut-server -n 50 --no-pager', check=False)
    if result['success']:
        return jsonify({'success': True, 'logs': result['stdout']})
    return jsonify({'success': False, 'error': result['stderr']})


@app.route('/api/system/info')
def system_info():
    """Get system information"""
    info = {}

    # Get hostname
    result = run_command('hostname')
    info['hostname'] = result['stdout'].strip() if result['success'] else 'unknown'

    # Get IP address
    result = run_command("hostname -I | awk '{print $1}'")
    info['ip_address'] = result['stdout'].strip() if result['success'] else 'unknown'

    # Get OS info
    result = run_command('cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d \'"\'')
    info['os'] = result['stdout'].strip() if result['success'] else 'unknown'

    # Get NUT version
    result = run_command('upsc -V 2>&1 | head -1')
    info['nut_version'] = result['stdout'].strip() if result['success'] else 'unknown'

    return jsonify({'success': True, 'info': info})


if __name__ == '__main__':
    # For development only - use gunicorn/uwsgi in production
    app.run(host='0.0.0.0', port=5000, debug=True)
