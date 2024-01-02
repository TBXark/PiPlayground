//
//  AppDelegate.swift
//  PiPlayground
//
//  Created by tbxark on 12/28/23.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = UIColor.systemBackground
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()
        return true
    }
}

