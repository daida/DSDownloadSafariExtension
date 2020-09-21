//
//  TaskModel.swift
//  DaidDsDownload
//
//  Created by Nicolas Bellon on 08/11/2016.
//  Copyright © 2016 Nicolas Bellon. All rights reserved.
//

import Foundation

struct TaskModel {
    
    enum Status {
        case waiting
        case downloading(progress: Double)
        case paused
        case finishing
        case finished
        case hash_checking
        case seeding
        case filehosting_waiting
        case extracting
        case error
        
        init?(stringRepresentation: String, progress: Double? = nil) {
            
            switch stringRepresentation.lowercased() {
            case "downloading":
                if let progress = progress {
                    self = .downloading(progress: progress)
                }
                else {
                    return nil
                }
            case "finished":  self = .finished
            case "paused": self = .paused
            case "waiting": self = .waiting
            case "finishing": self = .finishing
            case "hash_checking": self = .hash_checking
            case "seeding": self = .seeding
            case "filehosting_waiting": self = .filehosting_waiting
            case "extracting": self = .extracting
            case "error" : self = .error
                
            default:
                return nil
            }
        }
        
    }
    
    let taskID: String
    let status: Status
    let size: Int
    let title: String
    let createTime: Date
}


extension TaskModel {

    private static func parseSizeDownloaded(fileArrayDico: Array<[AnyHashable: Any]>) -> Double {
        
        var accumulator:Double = 0
        
        for dico in fileArrayDico {
            if let size_downloaded = dico["size_downloaded"] as? Double {
                accumulator = accumulator + size_downloaded
            }
        }
        return accumulator
    }
    
    init?(dico: [String: Any]) {
        
        
        guard
            let taskID = dico["id"] as? String,
            let size = dico["size"] as? Double,
            let title = dico["title"] as? String,
            let statusStr = dico["status"] as? String,
            let additional = dico["additional"] as? [AnyHashable: Any],
            let detail = additional["detail"] as? [AnyHashable: Any],
            let createdDateTimeInterval = detail["create_time"] as? TimeInterval else { return nil }
        
        if let fileArray = additional["file"] as? Array<[AnyHashable: Any]> {
            let sizeDownloaded = TaskModel.parseSizeDownloaded(fileArrayDico: fileArray)
            guard let status = Status(stringRepresentation: statusStr, progress: sizeDownloaded / size) else { return nil }
            self.status = status
        }
        else {
            guard let status = Status(stringRepresentation: statusStr) else { return nil }
            self.status = status
        }
        
        self.createTime = Date(timeIntervalSince1970: createdDateTimeInterval)
        self.taskID = taskID
        self.size = Int(size)
        self.title = title
    }
}
