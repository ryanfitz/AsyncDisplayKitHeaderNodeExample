//
//  RFSectionDelta.swift
//  RFSectionDelta
//
//  Created by Ryan Fitzgerald on 3/5/15.
//  Copyright (c) 2015 ryanfitz. All rights reserved.
//

public struct MovedIndex : Equatable, Printable {
    public let oldIndex : Int
    public let newIndex : Int
    
    public init (oldIndex : Int, newIndex : Int) {
        self.oldIndex = oldIndex
        self.newIndex = newIndex
    }
    
    public var description: String {
        return "oldIndex: \(oldIndex) newIndex: \(newIndex)"
    }
}

public func ==(lhs: MovedIndex, rhs: MovedIndex) -> Bool {
    return lhs.oldIndex == rhs.oldIndex && lhs.newIndex == rhs.newIndex
}

public struct RFDelta {
    public let addedIndices : NSIndexSet?
    public let removedIndices : NSIndexSet?
    public let unchangedIndices : NSIndexSet?
    public let movedIndexes : [MovedIndex]?
}

@objc public class RFSectionDelta {
    
    public init() {
        
    }
    
    public func generateDelta<T : Hashable>(fromOldArray oldArray : [T]?, toNewArray newArray: [T]?) -> RFDelta {
        var removeSets = NSMutableIndexSet()
        var insertSets = NSMutableIndexSet()
        var unchangedSets = NSMutableIndexSet()
        var movedIndexes = [MovedIndex]()
        
        if let oldData = oldArray {
            if let newData = newArray {
                
                // TODO switch to using native sets when support swift 1.2
                let newItemsSet = indexArray(newData)
                let oldItemSet = indexArray(oldData)
                
                for (item, newIdx) in newItemsSet {
                    if let oldIdx = oldItemSet[item] {
                        if newIdx == oldIdx {
                            unchangedSets.addIndex(newIdx)
                        } else {
                            movedIndexes.append(MovedIndex(oldIndex: oldIdx, newIndex: newIdx))
                        }
                    } else {
                        insertSets.addIndex(newIdx)
                    }
                }
                
                for (item, oldIdx) in oldItemSet {
                    if newItemsSet[item] == nil {
                       removeSets.addIndex(oldIdx)
                    }
                }
            } else {
                // new array is nil so remove all
                for (idx, _) in enumerate(oldData) {
                    removeSets.addIndex(idx)
                }
            }
        } else if let newData = newArray {
            for (idx, _) in enumerate(newData) {
                insertSets.addIndex(idx)
            }
        }
        
        var addedIndices : NSIndexSet? = insertSets.count > 0 ? insertSets : nil
        var removedIndices : NSIndexSet? = (removeSets.count > 0 ? removeSets : nil )
        var unchangedIndices : NSIndexSet? = (unchangedSets.count > 0 ? unchangedSets : nil )
        var movedIndices : [MovedIndex]? = (movedIndexes.count > 0 ? movedIndexes : nil )
        
        return RFDelta(addedIndices: addedIndices, removedIndices: removedIndices, unchangedIndices: unchangedIndices, movedIndexes: movedIndices)
    }
    
    private func indexArray<T : Hashable>(array : [T]) -> [T : Int] {
        var result = [T : Int]()
        
        for (idx, item) in enumerate(array) {
            result[item] = idx
        }
        
        return result
    }
}