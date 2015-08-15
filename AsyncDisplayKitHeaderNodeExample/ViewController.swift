//
//  ViewController.swift
//  AsyncDisplayKitHeaderNodeExample
//
//  Created by Ryan Fitzgerald on 8/12/15.
//  Copyright (c) 2015 ryanfitz. All rights reserved.
//

import UIKit
import AsyncDisplayKit
import RFSectionDelta

class ViewController: UIViewController, ASTableViewDelegate, SectionedDataSourceDelegate {
    let tableView: ASTableView
    
    private let tableViewManager = ASTableViewManager()
    private let dataSource = SectionedDataSource()
    private let dataFetchQueue : dispatch_queue_t
    
    override required init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.tableView = ASTableView(frame: CGRectZero, style: .Plain, asyncDataFetching: true)
        dataFetchQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_CONCURRENT)
        
        super.init(nibName: nil, bundle: nil)
        
        dataSource.delegate = self
        tableView.asyncDataSource = dataSource
        tableView.asyncDelegate = self
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("storyboards are incompatible with truth and beauty")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Header Nodes"
        
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.separatorStyle = .None
        self.tableView.backgroundColor = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1)
        
        self.view.addSubview(self.tableView)
        
        println("Fetching initial data....")
        self.loadContent()
    }
    
    override func viewWillLayoutSubviews() {
        self.tableView.frame = self.view.bounds
    }
    
    func loadContent() {
        dispatch_async(dataFetchQueue) {
            [weak self] in
            
            var start = 0
            if let data = self?.dataSource.data where !data.isEmpty {
                start = data.count
            }
            
            var range = start...(start + 25)
            
            let data = range.map { (idx) -> ViewModel in
               return ViewModel(title : "Node section \(idx)")
            }
            
            self?.dataSource.pendingData = data
        }
    }
    
    // MARK: ASTableViewDelegate
    
    func tableView(tableView: ASTableView!, willBeginBatchFetchWithContext context: ASBatchContext!) {
        println("Fetching next page of data, typically over a network....")
        tableViewManager.batchContext = context
        self.loadContent()
    }
    
    func shouldBatchFetchForTableView(tableView: ASTableView!) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView!, heightForHeaderInSection section: Int) -> CGFloat {
        return dataSource.tableView(tableView, heightForHeaderInSection: section)
    }
    
    func tableView(tableView: UITableView!, viewForHeaderInSection section: Int) -> UIView! {
        return dataSource.tableView(tableView, viewForHeaderInSection: section)
    }
    
    func tableView(tableView: UITableView!, willDisplayHeaderView view: UIView!, forSection section: Int) {
        if let header = dataSource.fetchHeaderNode(section) where header.displaySuspended {
            header.recursivelySetDisplaySuspended(false)
        }
    }
    
    func tableView(tableView: UITableView!, didEndDisplayingHeaderView view: UIView!, forSection section: Int) {
        if let header = dataSource.fetchHeaderNode(section) {
            header.recursivelySetDisplaySuspended(true)
//            header.layer.removeFromSuperlayer()
            header.recursivelyClearContents()
        }
    }
    
    func tableView(tableView: UITableView!, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(tableView: UITableView!, viewForFooterInSection section: Int) -> UIView! {
        return UIView(frame: CGRectZero)
    }
    
    // MARK: SectionedDataSourceDelegate
    
    func dataSource(dataSource: SectionedDataSource, removedSections: NSIndexSet?, insertedSections: NSIndexSet?, movedSections: [MovedIndex]?) {
        println("data loaded, updating table")
        self.tableViewManager.update(self.tableView, removedSections: removedSections, insertedSections: insertedSections, movedSections: movedSections)
    }
    
    func dataSource(dataSource: SectionedDataSource, constrainedSizeForNodeAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(CGRectGetWidth(self.tableView.bounds), CGFloat.max)
    }
}

