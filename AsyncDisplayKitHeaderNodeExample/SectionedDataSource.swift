//
//  SectionedDataSource.swift
//  AsyncDisplayKitHeaderNodeExample
//
//  Created by Ryan Fitzgerald on 8/13/15.
//  Copyright (c) 2015 ryanfitz. All rights reserved.
//

import Foundation
import Dollar
import RFSectionDelta
import AsyncDisplayKit

protocol SectionedDataSourceDelegate : class {
    func dataSource(dataSource: SectionedDataSource, removedSections: NSIndexSet?, insertedSections: NSIndexSet?, movedSections: [MovedIndex]?)
    func dataSource(dataSource: SectionedDataSource, constrainedSizeForNodeAtIndexPath indexPath: NSIndexPath) -> CGSize
}

class SectionedDataSource : NSObject, ASTableViewDataSource  {
    
    weak var delegate: SectionedDataSourceDelegate?
    
    private let editingHeadersTransactionQueue : NSOperationQueue
    
    override init() {
        editingHeadersTransactionQueue = NSOperationQueue()
        editingHeadersTransactionQueue.maxConcurrentOperationCount = 1 // Serial queue
        editingHeadersTransactionQueue.name = "com.ryanfitz.SectionedDataSource.editingHeadersTransactionQueue";
        
        super.init()
    }
    
    var dataSourceLocked : Bool = true {
        didSet {
            if !dataSourceLocked {
                self.flushPendingData()
            }
        }
    }
    
    var refresh = false
    
    private(set) var data : [ViewModel]?
    
    private var _pendingData = [ViewModel]()
    
    var pendingData : [ViewModel] {
        get {
            return _pendingData
        }
        set {
            _pendingData = $.union(_pendingData, newValue)
            self.flushPendingData()
        }
    }
    
    private var headerNodes = [ASDisplayNode]()
    
    func fetchHeaderNode(section : Int) -> ASDisplayNode? {
        return $.fetch(self.headerNodes, section)
    }
    
    private func flushPendingData() {
        var data : [ViewModel]?
        
        if !dataSourceLocked && self.pendingData.count > 0 {
            if self.refresh {
                data = _pendingData
            } else if let existingData = self.data {
                data = $.union(existingData, _pendingData)
            } else {
                data = _pendingData
            }
        }
        
        if let newData = data {
            let sectionDelta = RFSectionDelta()
            let delta = sectionDelta.generateDelta(fromOldArray: self.data, toNewArray: newData)
            
            if !dataSourceLocked {
                self.data = newData
                self.refresh = false
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                    self.updateStoredHeaderNodes(delta)
                }
                
                _pendingData.removeAll(keepCapacity: false)
            }
        }
    }
    
    private func updateStoredHeaderNodes(delta: RFDelta) {
        editingHeadersTransactionQueue.waitUntilAllOperationsAreFinished()
        
        editingHeadersTransactionQueue.addOperationWithBlock() {
            var addIndexes = [Int]()
            
            var headersMap = [Int : ASDisplayNode]()
            
            if let movedIndexes = delta.movedIndexes {
                for data in movedIndexes {
                    if data.oldIndex < self.headerNodes.count {
                        let header = self.headerNodes[data.oldIndex]
                        headersMap[data.newIndex] = header
                    }
                    
                    addIndexes.append(data.newIndex)
                }
            }
            
            delta.addedIndices?.enumerateIndexesUsingBlock() { (index, _) in
                addIndexes.append(index)
            }
            
            delta.unchangedIndices?.enumerateIndexesUsingBlock() { (index, _) in
                if index < self.headerNodes.count {
                    let header = self.headerNodes[index]
                    headersMap[index] = header
                }
                addIndexes.append(index)
            }
            
            addIndexes.sort { $0 < $1 }
            
            for idx in addIndexes {
                if headersMap[idx] == nil {
                    if let header = self.loadHeaderNode(InSection: idx) {
                        if let size = self.delegate?.dataSource(self, constrainedSizeForNodeAtIndexPath: NSIndexPath(forRow: 0, inSection: idx)) {
                            header.measure(size)
                            header.frame = CGRectMake(0.0, 0.0, header.calculatedSize.width, header.calculatedSize.height)
                        }
                        
                        headersMap[idx] = header
                    }
                }
            }
            
            var result = [ASDisplayNode]()
            
            for idx in addIndexes {
                if let header = headersMap[idx] {
                    result.append(header)
                }
            }
            
            self.headerNodes = result
            
            self.delegate?.dataSource(self, removedSections: delta.removedIndices, insertedSections: delta.addedIndices, movedSections : delta.movedIndexes)
        }
    }
    
    func loadHeaderNode(InSection section: Int) -> ASDisplayNode? {
        if let data = self.data, let vm = $.fetch(data, section) {
            var node = ASTextNode()
            node.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.75)
            let font = UIFont.systemFontOfSize(16)
            
            let style = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
            style.paragraphSpacing = 0.5 * font.lineHeight;
            style.hyphenationFactor = 1.0;
            
            let attributes = [
                NSFontAttributeName : font,
                NSParagraphStyleAttributeName : style,
                NSForegroundColorAttributeName : UIColor(red: 155/255, green: 155/255, blue: 155/255, alpha: 1)]
            
            node.attributedString = NSAttributedString(string: "Header: \(vm.title)", attributes: attributes)
            
            return node
        } else {
            return nil
        }
    }
    
    func tableView(tableView: UITableView!, heightForHeaderInSection section: Int) -> CGFloat {
        var result : CGFloat = 0
        
        if let header = fetchHeaderNode(section) {
            result = header.calculatedSize.height
        }
        
        return result
    }
    
    func tableView(tableView: UITableView!, viewForHeaderInSection section: Int) -> UIView! {
        var view = tableView.dequeueReusableHeaderFooterViewWithIdentifier("Header") as? UITableViewHeaderFooterView
        
        if view == nil {
            view = UITableViewHeaderFooterView(reuseIdentifier: "Header")
        }
        
        view?.backgroundView = UIImageView()
        
        let contentView = view!.contentView
        contentView.backgroundColor = UIColor.clearColor()
        
        for subview in contentView.subviews {
            subview.removeFromSuperview()
        }
        
        if let header = fetchHeaderNode(section) {
            contentView.addSubnode(header)
        }
        
        return view
    }
    
    // MARK: ASTableViewDataSource.
    
    func tableView(tableView: ASTableView!, nodeForRowAtIndexPath indexPath: NSIndexPath!) -> ASCellNode! {
        let node = ASTextCellNode()
        node.placeholderEnabled = false
        node.backgroundColor = UIColor.whiteColor()
        
        if let data = self.data, let vm = $.fetch(data, indexPath.section) {
            node.text = "Row \(indexPath.section).\(indexPath.row) - \(vm.title)"
        }
        
        return node
    }
    
    func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        if let d = data {
            return d.count
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        var result = 0
        
        if let data = self.data, let vm = $.fetch(data, section) {
            result = 1
        }
        
        return result
    }
    
    func tableViewLockDataSource(tableView: ASTableView!) {
        dataSourceLocked = true
    }
    
    func tableViewUnlockDataSource(tableView: ASTableView!) {
        dataSourceLocked = false
    }
}