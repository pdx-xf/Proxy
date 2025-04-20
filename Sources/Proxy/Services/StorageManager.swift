import Foundation

class StorageManager {
    static let shared = StorageManager()
    private let configKey = "com.proxy.config"
    
    private init() {}
    
    // 获取配置文件路径
    private var configURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("config.json")
    }
    
    // 保存配置
    func saveConfig(_ config: AppConfig) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(config)
        try data.write(to: configURL)
    }
    
    // 加载配置
    func loadConfig() -> AppConfig {
        do {
            let data = try Data(contentsOf: configURL)
            let decoder = JSONDecoder()
            return try decoder.decode(AppConfig.self, from: data)
        } catch {
            print("Failed to load config: \(error.localizedDescription)")
            return AppConfig.default
        }
    }
    
    // 导出配置
    func exportConfig() -> URL {
        return configURL
    }
    
    // 导入配置
    func importConfig(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let config = try decoder.decode(AppConfig.self, from: data)
        try saveConfig(config)
    }
} 