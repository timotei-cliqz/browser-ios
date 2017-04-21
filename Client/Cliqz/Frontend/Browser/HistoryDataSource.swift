//
//  HistoryDataSource.swift
//  Client
//
//  Created by Tim Palade on 4/20/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class HistoryDataSource: NSObject, HistoryProtocol{
    
    //Note: The mechanism is not robust enough to handle the failure of ConversationalHistoryAPI.getHistory
    //TO DO: Work on that.
    
    var domainsInfo: NSDictionary = NSDictionary()
    var domains: [String] = []
    
    let cliqzNews_header = "Cliqz News"
    let cliqzNews_title  = "Tap to Read"
    
    override init() {
        super.init()
        self.loadData(nil)
    }
    
    func loadData(completion:((ready:Bool) -> Void)?) {
        ConversationalHistoryAPI.getHistory { (data) in
            self.domainsInfo = data.valueForKey("domains") as! NSDictionary //how should I handle this. Is it guaranteed that it will always be an NSDictionary?
            
            let domains      = self.domainsInfo.keysSortedByValueUsingComparator({ (a, b) -> NSComparisonResult in
                if let dict_a = a as? [String: AnyObject], dict_b = b as? [String: AnyObject], time_a = dict_a["lastVisitedAt"] as? NSNumber, time_b = dict_b["lastVisitedAt"] as? NSNumber
                {
                    return time_a.doubleValue > time_b.doubleValue ? .OrderedAscending : .OrderedDescending
                }
                return .OrderedSame
            }) as! [String]
            
            self.domains = []
            self.domains.insert("cliqz.com", atIndex: 0)
            self.domains.appendContentsOf(domains)
            completion?(ready:true)
        }
    }
    
    func numberOfCells() -> Int{
        return self.domains.count
    }
    
    func urlLabelText(indexPath:NSIndexPath) -> String
    {
        if indexPath.row == 0{
            return cliqzNews_header
        }
        else if indexWithinBounds(indexPath){
            return domains[indexPath.row]
        }
        
        return ""
    }
    
    func titleLabelText(indexPath:NSIndexPath) -> String
    {
        if indexPath.row == 0{
            return cliqzNews_title
        }
        else{
            return domainValue(forKey: "lastVisitedAt", at: indexPath) ?? ""
        }
    }
    
    func timeLabelText(indexPath:NSIndexPath) -> String
    {
        return ""
    }
    
    func baseUrl(indexPath:NSIndexPath) -> String{
        if indexPath.row == 0{
            return "https://www.cliqz.com"
        }
        else{
            return domainValue(forKey: "baseUrl", at: indexPath) ?? ""
        }
    }
    
    func image(indexPath:NSIndexPath, completionBlock:(result:UIImage) -> Void){
        LogoLoader.loadLogoImageOrFakeLogo(self.domains[indexPath.row], completed: { (image, fakeLogo, error) in
            if let img = image{
                completionBlock(result: img)
            }
            else{
                completionBlock(result: UIImage(named: "coolLogo") ?? UIImage())
            }
        })
    }
    
    func domainValue(forKey key: String, at indexPath:NSIndexPath) -> String? {
        if indexWithinBounds(indexPath){
            let domainDict = domain(at: indexPath)
            if let timeinterval = domainDict[key] as? NSNumber{
                return NSDate(timeIntervalSince1970: timeinterval.doubleValue / 1000).toRelativeTimeString()
            }
            return domainDict[key] as? String
        }
        return ""
    }
    
    func domain(at indexPath:NSIndexPath) -> [String:AnyObject] {
        return self.domainsInfo.valueForKey(self.domains[indexPath.row]) as? [String:AnyObject] ?? [:]
    }
    
    func indexWithinBounds(indexPath:NSIndexPath) -> Bool {
        if indexPath.row < domains.count{
            return true
        }
        return false
    }
}
