import SwiftUI

struct PACEditorView: View {
    @StateObject private var viewModel = PACEditorViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showingImportSheet = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $viewModel.script)
                    .font(.system(.body, design: .monospaced))
                    .disableAutocorrection(true)
                    .padding()
                
                if !viewModel.lastUpdated.isEmpty {
                    Text("最后更新: \(viewModel.lastUpdated)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("PAC规则编辑器")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: HStack {
                    Button("导入") {
                        showingImportSheet = true
                    }
                    
                    Button("保存") {
                        viewModel.saveScript { error in
                            if let error = error {
                                alertMessage = "保存失败: \(error.localizedDescription)"
                                showingAlert = true
                            } else {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                }
            )
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("错误"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("确定"))
                )
            }
            .sheet(isPresented: $showingImportSheet) {
                PACImportView(viewModel: viewModel)
            }
        }
    }
}

class PACEditorViewModel: ObservableObject {
    @Published var script: String
    @Published var lastUpdated: String
    private let ruleManager = RuleManager.shared
    
    init() {
        script = ruleManager.getPACScript()
        lastUpdated = formatDate(ruleManager.getPACLastUpdated())
    }
    
    func saveScript(completion: @escaping (Error?) -> Void) {
        ruleManager.updatePACScript(script)
        lastUpdated = formatDate(ruleManager.getPACLastUpdated())
        completion(nil)
    }
    
    func importFromURL(_ url: URL) async {
        do {
            try await ruleManager.updatePACFromURL(url)
            await MainActor.run {
                script = ruleManager.getPACScript()
                lastUpdated = formatDate(ruleManager.getPACLastUpdated())
            }
        } catch {
            print("Failed to import PAC: \(error.localizedDescription)")
        }
    }
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

struct PACImportView: View {
    @ObservedObject var viewModel: PACEditorViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var urlString = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("从URL导入")) {
                    TextField("PAC文件URL", text: $urlString)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                }
                
                Section {
                    Button(action: importPAC) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("导入")
                        }
                    }
                    .disabled(urlString.isEmpty || isLoading)
                }
            }
            .navigationTitle("导入PAC")
            .navigationBarItems(
                trailing: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert(isPresented: $showingError) {
                Alert(
                    title: Text("导入错误"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("确定"))
                )
            }
        }
    }
    
    private func importPAC() {
        guard let url = URL(string: urlString) else {
            errorMessage = "无效的URL"
            showingError = true
            return
        }
        
        isLoading = true
        Task {
            await viewModel.importFromURL(url)
            await MainActor.run {
                isLoading = false
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
} 