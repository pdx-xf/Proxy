import NetworkExtension

class TunnelManager {
    static let shared = TunnelManager()
    
    func startTunnel(proxyHost: String, proxyPort: Int, completion: @escaping (Error?) -> Void) {
        // 创建VPN配置
        let manager = NETunnelProviderManager()
        let proto = NETunnelProviderProtocol()
        
        // 设置隧道配置
        proto.providerBundleIdentifier = "com.your.app.tunnel-extension" // 替换为您的 tunnel extension bundle ID
        proto.serverAddress = proxyHost
        
        // 设置隧道配置选项
        let options: [String: Any] = [
            "proxyHost": proxyHost,
            "proxyPort": proxyPort
        ]
        proto.providerConfiguration = options
        
        manager.protocolConfiguration = proto
        manager.localizedDescription = "Proxy Tunnel"
        
        // 保存配置
        manager.saveToPreferences { error in
            if let error = error {
                completion(error)
                return
            }
            
            // 加载配置
            manager.loadFromPreferences { error in
                if let error = error {
                    completion(error)
                    return
                }
                
                // 启动VPN
                do {
                    try manager.connection.startVPNTunnel()
                    completion(nil)
                } catch {
                    completion(error)
                }
            }
        }
    }
    
    func stopTunnel(completion: @escaping (Error?) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            if let error = error {
                completion(error)
                return
            }
            
            guard let manager = managers?.first else {
                completion(nil)
                return
            }
            
            manager.connection.stopVPNTunnel()
            completion(nil)
        }
    }
    
    // 获取当前流量统计
    func getCurrentTrafficStats() -> (inbound: String, outbound: String, speedIn: String, speedOut: String) {
        return TrafficManager.shared.getFormattedStats()
    }
} 