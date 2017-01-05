//
//  ConversationalHistoryDetails.swift
//  Client
//
//  Created by Sahakyan on 12/8/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class ConversationalHistoryDetails: UIViewController, UITableViewDataSource, UITableViewDelegate {
	
	var historyTableView: UITableView!
	let historyCellID = "HistoryCell"
	var sortedURLs = [String]()

	weak var delegate: BrowserNavigationDelegate?

	var detaildHistory: NSDictionary! {
		didSet {
			if let d = detaildHistory.valueForKey("urls") as? NSDictionary {
				 self.sortedURLs = d.keysSortedByValueUsingComparator({ (a, b) -> NSComparisonResult in
					if let x = a as? [String: AnyObject],
							y = b as? [String: AnyObject] {
						if let sort1 = x["sort"] as? NSNumber,
							sort2 = y["sort"] as? NSNumber {
							if sort1.doubleValue > sort2.doubleValue {
								return NSComparisonResult.OrderedAscending
							}
							return NSComparisonResult.OrderedDescending
						}
					}
					return NSComparisonResult.OrderedSame
				}) as! [String]
			}
			self.urls = detaildHistory.valueForKey("urls") as? NSDictionary
		}
	}
	
	private var urls: NSDictionary!

	override func viewDidLoad() {
		super.viewDidLoad()
		self.historyTableView = UITableView(frame: CGRectZero, style: .Plain)
		self.view.addSubview(self.historyTableView)
		self.historyTableView.snp_makeConstraints { (make) in
			make.top.left.right.bottom.equalTo(self.view)
		}
		self.historyTableView.delegate = self
		self.historyTableView.dataSource = self
		self.historyTableView.registerClass(HistoryDetailCell.self, forCellReuseIdentifier: historyCellID)
		self.historyTableView.separatorStyle = .None

//		self.historyTableView.tableFooterView = UIView()


	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.navigationBarHidden = true
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let data = self.urls {
			return data.allKeys.count
		}
		return 0
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell =  self.historyTableView.dequeueReusableCellWithIdentifier(self.historyCellID) as! HistoryDetailCell
		let key = self.sortedURLs[indexPath.row]
		let value = self.urls.valueForKey(key) as! NSDictionary
		cell.URLLabel.text = key
		if let timeinterval = value.valueForKey("lastVisitedAt") as? NSNumber {
			let x = NSDate(timeIntervalSince1970: timeinterval.doubleValue)
			cell.titleLabel.text = x.toRelativeTimeString()
		}
		cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		cell.selectionStyle = .None
		cell.accessoryType = .DisclosureIndicator

		return cell
	}
	
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 80
	}
	
	func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 80
	}
	
	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let header = UIView()
		let title = UILabel()
		title.numberOfLines = 0
		header.addSubview(title)
		let logo = UIImageView()
		logo.layer.cornerRadius = 20
		logo.clipsToBounds = true
		header.addSubview(logo)
		logo.snp_remakeConstraints { (make) in
			make.left.equalTo(header).offset(15)
			make.top.equalTo(header).offset(20)
			make.width.equalTo(40)
			make.height.equalTo(40)
		}
//		logo.image = UIImage(named: "coolLogo")
		if let url = self.detaildHistory.objectForKey("baseUrl") as? String {
			logo.loadLogo(forDomain: url) { (view) in
				if view != nil {
					logo.image = UIImage(named: "coolLogo")
				}
			}
		} else {
			logo.image = UIImage(named: "coolLogo")
		}

		title.snp_remakeConstraints { (make) in
			make.top.right.bottom.equalTo(header)
			make.left.equalTo(logo.snp_right).offset(10)
		}
		if let snippet = self.detaildHistory.valueForKey("snippet") as? NSDictionary,
		 titleTxt = snippet.valueForKey("title") as? String {
			title.text = titleTxt
		}
		return header
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let key = self.sortedURLs[indexPath.row]
		if let url = NSURL(string: key) {
			self.navigationController?.popViewControllerAnimated(false)
			self.delegate?.navigateToURL(url)
		}
	}
	
	@objc private func goBack() {
		self.navigationController?.popViewControllerAnimated(false)
	}
}

class HistoryDetailCell: UITableViewCell {
	let titleLabel = UILabel()
	let URLLabel = UILabel()
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.contentView.addSubview(titleLabel)
		titleLabel.font = UIFont.systemFontOfSize(14, weight: UIFontWeightMedium)
		titleLabel.textColor = UIColor.lightGrayColor()
		titleLabel.backgroundColor = UIColor.clearColor()
		self.contentView.addSubview(URLLabel)
		URLLabel.font = UIFont.systemFontOfSize(18, weight: UIFontWeightMedium)
		URLLabel.textColor = UIColor.blackColor() //UIColor(rgb: 0x77ABE6)
		URLLabel.backgroundColor = UIColor.clearColor()
		URLLabel.textAlignment = .Left
		let sep = UIView()
		self.addSubview(sep)
		sep.snp_makeConstraints { (make) in
			make.left.right.bottom.equalTo(self)
			make.height.equalTo(1)
		}
		sep.backgroundColor = UIColor.darkGrayColor()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func layoutSubviews() {
		self.URLLabel.snp_remakeConstraints { (make) in
			make.top.equalTo(self.contentView).offset(15)
			make.left.equalTo(self.contentView).offset(10)
			make.height.equalTo(20)
			make.right.equalTo(self.contentView)
		}
		self.titleLabel.snp_remakeConstraints { (make) in
			make.top.equalTo(self.URLLabel.snp_bottom)
			make.left.equalTo(self.contentView).offset(10)
			make.bottom.equalTo(self.contentView).offset(-5)
			make.right.equalTo(self.contentView)
		}
	}
	
}
