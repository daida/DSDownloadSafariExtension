//
//  CreateDownloadTorrentFileTaskOperation.swift
//  DaidDsDownload
//
//  Created by Nicolas Bellon on 20/10/2016.
//  Copyright © 2016 Nicolas Bellon. All rights reserved.
//

import Foundation

class CreateDownloadTorrentFileTaskOperation: Operation {
    
    enum CreateDownloadTaskStatus {
        case error(error: SynologyWebService.SynologyError)
        case success
    }
    
    typealias CreateDownloadTorrentFileCompletionClosure = (CreateDownloadTaskStatus) -> Void
    
    private let endOfStreamMarker = "905191404154484336597275426"
    
    private var _isExecuting: Bool = false
    private var _isAsynchronous: Bool = false
    

    private var dataTask: URLSessionDataTask?
    private let torrentFileName: String
    private let torrentData: Data
    private let serverURL: URL
    private let urlSession: URLSession
    private var sessionID: String?
    private let completionClosure: CreateDownloadTorrentFileCompletionClosure?
    
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

    private func data(WithParam param: [String: String], AndTorrentFile torrentFile: Data, torrentFileName:String) -> Data {
        
        let startBoundary:String   = "--\(endOfStreamMarker)"
        let endBoundary:String     = "--\(endOfStreamMarker)--"
        
        
        var body = ""
        
        for (key, value) in param {
            body.append("\(startBoundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        
        body.append("\(startBoundary)\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(torrentFileName)\"\r\n")
        body.append("Content-Type: application/x-bittorrent\r\n\r\n")
        
        var destData = body.data(using: String.Encoding.utf8)!
        
        destData.append(torrentFile)
        
        destData.append("\r\n\(endBoundary)\r\n".data(using: String.Encoding.utf8)!)
        
        return destData
    }
    
    init(serverURL: URL, torrentFileData: Data, torrentFileName: String, urlSession: URLSession, sessionID: String?, completionClosure: CreateDownloadTorrentFileCompletionClosure? = nil) {
        self.torrentFileName = torrentFileName
        self.torrentData = torrentFileData
        self.serverURL = serverURL
        self.urlSession = urlSession
        self.completionClosure = completionClosure
        self.sessionID = sessionID
        super.init()
        self.qualityOfService = .userInitiated
    }
    
    func startRequest(serverURL: URL, torrentFileData: Data, torrentFileName: String, urlSession: URLSession, sessionID: String, completionClosure: CreateDownloadTorrentFileCompletionClosure? = nil) {
        guard let createDownloadTaskURL = URL(string: "\(serverURL)/webapi/DownloadStation/task.cgi") else { fatalError("Wrong URL") }
        
        var createDownloadTaskRequest = URLRequest(url: createDownloadTaskURL)
        
        createDownloadTaskRequest.httpMethod = "POST"
        
        let dico =  [   "api"       :   "SYNO.DownloadStation.Task",
                        "version"   :   "1",
                        "method"    :   "create",
                        "_sid"       :   sessionID
                    ]
        
        
        let data = self.data(WithParam: dico, AndTorrentFile: torrentFileData, torrentFileName: torrentFileName)
        
        createDownloadTaskRequest.httpBody = data
        
        createDownloadTaskRequest.addValue("multipart/form-data; boundary=\(endOfStreamMarker)", forHTTPHeaderField: "Content-Type")
        
        createDownloadTaskRequest.addValue(data.count.description, forHTTPHeaderField: "Content-Length")
        
        createDownloadTaskRequest.httpShouldHandleCookies = false
        
        self.dataTask = urlSession.dataTask(with: createDownloadTaskRequest) { data, response, error in
            
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
        self.startRequest(serverURL: self.serverURL, torrentFileData: self.torrentData, torrentFileName: self.torrentFileName, urlSession: self.urlSession, sessionID: self.sessionID ?? "", completionClosure: self.completionClosure)
    }
    
    override func cancel() {
        super.cancel()
        self.isExecuting = false
        self.dataTask?.cancel()
    }

    
}
