//
//  SynologyWebService.swift
//  DaidDsDownload
//
//  Created by Nicolas Bellon on 18/10/2016.
//  Copyright © 2016 Nicolas Bellon. All rights reserved.
//

import Foundation
import UIKit

struct SynologyWebService {

    private let opperationQueue = OperationQueue()
    private let keychainManager = KeychainSwift()
    
    struct K {
        static let serveurURL: String = "kServerURL"
        static let login:      String = "kLogin"
        static let password:   String = "kPassword"
        static let sessionID:  String = "kSessionID"
    }
    
    enum DownloadRequestStatus {
        case loginSuccess
        case loginError
        
        case downloadSuccess
        case downloadError
    }
    
    enum LoginStatus {
        case loginSuccess
        case loginError
        case wrongCredentialsFormat
        case keychainSaveError
    }
    
    enum LogoutStatus {
        case logoutSuccess
        case logoutError
        case alreadyLogout
    }
    
    enum SynologyError: Error {
        case Error(code: Int)
        case UnknowError(networkError: Error?)
    }
    
    enum LoggedStatus {
        case logged(User)
        case notLogged
    }
    
    enum FetchTaskListStatus {
        case fetchSuccess(taskList: [TaskModel])
        case loginSuccess
        case loginError
        case fetchTaskListError
    }
    
    typealias DownloadRequestCallBack = (DownloadRequestStatus) -> Void
    typealias LoginCallBack = (LoginStatus) -> Void
    typealias LogoutCallBack = (LogoutStatus) -> Void
    
    typealias FetchTaskListCallBack = (FetchTaskListStatus) -> Void
    
    static let shared = SynologyWebService()
    private let userManager = UserManager()
    
    private let session: URLSession = {
        var config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        let session = URLSession(configuration: config)
        return session
    }()
    

    var loggedStatus:LoggedStatus {
        switch self.userManager.userConnectionStatus {
        case .connected(user: let user, sessionID: _):
            return .logged(user)
        case .invalidateSession(user: let user):
            return .logged(user)
        case .disconnected:
            return .notLogged
        }
    }
    
    func login(serverURL: String, login: String, password: String, callback: LoginCallBack? = nil) {
        
        guard let url = URL(string: serverURL), login.count > 0, password.count > 0 else {
            callback?(.wrongCredentialsFormat)
            return
        }
        
        let loginOperation = LoginOperation(serveurURL: url, login: login, password: password, urlSession:self.session) { status in
            switch status {
            case .success(sessionID: let sessionID):
                if self.userManager.createUser(serverURL: serverURL, login: login, password: password) && self.userManager.update(sessionID: sessionID) {
                    print("Login OK credentials saved SessionID-> \(sessionID)")
                    callback?(.loginSuccess)
                }
                else {
                    print("Login OK but CREDENTIALS SAVING FAIL!! SessionID-> \(sessionID)")
                    callback?(.keychainSaveError)
                }
            case .error(error: let error) :
                self.userManager.disconnectUser()
                print("Login Error \(error) credentials NOT saved")
                callback?(.loginError)
            }
        }
        
        self.opperationQueue.addOperation(loginOperation)
    }
    
    func fetchTaskList(callback: FetchTaskListCallBack? = nil) {
        guard let urlString = self.keychainManager.get(K.serveurURL), let url = URL(string: urlString), let login = self.keychainManager.get(K.login), let password = self.keychainManager.get(K.password) else {
            print("Wrong credentials !!")
            callback?(.loginError)
            return
        }
        
        let loginClosure = { (status: LoginOperation.Status) in
            switch status {
            case .success(let sid) :
                if self.userManager.update(sessionID: sid) == true {
                    print("login OK!! session ID-> \(sid)")
                    callback?(.loginSuccess)
                }
                else {
                    print("login OK but SESSION ID SAVING FAIL!! -> \(sid)")
                    callback?(.loginError)
                }
            case .error(let error):
                print("login failed error-> \(error)")
                callback?(.loginError)
            }
        }
    

        let taskListClosure = { (status: TaskListOperation.TaskListStatus) in
        
            switch status {
            case .success(let taskList):
                print("FetchTaskList OK")
                callback?(FetchTaskListStatus.fetchSuccess(taskList: taskList))
            case .error(let error):
                switch error {
                case .Error(code: let code) where code == 106 || code == 107 || code == 105:
                    print("invalid Session ID, start login process")
                    self.userManager.invalidSession()
                    self.fetchTaskList(callback: callback)
                default:
                    print("FetchTaskList failed error-> \(error)")
                    callback?(.fetchTaskListError)
                }
            }
            
        }
        
        let taskListOperation = TaskListOperation(serverURL: url, urlSession: self.session, sessionID: self.userManager.userConnectionStatus.sessionID, completionClosure:taskListClosure)
        
        if case .invalidateSession = self.userManager.userConnectionStatus {
            let loginOperation = LoginOperation(serveurURL: url, login: login, password: password, urlSession: self.session, completionClosure: loginClosure)
            self.opperationQueue.addOperation(loginOperation)
            taskListOperation.addDependency(loginOperation)
        }
        
        self.opperationQueue.addOperation(taskListOperation)
    }
    
