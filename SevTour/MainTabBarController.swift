//
//  MainTabBarController.swift
//  SevTour
//
//  Created by Stanislav Povolotskiy on 09.12.2019.
//  Copyright © 2019 Stanislav Povolotskiy. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        let listVC = ListVC(collectionViewLayout: UICollectionViewFlowLayout())
        let mapVC: UIViewController = UIStoryboard(name: "MapVC", bundle: nil).instantiateViewController(withIdentifier: "mapVCId") as UIViewController
        let cameraVC = CameraVC()
        let aboutCityVC = AboutCityVC()
        let tourVC = TourVC()
        
        viewControllers = [
            generateNavigationController(rootViewController: aboutCityVC, title: "City", image: #imageLiteral(resourceName: "info")),
            generateNavigationController(rootViewController: listVC, title: "List", image: #imageLiteral(resourceName: "list")),
            generateNavigationController(rootViewController: cameraVC, title: "Camera", image: #imageLiteral(resourceName: "camera")),
            generateNavigationController(rootViewController: mapVC, title: "Map", image: #imageLiteral(resourceName: "map")),
            generateNavigationController(rootViewController: tourVC, title: "Tours", image: #imageLiteral(resourceName: "guide"))
            
        ]
    }
    
    private func generateNavigationController(rootViewController: UIViewController, title: String, image: UIImage) -> UIViewController {
        let navigationVC = UINavigationController(rootViewController: rootViewController)
        navigationVC.tabBarItem.title = title
        navigationVC.tabBarItem.image = image
        return navigationVC
    }
}
