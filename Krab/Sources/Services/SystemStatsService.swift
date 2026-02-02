import Foundation
import IOKit.ps
import Combine

@MainActor
class SystemStatsService: ObservableObject {
    static let shared = SystemStatsService()
    
    @Published var stats: SystemStats?
    
    private var updateTimer: Timer?
    private var previousCPUInfo: host_cpu_load_info?
    
    func startMonitoring() {
        updateStats()
        scheduleUpdates()
    }
    
    func stopMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func scheduleUpdates() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }
    
    func updateStats() {
        let cpuUsage = getCPUUsage()
        let (memoryUsage, memoryUsed, memoryTotal) = getMemoryUsage()
        let (batteryLevel, isCharging) = getBatteryInfo()
        let (diskUsed, diskTotal) = getDiskUsage()
        let uptime = getUptime()
        
        stats = SystemStats(
            cpuUsage: cpuUsage,
            memoryUsage: memoryUsage,
            memoryUsed: memoryUsed,
            memoryTotal: memoryTotal,
            batteryLevel: batteryLevel,
            isCharging: isCharging,
            diskUsed: diskUsed,
            diskTotal: diskTotal,
            uptime: uptime
        )
    }
    
    private func getCPUUsage() -> Double {
        var cpuInfo: host_cpu_load_info?
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride)
        
        let result = withUnsafeMutablePointer(to: &cpuInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS, let info = cpuInfo else {
            return 0
        }
        
        let user = Double(info.cpu_ticks.0)
        let system = Double(info.cpu_ticks.1)
        let idle = Double(info.cpu_ticks.2)
        let nice = Double(info.cpu_ticks.3)
        
        let totalTicks = user + system + idle + nice
        
        if let previous = previousCPUInfo {
            let prevUser = Double(previous.cpu_ticks.0)
            let prevSystem = Double(previous.cpu_ticks.1)
            let prevIdle = Double(previous.cpu_ticks.2)
            let prevNice = Double(previous.cpu_ticks.3)
            
            let prevTotal = prevUser + prevSystem + prevIdle + prevNice
            
            let totalDiff = totalTicks - prevTotal
            let idleDiff = idle - prevIdle
            
            if totalDiff > 0 {
                previousCPUInfo = info
                return (1.0 - idleDiff / totalDiff) * 100
            }
        }
        
        previousCPUInfo = info
        return (1.0 - idle / totalTicks) * 100
    }
    
    private func getMemoryUsage() -> (Double, UInt64, UInt64) {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return (0, 0, 0)
        }
        
        let pageSize = UInt64(vm_kernel_page_size)
        
        let active = UInt64(stats.active_count) * pageSize
        let inactive = UInt64(stats.inactive_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        
        let used = active + wired + compressed
        let total = ProcessInfo.processInfo.physicalMemory
        
        let usage = Double(used) / Double(total) * 100
        
        return (usage, used, total)
    }
    
    private func getBatteryInfo() -> (Int, Bool) {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
            return (100, false)
        }
        
        let level = info[kIOPSCurrentCapacityKey] as? Int ?? 100
        let isCharging = info[kIOPSIsChargingKey] as? Bool ?? false
        
        return (level, isCharging)
    }
    
    private func getDiskUsage() -> (UInt64, UInt64) {
        let fileManager = FileManager.default
        
        do {
            let attrs = try fileManager.attributesOfFileSystem(forPath: "/")
            let total = attrs[.systemSize] as? UInt64 ?? 0
            let free = attrs[.systemFreeSize] as? UInt64 ?? 0
            let used = total - free
            
            return (used, total)
        } catch {
            return (0, 0)
        }
    }
    
    private func getUptime() -> TimeInterval {
        var boottime = timeval()
        var size = MemoryLayout<timeval>.stride
        var mib: [Int32] = [CTL_KERN, KERN_BOOTTIME]
        
        if sysctl(&mib, 2, &boottime, &size, nil, 0) != -1 {
            let bootDate = Date(timeIntervalSince1970: TimeInterval(boottime.tv_sec))
            return Date().timeIntervalSince(bootDate)
        }
        
        return 0
    }
}
