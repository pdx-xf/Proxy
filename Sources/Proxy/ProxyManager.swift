import Foundation
import NetworkExtension
import Logging
import Combine

public class ProxyManager {
    private let logger = Logger(label: "com.proxy.manager")
    private var vpnManager: NEVPNManager?
    private var statusObserver: NSObjectProtocol?
    private var currentConfig: VPNConfig?
    private let networkMonitor = NetworkMonitor.shared
    
    @Published public private(set) var status: NEVPNStatus = .invalid
    @Published public private(set) var trafficStats: TrafficStats = TrafficStats()
    
    public static let shared = ProxyManager()
    
    private init() {
        setupVPNManager()
        setupStatusObserver()
    }
    
    private func setupVPNManager() {
        vpnManager = NEVPNManager.shared()
        loadVPNPreferences()
    }
    
    private func setupStatusObserver() {
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let connection = notification.object as? NEVPNConnection else { return }
            self?.status = connection.status
            self?.handleStatusChange(connection.status)
        }
    }
    
    private func handleStatusChange(_ status: NEVPNStatus) {
        switch status {
        case .connected:
            logger.info("VPN connected successfully")
            startTrafficMonitoring()
        case .disconnected:
            logger.info("VPN disconnected")
            stopTrafficMonitoring()
        case .connecting:
            logger.info("VPN is connecting")
        case .disconnecting:
            logger.info("VPN is disconnecting")
        case .invalid:
            logger.error("VPN configuration is invalid")
        case .reasserting:
            logger.info("VPN is reasserting")
        @unknown default:
            logger.warning("Unknown VPN status: \(status)")
        }
    }
    
    private func loadVPNPreferences() {
        vpnManager?.loadFromPreferences { [weak self] error in
            if let error = error {
                self?.logger.error("Failed to load VPN preferences: \(error.localizedDescription)")
                return
            }
            self?.logger.info("VPN preferences loaded successfully")
        }
    }
    
    public func configureVPN(with config: VPNConfig) {
        guard let vpnManager = vpnManager else { return }
        
        currentConfig = config
        let proto = config.protocol.protocolConfiguration
        
        if let ikeProto = proto as? NEVPNProtocolIKEv2 {
            configureIKEv2(ikeProto, with: config)
        } else if let ipsecProto = proto as? NEVPNProtocolIPSec {
            configureIPSec(ipsecProto, with: config)
        }
        
        vpnManager.protocolConfiguration = proto
        vpnManager.localizedDescription = "Proxy VPN"
        vpnManager.isEnabled = true
        
        // 配置DNS
        if let proto = proto as? NEVPNProtocolIPSec {
            proto.dnsSettings = NEDNSSettings(servers: config.dnsServers)
        }
        
        vpnManager.saveToPreferences { [weak self] error in
            if let error = error {
                self?.logger.error("Failed to save VPN configuration: \(error.localizedDescription)")
                return
            }
            self?.logger.info("VPN configuration saved successfully")
        }
    }
    
    private func configureIKEv2(_ proto: NEVPNProtocolIKEv2, with config: VPNConfig) {
        proto.serverAddress = config.serverAddress
        proto.serverPort = config.serverPort
        proto.username = config.username
        proto.passwordReference = storePassword(config.password)
        proto.remoteIdentifier = config.serverAddress
        proto.localIdentifier = "client"
        
        // IKEv2 specific settings
        proto.useExtendedAuthentication = true
        proto.disconnectOnSleep = false
    }
    
    private func configureIPSec(_ proto: NEVPNProtocolIPSec, with config: VPNConfig) {
        proto.serverAddress = config.serverAddress
        proto.username = config.username
        proto.passwordReference = storePassword(config.password)
        
        // IPSec specific settings
        proto.authenticationMethod = .none
        proto.useExtendedAuthentication = true
        proto.disconnectOnSleep = false
    }
    
    private func storePassword(_ password: String) -> Data? {
        // TODO: 实现密码安全存储
        return password.data(using: .utf8)
    }
    
    public func startVPN() {
        do {
            try vpnManager?.connection.startVPNTunnel()
            logger.info("VPN tunnel started")
        } catch {
            logger.error("Failed to start VPN tunnel: \(error.localizedDescription)")
        }
    }
    
    public func stopVPN() {
        vpnManager?.connection.stopVPNTunnel()
        logger.info("VPN tunnel stopped")
    }
    
    // MARK: - Traffic Monitoring
    
    struct TrafficStats {
        var uploadBytes: UInt64 = 0
        var downloadBytes: UInt64 = 0
        var uploadSpeed: Double = 0
        var downloadSpeed: Double = 0
    }
    
    private var trafficMonitorTimer: Timer?
    
    private func startTrafficMonitoring() {
        trafficMonitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTrafficStats()
        }
    }
    
    private func stopTrafficMonitoring() {
        trafficMonitorTimer?.invalidate()
        trafficMonitorTimer = nil
    }
    
    private func updateTrafficStats() {
        // TODO: 实现流量统计
        let (upload, download) = networkMonitor.getCurrentBandwidth()
        trafficStats.uploadSpeed = upload
        trafficStats.downloadSpeed = download
    }
    
    deinit {
        if let observer = statusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        stopTrafficMonitoring()
    }
} 