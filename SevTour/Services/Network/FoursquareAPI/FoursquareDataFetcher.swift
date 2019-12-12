//
//  NetworkDataFetcher.swift
//  SevTour
//
//  Created by Stanislav Povolotskiy on 11.12.2019.
//  Copyright © 2019 Stanislav Povolotskiy. All rights reserved.
//

import Foundation
//отвечает за преобразование JSON-объекта в необходимую модель
class FoursquareDataFetcher {
    
    var service = FoursquareNetworkService()
    
    func fetchCategories(completion: @escaping (Category?) -> Void) {
        service.fetchVenueCategories { (data, error) in
            if let error = error {
                print(error.localizedDescription)
                completion(nil)
            }
            let decode = self.decodeJSON(type: Category.self, from: data)
            completion(decode)
        }
    }
    
    func decodeJSON<T: Decodable>(type: T.Type, from: Data?) -> T? {
        let decoder = JSONDecoder()
        guard let data = from else { return nil }
        print(data)
        do {
            let objects = try decoder.decode(type, from: data)
            return objects
        } catch {
            print("Failed to decode JSON: \(error)")
            return nil
        }
    }
    
}
