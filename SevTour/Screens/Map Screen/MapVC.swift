
import UIKit
import MapKit
import YandexMapKit
import YandexRuntime
import YandexMapKitTransport

class MapVC: UIViewController {

    
    @IBOutlet weak var yMapView: YMKMapView!
    var walkSession: YMKMasstransitSession?
    
    let locationManager = CLLocationManager()
    var routeCoordinates = [CLLocationCoordinate2D]()
    var destinationPoint = CLLocationCoordinate2D()
    
    var resultSearchController: UISearchController?
    
    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var orientedToTrueNorth: UISwitch!
    
    
    @IBOutlet weak var bottomLayoutConstraint: NSLayoutConstraint!
    
    var initialTouchPoint: CGPoint = CGPoint(x: 0,y: 0)
    var initialDetailViewPositionY: CGFloat!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //add panGesture to Detail View
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureHandler(_:)))
        detailView.addGestureRecognizer(panGesture)
        
        // Configuring Detail View
        initialDetailViewPositionY = detailView.frame.origin.y
        detailView.layer.cornerRadius = 15
        bottomLayoutConstraint.constant = -200
        
        // Configuring location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 2
        locationManager.requestWhenInUseAuthorization()
        
        // start location manager to get current position
        locationManager.startUpdatingLocation()
        
        // Configure location search table view controller
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "searchTableViewController") as! SearchTableViewController
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        locationSearchTable.handleMapSearchDelegate = self
        
        // Configure search bar
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        navigationItem.titleView = resultSearchController?.searchBar
        
        // Configure result search controller
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.obscuresBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        //config Y.maps
        confugureYandexMap()
        locationSearchTable.mapView = yMapView
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        self.navigationController!.isNavigationBarHidden = false
    }
    
    @objc func panGestureHandler(_ sender: UIPanGestureRecognizer) {
        let touchPoint = sender.location(in: detailView.window)
        print("touchPoint \(touchPoint)")
        if sender.state == UIGestureRecognizer.State.began {
            self.initialTouchPoint = touchPoint
        } else if sender.state == UIGestureRecognizer.State.changed {
            if touchPoint.y - self.initialTouchPoint.y > 0 {
                print("touchPoint.y - self.initialTouchPoint.y \(touchPoint.y - self.initialTouchPoint.y)")
                detailView.frame = CGRect(x: detailView.frame.origin.x,
                                          y: self.initialDetailViewPositionY + (touchPoint.y - self.initialTouchPoint.y),
                                          width: self.detailView.frame.size.width,
                                          height: self.detailView.frame.size.height)
            }
        } else if sender.state == UIGestureRecognizer.State.ended || sender.state == UIGestureRecognizer.State.cancelled {
            if touchPoint.y - self.initialTouchPoint.y > 40 {
                self.closeDetailView()
            } else {
                UIView.animate(withDuration: 0.3, animations: {
                    self.detailView.frame = CGRect(x: self.detailView.frame.origin.x,
                                                   y: self.initialDetailViewPositionY,
                                                   width: self.detailView.frame.size.width,
                                                   height: self.detailView.frame.size.height)
                })
            }
        }
    }

    
    //MARK: - Y.map conf
    func confugureYandexMap() {
        let map = yMapView.mapWindow.map
        //map.isNightModeEnabled = true
        map.isRotateGesturesEnabled = true
        
//        let scale = UIScreen.main.scale
        let mapKit = YMKMapKit.sharedInstance()!
        let userLocationLayer = mapKit.createUserLocationLayer(with: yMapView.mapWindow)

        userLocationLayer.setVisibleWithOn(true)
//        userLocationLayer.isHeadingEnabled = true
//        userLocationLayer.setAnchorWithAnchorNormal(
//            CGPoint(x: 0.5 * yMapView.frame.size.width * scale, y: 0.5 * yMapView.frame.size.height * scale),
//            anchorCourse: CGPoint(x: 0.5 * yMapView.frame.size.width * scale, y: 0.83 * yMapView.frame.size.height * scale))
        userLocationLayer.setObjectListenerWith(self)
    }
    
    
    //MARK: - get direction
    func calculateRoute(from source: YMKPoint, to destination: YMKPoint) {
        let requestPoints : [YMKRequestPoint] = [
            YMKRequestPoint(point: source, type: .waypoint, pointContext: nil),
            YMKRequestPoint(point: destination, type: .waypoint, pointContext: nil),
            ]
        
        let responseHandler = {(routesResponse: [YMKMasstransitRoute]?, error: Error?) -> Void in
            if let routes = routesResponse {
                self.onRoutesReceived(routes)
            } else {
                self.onRoutesError(error!)
            }
        }
        
        let walkRouter = YMKTransport.sharedInstance()?.createPedestrianRouter()
        
        walkSession = walkRouter?.requestRoutes(
            with: requestPoints,
            timeOptions: YMKTimeOptions(),
            routeHandler: responseHandler)
    }
    
    func onRoutesReceived(_ routes: [YMKMasstransitRoute]) {
        if let route = routes.first {
            let mapObjects = yMapView.mapWindow.map.mapObjects
            mapObjects.addPolyline(with: route.geometry)
            
            for point in route.geometry.points {
                routeCoordinates.append(CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude))
            }
            
            print(route.metadata.weight.time.value)
            print(route.metadata.weight.walkingDistance.value)
            
            
            let (h,m,_) = self.secondsToHoursMinutesSeconds(seconds: Int(route.metadata.weight.time.value))
            if h == 0 {
                self.timeLabel.text = "\(Int(m)) min"
            } else {
                self.timeLabel.text = "\(Int(h)) hr \(Int(m)) min"
            }
            
            let km = String(format: "%.2f", route.metadata.weight.walkingDistance.value / 1000)
            self.distanceLabel.text = km + " km"
            
            self.showDetailView()
        }
    }
    
    func onRoutesError(_ error: Error) {
        let routingError = (error as NSError).userInfo[YRTUnderlyingErrorKey] as! YRTError
        var errorMessage = "Unknown error"
        if routingError.isKind(of: YRTNetworkError.self) {
            errorMessage = "Network error"
        } else if routingError.isKind(of: YRTRemoteError.self) {
            errorMessage = "Remote server error"
        }
        
        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }

    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }

    func showDetailView() {
        bottomLayoutConstraint.constant = 0
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func closeDetailView() {
        resultSearchController?.searchBar.text?.removeAll()
        routeCoordinates.removeAll()
        
        let map = yMapView.mapWindow.map
        map.mapObjects.clear()
        
        bottomLayoutConstraint.constant = -200
        
        UIView.animate(withDuration: 0.1) {
            self.view.layoutIfNeeded()
        }
    }

    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "ARSegue" {
            let destinationViewController = segue.destination as? ARViewController
            
            // Pass the selected object to the new view controller.
            destinationViewController?.routeCoordinates = self.routeCoordinates
            destinationViewController?.destinationPoint = self.destinationPoint
            destinationViewController?.orientedToTrueNorth = self.orientedToTrueNorth.isOn
        }
    }

}


