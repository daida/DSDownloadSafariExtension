//
//  ShareExtension.swift
//  DaidDsDownload
//
//  Created by Nicolas Bellon on 27/10/2016.
//  Copyright © 2016 Nicolas Bellon. All rights reserved.
//

import Foundation
import UIKit

class shareExtension: UIViewController {
    
    enum ShareExtensionError: Error {
        case WrongLocalURL
        case WrongMagnetLink
    }
    
    private let torrentFileUTI = "com.bittorrent.torrent"
    
    var alreadyAppear = false
    
    let webService = SynologyWebService()
    let fadeAnimationDuration = 0.35
    
    
    func performAppearAnimation(completionClosure: (() -> Void)? = nil) {
        completionClosure?()
    }
    
    func performDisappearAnimation(completionClosure: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            completionClosure?()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        guard self.alreadyAppear == false else { return }
    }
    
    func getTorrentLocalFileURL(completionClosure:@escaping (URL?) -> Void) {
        guard let extensionItem = self.extensionContext?.inputItems as? [NSExtensionItem] else {
            completionClosure(nil)
            return
        }
        
        guard let provider = (extensionItem.reduce([NSItemProvider]()) { inital, item in
            
            guard let providers = item.attachments as? [NSItemProvider] else { return inital }
            
            return providers.filter { $0.hasItemConformingToTypeIdentifier(self.torrentFileUTI) }
        }).last else {
            completionClosure(nil)
            return
        }
        
        provider.loadItem(forTypeIdentifier: self.torrentFileUTI, options: nil) { item, error in
            completionClosure(item as? URL)
        }
    }
    
    func getPlainTextURL(completionClosure:@escaping (String?) -> Void) {
        guard let extensionItem = self.extensionContext?.inputItems as? [NSExtensionItem] else {
            completionClosure(nil)
            return
        }
        
        guard let provider = (extensionItem.reduce([NSItemProvider]()) { inital, item in
            
            guard let providers = item.attachments as? [NSItemProvider] else { return inital }
            
            return providers.filter { $0.hasItemConformingToTypeIdentifier("public.plain-text") }
        }).last else {
            completionClosure(nil)
            return
        }
        
        provider.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { item, error in
            completionClosure(item as? String)
        }
    }

    
    
    func showDownloadResultMessage(downloadStatus: SynologyWebService.DownloadRequestStatus, completionClosure: (()-> Void)? = nil) {
        
        let message: String
        
        switch downloadStatus {
        case .loginError:
            message = "Loging Error"
        case .downloadError:
            message = Constants.Wording.downloadErrorText
        case .downloadSuccess:
            message = Constants.Wording.downloadOkText
        case .loginSuccess:
            return
        }
        
        let alert = UIAlertController(title:Constants.Wording.appNameText, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: Constants.Wording.okText, style: .default) { _ in completionClosure?() }
        
        alert.addAction(action)
        
        DispatchQueue.main.async { self.present(alert, animated: true) }
    }
    
    func startDownload(url: URL) {
        self.webService.startDownload(torrentFileURL: url) { status in
            self.showDownloadResultMessage(downloadStatus: status) {
                self.performDisappearAnimation() {
                    self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                }
            }
        }
    }
    
    func startDownload(magnetString: String) {
        
        guard let url = URL(string: magnetString) else {
            self.performDisappearAnimation() {
                self.extensionContext?.cancelRequest(withError: ShareExtensionError.WrongMagnetLink)
            }
            return
        }
        
        self.webService.startDownload(torrentURL: url)  { status in
            self.showDownloadResultMessage(downloadStatus: status) {
                self.performDisappearAnimation() {
                    self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                }
            }
        }
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard self.alreadyAppear == false else { return }
        
        self.getTorrentLocalFileURL { url in
            
            if let url = url {
                self.startDownload(url: url)
            }
            else {
                self.getPlainTextURL { str in
                    if let str = str {
                        self.startDownload(magnetString: str)
                    }
                    else {
                        self.performDisappearAnimation() {
                            self.extensionContext?.cancelRequest(withError: ShareExtensionError.WrongLocalURL)
                            
                        }
                    }
                }
            }
        }
        self.alreadyAppear = true
    }
}
