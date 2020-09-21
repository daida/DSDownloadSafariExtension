//
//  DownloadViewController.swift
//  DaidDsDownload
//
//  Created by Nicolas Bellon on 21/10/2016.
//  Copyright © 2016 Nicolas Bellon. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import SafariServices

class DownloadViewController: UIViewController {
    
    @IBOutlet weak var openDSGetButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var subtitleLabel: UILabel!

    func showStartMagnetTorrent(magnet: URL) {
        
        let alertMessage = "\(Constants.Wording.startMagnetTorrentText) \(magnet) ?"
        
        let alertViewController = UIAlertController(title: Constants.Wording.appNameText, message: alertMessage, preferredStyle: .alert)
      let alertActionStartDownload = UIAlertAction(title: Constants.Wording.yesText, style: UIAlertAction.Style.default) { _ in
        
            SynologyWebService.shared.startDownload(torrentURL: magnet) { [weak self] status in
                self?.showDownloadResultMessage(downloadStatus: status)
            }
            
        }
      
      let alertActionDissmiss = UIAlertAction(title: Constants.Wording.noText, style: UIAlertAction.Style.cancel)
        
        
        alertViewController.addAction(alertActionStartDownload)
        alertViewController.addAction(alertActionDissmiss)
        
        self.present(alertViewController, animated: true, completion: nil)
    }
    
    @objc func checkPasteboard() {
         guard
         let torrentMagnet = UIPasteboard.general.string,
         let torrentURL = URL(string: torrentMagnet),
         torrentMagnet.contains("magnet:") == true else { return }
        
         self.showStartMagnetTorrent(magnet: torrentURL)
    }

    override func viewDidLoad() {

        super.viewDidLoad()
        self.openDSGetButton.layer.cornerRadius = 8
        self.disconnectButton.layer.cornerRadius = 8
        
        self.titleLabel.text = Constants.Wording.appNameText
        self.subtitleLabel.text = Constants.Wording.subtitleText
        self.disconnectButton.setTitle(Constants.Wording.disconnectButtonText, for: .normal)
        
      NotificationCenter.default.addObserver(self, selector: #selector(checkPasteboard), name: UIApplication.didBecomeActiveNotification, object: nil)
        self.checkPasteboard()
        
        SynologyWebService.shared.fetchTaskList { status in
            
            switch status {
            case .fetchSuccess(taskList: let task): print("fetchSuccess: \(task)")
            case .fetchTaskListError: print("fetchTaskListError")
            case .loginError: print("loginError")
            case .loginSuccess: print("loginSuccess")
            }
            
        }
    }
    
    
    @IBAction func openDSGetButtonDidTouch(_ sender: AnyObject) {

        if UIApplication.shared.canOpenURL(URL(string:"synodownload://")!) == false {
            UIApplication.shared.open(URL(string:"https://itunes.apple.com/us/app/ds-get/id540948028?mt=8")!)
        }
        else {
            UIApplication.shared.open(URL(string:"synodownload://")!)
        }
    }
    
    func showLogoutMessage() {
        let alert = UIAlertController(title: Constants.Wording.appNameText, message: Constants.Wording.logoutText, preferredStyle: .alert)
      let actionLogout = UIAlertAction(title: Constants.Wording.yesText, style: UIAlertAction.Style.destructive) { _ in
        
            SynologyWebService.shared.logout { _ in
            
                DispatchQueue.main.async {
                  let _ = self.navigationController?.popViewController(animated: true)
                }
            }
        }
        
      let actionDissmiss = UIAlertAction(title: Constants.Wording.noText, style: UIAlertAction.Style.cancel)
        
        alert.addAction(actionLogout)
        alert.addAction(actionDissmiss)
    
        self.present(alert, animated: true, completion: nil)
    }
    
    func showDownloadResultMessage(downloadStatus: SynologyWebService.DownloadRequestStatus, completionClosure: (()-> Void)? = nil) {
        
        let message: String
        
        switch downloadStatus {
        case .downloadError, .loginError:
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
    
    func startDownload(withTorrentLocalURLFile url: URL) {
    
        SynologyWebService.shared.startDownload(torrentFileURL: url) { status in
            
            self.showDownloadResultMessage(downloadStatus: status)
        }
    }
        
    @IBAction func disconnectDidTouch(_ sender: AnyObject) {
        self.showLogoutMessage()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}
