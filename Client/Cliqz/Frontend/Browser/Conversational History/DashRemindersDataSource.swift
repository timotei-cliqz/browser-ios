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
    
    init(delegate: HasDataSource) {
        self.delegate = delegate
        self.reminders = CIReminderManager.sharedInstance.allValidReminders()
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
    
    func picture(indexPath: IndexPath, completionBlock: @escaping (UIImage?) -> Void) {
        LogoLoader.loadLogoImageOrFakeLogo(self.url(indexPath: indexPath), completed: { (image, fakeLogo, error) in
            if let img = image{
                completionBlock(img)
            }
            else{
                //completionBlock(result: UIImage(named: "coolLogo") ?? UIImage())
                completionBlock(nil)
            }
        })
    }
    
    func cellPressed(indexPath: IndexPath) {
        Router.shared.action(action: Action(data: ["url": self.url(indexPath: indexPath)], type: .urlSelected, context: .dashRemindersDS))
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