    func logout(callback: LogoutCallBack? = nil) {
        guard let urlString = self.keychainManager.get(K.serveurURL), let url = URL(string: urlString), let session = self.userManager.userConnectionStatus.sessionID else {
            callback?(.alreadyLogout)
            return
        }
        
        let logoutOperation = LogoutOperation(serverURL: url, urlSession: self.session, sessionID: session) { status in
            self.userManager.disconnectUser()
            switch status {
            case .success:
                print("Logout success")
                callback?(.logoutSuccess)
            
            case .error(error: _):
                print("Logout error")
                callback?(.logoutError)
            }
        }
        
        self.opperationQueue.addOperation(logoutOperation)
    }
    
    func startDownload(torrentURL: URL, callback: DownloadRequestCallBack? = nil) {
        
        guard let urlString = self.keychainManager.get(K.serveurURL), let url = URL(string: urlString), let login = self.keychainManager.get(K.login), let password = self.keychainManager.get(K.password) else {
            print("Wrong credentials !!")
            callback?(.loginError)
            return
        }
        
        let loginClosure = { (status: LoginOperation.Status) in
            switch status {
            case .success(let sid) :
                if self.userManager.update(sessionID: sid) == true {
                    print("login OK!! session ID-> \(sid)")
                    callback?(.loginSuccess)
                }
                else {
                    print("login OK but SESSION ID SAVING FAIL!! -> \(sid)")
                    callback?(.loginError)
                }
            case .error(let error):
                print("login failed error-> \(error)")
                callback?(.loginError)
            }
        }
        
        let downloadClosure = { (status: CreateDownloadTorrentURLTaskOperation.CreateDownloadTaskStatus) in
            switch status {
            case .success:
                print("Download OK")
                callback?(.downloadSuccess)
            case .error(let error):
                switch error {
                case .Error(code: let code) where code == 106 || code == 107 || code == 105:
                    print("invalid Session ID, start login process")
                    self.userManager.invalidSession()
                    self.startDownload(torrentURL: torrentURL, callback: callback)
                default:
                    print("Download failed error-> \(error)")
                    callback?(.downloadError)
                }
            }
        }
        
        let downloadTask = CreateDownloadTorrentURLTaskOperation(serverURL: url, torrentLinkURL: torrentURL, sessionID: self.userManager.userConnectionStatus.sessionID, urlSession: self.session, completionClosure: downloadClosure)
        
        if case .invalidateSession = self.userManager.userConnectionStatus  {
            let loginOpp = LoginOperation(serveurURL: url, login: login, password: password, urlSession: self.session, completionClosure: loginClosure)
            downloadTask.addDependency(loginOpp)
            self.opperationQueue.addOperation(loginOpp)
        }
        
        self.opperationQueue.addOperation(downloadTask)
        self.opperationQueue.maxConcurrentOperationCount = 1
    }
    
    func startDownload(torrentFileURL: URL, callback: DownloadRequestCallBack? = nil) {
        
        guard let urlString = self.keychainManager.get(K.serveurURL), let url = URL(string: urlString), let login = self.keychainManager.get(K.login), let password = self.keychainManager.get(K.password) else {
            print("Wrong credentials !!")
            callback?(.loginError)
            return
        }
        
        let loginClosure = { (status: LoginOperation.Status) in
            switch status {
            case .success(let sid) :
                if self.userManager.update(sessionID: sid) == true {
                    print("login OK!! session ID-> \(sid)")
                    callback?(.loginSuccess)
                }
                else {
                    print("login OK but SESSION ID SAVING FAIL!! -> \(sid)")
                    callback?(.loginError)
                }
            case .error(let error):
                print("login failed error-> \(error)")
                callback?(.loginError)
            }
        }
        
        let downloadClosure = { (status: CreateDownloadTorrentFileTaskOperation.CreateDownloadTaskStatus) in
            switch status {
            case .success:
                print("Download OK")
                callback?(.downloadSuccess)
            case .error(let error):
                switch error {
                case .Error(code: let code) where code == 106 || code == 107 || code == 105:
                        print("invalid Session ID, start login process")
                        self.userManager.invalidSession()
                        self.startDownload(torrentFileURL: torrentFileURL, callback: callback)
                default:
                    print("Download failed error-> \(error)")
                    callback?(.downloadError)
                }
            }
        }
        
        
        guard let torrentData = try? Data(contentsOf: torrentFileURL) else {
            callback?(.downloadError)
            return
        }

        let torrentFileName = torrentFileURL.lastPathComponent
        
        let downloadTorrentFile = CreateDownloadTorrentFileTaskOperation(serverURL: url,
                                                                         torrentFileData: torrentData,
                                                                         torrentFileName: torrentFileName,
                                                                         urlSession: self.session,
                                                                         sessionID: self.userManager.userConnectionStatus.sessionID,
                                                                         completionClosure: downloadClosure)
        
        if case .invalidateSession = self.userManager.userConnectionStatus  {
            let loginOpp = LoginOperation(serveurURL: url, login: login, password: password, urlSession: self.session, completionClosure: loginClosure)
            downloadTorrentFile.addDependency(loginOpp)
            self.opperationQueue.addOperation(loginOpp)
        }
        
        self.opperationQueue.addOperation(downloadTorrentFile)
        self.opperationQueue.maxConcurrentOperationCount = 1
    }
}
