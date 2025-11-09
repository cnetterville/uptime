// NUT Web GUI - Frontend JavaScript

// Navigation
document.addEventListener('DOMContentLoaded', function() {
    // Handle navigation
    const navLinks = document.querySelectorAll('.nav-link');
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const pageName = this.dataset.page;
            showPage(pageName);

            // Update active state
            navLinks.forEach(l => l.classList.remove('active'));
            this.classList.add('active');
        });
    });

    // Initial load
    loadDashboard();
    setInterval(loadDashboard, 10000); // Refresh every 10 seconds
});

function showPage(pageName) {
    // Hide all pages
    document.querySelectorAll('.page').forEach(page => {
        page.classList.remove('active');
    });

    // Show selected page
    const page = document.getElementById(pageName);
    if (page) {
        page.classList.add('active');

        // Load page-specific data
        switch(pageName) {
            case 'dashboard':
                loadDashboard();
                break;
            case 'ups-list':
                loadUPSList();
                break;
            case 'configuration':
                loadConfig();
                loadDrivers();
                break;
            case 'logs':
                refreshLogs();
                break;
            case 'system':
                loadServiceStatus();
                break;
        }
    }
}

// Toast notifications
function showToast(message, type = 'info') {
    const toast = document.getElementById('toast');
    toast.textContent = message;
    toast.className = `toast show ${type}`;

    setTimeout(() => {
        toast.classList.remove('show');
    }, 3000);
}

// Dashboard
async function loadDashboard() {
    await Promise.all([
        loadServiceStatus(),
        loadSystemInfo(),
        loadUPSOverview()
    ]);
}

async function loadServiceStatus() {
    try {
        const response = await fetch('/api/service/status');
        const data = await response.json();

        if (data.success) {
            const container = document.getElementById('service-status');
            container.innerHTML = '';

            for (const [service, status] of Object.entries(data.services)) {
                const item = document.createElement('div');
                item.className = 'status-item';
                item.innerHTML = `
                    <span class="status-label">${service}</span>
                    <span class="status-badge ${status.active ? 'active' : 'inactive'}">
                        ${status.active ? 'Active' : 'Inactive'}
                    </span>
                `;
                container.appendChild(item);
            }
        }
    } catch (error) {
        console.error('Error loading service status:', error);
    }
}

async function loadSystemInfo() {
    try {
        const response = await fetch('/api/system/info');
        const data = await response.json();

        if (data.success) {
            const container = document.getElementById('system-info');
            container.innerHTML = '';

            for (const [key, value] of Object.entries(data.info)) {
                const item = document.createElement('div');
                item.className = 'status-item';
                item.innerHTML = `
                    <span class="status-label">${formatLabel(key)}</span>
                    <span class="status-value">${value}</span>
                `;
                container.appendChild(item);
            }
        }
    } catch (error) {
        console.error('Error loading system info:', error);
    }
}

async function loadUPSOverview() {
    try {
        const response = await fetch('/api/ups/list');
        const data = await response.json();

        const container = document.getElementById('ups-overview');

        if (data.success && data.devices.length > 0) {
            container.innerHTML = '<div class="loading">Loading UPS details...</div>';

            // Load status for each device
            const devices = [];
            for (const device of data.devices) {
                const statusResponse = await fetch(`/api/ups/status/${device}`);
                const statusData = await statusResponse.json();
                if (statusData.success) {
                    devices.push({ name: device, status: statusData.status });
                }
            }

            // Display devices
            container.innerHTML = '';
            devices.forEach(device => {
                const deviceDiv = document.createElement('div');
                deviceDiv.className = 'ups-device';

                const importantFields = {
                    'battery.charge': 'Battery Charge',
                    'battery.runtime': 'Runtime',
                    'input.voltage': 'Input Voltage',
                    'ups.status': 'Status',
                    'ups.load': 'Load'
                };

                let html = `<h3><i class="fas fa-battery-three-quarters"></i> ${device.name}</h3>`;
                html += '<div class="ups-grid">';

                for (const [key, label] of Object.entries(importantFields)) {
                    if (device.status[key]) {
                        html += `
                            <div class="status-item">
                                <span class="status-label">${label}</span>
                                <span class="status-value">${device.status[key]}</span>
                            </div>
                        `;
                    }
                }

                html += '</div>';
                deviceDiv.innerHTML = html;
                container.appendChild(deviceDiv);
            });
        } else {
            container.innerHTML = '<p style="text-align: center; padding: 2rem; color: #7f8c8d;">No UPS devices configured</p>';
        }
    } catch (error) {
        console.error('Error loading UPS overview:', error);
        document.getElementById('ups-overview').innerHTML = '<p style="color: red;">Error loading UPS devices</p>';
    }
}

