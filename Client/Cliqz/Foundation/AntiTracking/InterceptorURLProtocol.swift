//
//  InterceptorURLProtocol.swift
//  Client
//
//  Created by Mahmoud Adam on 8/12/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit


class InterceptorURLProtocol: NSURLProtocol {
    var connection: NSURLConnection?
    
    static let customURLProtocolHandledKey = "customURLProtocolHandledKey"
    static let excludeUrlPrefixes = ["https://lookback.io/api", "http://localhost"]
    
    //MARK: - NSURLProtocol handling
    override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        guard (
            NSURLProtocol.propertyForKey(customURLProtocolHandledKey, inRequest: request) == nil
             && request.mainDocumentURL != nil) else {
            return false
        }
        
        if let url = request.URL where isExcludedUrl(url) == false {
            return true
        }
        return false
        
    }
    
    override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }
    
    override class func requestIsCacheEquivalent(a: NSURLRequest, toRequest b: NSURLRequest) -> Bool {
        return super.requestIsCacheEquivalent(a, toRequest: b)
    }
    
    override func startLoading() {
        if self.request.URL == self.request.mainDocumentURL && AntiPhishingDetector.isPhishingURL(self.request.URL) {
            returnEmptyResponse()
        } else if let newRequest = AntiTrackingModule.sharedInstance.getModifiedRequest(self.request) {
            NSURLProtocol.setProperty(true, forKey: InterceptorURLProtocol.customURLProtocolHandledKey, inRequest: newRequest)
            self.connection = NSURLConnection(request: newRequest, delegate: self)
        } else {
            returnEmptyResponse()
        }
    }
    
    override func stopLoading() {
        self.connection?.cancel()
        self.connection = nil
    }
    
    
    //MARK: - NSURLConnectionDataDelegate
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        self.client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.client?.URLProtocol(self, didLoadData: data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        self.client?.URLProtocolDidFinishLoading(self)
        
    }
    
    func didFailWithError(error: NSError) {
        self.client?.URLProtocol(self, didFailWithError: error)
    }
    
    //MARK: - private helper methods
    class func isExcludedUrl(url: NSURL?) -> Bool {
        if let scheme = url?.scheme where !scheme.startsWith("http") {
            return true
        }

        if let urlString = url?.absoluteString {
            for prefix in excludeUrlPrefixes {
                if urlString.startsWith(prefix) {
                    return true
                }
            }
        }
        
        return false
    }
    
    func returnEmptyResponse() {
        // To block the load nicely, return an empty result to the client.
        // Nice => UIWebView's isLoading property gets set to false
        // Not nice => isLoading stays true while page waits for blocked items that never arrive
        
        guard let url = request.URL else { return }
        let response = NSURLResponse(URL: url, MIMEType: "text/html", expectedContentLength: 1, textEncodingName: "utf-8")
        client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
        client?.URLProtocol(self, didLoadData: NSData())
        client?.URLProtocolDidFinishLoading(self)
    }
}