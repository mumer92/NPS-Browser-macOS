//
//  Bookmark.swift
//  NPS Browser
//
//  Created by JK3Y on 6/9/18.
//  Copyright © 2018 JK3Y. All rights reserved.
//

import Cocoa

class Bookmark: NSObject {
    @objc dynamic var name                      : String
    @objc dynamic var title_id                  : String
    @objc dynamic var type                      : String
    @objc dynamic var zrif                      : String?
    @objc dynamic var pkg_direct_link           : URL?
    init(name: String, title_id: String, type: String, zrif: String?, pkg_direct_link: URL?) {
        self.name                       = name
        self.title_id                   = title_id
        self.type                       = type
        self.zrif                       = zrif
        self.pkg_direct_link            = pkg_direct_link
        super.init()
    }
}
