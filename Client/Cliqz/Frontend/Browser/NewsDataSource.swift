//
//  NewsDataSource.swift
//  Client
//
//  Created by Tim Palade on 4/19/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

//Note: Certainly not production ready.

import Alamofire

final class NewsDataSource{
    //how many news to fetch
    let news_to_fetch = 5
    
    static let sharedInstance = NewsDataSource()
    
    var ready = false
    var news_version: Int = 0
    var last_update_server: Int = 0
    var articles: [[String:AnyObject]] = []
    
    init() {
        getNews(news_to_fetch)
    }
    
    private func getNews(count:Int) { // -> [String: String]{
        
        ready = false
        
        let data = ["q": "","results": [[ "url": "rotated-top-news.cliqz.com",  "snippet":[String:String]()]]]
        let userRegion = self.getDefaultRegion()
        let newsUrl = "https://newbeta.cliqz.com/api/v2/rich-header?"
        let uri = "path=/v2/map&q=&lang=N/A&locale=\(NSLocale.currentLocale().localeIdentifier)&country=\(userRegion)&adult=0&loc_pref=ask&count=\(count)"
        
        Alamofire.request(.PUT, newsUrl + uri, parameters: data, encoding: .JSON, headers: nil).responseJSON { (response) in
            if response.result.isSuccess {
                if let result = response.result.value?["results"] as? [[String: AnyObject]] {
                    if let snippet = result[0]["snippet"] as? [String: AnyObject],
                        extra = snippet["extra"] as? [String: AnyObject],
                        articles = extra["articles"] as? [[String: AnyObject]]
                    {
                        self.news_version = (extra["news_version"] as? NSNumber)?.integerValue ?? 0
                        self.last_update_server = (extra["last_update"] as? NSNumber)?.integerValue ?? 0
                        self.articles = articles
                        self.ready = true
                    }
                }
            }
        }
        
    }
    
    private func getDefaultRegion() -> String {
        let availableCountries = ["DE", "US", "UK", "FR"]
        let currentLocale = NSLocale.currentLocale()
        if let countryCode = currentLocale.objectForKey(NSLocaleCountryCode) as? String where availableCountries.contains(countryCode) {
            return countryCode
        }
        return "DE"
    }
}
