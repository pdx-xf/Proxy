import Foundation
import NetworkExtension
import Logging

class PacketTunnelProvider: NEPacketTunnelProvider {
    private let logger = Logger(label: "com.proxy.tunnel")
    private let ruleManager = RuleManager.shared
    private let dnsResolver = DNSResolver.shared
    private let trafficManager = TrafficManager.shared
    private var proxyForwarder: ProxyForwarder?
    private var packetFlow: NEPacketTunnelFlow { self.packetFlow }
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        logger.info("Starting packet tunnel")
        
        // 初始化代理转发器
        if let proxyHost = options?["proxyHost"] as? String,
           let proxyPort = options?["proxyPort"] as? Int {
            proxyForwarder = ProxyForwarder(host: proxyHost, port: proxyPort)
        }
        
        // 配置网络设置
        let networkSettings = createNetworkSettings()
        setTunnelNetworkSettings(networkSettings) { [weak self] error in
            if let error = error {
                self?.logger.error("Failed to set tunnel settings: \(error.localizedDescription)")
                completionHandler(error)
                return
            }
            
            self?.logger.info("Tunnel settings configured successfully")
            self?.startPacketForwarding()
            completionHandler(nil)
        }
    }
    
    private func createNetworkSettings() -> NEPacketTunnelNetworkSettings {
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "192.168.1.1")
        
        // 配置IPv4设置
        let ipv4Settings = NEIPv4Settings(addresses: ["192.168.1.2"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4Settings
        
        // 配置DNS设置
        let dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "8.8.4.4"])
        dnsSettings.matchDomains = [""] // 匹配所有域名
        settings.dnsSettings = dnsSettings
        
        // 配置MTU
        settings.mtu = NSNumber(value: 1500)
        
        return settings
    }
    
    private func startPacketForwarding() {
        // 启动数据包读取循环
        readPackets()
    }
    
    private func readPackets() {
        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self = self else { return }
            
            for (index, packet) in packets.enumerated() {
                let protocol = protocols[index]
                self.handlePacket(packet, protocol: protocol)
            }
            
            // 继续读取下一批数据包
            self.readPackets()
        }
    }
    
    private func handlePacket(_ packet: Data, protocol: NSNumber) {
        // 解析数据包
        guard let ipPacket = IPPacket(data: packet) else {
            logger.error("Failed to parse IP packet")
            return
        }
        
        // 记录入站流量
        trafficManager.addInboundTraffic(UInt64(packet.count))
        
        // 应用规则
        let action = determineAction(for: ipPacket)
        
        switch action {
        case .proxy:
            forwardPacketViaProxy(ipPacket)
        case .direct:
            forwardPacketDirect(ipPacket)
        case .reject:
            dropPacket(ipPacket)
        }
    }
    
    private func determineAction(for packet: IPPacket) -> RuleAction {
        // 如果是DNS查询，总是使用代理
        if packet.isUDPDNSPacket {
            return .proxy
        }
        
        // 获取目标地址
        guard let destinationAddress = packet.destinationAddress else {
            return .direct
        }
        
        // 检查规则匹配
        if let url = URL(string: "http://" + destinationAddress) {
            return ruleManager.matchRule(for: url)
        }
        
        return .direct
    }
    
    private func forwardPacketViaProxy(_ packet: IPPacket) {
        guard let proxyForwarder = proxyForwarder,
              let destinationAddress = packet.destinationAddress else {
            logger.error("Cannot forward packet: missing proxy forwarder or destination address")
            return
        }
        
        // 记录出站流量
        trafficManager.addOutboundTraffic(UInt64(packet.data.count))
        
        // 创建源和目标端点
        let sourceEndpoint = NWEndpoint.hostPort(host: .init("192.168.1.2"), port: .init(integerLiteral: 0))
        let destinationEndpoint = NWEndpoint.hostPort(host: .init(destinationAddress), port: .init(integerLiteral: 0))
        
        proxyForwarder.forwardPacket(packet.data, from: sourceEndpoint, to: destinationEndpoint) { [weak self] error in
            if let error = error {
                self?.logger.error("Failed to forward packet via proxy: \(error.localizedDescription)")
                return
            }
            
            self?.logger.debug("Packet forwarded successfully via proxy")
        }
    }
    
    private func forwardPacketDirect(_ packet: IPPacket) {
        // 记录出站流量
        trafficManager.addOutboundTraffic(UInt64(packet.data.count))
        
        // 直接转发数据包
        packetFlow.writePackets([packet.data], withProtocols: [packet.protocol])
    }
    
    private func dropPacket(_ packet: IPPacket) {
        // 丢弃数据包，不做任何处理
        logger.debug("Dropped packet to \(packet.destinationAddress ?? "unknown")")
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        logger.info("Stopping packet tunnel with reason: \(reason)")
        proxyForwarder?.close()
        completionHandler()
    }
}

// MARK: - IP Packet Parser
struct IPPacket {
    let data: Data
    let `protocol`: NSNumber
    var destinationAddress: String?
    var isUDPDNSPacket: Bool
    
    init?(data: Data) {
        guard data.count >= 20 else { return nil }
        
        self.data = data
        
        // 解析IP头
        let version = (data[0] >> 4) & 0xF
        self.protocol = NSNumber(value: Int(data[9]))
        
        // 解析目标地址
        if version == 4 {
            // IPv4
            self.destinationAddress = "\(data[16]).\(data[17]).\(data[18]).\(data[19])"
        } else if version == 6 {
            // IPv6
            // TODO: 实现IPv6地址解析
            self.destinationAddress = nil
        } else {
            return nil
        }
        
        // 检查是否是UDP DNS查询（端口53）
        self.isUDPDNSPacket = self.protocol.intValue == 17 && // UDP
            data.count >= 28 && // UDP header length
            (UInt16(data[22]) << 8 | UInt16(data[23])) == 53 // Destination port
    }
} 