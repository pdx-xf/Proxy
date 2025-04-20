import SwiftUI

struct Server: Identifiable {
    let id: UUID
    var name: String
    var host: String
    var port: Int
    var username: String
    var password: String
    var isActive: Bool
    
    init(id: UUID = UUID(), name: String, host: String, port: Int, username: String, password: String, isActive: Bool) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.isActive = isActive
    }
    
    init(from config: ServerConfig) {
        self.id = config.id
        self.name = config.name
        self.host = config.host
        self.port = config.port
        self.username = config.username
        self.password = config.password
        self.isActive = config.isActive
    }
}

class ServersViewModel: ObservableObject {
    @Published var servers: [Server] = []
    @Published var selectedServer: Server?
    private let storageManager = StorageManager.shared
    
    init() {
        loadServers()
    }
    
    private func loadServers() {
        let config = storageManager.loadConfig()
        servers = config.servers.map { Server(from: $0) }
    }
    
    private func saveServers() {
        var config = storageManager.loadConfig()
        config.servers = servers.map { ServerConfig(from: $0) }
        
        do {
            try storageManager.saveConfig(config)
        } catch {
            print("Failed to save servers: \(error.localizedDescription)")
        }
    }
    
    func addServer(_ server: Server) {
        servers.append(server)
        saveServers()
    }
    
    func removeServer(at offsets: IndexSet) {
        servers.remove(atOffsets: offsets)
        saveServers()
    }
    
    func activateServer(_ server: Server) {
        // 停用其他服务器
        servers = servers.map { srv in
            var updatedServer = srv
            updatedServer.isActive = (srv.id == server.id)
            return updatedServer
        }
        
        // 配置VPN
        if let activeServer = servers.first(where: { $0.isActive }) {
            ProxyManager.shared.configureVPN(
                serverAddress: activeServer.host,
                port: activeServer.port
            )
        }
        
        saveServers()
    }
}

struct ServersView: View {
    @StateObject private var viewModel = ServersViewModel()
    @State private var showingAddServer = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.servers) { server in
                    ServerRow(server: server) {
                        viewModel.activateServer(server)
                    }
                }
                .onDelete(perform: viewModel.removeServer)
            }
            .navigationTitle("服务器")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddServer = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddServer) {
                AddServerView(viewModel: viewModel)
            }
        }
    }
}

struct ServerRow: View {
    let server: Server
    let onActivate: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(server.name)
                    .font(.headline)
                Text("\(server.host):\(server.port)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if server.isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onActivate()
        }
    }
}

struct AddServerView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ServersViewModel
    
    @State private var name = ""
    @State private var host = ""
    @State private var port = ""
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("服务器信息")) {
                    TextField("名称", text: $name)
                    TextField("主机地址", text: $host)
                    TextField("端口", text: $port)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("认证信息")) {
                    TextField("用户名", text: $username)
                    SecureField("密码", text: $password)
                }
            }
            .navigationTitle("添加服务器")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    let server = Server(
                        name: name,
                        host: host,
                        port: Int(port) ?? 1080,
                        username: username,
                        password: password,
                        isActive: false
                    )
                    viewModel.addServer(server)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(name.isEmpty || host.isEmpty || port.isEmpty)
            )
        }
    }
} 