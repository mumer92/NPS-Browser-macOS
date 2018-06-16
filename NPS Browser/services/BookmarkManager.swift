//
//  BookmarkManager.swift
//  NPS Browser
//
//  Created by JK3Y on 6/9/18.
//  Copyright © 2018 JK3Y. All rights reserved.
//

import Cocoa
import Foundation

class BookmarkManager {

    let cd = CoreDataIO()
    var entity: NSEntityDescription
    var bookmarkButtonIDArray = [String: NSButton]()
    
    init() {
        self.entity = cd.getEntity(entityName: "Bookmarks")
    }
    
    func getBookmarkList() -> [NSManagedObject?] {
        return cd.getBookmarks()
    }
    
    func getBookmark(title_id: String) -> NSManagedObject? {
        return cd.getRecordByTitleID(entityName: "Bookmarks", title_id: title_id)
    }
    
    func addBookmarkButtonIDToArray(title_id: String, button: NSButton) {
        bookmarkButtonIDArray[title_id] = button
    }
    
    func addBookmark(bookmark: Bookmark, item: NSManagedObject, sender: NSButton) {
        // Store button object id so we can toggle state when bookmark is removed via the popover
        addBookmarkButtonIDToArray(title_id: bookmark.title_id, button: sender)
        saveBookmark(bookmark: bookmark, item: item)
    }
    
    func removeBookmark(_ bookmark: Bookmark) {
        let obj = cd.getRecordByTitleID(entityName: "Bookmarks", title_id: bookmark.title_id)
        
        bookmarkButtonIDArray[bookmark.title_id]?.state = .off
        bookmarkButtonIDArray.remove(at: bookmarkButtonIDArray.index(forKey: bookmark.title_id)!)

//        Helpers().getDataController().tableView.re
        
        do {
            cd.getContext().mergePolicy = NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType
            try cd.getContext().delete(obj!)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func saveBookmark(bookmark: Bookmark, item: NSManagedObject) {
        let obj = cd.getObject(entity: self.entity)
        obj.setValue(bookmark.name, forKey: "name")
        obj.setValue(bookmark.title_id, forKey: "title_id")
        obj.setValue(bookmark.type, forKey: "type")
        obj.setValue(bookmark.zrif, forKey: "zrif")
        obj.setValue(bookmark.pkg_direct_link, forKey: "pkg_direct_link")
        obj.setValue(item, forKey: "item")
        
        do {
            try cd.getContext().save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func deleteAll() {
        self.cd.deleteAll()
    }
}
