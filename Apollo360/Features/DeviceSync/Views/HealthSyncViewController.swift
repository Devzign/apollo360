import UIKit

final class HealthSyncViewController: UIViewController {
  private let viewModel: HealthSyncViewModel
  private let encodedUsername: String
  private let deviceId: String

  private let statusLabel = UILabel()
  private let lastSyncLabel = UILabel()
  private let sourceCountLabel = UILabel()
  private let syncButton = UIButton(type: .system)

  init(viewModel: HealthSyncViewModel, encodedUsername: String, deviceId: String) {
    self.viewModel = viewModel
    self.encodedUsername = encodedUsername
    self.deviceId = deviceId
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    render()
  }

  private func setupUI() {
    title = "Device Sync"
    view.backgroundColor = .systemBackground

    statusLabel.numberOfLines = 0
    lastSyncLabel.numberOfLines = 1
    sourceCountLabel.numberOfLines = 1

    syncButton.setTitle("Sync with Apple Health", for: .normal)
    syncButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
    syncButton.backgroundColor = .systemGreen
    syncButton.setTitleColor(.white, for: .normal)
    syncButton.layer.cornerRadius = 10
    syncButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 20, bottom: 14, right: 20)
    syncButton.addTarget(self, action: #selector(syncTapped), for: .touchUpInside)

    let stack = UIStackView(arrangedSubviews: [statusLabel, lastSyncLabel, sourceCountLabel, syncButton])
    stack.axis = .vertical
    stack.spacing = 16
    stack.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
    ])
  }

  @objc
  private func syncTapped() {
    Task { [weak self] in
      guard let self else { return }
      await self.viewModel.sync(encodedUsername: self.encodedUsername, deviceId: self.deviceId)
      await MainActor.run {
        self.render()
      }
    }
  }

  private func render() {
    switch viewModel.state {
    case .idle:
      statusLabel.text = "Ready to sync."
      syncButton.isEnabled = true
      syncButton.alpha = 1.0
    case .syncing:
      statusLabel.text = "Syncing..."
      syncButton.isEnabled = false
      syncButton.alpha = 0.7
    case .success(let message):
      statusLabel.text = message
      syncButton.isEnabled = true
      syncButton.alpha = 1.0
    case .failure(let message):
      statusLabel.text = "Error: \(message)"
      syncButton.isEnabled = true
      syncButton.alpha = 1.0
    }

    if let date = viewModel.lastSyncedAt {
      let formatter = DateFormatter()
      formatter.dateStyle = .medium
      formatter.timeStyle = .medium
      lastSyncLabel.text = "Last Sync: \(formatter.string(from: date))"
    } else {
      lastSyncLabel.text = "Last Sync: Not synced yet"
    }

    sourceCountLabel.text = "Connected Sources: \(viewModel.sourceCount)"
  }
}
