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
import Shared

class ConversationalHistoryAPI {
	
	static let host = "https://hs.cliqz.com/"
	static let uniqueID: String = {
		if let ID = UIDevice().identifierForVendor {
			return ID.UUIDString
		}
		return "000"
	}()

	class func pushHistoryItem(visit: SiteVisit) {
		let completeParams = ["historyItems": [self.generateParamsForHistoryItem(visit.site.url, title: visit.site.title, visitedDate: visit.date)], "timestamp": NSNumber(unsignedLongLong: NSDate.nowMicroseconds())]
		self.postHisotryRequest(completeParams, complitionHandler: nil)
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

	class func pushAllHistory(history: Cursor<Site>?, completionHandler:(NSError?) -> Void) {
		if let sites = history {
			var historyResults = [[String: AnyObject]]()
			for site in sites {
				historyResults.append(self.generateParamsForHistoryItem((site?.url)!, title: (site?.title)!, visitedDate: (site?.latestVisit!.date)!))
			}
			let completeParams = ["historyItems": historyResults, "timestamp": NSNumber(unsignedLongLong: NSDate.nowMicroseconds())]
			self.postHisotryRequest(completeParams, complitionHandler: completionHandler)
		}
	}

	class func pushURLAndQuery(url: String, query: String) {
		let completeParams = ["queries": [["query": query, "url": url]]]
		Alamofire.request(.POST, "\(self.host)pushQueries?uid=\(self.uniqueID)", parameters: completeParams, encoding: .JSON, headers: nil).response(completionHandler: { (request, response, data, error) in
			if error != nil {
				print("Request is failed: \(error)")
			}
		})
	}

	private class func generateParamsForHistoryItem(url: String, title: String, visitedDate: MicrosecondTimestamp) -> [String: AnyObject] {
		return ["url": url,
		        "title": title,
			    "lastVisitDate": NSNumber(unsignedLongLong:visitedDate)]
	}

	private class func postHisotryRequest(history: [String: AnyObject], complitionHandler: ((NSError?) -> Void)?) {
		Alamofire.request(.POST, "\(self.host)pushHistory?uid=\(self.uniqueID)", parameters: history, encoding: .JSON, headers: nil).response(completionHandler: { (request, response, data, error) in
			if error != nil {
				print("Request is failed: \(error)")
			}
			if let c = complitionHandler {
				c(error)
			}
		})
	}
}
