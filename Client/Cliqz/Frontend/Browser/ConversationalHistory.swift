//
//  ConversationalHistory.swift
//  Client
//
//  Created by Sahakyan on 12/8/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import SnapKit
import Alamofire
import Shared

protocol HistoryProtocol: class{
    func numberOfCells() -> Int
    func urlLabelText(indexPath:NSIndexPath) -> String
    func titleLabelText(indexPath:NSIndexPath) -> String
    func timeLabelText(indexPath:NSIndexPath) -> String
    func baseUrl(indexPath:NSIndexPath) -> String
    func image(indexPath:NSIndexPath, completionBlock:(result:UIImage) -> Void)
}

class ConversationalHistory: UIViewController, UITableViewDataSource, UITableViewDelegate {
	
	var historyTableView: UITableView!
	let historyCellID = "HistoryCell"
    
    var dataSource: HistoryDataSource = HistoryDataSource()
    var first_appear:Bool = true
    
    var didPressCell:(tableView: UITableView, indexPath:NSIndexPath) -> () = { _ in }

	weak var delegate: BrowserNavigationDelegate?

	override func viewDidLoad() {
		super.viewDidLoad()
		self.historyTableView = UITableView(frame: CGRectZero, style: .Plain)
		self.view.addSubview(self.historyTableView)
		self.historyTableView.snp_makeConstraints { (make) in
			make.top.left.right.bottom.equalTo(self.view)
		}
		self.historyTableView.delegate = self
		self.historyTableView.dataSource = self
		self.historyTableView.registerClass(HistoryCell.self, forCellReuseIdentifier: historyCellID)
		self.historyTableView.tableFooterView = UIView()
		self.historyTableView.separatorStyle = .SingleLine
		self.historyTableView.separatorColor = UIColor.lightGrayColor()
	}

	override func viewWillDisappear(animated: Bool) {
        //dataSource.clean()
		self.navigationController?.navigationBarHidden = true
		super.viewWillDisappear(animated)
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.navigationBarHidden = true
//		self.backButton.hidden = true
        self.loadData()        
    }
    
    func loadData() {
        dataSource.loadData { (ready) in
            self.historyTableView.reloadData()
        }
    }

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dataSource.numberOfCells()
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
		let cell =  self.historyTableView.dequeueReusableCellWithIdentifier(self.historyCellID) as! HistoryCell
		cell.delegate = self
        cell.tag = indexPath.row
    
        cell.URLLabel.text   = dataSource.urlLabelText(indexPath)
        cell.titleLabel.text = dataSource.titleLabelText(indexPath)
        dataSource.image(indexPath) { (result) in
            if cell.tag == indexPath.row{
                cell.logoButton.setImage(result, forState: .Normal)
            }
        }

		cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		cell.accessoryType = .DisclosureIndicator
		cell.selectionStyle = .None
		return cell
	}
	
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 70
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let vc = ConversationalHistoryDetails()
        vc.delegate = self.delegate
        
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! HistoryCell
        if indexPath.row == 0 {
            //news
            if NewsDataSource.sharedInstance.ready{
                let datasource = CliqzNewsDetailsDataSource(image:cell.logoButton.imageView?.image, articles: NewsDataSource.sharedInstance.articles)
                vc.dataSource = datasource
            }
        }
        else{
            let key = dataSource.domains[indexPath.row]
            let value = dataSource.domainsInfo.valueForKey(key) as! NSDictionary
            vc.dataSource = CliqzHistoryDetailsDataSource(images: cell.logoButton.imageView?.image, visits: value.valueForKey("visits") as? NSArray ?? NSArray(), baseUrl: value.valueForKey("baseUrl") as? String ?? "")
        }
        
		self.navigationController?.pushViewController(vc, animated: false)
	}
	
	@objc private func goBack() {
		self.navigationController?.popViewControllerAnimated(false)
	}

}

extension ConversationalHistory: HistoryActionDelegate {
	func didSelectLogo(atIndex index: Int) {
        if index == 0{
            //pressed on the cliqz news logo
        }
        else{
            let key = dataSource.domains[index]
            if let value = dataSource.domainsInfo.valueForKey(key) as? NSDictionary,
                baseURL = value.valueForKey("baseUrl") as? String,
                url = NSURL(string: baseURL) {
                self.delegate?.navigateToURL(url)
            }
        }
	}
}

//extension ConversationalHistory: KeyboardHelperDelegate {
//	func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
//		updateViewConstraints()
//		
//	}
//	
//	func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
//		updateViewConstraints()
//	}
//	
//	func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {
//	}
//}

protocol HistoryActionDelegate: class {
	func didSelectLogo(atIndex index: Int)
}

class HistoryCell: UITableViewCell {
	let titleLabel = UILabel()
	let URLLabel = UILabel()
	let logoButton = UIButton() //UIImageView()

	weak var delegate: HistoryActionDelegate?

	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.contentView.addSubview(titleLabel)
		titleLabel.font = UIFont.systemFontOfSize(14, weight: UIFontWeightMedium)
		titleLabel.textColor = UIColor.lightGrayColor()
		titleLabel.backgroundColor = UIColor.clearColor()
		titleLabel.textAlignment = .Left
		self.contentView.addSubview(URLLabel)
		URLLabel.font = UIFont.systemFontOfSize(18, weight: UIFontWeightMedium)
		URLLabel.textColor = UIColor.blackColor() //UIColor(rgb: 0x77ABE6)
		URLLabel.backgroundColor = UIColor.clearColor()
		URLLabel.textAlignment = .Left
		self.contentView.addSubview(logoButton)
		logoButton.layer.cornerRadius = 20
		logoButton.clipsToBounds = true
		self.logoButton.addTarget(self, action: #selector(logoPressed), forControlEvents: .TouchUpInside)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		self.logoButton.snp_remakeConstraints { (make) in
			make.left.equalTo(self.contentView).offset(10)
			make.centerY.equalTo(self.contentView)
			make.width.equalTo(40)
			make.height.equalTo(40)
		}
		self.URLLabel.snp_remakeConstraints { (make) in
			make.top.equalTo(self.contentView).offset(15)
			make.left.equalTo(self.logoButton.snp_right).offset(15)
			make.height.equalTo(20)
			make.right.equalTo(self.contentView).offset(40)
		}
		self.titleLabel.snp_remakeConstraints { (make) in
			make.top.equalTo(self.URLLabel.snp_bottom).offset(5)
			make.left.equalTo(self.URLLabel.snp_left)
			make.height.equalTo(20)
			make.right.equalTo(self.contentView).offset(40)
		}
	}
	
	@objc private func logoPressed() {
		self.delegate?.didSelectLogo(atIndex: self.tag)
	}
	
}
