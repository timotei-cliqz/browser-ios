//
//  ConversationalHistoryAPI.swift
//  Client
//
//  Created by Sahakyan on 12/8/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import Alamofire
import UIKit
import Storage

class ConversationalHistoryAPI {
	
	static let host = "http://history-server-2082834335.us-east-1.elb.amazonaws.com/"
	static let uniqueID: String = {
		if let ID = UIDevice().identifierForVendor {
			return ID.UUIDString
		}
		return "000"
	}()

	class func pushHistoryItem(visit: SiteVisit) {
		let params = ["url": visit.site.url,
		              "title": visit.site.title,
		              "lastVisitDate": NSNumber(unsignedLongLong:visit.date)]
		let completeParams = ["historyItems": params, "timestamp": NSNumber(unsignedLongLong: NSDate.nowMicroseconds())]
		Alamofire.request(.POST, "\(self.host)pushHistory?uid=\(self.uniqueID)", parameters: completeParams, encoding: .URL, headers: nil).response(completionHandler: { (request, response, data, error) in
				print("Request failed ---- \(error)")
				print("Request failed ---- \(response)")

			})
	}
	
	class func getHistory(callback: (NSDictionary) -> Void) {
		Alamofire.request(.GET, "\(self.host)/getHistory?uid=\(self.uniqueID)", parameters: nil, encoding: .URL, headers: nil).responseJSON { (response) in
			if response.result.isSuccess {
				if let result = response.result.value as? NSDictionary,
					domains = result.valueForKey("domains") as? NSDictionary {
					callback(domains)
				}
			} else {
				callback(NSDictionary())
				print("Get History is failed :((( --- \(response)")
			}
		}
	}

	class func pushAllHistory(history: [SiteVisit]) {
		
	}
}
