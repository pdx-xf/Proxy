import SwiftUI
import UniformTypeIdentifiers

class SettingsViewModel: ObservableObject {
    @Published var autoConnect: Bool = false {
        didSet { saveSettings() }
    }
    @Published var showNetworkStatus: Bool = true {
        didSet { saveSettings() }
    }
    @Published var dnsServer: String = "8.8.8.8" {
        didSet { saveSettings() }
    }
    @Published var defaultRoute: RuleAction = .direct {
        didSet { saveSettings() }
    }
    
    private let storageManager = StorageManager.shared
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        let config = storageManager.loadConfig()
        autoConnect = config.settings.autoConnect
        showNetworkStatus = config.settings.showNetworkStatus
        dnsServer = config.settings.dnsServer
        defaultRoute = config.settings.defaultRoute.toRuleAction
    }
    
    private func saveSettings() {
        var config = storageManager.loadConfig()
        config.settings.autoConnect = autoConnect
        config.settings.showNetworkStatus = showNetworkStatus
        config.settings.dnsServer = dnsServer
        config.settings.defaultRoute = RuleActionType(from: defaultRoute)
        
        do {
            try storageManager.saveConfig(config)
        } catch {
            print("Failed to save settings: \(error.localizedDescription)")
        }
    }
    
    func importConfig() {
        // TODO: 实现文件选择器和导入逻辑
    }
    
    func exportConfig() {
        // TODO: 实现文件分享功能
    }
}

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("通用设置")) {
                    Toggle("启动时自动连接", isOn: $viewModel.autoConnect)
                    Toggle("显示网络状态", isOn: $viewModel.showNetworkStatus)
                }
                
                Section(header: Text("DNS设置")) {
                    TextField("DNS服务器", text: $viewModel.dnsServer)
                }
                
                Section(header: Text("规则设置")) {
                    Picker("默认路由", selection: $viewModel.defaultRoute) {
                        Text("代理").tag(RuleAction.proxy)
                        Text("直连").tag(RuleAction.direct)
                        Text("拒绝").tag(RuleAction.reject)
                    }
                }
                
                Section(header: Text("配置管理")) {
                    Button("导入配置") {
                        viewModel.importConfig()
                    }
                    
                    Button("导出配置") {
                        viewModel.exportConfig()
                    }
                }
                
                Section(header: Text("关于")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
} 