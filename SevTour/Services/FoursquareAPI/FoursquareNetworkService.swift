//
//  NetworkDataService.swift
//  SevTour
//
//  Created by Stanislav Povolotskiy on 11.12.2019.
//  Copyright © 2019 Stanislav Povolotskiy. All rights reserved.
//

import Foundation

class FoursquareNetworkService {

    let clientId = "H3YG4HRR0JJXGI4TY2CYK1UYIFEQKX5ETSURN0HH3JL1KWRT"
    let clientSecret = "LJK3UZEC1SKFI4TEN43AS1CM1QOKO2FHZ5UQ0CCDJH5LDQHR"
    let v = String(20190101)

//get venue categories
    func fetchVenueCategories(completion: @escaping (Data?, Error?) -> Void) {
        let parameters = self.prepareCategoriesParams()
        let url = venueCategoriesUrl(params: parameters)
        var request = URLRequest(url: url)
        request.httpMethod = "get"
        
        let task = createDataTask(from: request, completion: completion)
        task.resume()
    }
    
//search for venues
    func fetchSearchedVenue(searchTerm: String, userLocation: String, completion: @escaping (Data?, Error?) -> Void) {
        let parameters = self.prepareSearchParams(searchTerm: searchTerm, userLocation: userLocation)
        let url = venueSearchUrl(params: parameters)
        var request = URLRequest(url: url)
        request.httpMethod = "get"
        
        let task = createDataTask(from: request, completion: completion)
        task.resume()
    }
    
//get details of a venue
    func fetchVenueDetails(venueId: Int, completion: @escaping (Data?, Error?) -> Void) {
        let parameters = self.prepareDetailsParams()
        let url = venueDetailsUrl(params: parameters, venueId: venueId)
        var request = URLRequest(url: url)
        request.httpMethod = "get"
        
        let task = createDataTask(from: request, completion: completion)
        task.resume()
    }
    
//get venue recommendations
    func fetchVenueRecommendations(searchItem: String, userLocation: String, isOpenNow: Bool, completion: @escaping (Data?, Error?) -> Void) {
        let parameters = self.prepareRecommendationParams(searchItem: searchItem, userLocation: userLocation, isOpenNow: isOpenNow)
        let url = venueRecommendationUrl(params: parameters)
        var request = URLRequest(url: url)
        request.httpMethod = "get"
        
        let task = createDataTask(from: request, completion: completion)
        task.resume()
    }
    
//get venue`s photos
    func fetchVenuePhotos(venueId: Int, completion: @escaping (Data?, Error?) -> Void) {
        let parameters = self.preparePhotoParams()
        let url = venuePhotoUrl(params: parameters, venueId: venueId)
        var request = URLRequest(url: url)
        request.httpMethod = "get"
        
        let task = createDataTask(from: request, completion: completion)
        task.resume()
    }
    
//get venue`s hours
    func fetchVenueHours(venueId: Int, completion: @escaping (Data?, Error?) -> Void) {
        let parameters = self.prepareHoursParams()
        let url = venueHoursUrl(params: parameters, venueId: venueId)
        var request = URLRequest(url: url)
        request.httpMethod = "get"
        
        let task = createDataTask(from: request, completion: completion)
        task.resume()
    }
    
//get trending venues
    func fetchTrendingVenues(userLocation: String, completion: @escaping (Data?, Error?) -> Void) {
        let parameters = self.prepareTrendingParams(userLocation: userLocation)
        let url = trendingVenueUrl(params: parameters)
        var request = URLRequest(url: url)
        request.httpMethod = "get"
        
        let task = createDataTask(from: request, completion: completion)
        task.resume()
        
    }
    
//get similar venues
    func fetchSimilarVenues(venueId: Int, completion: @escaping (Data?, Error?) -> Void) {
        let parameters = self.prepareSimilarParams()
        let url = venueSimilarUrl(params: parameters, venueId: venueId)
        var request = URLRequest(url: url)
        request.httpMethod = "get"
        
        let task = createDataTask(from: request, completion: completion)
        task.resume()
    }
    
//get suggested next venue
    func fetchNextVenue(venueId: Int, completion: @escaping (Data?, Error?) -> Void) {
        let parameters = self.prepareNextParams()
        let url = venueNextUrl(params: parameters, venueId: venueId)
        var request = URLRequest(url: url)
        request.httpMethod = "get"
        
        let task = createDataTask(from: request, completion: completion)
        task.resume()
    }
    
//MARK:- Building Categories Request
    private func venueCategoriesUrl(params: [String: String]) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.foursquare.com"
        components.path = "/v2/venues/categories"
        components.queryItems = params.map { URLQueryItem(name: $0, value: $1) }
        
        return components.url!
    }
    
    private func prepareCategoriesParams() -> [String: String] {
        var parameters = [String: String]()
        parameters["client_id"] = clientId
        parameters["client_secret"] = clientSecret
        parameters["v"] = v
        
        return parameters
    }
    
