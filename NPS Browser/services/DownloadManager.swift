//
//  DownloadManager.swift
//  NPS Browser
//
//  Created by JK3Y on 5/18/18.
//  Copyright © 2018 JK3Y. All rights reserved.
//

import Cocoa
import Queuer
import Alamofire

class DownloadManager {
    
    var downloadItems: [DLItem] = []
    let queue = Queuer(name: "DLQueue", maxConcurrentOperationCount: 3, qualityOfService: .default)
    
    init() {}
    
    func addToDownloadQueue(data: DLItem) {
        // create destination for file
        let destination: DownloadRequest.DownloadFileDestination = { _, response in
            // .pkg filename
            let pathComponent = response.suggestedFilename!
            let downloadSettings = SettingsManager().getDownloads()
            var path: URL = downloadSettings.download_location
            path.appendPathComponent(pathComponent)
            return (path, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        // store request in same object so we can cancel/pause/resume it later
        let request = Alamofire.download(data.url!, to: destination)
        data.setRequest(request)
        
        // add object to downloadItems array
        downloadItems.insert(data, at: 0)
        
        let downloadItemsIndex = downloadItems.index(of: data)!
        
        // get object back out of downloadItems array so the async operation can use it and update the properties as it runs
        let dlItem = self.downloadItems[downloadItemsIndex]
        
        let dlFileOperation = ConcurrentOperation {
            request.downloadProgress { progress in
                dlItem.status = "Downloading..."
                dlItem.progress = (progress.fractionCompleted * 100).rounded()
                dlItem.timeRemaining = progress.fractionCompleted
            }
            .responseData { response in
                response.result.ifSuccess {

                    dlItem.destinationURL = response.destinationURL

                    ExtractionManager(item: dlItem, downloadManager: self).start()
                }
                response.result.ifFailure {
                    guard let resumeData = response.resumeData else {
                        dlItem.status = "Failed! \(response.error.debugDescription)"
                        dlItem.isCancelable = false
                        return
                    }
                    dlItem.status = "Download Cancelled"
                    dlItem.isResumable = true
                }
            }
        }
        self.queue.addOperation(dlFileOperation)
    }

    func removeCompleted() {
        for item in downloadItems {
            if (item.isRemovable) {
                moveToCompleted(item: item)
            }
        }
    }
    
    func moveToCompleted(item: DLItem) {
        downloadItems.remove(at: downloadItems.index(of: item)!)
        downloadItems.insert(item, at: downloadItems.endIndex)
    }
    
    func getObjectQueue() -> [DLItem] {
        return self.downloadItems
    }
}