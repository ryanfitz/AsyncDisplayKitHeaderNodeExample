//
//  ASTableViewManager.swift
//  AsyncDisplayKitHeaderNodeExample
//
//  Created by Ryan Fitzgerald on 8/13/15.
//  Copyright (c) 2015 ryanfitz. All rights reserved.
//

import Foundation
import RFSectionDelta
import AsyncDisplayKit

class ASTableViewManager {
    var batchContext : ASBatchContext?
    
    func update(tableView: ASTableView, removedSections: NSIndexSet?, insertedSections: NSIndexSet?, movedSections: [MovedIndex]?) {
        var del = NSMutableIndexSet()
        var add = NSMutableIndexSet()
        
        if let remove = removedSections {
            del.addIndexes(remove)
        }
        
        if let inserts = insertedSections {
            add.addIndexes(inserts)
        }
        
        if let moves = movedSections {
            for move in moves.reverse() {
                del.addIndex(move.oldIndex)
                add.addIndex(move.newIndex)
            }
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            tableView.beginUpdates()
            
            if del.count > 0 {
                tableView.deleteSections(del, withRowAnimation: .Fade)
            }
            
            if add.count > 0 {
                tableView.insertSections(add, withRowAnimation: .Fade)
            }
            
            tableView.endUpdates()
        }
        
        if let context = self.batchContext {
            context.completeBatchFetching(true)
            self.batchContext = nil
        }
    }
}