// UPS List Page
async function loadUPSList() {
    try {
        const response = await fetch('/api/ups/list');
        const data = await response.json();

        const container = document.getElementById('ups-devices');

        if (data.success && data.devices.length > 0) {
            container.innerHTML = '<div class="card-body"><div class="loading">Loading detailed status...</div></div>';

            // Load detailed status for each device
            let html = '<div class="card-body">';
            for (const device of data.devices) {
                const statusResponse = await fetch(`/api/ups/status/${device}`);
                const statusData = await statusResponse.json();

                if (statusData.success) {
                    html += `
                        <div class="ups-device">
                            <h3><i class="fas fa-plug"></i> ${device}</h3>
                            <div class="ups-grid">
                    `;

                    for (const [key, value] of Object.entries(statusData.status)) {
                        html += `
                            <div class="status-item">
                                <span class="status-label">${key}</span>
                                <span class="status-value">${value}</span>
                            </div>
                        `;
                    }

                    html += '</div></div>';
                }
            }
            html += '</div>';
            container.innerHTML = html;
        } else {
            container.innerHTML = '<div class="card-body"><p style="text-align: center; padding: 2rem; color: #7f8c8d;">No UPS devices configured. Edit configuration to add devices.</p></div>';
        }
    } catch (error) {
        console.error('Error loading UPS list:', error);
    }
}

// Configuration
async function loadConfig() {
    try {
        const response = await fetch('/api/ups/config');
        const data = await response.json();

        if (data.success) {
            document.getElementById('ups-config').value = data.config;
        } else {
            showToast('Error loading configuration: ' + data.error, 'error');
        }
    } catch (error) {
        console.error('Error loading config:', error);
        showToast('Error loading configuration', 'error');
    }
}

async function saveConfig() {
    const config = document.getElementById('ups-config').value;

    try {
        const response = await fetch('/api/ups/config', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ config })
        });

        const data = await response.json();

        if (data.success) {
            showToast('Configuration saved successfully!', 'success');
        } else {
            showToast('Error saving configuration: ' + data.error, 'error');
        }
    } catch (error) {
        console.error('Error saving config:', error);
        showToast('Error saving configuration', 'error');
    }
}

async function loadDrivers() {
    try {
        const response = await fetch('/api/drivers/list');
        const data = await response.json();

        const container = document.getElementById('drivers-list');

        if (data.success) {
            container.innerHTML = '<div style="max-height: 400px; overflow-y: auto;">';
            container.innerHTML += '<ul style="column-count: 3; column-gap: 2rem; list-style-type: none;">';
            data.drivers.forEach(driver => {
                container.innerHTML += `<li style="padding: 0.25rem; font-family: monospace; font-size: 0.875rem;"><i class="fas fa-plug"></i> ${driver}</li>`;
            });
            container.innerHTML += '</ul></div>';
        }
    } catch (error) {
        console.error('Error loading drivers:', error);
    }
}

// Logs
async function refreshLogs() {
    const container = document.getElementById('logs-content');
    container.innerHTML = '<pre class="logs"><div class="loading">Loading logs...</div></pre>';

    try {
        const response = await fetch('/api/logs');
        const data = await response.json();

        if (data.success) {
            container.innerHTML = `<pre class="logs">${escapeHtml(data.logs)}</pre>`;
        } else {
            container.innerHTML = '<pre class="logs">Error loading logs</pre>';
        }
    } catch (error) {
        console.error('Error loading logs:', error);
        container.innerHTML = '<pre class="logs">Error loading logs</pre>';
    }
}

// Service Control
async function serviceAction(service, action) {
    try {
        const response = await fetch(`/api/service/${action}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ service })
        });

        const data = await response.json();

        if (data.success) {
            showToast(data.message, 'success');
            await loadServiceStatus();
        } else {
            showToast('Error: ' + data.message, 'error');
        }
    } catch (error) {
        console.error('Error performing service action:', error);
        showToast('Error performing action', 'error');
    }
}

// Utility functions
function formatLabel(key) {
    return key.split('_').map(word =>
        word.charAt(0).toUpperCase() + word.slice(1)
    ).join(' ');
}

function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, m => map[m]);
}
