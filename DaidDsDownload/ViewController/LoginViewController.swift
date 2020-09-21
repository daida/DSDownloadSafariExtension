//
//  ViewController.swift
//  DaidDsDownload
//
//  Created by Nicolas Bellon on 18/10/2016.
//  Copyright © 2016 Nicolas Bellon. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var serverUrlTextField: UITextField!
    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var connectionSpinerView: UIActivityIndicatorView!
    @IBOutlet weak var titleLabel: UILabel!
    
    private var shouldShowLoginErrorMessage = false
    private var prefillUser: User? = nil
    
    func showLoginErrorWhenViewIsReady() {
        shouldShowLoginErrorMessage = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.connectButton.layer.cornerRadius = 8
        self.titleLabel.text = Constants.Wording.appNameText
        self.serverUrlTextField.placeholder = Constants.Wording.serverURLPlaceholderText
        self.loginTextField.placeholder = Constants.Wording.loginPlaceholderText
        self.passwordTextField.placeholder = Constants.Wording.passwordPlaceholderText
    
        self.connectButton.setTitle(Constants.Wording.connectButtonText, for: .normal)
        
        self.serverUrlTextField.delegate = self
        self.loginTextField.delegate = self
        self.passwordTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.shouldShowLoginErrorMessage == true {
            self.showLoginResult(status: SynologyWebService.LoginStatus.loginError)
            self.shouldShowLoginErrorMessage = false
        }
        
        if let prefillUser = self.prefillUser {
            self.loginTextField.text = prefillUser.login
            self.passwordTextField.text = prefillUser.password
            self.serverUrlTextField.text = prefillUser.serverURL
            self.prefillUser = nil
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func fillLoginForm(withUser user: User) {
        self.prefillUser = user
    }
    
    func showLoginResult(status: SynologyWebService.LoginStatus, completion: (() -> Void)? = nil){
        
        let message:String
        
        switch status {
        case .loginSuccess:
            message = Constants.Wording.loginOKText
        case .loginError:
            message = Constants.Wording.loginErrorText
        case .keychainSaveError:
            message = Constants.Wording.loginErrorSaveCredentialText
        case .wrongCredentialsFormat:
            message = Constants.Wording.loginErrorInvalidInput
        }
        
        let alert = UIAlertController(title: Constants.Wording.appNameText, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: Constants.Wording.okText, style: .default) { _ in completion?() }
        
        alert.addAction(action)
        
        self.present(alert, animated: true)
        
    }
    
    func login(serverURL: String, login: String, password: String) {
        self.connectionSpinerView.isHidden = false
        self.connectionSpinerView.startAnimating()
        SynologyWebService.shared.login(serverURL: serverURL, login: login, password: password) { status in
        
            DispatchQueue.main.async {
                self.connectionSpinerView.stopAnimating()
                self.connectionSpinerView.isHidden = true
                self.showLoginResult(status: status) {
                    
                    DispatchQueue.main.async {
                        if case .loginSuccess = status {
                            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                            let downloadController = storyboard.instantiateViewController(withIdentifier: "DownloadViewController")
                            self.navigationController?.pushViewController(downloadController, animated: true)
                        }
                    }
                }
            }
        }
    }
    
    func login() {
        
        self.loginTextField.resignFirstResponder()
        self.passwordTextField.resignFirstResponder()
        self.serverUrlTextField.resignFirstResponder()
        
        guard let serverURL = self.serverUrlTextField.text, let login = self.loginTextField.text, let password = self.passwordTextField.text else {
            self.showLoginResult(status: .wrongCredentialsFormat)
            return
        }
        
        self.login(serverURL: serverURL, login: login, password: password)
    }
    
    @IBAction func connectButtonDidTouch(_ sender: AnyObject) {
        self.login()
        }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.serverUrlTextField {
            self.loginTextField.becomeFirstResponder()
        }
        else if textField == self.loginTextField {
            self.passwordTextField.becomeFirstResponder()
        }
        else {
            self.login()
        }
        return true
    }
}

