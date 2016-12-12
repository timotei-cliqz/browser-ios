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
	
	weak var delegate: BrowserNavigationDelegate?

	var detaildHistory: NSDictionary! {
		didSet {
			self.urls = detaildHistory.valueForKey("urls") as! NSDictionary
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
		self.historyTableView.tableFooterView = UIView()
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "cliqzBack"), style: .Plain, target: self, action: #selector(goBack))

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
		let key = self.urls.allKeys[indexPath.row] as! String
		let value = self.urls.valueForKey(key) as! NSDictionary
		cell.URLLabel.text = key
		if let timeinterval = value.valueForKey("lastVisitedAt") as? NSNumber {
			let x = NSDate.fromMicrosecondTimestamp(timeinterval.unsignedLongLongValue)
			cell.titleLabel.text = x.toRelativeTimeString()
		}
		return cell
	}
	
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 60
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
		header.addSubview(logo)
		logo.snp_remakeConstraints { (make) in
			make.left.top.equalTo(header)
			make.width.height.equalTo(40)
		}
		logo.image = UIImage(named: "coolLogo")
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
		let key = self.urls.allKeys[indexPath.row] as! String
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
		titleLabel.font = UIFont.systemFontOfSize(12, weight: UIFontWeightMedium)
		titleLabel.textColor = UIColor.blackColor()
		titleLabel.backgroundColor = UIColor.clearColor()
		self.contentView.addSubview(URLLabel)
		URLLabel.font = UIFont.systemFontOfSize(12, weight: UIFontWeightMedium)
		URLLabel.textColor = UIColor(rgb: 0x77ABE6)
		URLLabel.backgroundColor = UIColor.clearColor()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func layoutSubviews() {
		self.URLLabel.snp_remakeConstraints { (make) in
			make.top.equalTo(self.contentView).offset(10)
			make.left.equalTo(self.contentView).offset(10)
			make.height.equalTo(20)
			make.right.equalTo(self.contentView)
		}
		self.titleLabel.snp_remakeConstraints { (make) in
			make.top.equalTo(self.URLLabel.snp_bottom)
			make.left.equalTo(self.contentView).offset(10)
			make.height.equalTo(20)
			make.right.equalTo(self.contentView)
		}
	}
	
}
