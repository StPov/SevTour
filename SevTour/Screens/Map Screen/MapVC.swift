//
//  SecondVC.swift
//  SevTour
//
//  Created by Stanislav Povolotskiy on 09.12.2019.
//  Copyright © 2019 Stanislav Povolotskiy. All rights reserved.
//

import UIKit
import Foundation
import YandexMapKit

class MapVC: UIViewController {
    @IBOutlet weak var mapView: YMKMapView!
    
    let TARGET_LOCATION = YMKPoint(latitude: 44.6054434, longitude: 33.5220842)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemPink
        
//        mapView.mapWindow.map.move(
//            with: YMKCameraPosition(target: TARGET_LOCATION, zoom: 15, azimuth: 0, tilt: 0),
//            animationType: YMKAnimation(type: YMKAnimationType.smooth, duration: 5),
//            cameraCallback: nil)
    }
}
