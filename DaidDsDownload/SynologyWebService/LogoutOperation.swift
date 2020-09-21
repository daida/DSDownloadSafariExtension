//
//  LogoutOperation.swift
//  DaidDsDownload
//
//  Created by Nicolas Bellon on 20/10/2016.
//  Copyright © 2016 Nicolas Bellon. All rights reserved.
//

import Foundation

class LogoutOperation: Operation {
    
    enum LogoutSuccessStatus {
        case success
        case error(error: SynologyWebService.SynologyError)
    }

    typealias LogoutCompletionClosure = (LogoutSuccessStatus) -> Void
    
    var dataTask: URLSessionDataTask?
    
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
    
    init(serverURL: URL, urlSession: URLSession, sessionID: String, completionClosure: LogoutCompletionClosure? = nil) {
        let urlStr = "\(serverURL)/webapi/auth.cgi?api=SYNO.API.Auth&version=1&method=logout&session=DownloadStation&_sid=\(sessionID)"
        
        super.init()
        
        guard let url = URL(string:urlStr) else { fatalError() }
        
        var request = URLRequest(url: url)
        
        request.httpShouldHandleCookies = false
        
        self.dataTask = urlSession.dataTask(with: request) {  data,  response,  error in
            
            if  let data = data,
                let dico = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String : AnyObject],
                let success = dico["success"] as? Bool {
                
                if success == true {
                    completionClosure?(LogoutSuccessStatus.success)
                }
                else if let errorCode = dico["error"]?["code"] as? Int {
                    completionClosure?(.error(error: SynologyWebService.SynologyError.Error(code: errorCode)))
                 }
                else {
                    completionClosure?(.error(error: SynologyWebService.SynologyError.UnknowError(networkError: error)))
                }
            }
            else {
                completionClosure?(.error(error: SynologyWebService.SynologyError.UnknowError(networkError: error)))
            }

            self.isFinished = true
            self.isExecuting = false
        }
        self.qualityOfService = .userInitiated
    }
    
    override func start() {
        super.start()
        self._isExecuting = true
        self.dataTask?.resume()
    }
}
