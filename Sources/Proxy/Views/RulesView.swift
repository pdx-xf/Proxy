import SwiftUI

struct RulesView: View {
    @StateObject private var viewModel = RulesViewModel()
    @State private var showingAddRule = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.rules.indices, id: \.self) { index in
                    RuleRow(rule: viewModel.rules[index])
                }
                .onDelete(perform: viewModel.deleteRule)
            }
            .navigationTitle("规则管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddRule = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddRule) {
                AddRuleView(viewModel: viewModel)
            }
        }
    }
}

struct RuleRow: View {
    let rule: Rule
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(rule.pattern)
                    .font(.headline)
                Text(rule.action.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(rule.action.color)
                .frame(width: 12, height: 12)
        }
        .padding(.vertical, 8)
    }
}

class RulesViewModel: ObservableObject {
    @Published var rules: [Rule] = []
    private let ruleManager = RuleManager.shared
    
    init() {
        rules = ruleManager.getRules()
    }
    
    func addRule(pattern: String, action: RuleAction) {
        let rule = Rule(pattern: pattern, action: action)
        ruleManager.addRule(rule)
        rules = ruleManager.getRules()
    }
    
    func deleteRule(at offsets: IndexSet) {
        offsets.forEach { index in
            ruleManager.removeRule(at: index)
        }
        rules = ruleManager.getRules()
    }
}

struct AddRuleView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: RulesViewModel
    @State private var pattern = ""
    @State private var selectedAction = RuleAction.proxy
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("规则详情")) {
                    TextField("规则匹配模式", text: $pattern)
                    Picker("动作", selection: $selectedAction) {
                        Text("代理").tag(RuleAction.proxy)
                        Text("直连").tag(RuleAction.direct)
                        Text("拒绝").tag(RuleAction.reject)
                    }
                }
            }
            .navigationTitle("添加规则")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    viewModel.addRule(pattern: pattern, action: selectedAction)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(pattern.isEmpty)
            )
        }
    }
}

extension RuleAction {
    var description: String {
        switch self {
        case .proxy: return "代理"
        case .direct: return "直连"
        case .reject: return "拒绝"
        }
    }
    
    var color: Color {
        switch self {
        case .proxy: return .blue
        case .direct: return .green
        case .reject: return .red
        }
    }
} 