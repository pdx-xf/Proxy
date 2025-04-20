import Foundation
import Network
import Logging

class DNSResolver {
    static let shared = DNSResolver()
    private let logger = Logger(label: "com.proxy.dns")
    private let queue = DispatchQueue(label: "DNSResolver", qos: .userInitiated)
    
    private var dnsServers: [String]
    private var cache: [String: DNSRecord] = [:]
    
    struct DNSRecord {
        let ipAddress: String
        let timestamp: Date
        let ttl: TimeInterval
        
        var isExpired: Bool {
            return Date().timeIntervalSince(timestamp) > ttl
        }
    }
    
    private init() {
        self.dnsServers = ["8.8.8.8", "8.8.4.4"] // 默认使用Google DNS
    }
    
    func setDNSServers(_ servers: [String]) {
        dnsServers = servers
        logger.info("DNS servers updated: \(servers)")
    }
    
    func resolve(_ hostname: String, completion: @escaping (String?) -> Void) {
        // 首先检查缓存
        if let cached = cache[hostname], !cached.isExpired {
            completion(cached.ipAddress)
            return
        }
        
        queue.async {
            self.performDNSLookup(hostname) { result in
                switch result {
                case .success(let record):
                    self.cache[hostname] = record
                    completion(record.ipAddress)
                case .failure(let error):
                    self.logger.error("DNS resolution failed: \(error.localizedDescription)")
                    completion(nil)
                }
            }
        }
    }
    
    private func performDNSLookup(_ hostname: String, completion: @escaping (Result<DNSRecord, Error>) -> Void) {
        let host = NWEndpoint.Host(hostname)
        let timeout = DispatchTime.now() + .seconds(5)
        
        var addresses: [String] = []
        let group = DispatchGroup()
        
        for server in dnsServers {
            group.enter()
            
            // 使用Network.framework进行DNS查询
            let parameters = NWParameters()
            parameters.requiredInterfaceType = .any
            
            let connection = NWConnection(host: host, port: 53, using: parameters)
            
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    // 连接就绪，可以发送DNS查询
                    break
                case .failed(let error):
                    self.logger.error("DNS query failed: \(error.localizedDescription)")
                    group.leave()
                case .cancelled:
                    group.leave()
                default:
                    break
                }
            }
            
            connection.start(queue: queue)
        }
        
        group.notify(queue: queue) {
            if let address = addresses.first {
                let record = DNSRecord(
                    ipAddress: address,
                    timestamp: Date(),
                    ttl: 300 // 5分钟的TTL
                )
                completion(.success(record))
            } else {
                completion(.failure(NSError(domain: "DNSResolver", code: -1, userInfo: [NSLocalizedDescriptionKey: "No addresses found"])))
            }
        }
    }
    
    func clearCache() {
        cache.removeAll()
        logger.info("DNS cache cleared")
    }
    
    func getCachedRecord(for hostname: String) -> DNSRecord? {
        return cache[hostname]
    }
} 