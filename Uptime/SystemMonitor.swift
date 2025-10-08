import Foundation
import Combine
import IOKit.ps

class SystemMonitor: ObservableObject {
    @Published var cpuUsage: Double = 0
    @Published var memoryUsed: Double = 0
    @Published var memoryTotal: Double = 0
    @Published var diskUsage: Double = 0
    @Published var batteryLevel: Double = 0
    @Published var isPluggedIn: Bool = false
    
    private var timer: Timer?
    private var lastCPUInfo: (user: UInt64, system: UInt64, idle: UInt64, nice: UInt64) = (0, 0, 0, 0)
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            DispatchQueue.global(qos: .background).async {
                self.updateSystemStats()
            }
        }
        // Get initial reading
        updateSystemStats()
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateSystemStats() {
        let cpu = getCPUUsage()
        let (memUsed, memTotal) = getMemoryUsage()
        let disk = getDiskUsage()
        
        DispatchQueue.main.async {
            self.cpuUsage = cpu
            self.memoryUsed = memUsed
            self.memoryTotal = memTotal
            self.diskUsage = disk
            self.updateBatteryInfo()
        }
    }
    
    private func getCPUUsage() -> Double {
        var cpuInfo: processor_info_array_t!
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCpus: natural_t = 0
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCpus, &cpuInfo, &numCpuInfo)
        
        if result != KERN_SUCCESS {
            return 0.0
        }
        
        defer {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(numCpuInfo))
        }
        
        var totalUser: UInt64 = 0
        var totalSystem: UInt64 = 0
        var totalIdle: UInt64 = 0
        var totalNice: UInt64 = 0
        
        for i in 0..<numCpus {
            let cpuLoadInfo = cpuInfo.advanced(by: Int(i) * Int(CPU_STATE_MAX)).withMemoryRebound(to: UInt32.self, capacity: Int(CPU_STATE_MAX)) { $0 }
            
            totalUser += UInt64(cpuLoadInfo[Int(CPU_STATE_USER)])
            totalSystem += UInt64(cpuLoadInfo[Int(CPU_STATE_SYSTEM)])
            totalIdle += UInt64(cpuLoadInfo[Int(CPU_STATE_IDLE)])
            totalNice += UInt64(cpuLoadInfo[Int(CPU_STATE_NICE)])
        }
        
        let totalTicks = totalUser + totalSystem + totalIdle + totalNice
        let lastTotalTicks = lastCPUInfo.user + lastCPUInfo.system + lastCPUInfo.idle + lastCPUInfo.nice
        
        if lastTotalTicks == 0 {
            // First reading, store values and return 0
            lastCPUInfo = (totalUser, totalSystem, totalIdle, totalNice)
            return 0.0
        }
        
        let userDiff = totalUser - lastCPUInfo.user
        let systemDiff = totalSystem - lastCPUInfo.system
        let totalDiff = totalTicks - lastTotalTicks
        
        lastCPUInfo = (totalUser, totalSystem, totalIdle, totalNice)
        
        if totalDiff == 0 {
            return 0.0
        }
        
        return Double(userDiff + systemDiff) / Double(totalDiff) * 100.0
    }
    
    private func getMemoryUsage() -> (used: Double, total: Double) {
        // Get total physical memory
        var totalMemory: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        if sysctlbyname("hw.memsize", &totalMemory, &size, nil, 0) != 0 {
            return (0.0, 0.0)
        }
        
        // Get VM statistics
        var vmStat = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &vmStat) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        if result != KERN_SUCCESS {
            return (0.0, 0.0)
        }
        
        let pageSize = UInt64(vm_kernel_page_size)
        
        // Calculate memory usage
        // Used memory = Total - Free - Cached (inactive)
        let freeMemory = UInt64(vmStat.free_count) * pageSize
        let inactiveMemory = UInt64(vmStat.inactive_count) * pageSize
        let availableMemory = freeMemory + inactiveMemory
        let usedMemory = totalMemory - availableMemory
        
        // Convert to GB
        let totalGB = Double(totalMemory) / (1024 * 1024 * 1024)
        let usedGB = Double(usedMemory) / (1024 * 1024 * 1024)
        
        return (usedGB, totalGB)
    }
    
    private func getDiskUsage() -> Double {
        let fileURL = URL(fileURLWithPath: "/")
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityKey, .volumeTotalCapacityKey])
            if let capacity = values.volumeTotalCapacity, let available = values.volumeAvailableCapacity {
                let used = capacity - available
                return Double(used) / Double(capacity) * 100.0
            }
        } catch {
            print("Error getting disk usage: \(error)")
        }
        return 0.0
    }
    
    private func updateBatteryInfo() {
        let powerSources = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(powerSources)?.takeRetainedValue() as? [CFDictionary] ?? []
        
        for source in sources {
            let description = source as NSDictionary
            if let type = description[kIOPSTypeKey] as? String,
               type == kIOPSInternalBatteryType {
                
                if let capacity = description[kIOPSCurrentCapacityKey] as? Int {
                    batteryLevel = Double(capacity)
                }
                
                if let powerSource = description[kIOPSPowerSourceStateKey] as? String {
                    isPluggedIn = (powerSource == kIOPSACPowerValue)
                }
                break
            }
        }
    }
    
    // Formatted properties for display
    var formattedCPUUsage: String {
        return String(format: "%.1f%%", cpuUsage)
    }
    
    var formattedMemoryUsage: String {
        return String(format: "%.1f/%.1f GB", memoryUsed, memoryTotal)
    }
    
    var memoryUsagePercentage: Double {
        guard memoryTotal > 0 else { return 0 }
        return (memoryUsed / memoryTotal) * 100
    }
    
    var formattedDiskUsage: String {
        return String(format: "%.1f%%", diskUsage)
    }
    
    var formattedBatteryLevel: String {
        guard batteryLevel > 0 else { return "N/A" }
        return String(format: "%.0f%%", batteryLevel)
    }
}