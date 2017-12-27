/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Storage
import Shared
import SwiftyJSON
import XCGLogger

private let log = Logger.browserLogger

protocol TabHelper {
    static func name() -> String
    func scriptMessageHandlerName() -> String?
    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage)
}

@objc
protocol TabDelegate {
    func tab(_ tab: Tab, didAddSnackbar bar: SnackBar)
    func tab(_ tab: Tab, didRemoveSnackbar bar: SnackBar)
    func tab(_ tab: Tab, didSelectFindInPageForSelection selection: String)
	// Cliqz:[UIWebView] Type change
	@objc optional func tab(_ tab: Tab, didCreateWebView webView: CliqzWebView)
	@objc optional func tab(_ tab: Tab, willDeleteWebView webView: CliqzWebView)
//	optional func tab(tab: Tab, didCreateWebView webView: WKWebView)
//	optional func tab(tab: Tab, willDeleteWebView webView: WKWebView)
    @objc optional func urlChangedForTab(_ tab:Tab)
}

struct TabState {
    var isPrivate: Bool = false
    var desktopSite: Bool = false
    var isBookmarked: Bool = false
    var url: URL?
    var title: String?
    var favicon: Favicon?
}

class Tab: NSObject {

//  Cliqz:  var webView: WKWebView? = nil
	var webView: CliqzWebView? = nil
    weak var tabDelegate: TabDelegate? = nil
    weak var appStateDelegate: AppStateDelegate?
    var bars = [SnackBar]()
    var favicons = [Favicon]()
    var lastExecutedTime: Timestamp?
    var sessionData: SessionData?
    fileprivate var lastRequest: URLRequest? = nil
    var restoring: Bool = false
    var pendingScreenshot = false
	var url: URL?
    // Cliqz: save restoring url for the tab
    var restoringUrl: URL?
    var requestInProgress = false
    /// The last title shown by this tab. Used by the tab tray to show titles for zombie tabs.
    var lastTitle: String?
    // CI
    var keepOpen = false
    
    fileprivate(set) var screenshot: UIImage?
    var screenshotUUID: UUID?
    
    fileprivate var helperManager: HelperManager? = nil
    fileprivate var configuration: WKWebViewConfiguration? = nil
    
    /// Any time a tab tries to make requests to display a Javascript Alert and we are not the active
    /// tab instance, queue it for later until we become foregrounded.
    fileprivate var alertQueue = [JSAlertInfo]()
    
