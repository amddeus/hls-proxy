import Cocoa
import Foundation

// MARK: - ARM macOS Optimization
//
// This application is optimized for Apple Silicon (M-series chips) using:
//
// 1. Grand Central Dispatch (GCD) with Quality of Service (QoS) classes
//    - userInitiated QoS: User-facing operations (browser launch, restart, quit)
//      -> Schedules work on Performance cores (P-cores) for responsiveness
//    - background QoS: Maintenance tasks (future: EPG refresh, cache cleanup)
//      -> Schedules work on Efficiency cores (E-cores) to save power
//
// 2. The hls-proxy binary is a native ARM64 Node.js application
//    - No Rosetta 2 translation needed
//    - Uses ARM-optimized V8 JavaScript engine
//    - Includes ARM64 crypto optimizations (AES, SHA, etc.)
//
// For more details on Apple Silicon optimization, see ARM_OPTIMIZATION.md

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var proxyProcess: Process?
    var serverPort: Int = 8202
    
    // Quality of Service queues for optimal Apple Silicon performance
    // userInitiated: Uses Performance cores for user-facing tasks
    private let userInitiatedQueue = DispatchQueue(label: "com.hlsproxy.userInitiated", qos: .userInitiated)
    // background: Uses Efficiency cores for maintenance tasks
    private let backgroundQueue = DispatchQueue(label: "com.hlsproxy.background", qos: .background)
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Try to load menu bar icon
            let resourcePath = Bundle.main.resourcePath ?? ""
            let menubarIconPath = (resourcePath as NSString).appendingPathComponent("menubar-icon.png")
            
            if FileManager.default.fileExists(atPath: menubarIconPath),
               let image = NSImage(contentsOfFile: menubarIconPath) {
                image.isTemplate = true
                image.size = NSSize(width: 18, height: 18)
                button.image = image
            } else if let image = NSImage(named: "AppIcon") {
                image.isTemplate = true
                image.size = NSSize(width: 18, height: 18)
                button.image = image
            } else {
                // Fallback to text
                button.title = "▶️"
            }
            button.toolTip = "HLS Proxy"
        }
        
        // Read port from config first
        readServerPort()
        
        // Create menu
        let menu = NSMenu()
        
        let titleItem = NSMenuItem(title: "HLS Proxy", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let browserItem = NSMenuItem(title: "Launch in Web Browser", action: #selector(openInBrowser), keyEquivalent: "o")
        browserItem.target = self
        menu.addItem(browserItem)
        
        let restartItem = NSMenuItem(title: "Restart Proxy", action: #selector(restartProxy), keyEquivalent: "r")
        restartItem.target = self
        menu.addItem(restartItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        
        // Start proxy server
        startProxy()
    }
    
    func readServerPort() {
        let resourcePath = Bundle.main.resourcePath ?? ""
        let localConfigPath = (resourcePath as NSString).appendingPathComponent("local.json")
        let defaultConfigPath = (resourcePath as NSString).appendingPathComponent("default.json")
        
        // Try local.json first
        if FileManager.default.fileExists(atPath: localConfigPath) {
            if let port = extractPortFromConfig(localConfigPath) {
                serverPort = port
                return
            }
        }
        
        // Fall back to default.json
        if FileManager.default.fileExists(atPath: defaultConfigPath) {
            if let port = extractPortFromConfig(defaultConfigPath) {
                serverPort = port
            }
        }
    }
    
    func extractPortFromConfig(_ path: String) -> Int? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let server = json["SERVER"] as? [String: Any],
              let port = server["port"] as? Int else {
            return nil
        }
        return port
    }
    
    func startProxy() {
        // Use userInitiated QoS for starting proxy (user is waiting)
        // This tells macOS to use Performance cores for responsive startup
        userInitiatedQueue.async { [weak self] in
            guard let self = self else { return }
            
            let resourcePath = Bundle.main.resourcePath ?? ""
            let proxyPath = (resourcePath as NSString).appendingPathComponent("hls-proxy")
            
            self.proxyProcess = Process()
            self.proxyProcess?.executableURL = URL(fileURLWithPath: proxyPath)
            self.proxyProcess?.currentDirectoryURL = URL(fileURLWithPath: resourcePath)
            
            // Configure Node.js environment for optimal ARM64 performance
            var environment = ProcessInfo.processInfo.environment
            
            // Enable V8 optimizations for ARM64
            environment["NODE_OPTIONS"] = "--max-old-space-size=2048"
            
            // Enable V8 optimizing compiler for better performance
            environment["UV_THREADPOOL_SIZE"] = "8"  // Increase libuv thread pool for better I/O
            
            // Set quality of service hint for the subprocess
            self.proxyProcess?.qualityOfService = .userInitiated
            self.proxyProcess?.environment = environment
            
            do {
                try self.proxyProcess?.run()
                print("HLS Proxy started with performance optimizations:")
                print("  - Node.js max heap: 2048 MB")
                print("  - UV thread pool: 8 threads")
                print("  - QoS: userInitiated (Performance cores)")
            } catch {
                print("ERROR: Failed to start HLS Proxy: \(error)")
                print("Binary path: \(proxyPath)")
                print("Resource path: \(resourcePath)")
                DispatchQueue.main.async {
                    self.showAlert(message: "Failed to start HLS Proxy server", info: error.localizedDescription)
                }
            }
        }
    }
    
    func stopProxy() {
        // Use userInitiated QoS for stopping proxy (user is waiting for shutdown)
        // This ensures responsive termination on Performance cores
        userInitiatedQueue.async { [weak self] in
            guard let self = self else { return }
            
            if let process = self.proxyProcess, process.isRunning {
                process.terminate()
                process.waitUntilExit()
                print("HLS Proxy stopped")
            }
        }
    }
    
    @objc func openInBrowser() {
        // Use userInitiated QoS for opening browser (user explicitly requested)
        // This ensures responsive browser launch on Performance cores
        userInitiatedQueue.async { [weak self] in
            guard let self = self else { return }
            
            guard let url = URL(string: "http://localhost:\(self.serverPort)") else {
                DispatchQueue.main.async {
                    self.showAlert(message: "Invalid URL", info: "Could not create URL for port \(self.serverPort)")
                }
                return
            }
            
            DispatchQueue.main.async {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    @objc func restartProxy() {
        // Use userInitiated QoS for restart (user explicitly requested)
        // This ensures responsive restart on Performance cores
        userInitiatedQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Stop the proxy
            if let process = self.proxyProcess, process.isRunning {
                process.terminate()
                process.waitUntilExit()
            }
            
            // Brief pause to ensure clean shutdown
            // Using Thread.sleep here is intentional - we're already on a background queue
            // and need a synchronous delay before the next operation
            Thread.sleep(forTimeInterval: 1.0)
            
            // Start the proxy with performance optimizations
            let resourcePath = Bundle.main.resourcePath ?? ""
            let proxyPath = (resourcePath as NSString).appendingPathComponent("hls-proxy")
            
            self.proxyProcess = Process()
            self.proxyProcess?.executableURL = URL(fileURLWithPath: proxyPath)
            self.proxyProcess?.currentDirectoryURL = URL(fileURLWithPath: resourcePath)
            
            // Configure Node.js environment for optimal ARM64 performance
            var environment = ProcessInfo.processInfo.environment
            environment["NODE_OPTIONS"] = "--max-old-space-size=2048"
            environment["UV_THREADPOOL_SIZE"] = "8"
            
            self.proxyProcess?.qualityOfService = .userInitiated
            self.proxyProcess?.environment = environment
            
            do {
                try self.proxyProcess?.run()
                print("HLS Proxy restarted with performance optimizations")
                
                // Only show alert if the process started successfully
                DispatchQueue.main.async {
                    if let process = self.proxyProcess, process.isRunning {
                        self.showAlert(message: "HLS Proxy Restarted", info: "The proxy server has been restarted successfully.")
                    } else {
                        self.showAlert(message: "Restart Failed", info: "The proxy server failed to restart. Check Console.app for errors.")
                    }
                }
            } catch {
                print("ERROR: Failed to restart HLS Proxy: \(error)")
                print("Binary path: \(proxyPath)")
                DispatchQueue.main.async {
                    self.showAlert(message: "Restart Failed", info: error.localizedDescription)
                }
            }
        }
    }
    
    @objc func quitApp() {
        // Use userInitiated QoS for quitting (user explicitly requested)
        userInitiatedQueue.async { [weak self] in
            guard let self = self else { return }
            
            if let process = self.proxyProcess, process.isRunning {
                process.terminate()
                process.waitUntilExit()
            }
            
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
        }
    }
    
    func showAlert(message: String, info: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = info
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        stopProxy()
    }
}

// Entry point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
