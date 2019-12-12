//
//  Venue.swift
//  SevTour
//
//  Created by Stanislav Povolotskiy on 11.12.2019.
//  Copyright © 2019 Stanislav Povolotskiy. All rights reserved.
//

import Foundation

struct Venue: Codable {
    let id: String
    let name: String
    let location: Location
    let categories: [Category]
    let venuePage: String
    
}

