import Foundation
import NetworkExtension

struct VPNConfig {
    enum VPNProtocol {
        case ikev2
        case ipsec
        case shadowsocks
        
        var protocolConfiguration: NEVPNProtocol {
            switch self {
            case .ikev2:
                return NEVPNProtocolIKEv2()
            case .ipsec:
                return NEVPNProtocolIPSec()
            case .shadowsocks:
                // 需要自定义Shadowsocks协议配置
                return NEVPNProtocolIKEv2()
            }
        }
    }
    
    struct Shadowsocks {
        var method: String
        var password: String
        var plugin: String?
        var pluginOpts: String?
    }
    
    var serverAddress: String
    var serverPort: Int
    var username: String
    var password: String
    var protocol: VPNProtocol
    var shadowsocks: Shadowsocks?
    var dnsServers: [String]
    var mtu: Int
    
    static var `default`: VPNConfig {
        VPNConfig(
            serverAddress: "",
            serverPort: 443,
            username: "",
            password: "",
            protocol: .ikev2,
            dnsServers: ["8.8.8.8", "8.8.4.4"],
            mtu: 1500
        )
    }
} 