//
//  Category.swift
//  SevTour
//
//  Created by Stanislav Povolotskiy on 11.12.2019.
//  Copyright © 2019 Stanislav Povolotskiy. All rights reserved.
//

import Foundation

struct Category: Codable {
    let categoryId: String
    let name: String
    let categories: [Category]
    
    private enum CodingKeys: String, CodingKey {
        case categoryId = "id"
        case name
        case categories
    }
}