//MARK: - CLLocationManagerDelegate
extension MapVC: CLLocationManagerDelegate {
    //TODO: - Выпилить?
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count > 0 {
            let location = locations.last!
            print("Accuracy: \(location.horizontalAccuracy)")
            
            if location.horizontalAccuracy < 666 {
                manager.stopUpdatingLocation()
                print(location.altitude)
                print(location.coordinate)
                
                // Zoom to user location
                yMapView.mapWindow.map.move(
                    with: YMKCameraPosition.init(target: YMKPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude), zoom: 15, azimuth: 0, tilt: 0),
                    animationType: YMKAnimation(type: YMKAnimationType.smooth, duration: 5),
                    cameraCallback: nil)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error finding location: \(error.localizedDescription)")
    }
}


//MARK: - HandleMapSearch
extension MapVC: HandleMapSearch {
    func createRoute(point: YMKPoint) {
        let ROUTE_START_POINT = YMKPoint(latitude: (locationManager.location?.coordinate.latitude)!,
                                         longitude: (locationManager.location?.coordinate.longitude)!)
        destinationPoint = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
        calculateRoute(from: ROUTE_START_POINT, to: point)
    }
}


extension MapVC: YMKUserLocationObjectListener {
    func onObjectAdded(with view: YMKUserLocationView) {
        
        //UserArrow
        view.arrow.setIconWith(UIImage(named:"pin")!,
                               style: YMKIconStyle(
                                anchor: CGPoint(x: 0.5, y: 0.5) as NSValue,
                                rotationType:YMKRotationType.noRotation.rawValue as NSNumber,
                                zIndex: 0,
                                flat: true,
                                visible: true,
                                scale: 0.13,
                                tappableArea: nil))
        
        let pinPlacemark = view.pin.useCompositeIcon()
        
        //Icon
        pinPlacemark.setIconWithName(
            "pin",
            image: UIImage(named:"pin")!,
             style:YMKIconStyle(
                anchor: CGPoint(x: 0.5, y: 0.5) as NSValue,
                rotationType:YMKRotationType.noRotation.rawValue as NSNumber,
                zIndex: 0,
                flat: true,
                visible: true,
                scale: 0.13,
                tappableArea: nil))
        
        //SearchResult
        pinPlacemark.setIconWithName(
            "pin",
            image: UIImage(named:"pin")!,
            style:YMKIconStyle(
                anchor: CGPoint(x: 0.5, y: 0.5) as NSValue,
                rotationType:YMKRotationType.rotate.rawValue as NSNumber,
                zIndex: 1,
                flat: true,
                visible: true,
                scale: 0.13,
                tappableArea: nil))
        
        view.accuracyCircle.fillColor = UIColor.blue.withAlphaComponent(0.1)
    }
    
    func onObjectRemoved(with view: YMKUserLocationView) {}
    
    func onObjectUpdated(with view: YMKUserLocationView, event: YMKObjectEvent) {}
}


