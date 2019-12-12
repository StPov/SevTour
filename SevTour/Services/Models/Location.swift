//
//  Location.swift
//  SevTour
//
//  Created by Stanislav Povolotskiy on 11.12.2019.
//  Copyright © 2019 Stanislav Povolotskiy. All rights reserved.
//

import Foundation

struct Location: Codable {
    let address: String
    let lat: Double
    let lng: Double
    let distance: String
    let formattedAddress: [String]
    
}
