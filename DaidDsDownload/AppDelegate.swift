//
//  AppDelegate.swift
//  DaidDsDownload
//
//  Created by Nicolas Bellon on 18/10/2016.
//  Copyright © 2016 Nicolas Bellon. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = AppRouter().openAppRegular()
        
        self.window?.makeKeyAndVisible()
        return true
    }
    
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        self.window?.rootViewController = AppRouter().openApp(withTorrentfileUrl: url)
        return true
    }
    
}

