import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = MainViewController()
        window?.makeKeyAndVisible()
        return true
    }
}

class MainViewController: UIViewController {
    private let startButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    private let statsLabel = UILabel()
    private var statsTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startStatsTimer()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // 配置开始按钮
        startButton.setTitle("启动隧道", for: .normal)
        startButton.addTarget(self, action: #selector(startTunnelTapped), for: .touchUpInside)
        view.addSubview(startButton)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50)
        ])
        
        // 配置停止按钮
        stopButton.setTitle("停止隧道", for: .normal)
        stopButton.addTarget(self, action: #selector(stopTunnelTapped), for: .touchUpInside)
        view.addSubview(stopButton)
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stopButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stopButton.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant: 20)
        ])
        
        // 配置统计标签
        statsLabel.numberOfLines = 0
        statsLabel.textAlignment = .center
        view.addSubview(statsLabel)
        statsLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statsLabel.topAnchor.constraint(equalTo: stopButton.bottomAnchor, constant: 30),
            statsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func startStatsTimer() {
        statsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }
    
    private func updateStats() {
        let stats = TunnelManager.shared.getCurrentTrafficStats()
        statsLabel.text = """
            入站流量：\(stats.inbound)
            出站流量：\(stats.outbound)
            入站速度：\(stats.speedIn)
            出站速度：\(stats.speedOut)
            """
    }
    
    @objc private func startTunnelTapped() {
        TunnelManager.shared.startTunnel(proxyHost: "your.proxy.host", proxyPort: 1080) { [weak self] error in
            if let error = error {
                self?.showAlert(title: "启动失败", message: error.localizedDescription)
                return
            }
            self?.showAlert(title: "成功", message: "隧道已启动")
        }
    }
    
    @objc private func stopTunnelTapped() {
        TunnelManager.shared.stopTunnel { [weak self] error in
            if let error = error {
                self?.showAlert(title: "停止失败", message: error.localizedDescription)
                return
            }
            self?.showAlert(title: "成功", message: "隧道已停止")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
} 