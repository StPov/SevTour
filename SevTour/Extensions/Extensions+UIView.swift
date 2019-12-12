//
//  Extensions+UIView.swift
//  SevTour
//
//  Created by Stanislav Povolotskiy on 12.12.2019.
//  Copyright © 2019 Stanislav Povolotskiy. All rights reserved.
//

import UIKit

extension UIView {
    func pinEdges(to other: UIView) {
        leadingAnchor.constraint(equalTo: other.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: other.trailingAnchor).isActive = true
        topAnchor.constraint(equalTo: other.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: other.bottomAnchor).isActive = true
    }
}
