import Foundation
import Logging

public struct Rule {
    public let pattern: String
    public let action: RuleAction
    
    public init(pattern: String, action: RuleAction) {
        self.pattern = pattern
        self.action = action
    }
    
    init(from config: RuleConfig) {
        self.pattern = config.pattern
        self.action = config.action.toRuleAction
    }
}

public enum RuleAction {
    case proxy
    case direct
    case reject
}

public class RuleManager {
    private let logger = Logger(label: "com.proxy.rules")
    private var rules: [Rule] = []
    private let storageManager = StorageManager.shared
    
    public static let shared = RuleManager()
    
    private init() {
        loadRules()
    }
    
    private func loadRules() {
        let config = storageManager.loadConfig()
        rules = config.rules.map { Rule(from: $0) }
        logger.info("Loaded \(rules.count) rules")
    }
    
    public func addRule(_ rule: Rule) {
        rules.append(rule)
        saveRules()
    }
    
    public func removeRule(at index: Int) {
        guard index < rules.count else { return }
        rules.remove(at: index)
        saveRules()
    }
    
    public func getRules() -> [Rule] {
        return rules
    }
    
    private func saveRules() {
        var config = storageManager.loadConfig()
        config.rules = rules.map { RuleConfig(from: $0) }
        
        do {
            try storageManager.saveConfig(config)
            logger.info("Rules saved successfully")
        } catch {
            logger.error("Failed to save rules: \(error.localizedDescription)")
        }
    }
    
    public func matchRule(for url: URL) -> RuleAction {
        for rule in rules {
            if url.absoluteString.contains(rule.pattern) {
                logger.debug("URL \(url) matched rule: \(rule.pattern)")
                return rule.action
            }
        }
        return .direct // 默认直连
    }
} 