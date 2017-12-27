//
//  PortraitFlowLayout.swift
//  TabsRedesign
//
//  Created by Tim Palade on 3/29/17.
//  Copyright © 2017 Tim Palade. All rights reserved.
//

import UIKit

class PortraitFlowLayout: UICollectionViewFlowLayout {
    
    var currentCount: Int = 0
    var currentTransform: CATransform3D = CATransform3DIdentity
    
    override init() {
        super.init()
        self.minimumInteritemSpacing = UIScreen.main.bounds.size.width
        self.minimumLineSpacing = 0.0
        self.scrollDirection = .vertical
        self.sectionInset = UIEdgeInsetsMake(16, 0, 0, 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
