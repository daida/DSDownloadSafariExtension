//
//  CreateDownloadTorrentURLTaskOperation.swift
//  DaidDsDownload
//
//  Created by Nicolas Bellon on 20/10/2016.
//  Copyright © 2016 Nicolas Bellon. All rights reserved.
//

import Foundation

class CreateDownloadTorrentURLTaskOperation: Operation {
    
    enum CreateDownloadTaskStatus {
        case error(error: SynologyWebService.SynologyError)
        case success
    }
    
    typealias CreateDownloadTorrentURLCompletionClosure = (CreateDownloadTaskStatus) -> Void
    private var _isExecuting: Bool = false
    private var _isAsynchronous: Bool = false
    

    private var dataTask: URLSessionDataTask?
    private let torrentLinkURL: URL
    private let serverURL: URL
    private let urlSession: URLSession
    private var sessionID: String?
    private let completionClosure: CreateDownloadTorrentURLCompletionClosure?
    
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
    
    override var isAsynchronous: Bool {
        return true
    }

    private var _isFinished: Bool = false;
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

    init(serverURL: URL, torrentLinkURL: URL, sessionID: String?, urlSession: URLSession, completionClosure: CreateDownloadTorrentURLCompletionClosure? = nil) {
        self.serverURL = serverURL
        self.torrentLinkURL = torrentLinkURL
        self.sessionID = sessionID
        self.completionClosure = completionClosure
        self.urlSession = urlSession
        super.init()
    }
    
    func startRequest(serverURL: URL, torrentLinkURL: URL, sessionID: String, urlSession:URLSession, completionClosure: CreateDownloadTorrentURLCompletionClosure? = nil) {
        
        guard let downloadURL = URL(string: "\(serverURL)/webapi/DownloadStation/task.cgi?api=SYNO.DownloadStation.Task&version=1&method=create&uri=\(torrentLinkURL)&_sid=\(sessionID)") else { fatalError("Wrong URL") }
        
        var urlRequest = URLRequest(url: downloadURL)
        
        urlRequest.httpShouldHandleCookies = false
        
        self.dataTask = urlSession.dataTask(with: urlRequest) { data, response, error in
            if let data = data,
                let dico = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject],
              let success = dico["success"] as? Bool, success == true {
                completionClosure?(.success)
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
            }
            
            self.isExecuting = false
            self.isFinished = true
        }
        
        self.dataTask?.resume()
    }
    
    override func start() {
        super.start()
        
        if let dependecieOperation = self.dependencies.last as? LoginOperation {
            
            guard
                let sessionID = dependecieOperation.sessionID,
                dependecieOperation.isCancelled == false else {
                self.isExecuting = false
                self._isFinished = true
                return
            }
            
            self.sessionID = sessionID
        }
        
        self.isExecuting = true
        self.startRequest(serverURL: self.serverURL, torrentLinkURL: self.torrentLinkURL, sessionID: self.sessionID ?? "", urlSession: self.urlSession, completionClosure: self.completionClosure)
    }
    
    override func cancel() {
        super.cancel()
        self.isExecuting = false
        self.dataTask?.cancel()
    }

    
}
