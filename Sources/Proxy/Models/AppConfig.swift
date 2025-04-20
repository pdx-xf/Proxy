import Foundation

struct AppConfig: Codable {
    var servers: [ServerConfig]
    var rules: [RuleConfig]
    var settings: Settings
    
    static var `default`: AppConfig {
        AppConfig(
            servers: [],
            rules: [],
            settings: Settings()
        )
    }
}

struct ServerConfig: Codable, Identifiable {
    let id: UUID
    var name: String
    var host: String
    var port: Int
    var username: String
    var password: String
    var isActive: Bool
    
    init(from server: Server) {
        self.id = server.id
        self.name = server.name
        self.host = server.host
        self.port = server.port
        self.username = server.username
        self.password = server.password
        self.isActive = server.isActive
    }
}

struct RuleConfig: Codable {
    var pattern: String
    var action: RuleActionType
    
    init(from rule: Rule) {
        self.pattern = rule.pattern
        self.action = RuleActionType(from: rule.action)
    }
}

enum RuleActionType: String, Codable {
    case proxy
    case direct
    case reject
    
    init(from action: RuleAction) {
        switch action {
        case .proxy: self = .proxy
        case .direct: self = .direct
        case .reject: self = .reject
        }
    }
    
    var toRuleAction: RuleAction {
        switch self {
        case .proxy: return .proxy
        case .direct: return .direct
        case .reject: return .reject
        }
    }
}

struct Settings: Codable {
    var autoConnect: Bool = false
    var showNetworkStatus: Bool = true
    var dnsServer: String = "8.8.8.8"
    var defaultRoute: RuleActionType = .direct
} 