//MARK:- Building Search Venues Request
    private func venueSearchUrl(params: [String: String]) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.foursquare.com"
        components.path = "/v2/venues/search"
        components.queryItems = params.map { URLQueryItem(name: $0, value: $1) }
        
        return components.url!
    }
    
    private func prepareSearchParams(searchTerm: String, userLocation: String) -> [String: String] {
        var parameters = [String: String]()
        parameters["client_id"] = clientId
        parameters["client_secret"] = clientSecret
        parameters["v"] = v
        parameters["ll"] = userLocation
        parameters["radius"] = String(2000)
        parameters["query"] = searchTerm
        parameters["limit"] = String(30)
        
        return parameters
    }
    
//MARK:- Building Venue Details Request
    private func venueDetailsUrl(params: [String: String], venueId: Int) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.foursquare.com"
        components.path = "/v2/venues/\(venueId)"
        components.queryItems = params.map { URLQueryItem(name: $0, value: $1) }
        
        return components.url!
    }
    
    private func prepareDetailsParams() -> [String: String] {
        var parameters = [String: String]()
        parameters["client_id"] = clientId
        parameters["client_secret"] = clientSecret
        parameters["v"] = v
        
        return parameters
    }
    
//MARK:- Building Venue Recommendation Request
    private func venueRecommendationUrl(params: [String: String]) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.foursquare.com"
        components.path = "/v2/venues/explore"
        components.queryItems = params.map { URLQueryItem(name: $0, value: $1) }
        
        return components.url!
    }
    
    private func prepareRecommendationParams(searchItem: String, userLocation: String, isOpenNow: Bool) -> [String: String] {
        var parameters = [String: String]()
        parameters["client_id"] = clientId
        parameters["client_secret"] = clientSecret
        parameters["v"] = v
        parameters["query"] = searchItem
        parameters["ll"] = userLocation
        parameters["limit"] = String(30)
        parameters["openNow"] = isOpenNow ? "1" : "0"
        
        return parameters
    }
    
//MARK:- Building Venue Photo Request
    private func venuePhotoUrl(params: [String: String], venueId: Int) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.foursquare.com"
        components.path = "/v2/venues/\(venueId)/photos"
        components.queryItems = params.map { URLQueryItem(name: $0, value: $1) }
        
        return components.url!
    }
    
    private func preparePhotoParams() -> [String: String] {
        var parameters = [String: String]()
        parameters["client_id"] = clientId
        parameters["client_secret"] = clientSecret
        parameters["v"] = v
        parameters["group"] = "venue"
        parameters["limit"] = String(10)
        
        return parameters
    }
    
//MARK:- Building Venue Hours Request
    private func venueHoursUrl(params: [String: String], venueId: Int) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.foursquare.com"
        components.path = "/v2/venues/\(venueId)/hours"
        components.queryItems = params.map { URLQueryItem(name: $0, value: $1) }
        
        return components.url!
    }
    
    private func prepareHoursParams() -> [String: String] {
        var parameters = [String: String]()
        parameters["client_id"] = clientId
        parameters["client_secret"] = clientSecret
        parameters["v"] = v
        
        return parameters
    }
    
//MARK:- Building Trending Venues Request
    private func trendingVenueUrl(params: [String: String]) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.foursquare.com"
        components.path = "/v2/venues/trending"
        components.queryItems = params.map { URLQueryItem(name: $0, value: $1) }
        
        return components.url!
    }
    
    private func prepareTrendingParams(userLocation: String) -> [String: String] {
        var parameters = [String: String]()
        parameters["client_id"] = clientId
        parameters["client_secret"] = clientSecret
        parameters["v"] = v
        parameters["ll"] = userLocation
        parameters["radius"] = String(4000)
        parameters["limit"] = String(30)
        
        return parameters
    }
    
//MARK:- Building Similar Venues Request
    private func venueSimilarUrl(params: [String: String], venueId: Int) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.foursquare.com"
        components.path = "/v2/venues/\(venueId)/similar"
        components.queryItems = params.map { URLQueryItem(name: $0, value: $1) }
        
        return components.url!
    }
    
    private func prepareSimilarParams() -> [String: String] {
        var parameters = [String: String]()
        parameters["client_id"] = clientId
        parameters["client_secret"] = clientSecret
        parameters["v"] = v
        
        return parameters
    }
    
//MARK:- Building Next Venue Request
    private func venueNextUrl(params: [String: String], venueId: Int) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.foursquare.com"
        components.path = "/v2/venues/\(venueId)/nextvenues"
        components.queryItems = params.map { URLQueryItem(name: $0, value: $1) }
        
        return components.url!
    }
    
    private func prepareNextParams() -> [String: String] {
        var parameters = [String: String]()
        parameters["client_id"] = clientId
        parameters["client_secret"] = clientSecret
        parameters["v"] = v
        
        return parameters
    }
    
    
    
    private func createDataTask(from request: URLRequest, completion: @escaping (Data?, Error?) -> Void) -> URLSessionDataTask {
        return URLSession.shared.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                completion(data, error)
            }
        }
    }
    
}
