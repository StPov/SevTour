
import UIKit
import MapKit
import YandexMapKitSearch

class SearchTableViewController: UITableViewController {
    
    var mapView: YMKMapView?
    let searchManager = YMKSearch.sharedInstance().createSearchManager(with: .combined)
    let SEARCH_OPTIONS = YMKSearchOptions()
    var searchSession: YMKSearchSession?
    var matchingItems = [YMKGeoObjectCollectionItem]()
    
    // What this delegate is conforming to
    var handleMapSearchDelegate: HandleMapSearch?
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return matchingItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let selectedItem = matchingItems[indexPath.row]
        cell.textLabel?.text = selectedItem.obj?.name
        cell.detailTextLabel?.text = selectedItem.obj?.descriptionText

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let point = matchingItems[indexPath.row].obj?.geometry.first?.point {
            handleMapSearchDelegate?.createRoute(point: point)
        }
        
        dismiss(animated: true, completion: nil)
    }
}

extension SearchTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let responseHandler = {(searchResponse: YMKSearchResponse?, error: Error?) -> Void in
            if let response = searchResponse {
                self.onSearchResponse(response)
            } else {
                self.onSearchError(error!)
            }
        }
        
        let BOUNDING_BOX = YMKBoundingBox(
            southWest: (mapView?.mapWindow.focusRegion.bottomLeft)!,
            northEast: (mapView?.mapWindow.focusRegion.topRight)!)
        
        searchSession = searchManager.submit(
            withText: searchController.searchBar.text!,
            geometry: YMKGeometry(boundingBox: BOUNDING_BOX),
            searchOptions: YMKSearchOptions(),
            responseHandler: responseHandler)
    }
    
    func onSearchResponse(_ response: YMKSearchResponse) {
        matchingItems = response.collection.children
        tableView.reloadData()
    }
    
    func onSearchError(_ error: Error) {
        let searchError = (error as NSError).userInfo[YRTUnderlyingErrorKey] as! YRTError
        var errorMessage = "Unknown error"
        if searchError.isKind(of: YRTNetworkError.self) {
            errorMessage = "Network error"
        } else if searchError.isKind(of: YRTRemoteError.self) {
            errorMessage = "Remote server error"
        }
        
        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
}
