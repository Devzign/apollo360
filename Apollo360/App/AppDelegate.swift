import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        KeyboardAccessoryManager.shared.activate()
        return true
    }
}

private final class KeyboardAccessoryManager {
    static let shared = KeyboardAccessoryManager()
    private let accessoryToolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        return toolbar
    }()
    private weak var currentResponder: UIResponder?
    private var notificationToken: NSObjectProtocol?
    private let supportedKeyboardTypes: Set<UIKeyboardType> = [.numberPad, .phonePad, .decimalPad]

    private init() {
        let doneItem = UIBarButtonItem(title: "OK", style: .done, target: self, action: #selector(dismissKeyboard))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        accessoryToolbar.setItems([spacer, doneItem], animated: false)
    }

    func activate() {
        guard notificationToken == nil else { return }
        notificationToken = NotificationCenter.default.addObserver(
            forName: UITextField.textDidBeginEditingNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.attachAccessory(to: notification.object as? UITextField)
        }
    }

    private func attachAccessory(to textField: UITextField?) {
        guard let textField = textField,
              supportedKeyboardTypes.contains(textField.keyboardType) else {
            return
        }

        textField.inputAccessoryView = accessoryToolbar
        currentResponder = textField
    }

    @objc private func dismissKeyboard() {
        currentResponder?.resignFirstResponder()
    }
}

