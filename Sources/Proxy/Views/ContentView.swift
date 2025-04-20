import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }
                .tag(0)
            
            RulesView()
                .tabItem {
                    Label("规则", systemImage: "list.bullet")
                }
                .tag(1)
            
            ServersView()
                .tabItem {
                    Label("服务器", systemImage: "server.rack")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
                .tag(3)
        }
    }
}

class ContentViewModel: ObservableObject {
    @Published var isVPNConnected = false
    private let proxyManager = ProxyManager.shared
    
    func toggleVPN() {
        if isVPNConnected {
            proxyManager.stopVPN()
        } else {
            proxyManager.startVPN()
        }
        isVPNConnected.toggle()
    }
}

struct HomeView: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack {
            Button(action: viewModel.toggleVPN) {
                VStack {
                    Image(systemName: viewModel.isVPNConnected ? "power.circle.fill" : "power.circle")
                        .font(.system(size: 60))
                        .foregroundColor(viewModel.isVPNConnected ? .green : .red)
                    
                    Text(viewModel.isVPNConnected ? "已连接" : "未连接")
                        .font(.headline)
                        .padding(.top)
                }
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("Proxy")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 