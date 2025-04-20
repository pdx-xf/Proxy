import Foundation
import Network
import Logging

class ProxyForwarder {
    private let logger = Logger(label: "com.proxy.forwarder")
    private let proxyHost: String
    private let proxyPort: Int
    private let trafficManager = TrafficManager.shared
    private let queue = DispatchQueue(label: "ProxyForwarder", qos: .userInitiated)
    
    init(host: String, port: Int) {
        self.proxyHost = host
        self.proxyPort = port
    }
    
    func forwardPacket(_ packet: Data, from source: NWEndpoint, to destination: NWEndpoint, completion: @escaping (Error?) -> Void) {
        // 创建到代理服务器的连接
        let proxyEndpoint = NWEndpoint.hostPort(host: .init(proxyHost), port: .init(integerLiteral: UInt16(proxyPort)))
        let connection = NWConnection(to: proxyEndpoint, using: .tcp)
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.sendPacketToProxy(connection, packet, from: source, to: destination, completion: completion)
            case .failed(let error):
                self?.logger.error("Proxy connection failed: \(error.localizedDescription)")
                completion(error)
            case .cancelled:
                completion(NSError(domain: "ProxyForwarder", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection cancelled"]))
            default:
                break
            }
        }
        
        connection.start(queue: queue)
    }
    
    private func sendPacketToProxy(_ connection: NWConnection, _ packet: Data, from source: NWEndpoint, to destination: NWEndpoint, completion: @escaping (Error?) -> Void) {
        // 构建SOCKS5代理请求
        var proxyRequest = Data()
        
        // SOCKS5握手
        proxyRequest.append(contentsOf: [0x05, 0x01, 0x00]) // 版本5，1种认证方法，无认证
        
        connection.send(content: proxyRequest, completion: .contentProcessed { [weak self] error in
            if let error = error {
                self?.logger.error("Failed to send SOCKS5 handshake: \(error.localizedDescription)")
                completion(error)
                return
            }
            
            // 接收服务器响应
            connection.receive(minimumIncompleteLength: 2, maximumLength: 2) { data, _, isComplete, error in
                if let error = error {
                    self?.logger.error("Failed to receive SOCKS5 response: \(error.localizedDescription)")
                    completion(error)
                    return
                }
                
                guard let data = data, data.count == 2, data[0] == 0x05, data[1] == 0x00 else {
                    completion(NSError(domain: "ProxyForwarder", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid SOCKS5 response"]))
                    return
                }
                
                // 发送连接请求
                self?.sendConnectRequest(to: destination, completion: completion)
            }
        })
    }
    
    private func sendConnectRequest(to destination: NWEndpoint, completion: @escaping (Error?) -> Void) {
        guard let connection = connections[destination] else {
            completion(ProxyError.connectionNotFound)
            return
        }
        
        let request = "CONNECT \(destination) HTTP/1.1\r\nHost: \(destination)\r\n\r\n"
        guard let requestData = request.data(using: .utf8) else {
            completion(ProxyError.invalidRequest)
            return
        }
        
        // 记录出站流量
        trafficManager.addOutboundTraffic(UInt64(requestData.count))
        
        connection.send(content: requestData, completion: .contentProcessed { error in
            if let error = error {
                self.logger.error("Failed to send CONNECT request: \(error.localizedDescription)")
                completion(error)
                return
            }
            
            completion(nil)
        })
    }
    
    func forwardActualPacket(_ packet: Data, from source: NWEndpoint, to destination: NWEndpoint, completion: @escaping (Error?) -> Void) {
        // 记录入站流量
        trafficManager.addInboundTraffic(UInt64(packet.count))
        
        guard let connection = connections[destination] else {
            completion(ProxyError.connectionNotFound)
            return
        }
        
        connection.send(content: packet, completion: .contentProcessed { error in
            if let error = error {
                self.logger.error("Failed to forward packet: \(error.localizedDescription)")
                completion(error)
                return
            }
            
            // 记录出站流量
            self.trafficManager.addOutboundTraffic(UInt64(packet.count))
            completion(nil)
        })
    }
    
    func close() {
        // 清理资源
    }
} 