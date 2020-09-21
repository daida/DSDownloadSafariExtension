//
//  UserManager.swift
//  DaidDsDownload
//
//  Created by Nicolas Bellon on 23/10/2016.
//  Copyright © 2016 Nicolas Bellon. All rights reserved.
//

import Foundation

struct User {
    
    let serverURL: String
    let login: String
    let password: String
    
    init(serverURL: String, login: String, pass: String) {
        self.serverURL = serverURL
        self.login = login
        self.password = pass
    }
}

extension User {
    
    init?(fromKeychain keychain: KeychainSwift) {
        
        guard
            let url = keychain.get(UserManager.K.serveurURL),
            let login = keychain.get(UserManager.K.login),
            let pass = keychain.get(UserManager.K.password)
            else { return nil }
        
        self.serverURL = url
        self.password = pass
        self.login = login
    }
}

struct UserManager {
    
    enum ConnectionStatus {
        case connected(user: User, sessionID: String)
        case invalidateSession(user: User)
        case disconnected
        
        var sessionID: String? {
            if case .connected(_, let sessionID) = self {
                return sessionID
            }
            return nil
        }
        
    }
    
    var userConnectionStatus: ConnectionStatus {
        
        guard let user = User(fromKeychain: self.keychainManager) else { return .disconnected }
        guard let sessionID = self.keychainManager.get(K.sessionID) else { return .invalidateSession(user: user) }
        
        return .connected(user: user, sessionID: sessionID)
    }
    
    struct K {
        static let serveurURL: String = "kServerURL"
        static let login: String = "kLogin"
        static let password: String = "kPassword"
        static let sessionID: String = "kSessionID"
    }

    
    private let keychainManager: KeychainSwift = {
        let dest = KeychainSwift()
        
        guard let appGroupID = Bundle.main.infoDictionary?["APP_GROUP"] as? String else { fatalError("No App Group ID") }
        
        dest.accessGroup = appGroupID
        return dest
    }()
    
    
    func createUser(serverURL: String, login: String, password: String) -> Bool {
        
            guard   self.keychainManager.set(serverURL, forKey: K.serveurURL),
                    self.keychainManager.set(login,     forKey: K.login),
                    self.keychainManager.set(password,  forKey: K.password)
                else {
                print("Error Keychain")
                self.keychainManager.clear()
                return false
        }
        
        return true
    }
    
   @discardableResult func invalidSession() -> Bool {
        return self.keychainManager.delete(K.sessionID)
    }
    
    func update(sessionID: String) -> Bool {
        
        guard self.keychainManager.set(sessionID, forKey: K.sessionID) == true else {
            print("Error Keychain")
            self.invalidSession()
            return false
        }
        return true
    }
    
    func disconnectUser() {
        self.keychainManager.clear()
    }
}