    fileprivate var _isPrivate: Bool = false
    internal fileprivate(set) var isPrivate: Bool {
        get {
            if #available(iOS 9, *) {
                return _isPrivate
            } else {
                return false
            }
        }
        set {
            if _isPrivate != newValue {
                _isPrivate = newValue
            }
        }
    }
    
    var tabState: TabState {
        return TabState(isPrivate: _isPrivate, desktopSite: desktopSite, isBookmarked: isBookmarked, url: url, title: displayTitle, favicon: displayFavicon)
    }

    /// Whether or not the desktop site was requested with the last request, reload or navigation. Note that this property needs to
    /// be managed by the web view's navigation delegate.
    var desktopSite: Bool = false {
        didSet {
            if oldValue != desktopSite {
                
            }
        }
    }
    var isBookmarked: Bool = false {
        didSet {
            if oldValue != isBookmarked {
                
            }
        }
    }
    
    var loading: Bool {
        return webView?.isLoading ?? false
    }
    
    var estimatedProgress: Double {
        return webView?.estimatedProgress ?? 0
    }
    
    var backList: [LegacyBackForwardListItem]? {
        return webView?.backForwardList.backList
    }
    
    var forwardList: [LegacyBackForwardListItem]? {
        return webView?.backForwardList.forwardList
    }
    
    var historyList: [URL] {
        func listToUrl(item: LegacyBackForwardListItem) -> URL { return item.url }
        var tabs = self.backList?.map(listToUrl) ?? [URL]()
        tabs.append(self.url!)
        return tabs
    }
    
    var title: String? {
        return webView?.title
    }
    
    var displayTitle: String {
        if let title = webView?.title {
            if !title.isEmpty {
                return title
            }
        }
        
        guard let lastTitle = lastTitle, !lastTitle.isEmpty else {
            return displayURL?.absoluteString ??  ""
        }
        
        return lastTitle
    }
    
    var currentInitialURL: URL? {
        get {
            let initalURL = self.webView?.backForwardList.currentItem?.initialURL
            return initalURL
        }
    }
    
    var displayFavicon: Favicon? {
        var width = 0
        var largest: Favicon?
        for icon in favicons {
            if icon.width! > width {
                width = icon.width!
                largest = icon
            }
        }
        return largest
    }
    
    var displayURL: URL? {
        if let url = url {
            if ReaderModeUtils.isReaderModeURL(url) {
                return ReaderModeUtils.decodeURL(url)
            }
            if isCliqzGoToURL(url: url) {
                return nil
            }
            if ErrorPageHelper.isErrorPageURL(url) {
                let decodedURL = ErrorPageHelper.originalURLFromQuery(url)
                if !AboutUtils.isAboutURL(decodedURL) {
                    return decodedURL
                } else {
                    return nil
                }
            }
            
            if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), (urlComponents.user != nil) || (urlComponents.password != nil) {
                urlComponents.user = nil
                urlComponents.password = nil
                return urlComponents.url
            }
            
            if !AboutUtils.isAboutURL(url) {
                return url
            }
        }
        return nil
    }
    
    weak var navigationDelegate: WKNavigationDelegate? {
        didSet {
            if let webView = webView {
                webView.navigationDelegate = navigationDelegate
            }
        }
    }
    
    init(configuration: WKWebViewConfiguration) {
        self.configuration = configuration
    }

    @available(iOS 9, *)
    init(configuration: WKWebViewConfiguration, isPrivate: Bool) {
        self.configuration = configuration
        super.init()
        self.isPrivate = isPrivate
    }
    
    deinit {
        if let webView = webView {
            //tabDelegate is nil for the last tab
            tabDelegate?.tab?(self, willDeleteWebView: webView)
            //webView.removeObserver(self, forKeyPath: "URL")
        }
    }

    //Notes: Where is this called from
    //Called from the TabManager
    //1) when a Tab is selected
    //2) other cases
    func createWebview() {
        if webView == nil {
            assert(configuration != nil, "Create webview can only be called once")
            configuration!.userContentController = WKUserContentController()
            configuration!.preferences = WKPreferences()
            configuration!.preferences.javaScriptCanOpenWindowsAutomatically = false
            let webView = TabWebView(frame: CGRect.zero, configuration: configuration!)
            configuration = nil
            
            //Delegates
            //Who is the navigation delegate for the Tab in this case
            webView.navigationDelegate = navigationDelegate
            webView.webViewDelegate = self
#if CLIQZ
            // Cliqz: [UIWebView] renamed delegate to tabWebViewDelegate
			webView.tabWebViewDelegate = self
#else
			webView.delegate = self
#endif
            //Styles
            webView.accessibilityLabel = NSLocalizedString("Web content", comment: "Accessibility label for the main web content view")
            webView.allowsBackForwardNavigationGestures = true
            webView.backgroundColor = UIColor.lightGray
            // Turning off masking allows the web content to flow outside of the scrollView's frame
            // which allows the content appear beneath the toolbars in the BrowserViewController
            webView.scrollView.layer.masksToBounds = false
            
            helperManager = HelperManager(webView: webView)
            restore(webView)

            self.webView = webView
            //Why have an observer for the URL?
            //self.webView?.addObserver(self, forKeyPath: "URL", options: .new, context: nil)
            //What does this call?
            tabDelegate?.tab?(self, didCreateWebView: webView)
        }
    }

