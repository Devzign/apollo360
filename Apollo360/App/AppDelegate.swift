//
//  AppDelegate.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import IQKeyboardManagerSwift
import IQKeyboardToolbar
import IQKeyboardToolbarManager
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock: UIInterfaceOrientationMask = .allButUpsideDown

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        configureKeyboard()
        return true
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        Self.orientationLock
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

    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        orientationLock = orientation
    }

    static func lockOrientation(_ orientation: UIInterfaceOrientationMask, rotateTo rotateOrientation: UIInterfaceOrientation) {
        orientationLock = orientation
        if #available(iOS 16.0, *) {
            guard let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
                    return
                }

            let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: orientation)
            windowScene.requestGeometryUpdate(preferences) { _ in }
        } else {
            UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
            UINavigationController.attemptRotationToDeviceOrientation()
        }
    }
}
