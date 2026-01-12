import IQKeyboardManagerSwift
import IQKeyboardToolbar
import IQKeyboardToolbarManager
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        configureKeyboard()
        return true
    }
    
    private func configureKeyboard() {
        let keyboardManager = IQKeyboardManager.shared
        keyboardManager.isEnabled = true
        keyboardManager.resignOnTouchOutside = true

        let toolbarManager = IQKeyboardToolbarManager.shared
        toolbarManager.isEnabled = true
        toolbarManager.toolbarConfiguration.placeholderConfiguration.showPlaceholder = false
        toolbarManager.toolbarConfiguration.doneBarButtonConfiguration = IQBarButtonItemConfiguration(title: "Done")
    }
}