// Cliqz:[UIWebView] Changed type to CliqzWebView
//    func restore(webView: WKWebView) {
	func restore(_ webView: CliqzWebView) {
        // Pulls restored session data from a previous SavedTab to load into the Tab. If it's nil, a session restore
        // has already been triggered via custom URL, so we use the last request to trigger it again; otherwise,
        // we extract the information needed to restore the tabs and create a NSURLRequest with the custom session restore URL
        // to trigger the session restore via custom handlers
        
        func getEscapedJSON(_ jsonDict: [String: Any]) -> String?{
            let jsonString = JSON(jsonDict).rawString(String.Encoding.utf8, options: [])
            let escapedJSON = jsonString?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            return escapedJSON
        }
        
        if let sessionData = self.sessionData {
            restoring = true

            var updatedURLs = [String]()
            for url in sessionData.urls {
                guard let updatedURL = WebServer.sharedInstance.updateLocalURL(url) else {
                    assertionFailure("Invalid session URL: \(url)")
                    continue
                }
				let urlString = updatedURL.absoluteString
                updatedURLs.append(urlString)
            }

            let currentPage = sessionData.currentPage
            self.sessionData = nil
            var jsonDict = [String: Any]()
            jsonDict["history"] = updatedURLs
            jsonDict["currentPage"] = currentPage
            if let escapedJSON = getEscapedJSON(jsonDict), let restoreURL = URL(string: "\(WebServer.sharedInstance.base)/about/sessionrestore?history=\(escapedJSON)") {
                lastRequest = PrivilegedRequest(url: restoreURL) as URLRequest
                webView.loadRequest(lastRequest!)
            }
        } else if let request = lastRequest {
            webView.loadRequest(request)
        } else {
            log.error("creating webview with no lastRequest and no session data: \(String(describing: self.url))")
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
		// Cliqz:[UIWebView] Type change
//		guard let webView = object as? WKWebView where webView == self.webView,
        guard let webView = object as? CliqzWebView, webView == self.webView,
            let path = keyPath, path == "URL" else {
            return assertionFailure("Unhandled KVO key: \(String(describing: keyPath))")
        }
        requestInProgress = false
    }
}

//Navigation stuff
extension Tab {
    func goToBackForwardListItem(item: LegacyBackForwardListItem) {
        webView?.goToBackForwardListItem(item: item)
    }
    
    func loadRequest(_ request: URLRequest) -> WKNavigation? {
        if let webView = webView {
            lastRequest = request
            
            if !AboutUtils.isAboutURL(request.url) {
                requestInProgress = true
            }
            // Cliqz:[UIWebView] Replaced with fake WKNavigation
            webView.loadRequest(request)
            return DangerousReturnWKNavigation.emptyNav
        }
        return nil
    }
    
    func stop() {
        webView?.stopLoading()
    }
    
    func reload() {
        if #available(iOS 9.0, *) {
            let userAgent: String? = desktopSite ? UserAgent.desktopUserAgent() : nil
            if (userAgent ?? "") != webView?.customUserAgent,
                let currentItem = webView?.backForwardList.currentItem
            {
                webView?.customUserAgent = userAgent
                
                // Reload the initial URL to avoid UA specific redirection
                _ = loadRequest(URLRequest(url: currentItem.initialURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60))
                return
            }
        }
        
        if let _ = webView?.reloadFromOrigin() {
            log.info("reloaded zombified tab from origin")
            return
        }
        
        if let webView = self.webView {
            log.info("restoring webView from scratch")
            restore(webView)
        }
    }
    
    @available(iOS 9, *)
    func toggleDesktopSite() {
        desktopSite = !desktopSite
        reload()
    }
}


//Helper Manager
extension Tab {
    func addHelper(_ helper: TabHelper, name: String) {
        helperManager!.addHelper(helper, name: name)
    }
    
    func getHelper(_ name: String) -> TabHelper? {
        return helperManager?.getHelper(name)
    }
}

//JS Alerts
extension Tab {
    func queueJavascriptAlertPrompt(_ alert: JSAlertInfo) {
        alertQueue.append(alert)
    }
    
    func dequeueJavascriptAlertPrompt() -> JSAlertInfo? {
        guard !alertQueue.isEmpty else {
            return nil
        }
        return alertQueue.removeFirst()
    }
    
    func cancelQueuedAlerts() {
        alertQueue.forEach { alert in
            alert.cancel()
        }
    }
}

//Show/Hide Content + Screenshot + Modes
extension Tab {
    func hideContent(_ animated: Bool = false) {
        webView?.isUserInteractionEnabled = false
        if animated {
            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                self.webView?.alpha = 0.0
            })
        } else {
            webView?.alpha = 0.0
        }
    }
    
    func showContent(_ animated: Bool = false) {
        webView?.isUserInteractionEnabled = true
        if animated {
            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                self.webView?.alpha = 1.0
            })
        } else {
            webView?.alpha = 1.0
        }
    }
    
    func setScreenshot(_ screenshot: UIImage?, revUUID: Bool = true) {
        self.screenshot = screenshot
        if revUUID {
            self.screenshotUUID = UUID()
        }
    }
    
    func setNoImageMode(_ enabled: Bool = false, force: Bool) {
        if enabled || force {
            webView?.evaluateJavaScript("__firefox__.setNoImageMode(\(enabled))", completionHandler: nil)
        }
    }
    
    func setNightMode(_ enabled: Bool) {
        webView?.evaluateJavaScript("__firefox__.setNightMode(\(enabled))", completionHandler: nil)
    }
}

