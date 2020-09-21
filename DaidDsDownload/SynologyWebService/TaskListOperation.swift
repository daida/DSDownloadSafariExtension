//
//  TaskListOperation.swift
//  DaidDsDownload
//
//  Created by Nicolas Bellon on 20/10/2016.
//  Copyright © 2016 Nicolas Bellon. All rights reserved.
//

import Foundation

class TaskListOperation: Operation {
    
    enum TaskListStatus {
        case success([TaskModel])
        case error(error: SynologyWebService.SynologyError)
    }
    
    typealias TaskListCompletionClosure = (TaskListStatus) -> Void
    
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
    
    let serverURL: URL
    let urlSession: URLSession
    var sessionID: String?
    let completionClosure: TaskListCompletionClosure?
    
    func parseTaskArray(taskArray: Array<[String: Any]>) -> [TaskModel] {
        var dest = [TaskModel]()
        
        for dico in taskArray {
            if let task = TaskModel(dico: dico) {
                dest.append(task)
            }
        }
        return dest
    }
    
    func startRequest(serverURL: URL, urlSession: URLSession, sessionID: String, completionClosure: TaskListCompletionClosure? = nil) {
        
        let urlStr = "\(serverURL)/webapi/DownloadStation/task.cgi?api=SYNO.DownloadStation.Task&version=1&method=list&additional=detail,file&_sid=\(sessionID)"
        
        guard let url = URL(string:urlStr) else { fatalError() }
        
        var request = URLRequest(url: url)
        
        request.httpShouldHandleCookies = false
        
        self.dataTask = urlSession.dataTask(with: request) {  data,  response,  error in
            
            if  let data = data,
                let dico = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String : AnyObject],
                let success = dico["success"] as? Bool {
                
                if success == true {
                    
                    guard
                        let data = dico["data"] as? [String : AnyObject],
                        let tasks = data["tasks"] as? Array<[String: Any]> else { completionClosure?(.error(error: SynologyWebService.SynologyError.UnknowError(networkError: error))); return }
                    
                    completionClosure?(TaskListStatus.success(self.parseTaskArray(taskArray: tasks)))
                    
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
        self.dataTask?.resume()
    }
    
    init(serverURL: URL, urlSession: URLSession, sessionID: String?, completionClosure: TaskListCompletionClosure? = nil) {
    
        self.serverURL = serverURL
        self.urlSession = urlSession
        self.sessionID = sessionID
        self.completionClosure = completionClosure
        
        super.init()
        
        self.qualityOfService = .userInitiated
    }
    
    override func start() {
        super.start()
        self._isExecuting = true
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
        self.startRequest(serverURL: self.serverURL, urlSession: self.urlSession, sessionID: self.sessionID ?? "", completionClosure: completionClosure)
    }
}
