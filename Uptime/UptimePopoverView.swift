import SwiftUI

struct UptimePopoverView: View {
    @ObservedObject var uptimeManager: UptimeManager
    @ObservedObject var systemMonitor: SystemMonitor
    let onHistoryAction: () -> Void
    let onPreferencesAction: () -> Void
    @AppStorage("showSystemStats") private var showSystemStats = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("System Uptime")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(uptimeManager.detailedUptime)
                        .font(.subheadline)
                        .fontDesign(.monospaced)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            if showSystemStats {
                Divider()
                
                // System Stats
                VStack(spacing: 8) {
                    StatRow(
                        icon: "cpu", 
                        label: "CPU Usage", 
                        value: systemMonitor.formattedCPUUsage, 
                        color: cpuColor
                    )
                    
                    StatRow(
                        icon: "memorychip", 
                        label: "Memory", 
                        value: systemMonitor.formattedMemoryUsage, 
                        color: memoryColor
                    )
                    
                    StatRow(
                        icon: "internaldrive", 
                        label: "Disk Usage", 
                        value: systemMonitor.formattedDiskUsage, 
                        color: diskColor
                    )
                    
                    if systemMonitor.batteryLevel > 0 {
                        StatRow(
                            icon: systemMonitor.isPluggedIn ? "battery.100.bolt" : batteryIcon,
                            label: "Battery",
                            value: systemMonitor.formattedBatteryLevel,
                            color: batteryColor
                        )
                    }
                }
            }
            
            Divider()
            
            // Boot Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Boot Time")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(uptimeManager.bootTime)
                    .font(.caption)
                    .fontDesign(.monospaced)
            }
            
            // Quick Actions
            HStack {
                Button("History") {
                    onHistoryAction()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                Button("Preferences") {
                    onPreferencesAction()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(16)
        .frame(width: 280, height: showSystemStats ? 220 : 150)
        .animation(.easeInOut(duration: 0.2), value: showSystemStats)
    }
    
    // Helper computed properties for dynamic colors and icons
    private var cpuColor: Color {
        if systemMonitor.cpuUsage > 80 {
            return .red
        } else if systemMonitor.cpuUsage > 50 {
            return .orange
        } else {
            return .green
        }
    }
    
    private var memoryColor: Color {
        let percentage = systemMonitor.memoryUsagePercentage
        if percentage > 90 {
            return .red
        } else if percentage > 80 {
            return .orange
        } else {
            return .blue
        }
    }
    
    private var diskColor: Color {
        if systemMonitor.diskUsage > 90 {
            return .red
        } else if systemMonitor.diskUsage > 80 {
            return .orange
        } else {
            return .green
        }
    }
    
    private var batteryColor: Color {
        if systemMonitor.batteryLevel < 20 {
            return .red
        } else if systemMonitor.batteryLevel < 50 {
            return .orange
        } else {
            return .green
        }
    }
    
    private var batteryIcon: String {
        if systemMonitor.batteryLevel < 25 {
            return "battery.25"
        } else if systemMonitor.batteryLevel < 50 {
            return "battery.50"
        } else if systemMonitor.batteryLevel < 75 {
            return "battery.75"
        } else {
            return "battery.100"
        }
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 16)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontDesign(.monospaced)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    UptimePopoverView(
        uptimeManager: UptimeManager(),
        systemMonitor: SystemMonitor(),
        onHistoryAction: {},
        onPreferencesAction: {}
    )
}