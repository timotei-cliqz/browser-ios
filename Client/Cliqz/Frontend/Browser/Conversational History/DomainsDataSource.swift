//
//  HistoryDataSource.swift
//  Client
//
//  Created by Tim Palade on 4/20/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation

//The data source for the ConversationalHistory View. 

final class DomainsDataSource: NSObject, DomainsProtocol {
    
    //This still needs work
    //Loads every time this view is shown. This can be problematic with big history. Need to handle that.
    
    var domains: [Domain] = []
    
    let cliqzNews_header = "Cliqz News"
    let cliqzNews_title  = "Tap to Read"
    
    weak var delegate: HasDataSource?
    
    override init() {
        super.init()
        loadDomains()
        NotificationCenter.default.addObserver(self, selector: #selector(domainsUpdated), name: DomainsModule.notification_updated, object: nil)
    }
    
    func loadDomains() {
        domains = DomainsModule.sharedInstance.domains
    }
    
    func numberOfCells() -> Int {
        return self.domains.count
    }
    
    func urlLabelText(indexPath:IndexPath) -> String {
        return domains[indexPath.row].host
    }
    
    func titleLabelText(indexPath:IndexPath) -> String {
        return domains[indexPath.row].date?.toRelativeTimeString() ?? ""
    }
    
    func timeLabelText(indexPath:IndexPath) -> String {
        return ""
    }
    
    func baseUrl(indexPath:IndexPath) -> String {
        let domainDetail = domains[indexPath.row].domainDetails
        return domainDetail.first?.url.host ?? ""
    }
    
    func image(indexPath:IndexPath, completionBlock: @escaping (_ result:UIImage?) -> Void) {
        LogoLoader.loadLogoImageOrFakeLogo(self.baseUrl(indexPath: indexPath), completed: { (image, fakeLogo, error) in
            if let img = image{
                completionBlock(img)
            }
            else{
                //completionBlock(result: UIImage(named: "coolLogo") ?? UIImage())
                completionBlock(nil)
            }
        })
    }
    
    func shouldShowNotification(indexPath:IndexPath) -> Bool {
        return false
    }
    
    func notificationNumber(indexPath:IndexPath) -> Int {
        return NewsManager.sharedInstance.newArticleCount()
    }
    
    func indexWithinBounds(indexPath:IndexPath) -> Bool {
        if indexPath.row < self.domains.count{
            return true
        }
        return false
    }
    
    @objc
    func domainsUpdated(_ notification: Notification) {
        loadDomains()
        delegate?.dataSourceWasUpdated(identifier: "DomainsDataSource")
    }
}
