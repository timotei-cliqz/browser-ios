//
//  DashRemindersDataSource.swift
//  Client
//
//  Created by Tim Palade on 8/11/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class DashRemindersDataSource: ExpandableViewProtocol {
    
    static let identifier = "DashRemindersDataSource"
    
    weak var delegate: HasDataSource? = nil
    
    var reminders: [CIReminderManager.Reminder]
    
    init(delegate: HasDataSource? = nil) {
        self.delegate = delegate
        self.reminders = CIReminderManager.sharedInstance.allValidRemindersAscending()
        NotificationCenter.default.addObserver(self, selector: #selector(remindersUpdated), name: CIReminderManager.notification_update, object: nil)
    }
    
    func maxNumCells() -> Int {
        return self.reminders.count
    }
    
    func minNumCells() -> Int {
        return min(self.reminders.count, 2)
    }
    
    func title(indexPath: IndexPath) -> String {
        return reminders[indexPath.row]["title"] as? String ?? ""
    }
    
    func url(indexPath: IndexPath) -> String {
        return reminders[indexPath.row]["url"] as? String ?? ""
    }
    
    func picture(indexPath: IndexPath, completionBlock: @escaping (UIImage?, UIView?) -> Void) {
		LogoLoader.loadLogo(self.url(indexPath: indexPath)) { (image, logoInfo, error) in
			if let img = image {
				completionBlock(img, nil)
			} else {
				if let info = logoInfo {
					let logoPlaceholder = LogoPlaceholder.init(logoInfo: info)
					completionBlock(nil, logoPlaceholder)
				} else {
					completionBlock(nil, nil)
				}
			}
		}
	}

    func cellPressed(indexPath: IndexPath) {
        StateManager.shared.handleAction(action: Action(data: ["url": self.url(indexPath: indexPath)], type: .urlSelected))
    }
    
    @objc
    func remindersUpdated(_ notification: Notification) {
        updateReminders()
        delegate?.dataSourceWasUpdated(identifier: DashRemindersDataSource.identifier)
    }
    
    func updateReminders() {
        reminders = CIReminderManager.sharedInstance.allValidReminders()
    }
}