//Snackbar stuff
extension Tab {
    func addSnackbar(_ bar: SnackBar) {
        bars.append(bar)
        tabDelegate?.tab(self, didAddSnackbar: bar)
    }
    
    func removeSnackbar(_ bar: SnackBar) {
        if let index = bars.index(of: bar) {
            bars.remove(at: index)
            tabDelegate?.tab(self, didRemoveSnackbar: bar)
        }
    }
    
    func removeAllSnackbars() {
        // Enumerate backwards here because we'll remove items from the list as we go.
        for i in (0..<bars.count).reversed() {
            let bar = bars[i]
            removeSnackbar(bar)
        }
    }
    
    func expireSnackbars() {
        // Enumerate backwards here because we may remove items from the list as we go.
        for i in (0..<bars.count).reversed() {
            let bar = bars[i]
            if !bar.shouldPersist(self) {
                removeSnackbar(bar)
            }
        }
    }
}

extension Tab: TabWebViewDelegate {
    fileprivate func tabWebView(_ tabWebView: TabWebView, didSelectFindInPageForSelection selection: String) {
        tabDelegate?.tab(self, didSelectFindInPageForSelection: selection)
    }

}

extension Tab: CliqzWebViewDelegate {
    func didFinishLoadingRequest(request: NSURLRequest?) {
        //finished loading request
        self.url = request?.url
//        if let urlString = self.url?.absoluteString {
//            //self.navigateToState(.web(urlString))
//        }
        self.tabDelegate?.urlChangedForTab?(self)
    }
}

//extension Tab {
//
//    var canGoBack: Bool {
//        return (self.webView?.canGoBack)!//self.navigationHistory.canGoBack()
//    }
//
//    var canGoForward: Bool {
//        return (self.webView?.canGoForward)!//self.navigationHistory.canGoForward()
//    }
//
//}

private protocol TabWebViewDelegate: class {
    func tabWebView(_ tabWebView: TabWebView, didSelectFindInPageForSelection selection: String)
}

private class TabWebView: CliqzWebView, MenuHelperInterface {
	// Cliqz: renamed delegate to tab
    fileprivate weak var tabWebViewDelegate: TabWebViewDelegate?

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == MenuHelper.SelectorFindInPage {
            return true
        }
        return super.canPerformAction(action, withSender: sender)
    }

    @objc func menuHelperFindInPage() {
        evaluateJavaScript("getSelection().toString()") { result, _ in
            let selection = result as? String ?? ""
			// Cliqz renamed delegate
            self.tabWebViewDelegate?.tabWebView(self, didSelectFindInPageForSelection: selection)
        }
    }

    fileprivate override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // The find-in-page selection menu only appears if the webview is the first responder.
        becomeFirstResponder()

        return super.hitTest(point, with: event)
    }
}

private class HelperManager: NSObject, WKScriptMessageHandler {
    fileprivate var helpers = [String: TabHelper]()
    #if CLIQZ
    // Cliqz:[UIWebView] Type change
    private weak var webView: CliqzWebView?
    #else
    fileprivate weak var webView: WKWebView?
    #endif
    
    // Cliqz:[UIWebView] Type change
    #if CLIQZ
    init(webView: CliqzWebView) {
        self.webView = webView
    }
    #else
    init(webView: WKWebView) {
    self.webView = webView
    }
    #endif
    
    @objc func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        for helper in helpers.values {
            if let scriptMessageHandlerName = helper.scriptMessageHandlerName() {
                if scriptMessageHandlerName == message.name {
                    helper.userContentController(userContentController, didReceiveScriptMessage: message)
                    return
                }
            }
        }
    }
    
    func addHelper(_ helper: TabHelper, name: String) {
        if let _ = helpers[name] {
            assertionFailure("Duplicate helper added: \(name)")
        }
        
        helpers[name] = helper
        
        // If this helper handles script messages, then get the handler name and register it. The Browser
        // receives all messages and then dispatches them to the right TabHelper.
        if let scriptMessageHandlerName = helper.scriptMessageHandlerName() {
            webView?.configuration.userContentController.addScriptMessageHandler(self, name: scriptMessageHandlerName)
        }
    }
    
    func getHelper(_ name: String) -> TabHelper? {
        return helpers[name]
    }
}
