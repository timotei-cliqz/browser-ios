//
//  CliqzURLBarView.swift
//  Client
//
//  Created by Sahakyan on 8/25/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit
import SnapKit

class CliqzURLBarView: URLBarView {

	private let antitrackingBackgroundColor = UIColor(rgb: 0x2CBA84)
	private let antitrackingButtonSize = CGSizeMake(42, CGFloat(URLBarViewUX.LocationHeight))
	
	private lazy var antitrackingButton: UIButton = {
		let button = UIButton(type: .Custom)
		button.setTitle("0", forState: .Normal)
		button.titleLabel?.font = UIFont.systemFontOfSize(12)
		button.backgroundColor = self.antitrackingBackgroundColor
		return button
	}()
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}

	override func updateConstraints() {
		super.updateConstraints()
		if !antitrackingButton.hidden {
			locationContainer.snp_updateConstraints { make in
				let x = -(UIConstants.ToolbarHeight + 10)
				make.trailing.equalTo(self).offset(x)
			}
			self.antitrackingButton.snp_updateConstraints(closure: { (make) in
				make.size.equalTo(self.antitrackingButtonSize)
			})
			if self.antitrackingButton.backgroundColor != UIColor.clearColor() && self.antitrackingButton.bounds.size != CGSizeZero {
				self.antitrackingButton.addRoundedCorners(cornersToRound: [.TopRight, .BottomRight], cornerRadius: CGSizeMake(URLBarViewUX.TextFieldCornerRadius, URLBarViewUX.TextFieldCornerRadius), color: self.antitrackingBackgroundColor)
			}
		} else {
			self.antitrackingButton.snp_updateConstraints(closure: { (make) in
				make.size.equalTo(CGSizeMake(0, 0))
			})
		}
	}

	func updateTrackersCount(count: Int) {
		self.antitrackingButton.setTitle("\(count)", forState: .Normal)
		self.setNeedsDisplay()
	}

	func showAntitrackingButton(hidden: Bool) {
		self.antitrackingButton.hidden = !hidden
		self.setNeedsUpdateConstraints()
	}

	func enableAntitrackingButton(enable: Bool) {
		self.antitrackingButton.enabled = enable
	}

	internal lazy var historyBackButton: UIButton = {
		let btn = UIButton(type: .Custom)
		let img = UIImage(named: "cliqzBack")
		btn.setImage(img, forState: .Normal)
		return btn
	}()
	
	func showHistoryBackButton(hidden: Bool) {
		self.historyBackButton.hidden = !hidden
		self.setNeedsUpdateConstraints()
	}

	private func commonInit() {
		
		let img = UIImage(named: "shieldButton")
		self.antitrackingButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
		self.antitrackingButton.setImage(img, forState: .Normal)
		self.antitrackingButton.titleEdgeInsets = UIEdgeInsets(top: 5, left: 2, bottom: 5, right: 0)
		self.antitrackingButton.imageEdgeInsets = UIEdgeInsets(top: 4, left: 5, bottom: 4, right: 20)
		self.antitrackingButton.addTarget(self, action: #selector(antitrackingButtonPressed), forControlEvents: .TouchUpInside)
		self.antitrackingButton.hidden = true
		addSubview(self.antitrackingButton)
		addSubview(self.historyBackButton)
		antitrackingButton.snp_makeConstraints { make in
			make.centerY.equalTo(self.locationContainer)
			make.leading.equalTo(self.locationContainer.snp_trailing)
			make.size.equalTo(self.antitrackingButtonSize)
		}
		
		historyBackButton.snp_makeConstraints { make in
			make.centerY.equalTo(self.locationContainer)
			make.left.equalTo(self)
			make.size.equalTo(UIConstants.ToolbarHeight)
		}

	}
	
	@objc private func antitrackingButtonPressed(sender: UIButton) {
		self.delegate?.urlBarDidClickAntitracking(self)
	}
}
