//
//  Extensions+UIViewController.swift
//  SevTour
//
//  Created by Stanislav Povolotskiy on 11.12.2019.
//  Copyright © 2019 Stanislav Povolotskiy. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func setLargeTitle(title str: String, isOn option: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = option
        title = str
    }
    
}
