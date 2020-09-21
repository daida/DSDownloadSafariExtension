//
//  AppRouter.swift
//  DaidDsDownload
//
//  Created by Nicolas Bellon on 21/10/2016.
//  Copyright © 2016 Nicolas Bellon. All rights reserved.
//

import Foundation
import UIKit

struct AppRouter {
    
    private func prepareNavigationController() -> UINavigationController {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        guard let loginViewController = storyBoard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController else { return UINavigationController() }
        
        let navigationController = UINavigationController(rootViewController: loginViewController)
        navigationController.setNavigationBarHidden(true, animated: false)
        
        if case SynologyWebService.LoggedStatus.logged(let user) = SynologyWebService.shared.loggedStatus {
            loginViewController.fillLoginForm(withUser: user)
        }
        
        return navigationController
    }
    
    func openAppRegular() -> UINavigationController {
        
        let navigationController = self.prepareNavigationController()
    
        let storyBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        if case SynologyWebService.LoggedStatus.logged(_) = SynologyWebService.shared.loggedStatus {
            let downloadController = storyBoard.instantiateViewController(withIdentifier: "DownloadViewController")
            navigationController.pushViewController(downloadController, animated: false)
        }
        
        return navigationController
    }
    
    func openApp(withTorrentfileUrl fileURL: URL) -> UINavigationController {
        let storyBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let navigationController = self.prepareNavigationController()
        
        
         if case SynologyWebService.LoggedStatus.logged(_) = SynologyWebService.shared.loggedStatus {
            
            guard let downloadController = storyBoard.instantiateViewController(withIdentifier: "DownloadViewController") as? DownloadViewController else { return navigationController }
            
            navigationController.pushViewController(downloadController, animated: false)
            downloadController.startDownload(withTorrentLocalURLFile: fileURL)
        }
        else if let LoginViewController = navigationController.viewControllers.first as? LoginViewController {
            LoginViewController.showLoginErrorWhenViewIsReady()
        }
        
        return navigationController
    }
    
}
