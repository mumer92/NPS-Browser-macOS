//
//  CoreDataIO.swift
//  NPS Browser
//
//  Created by JK3Y on 5/5/18.
//  Copyright © 2018 JK3Y. All rights reserved.
//

import Cocoa
import CoreData

class CoreDataIO: NSObject {
    
    let delegate = NSApplication.shared.delegate as! AppDelegate
    let windowDelegate: WindowDelegate = Helpers().getWindowDelegate()

    var context: NSManagedObjectContext
    var type: String
    var region: String
    
    override init(){
        self.context    = delegate.persistentContainer.viewContext
        self.type       = windowDelegate.getType()
        self.region     = windowDelegate.getRegion()
        super.init()
    }
    
    func getContext() -> NSManagedObjectContext {
        return self.context
    }
    
    func getEntity(entityName: String) -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: entityName, in: self.context)!
    }
    
    func getEntity() -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: self.type, in: self.context)!
    }
    
    func getObject(entity: NSEntityDescription) -> NSManagedObject {
        return NSManagedObject(
            entity: entity,
            insertInto: self.context
        )
    }
    
    func getObject() -> NSManagedObject {
        return NSManagedObject(
            entity: getEntity(),
            insertInto: self.context
        )
    }
    
    func storeValues(array: [NPSBase]) {
        
        for item in array {
            let nps = getObject()

            nps.setValue(item.title_id, forKey: "title_id")
            nps.setValue(item.region, forKey: "region")
            nps.setValue(item.name, forKey: "name")
            nps.setValue(item.pkg_direct_link, forKey: "pkg_direct_link")
            nps.setValue(item.last_modification_date, forKey: "last_modification_date")
            nps.setValue(item.file_size, forKey: "file_size")
            nps.setValue(item.sha256, forKey: "sha256")
            
            switch(self.type) {
            case "PSVGames":
                let obj = item as! PSVGame
                nps.setValue(obj.content_id, forKey: "content_id")
                nps.setValue(obj.original_name, forKey: "original_name")
                nps.setValue(obj.required_fw, forKey: "required_fw")
                nps.setValue(obj.zrif, forKey: "zrif")
                break
            case "PSVUpdates":
                let obj = item as! PSVUpdate
                nps.setValue(obj.update_version, forKey: "update_version")
                nps.setValue(obj.fw_version, forKey: "fw_version")
                nps.setValue(obj.nonpdrm_mirror, forKey: "nonpdrm_mirror")
                break
            case "PSVDLCs":
                let obj = item as! PSVDLC
                nps.setValue(obj.content_id, forKey: "content_id")
                nps.setValue(obj.zrif, forKey: "zrif")
                break
            case "PSPGames":
                let obj = item as! PSPGame
                nps.setValue(obj.content_id, forKey: "content_id")
                nps.setValue(obj.rap, forKey: "rap")
                nps.setValue(obj.download_rap_file, forKey: "download_rap_file")
                break
            case "PSXGames":
                let obj = item as! PSXGame
                nps.setValue(obj.content_id, forKey: "content_id")
                nps.setValue(obj.original_name, forKey: "original_name")
                break
            default:
                break
            }
        }
        
        do {
            try self.context.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func getRecordByTitleID(entityName: String, title_id: String) -> NSManagedObject? {
        let req             = NSFetchRequest<NSManagedObject>(entityName: entityName)
        let predicate       = NSPredicate(format: "title_id == %@", title_id)
        req.predicate       = predicate
        
        do {
            return try self.context.fetch(req).first
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return nil
    }
    
    func getRecords() -> [NSManagedObject]? {
        let req             = NSFetchRequest<NSManagedObject>(entityName: self.type)
        let predicate       = NSPredicate(format: "region == %@", self.region)
        req.predicate       = predicate
        req.sortDescriptors = [NSSortDescriptor(key: "title_id", ascending: true)]
        
        do {
            return try self.context.fetch(req)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return nil
    }
    
    func searchRecords(searchString: String) -> [NSManagedObject]? {
        let req             = NSFetchRequest<NSManagedObject>(entityName: self.type)
        let predicate       = NSPredicate(format: "region == %@ AND name contains[c] %@", self.region, searchString)
        req.predicate       = predicate
        req.sortDescriptors = [NSSortDescriptor(key: "title_id", ascending: true)]
        
        do {
            return try self.context.fetch(req)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return nil
    }
    
    func removeExpiredCache() {
        var plist: NSDictionary?
        if let path = Bundle.main.path(forResource: "ListTimestamps", ofType: "plist") {
            plist = NSDictionary(contentsOfFile: path)
        }
        if let p = plist {
            let lifespan    : Double = p.value(forKey: "refresh_after_hours") as! Double
            let timestamp   : Date = p.value(forKeyPath: self.type) as! Date
            let interval    : TimeInterval = 60 * 60 * lifespan
            let expires     = timestamp.addingTimeInterval(interval)
            
            if(expires < Date()) {
                batchDelete(type: self.type)
            }
        }
    }
    
    func batchDelete(type: String) {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: type)
        let req = NSBatchDeleteRequest(fetchRequest: fetch)
        do {
            try self.context.execute(req)
        } catch let error as NSError {
            print("Could not delete entity. \(error), \(error.userInfo)")
        }
    }
    
    func deleteAll() {
        let types = [
            "PSVGames",
            "PSVUpdates",
            "PSVDLCs",
            "PSPGames",
            "PSXGames",
            "Bookmarks"
        ]
        types.forEach { type in
            batchDelete(type: type)
        }
    }

    func updateCacheTimestamp() {
        var plist: NSDictionary?
        let path = Bundle.main.path(forResource: "ListTimestamps", ofType: "plist")
        if let dir = path {
            plist = NSDictionary(contentsOfFile: path!)
        }
        if let p = plist {
            p.setValue(Date(), forKey: self.type)
            p.write(toFile: path!, atomically: true)
        }
    }

    func recordsAreEmpty() -> Bool {
        let records = getRecords()
        if (records!.isEmpty) {
            return true
        }
        return false
    }
    
    // MARK: Bookmark Retrieval
    func getBookmarks() -> [NSManagedObject?] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "Bookmarks")
        req.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            return try self.context.fetch(req)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return []
    }
}
