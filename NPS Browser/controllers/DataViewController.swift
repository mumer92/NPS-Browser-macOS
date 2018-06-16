//
//  ViewController.swift
//  NPS Browser
//
//  Created by JK3Y on 4/28/18.
//  Copyright © 2018 JK3Y. All rights reserved.
//

import Cocoa

class DataViewController: NSViewController, ToolbarDelegate {
    
    @IBOutlet var tsvResultsController: NSArrayController!
    @IBOutlet weak var tableView: NSTableView!
    lazy var windowDelegate: WindowDelegate = Helpers().getWindowDelegate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
    }
    
    override func viewDidAppear() {
        
        CoreDataIO().deleteAll()
        
        windowDelegate.startBtnReloadAnimation()
        if (CoreDataIO().recordsAreEmpty()) {
            NetworkManager().makeHTTPRequest()
        } else {
            let content = CoreDataIO().getRecords()
            tsvResultsController.content = content
        }
        windowDelegate.stopBtnReloadAnimation()
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
            let vc: DetailsViewController = parent?.childViewControllers[1] as! DetailsViewController
            vc.representedObject = representedObject
        }
    }

    @IBAction func tableSelectionChanged(_ sender: NSTableView) {
        if (!tsvResultsController.selectedObjects.isEmpty) {
            self.representedObject = tsvResultsController.selectedObjects.first
        }
    }
    
    func setArrayControllerContent(content: [NSManagedObject]?) {
        tsvResultsController.content = nil
        tsvResultsController.content = content
        windowDelegate.stopBtnReloadAnimation()
        tableView.reloadData()
    }
}

extension NSTableView {
    override open func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 125:
            // Arrow Down
            if (Helpers().getDataController().tsvResultsController.canSelectNext) {
                Helpers().getDataController().tsvResultsController.setSelectionIndex(selectedRow + 1)
                Helpers().getDataController().tableSelectionChanged(self)
            }
            break
        case 126:
            // Arrow Up
            if (Helpers().getDataController().tsvResultsController.canSelectPrevious) {
                Helpers().getDataController().tsvResultsController.setSelectionIndex(selectedRow - 1)
                Helpers().getDataController().tableSelectionChanged(self)
            }
            break
        default:
            break
        }
    }
}
