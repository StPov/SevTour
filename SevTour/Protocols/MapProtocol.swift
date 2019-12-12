//
//  MapProtocol.swift
//  SevTour
//
//  Created by Stanislav Povolotskiy on 12.12.2019.
//  Copyright © 2019 Stanislav Povolotskiy. All rights reserved.
//

import Foundation
import YandexMapKit

// Protocol for dropping a pin at a specified place
protocol HandleMapSearch {
    func createRoute(point: YMKPoint)
}
