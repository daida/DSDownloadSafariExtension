//
//  LoginOperation.swift
//  DaidDsDownload
//
//  Created by Nicolas Bellon on 18/10/2016.
//  Copyright © 2016 Nicolas Bellon. All rights reserved.
//

import Foundation

class LoginOperation: Operation {
    
    enum Status {
        case error(error: SynologyWebService.SynologyError)
        case success(sessionID: String)
    }
    
    typealias CompletionClosure = (Status) -> Void
    
    private var dataTask:URLSessionDataTask?
    
    var sessionID: String?
    
    private var _isExecuting: Bool = false
    override var isExecuting: Bool {
        get {
            return _isExecuting
        }
        set {
            if _isExecuting != newValue {
                willChangeValue(forKey: "isExecuting")
                _isExecuting = newValue
                didChangeValue(forKey: "isExecuting")
            }
        }
    }
    
    private var _isFinished: Bool = false
    override var isFinished: Bool {
        get {
            return _isFinished
        }
        set {
            if _isFinished != newValue {
                willChangeValue(forKey: "isFinished")
                _isFinished = newValue
                didChangeValue(forKey: "isFinished")
            }
        }
    }
    
    override var isAsynchronous:Bool {
        return true
    }
    
    init(serveurURL: URL, login: String, password: String, urlSession: URLSession, completionClosure: CompletionClosure? = nil) {
        super.init()
        
        self.qualityOfService = .userInitiated
        guard let loginURL = URL(string: "\(serveurURL)/webapi/auth.cgi?api=SYNO.API.Auth&version=2&method=login&account=\(login)&passwd=\(password)&session=DownloadStation&format=sid") else { fatalError("Wrong URL") }
        
        var request = URLRequest(url: loginURL)
        
        request.httpShouldHandleCookies = false
        
        self.dataTask = urlSession.dataTask(with: request) { data, response, error in
            if
                let data = data,
                let dico = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject],
              let success = dico["success"] as? Bool,
              let sessionID = dico["data"]?["sid"] as? String, success == true {
                self.sessionID = sessionID
                completionClosure?(.success(sessionID: sessionID))
            }
            else {
                
                if  let data = data,
                    let dico = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject],
                  let code = dico["error"]?["code"] as? Int {
                    completionClosure?(.error(error: .Error(code: code)))
                }
                else {
                    completionClosure?(.error(error: .UnknowError(networkError: error)))
                }
                self.cancel()
            }
            self.isFinished = true
        }
    }
    
    override func start() {
        super.start()
        self.isExecuting = true
        self.dataTask?.resume()
    }
    
    override func cancel() {
        super.cancel()
        self.isExecuting = false
        dataTask?.cancel()
    }
}
