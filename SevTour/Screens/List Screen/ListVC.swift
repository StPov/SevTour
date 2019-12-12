//
//  ListVC.swift
//  SevTour
//
//  Created by Stanislav Povolotskiy on 10.12.2019.
//  Copyright © 2019 Stanislav Povolotskiy. All rights reserved.
//

import UIKit

class ListVC: UICollectionViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = .red
        setLargeTitle(title: "City Infrastructure", isOn: true)
    }
    
}
