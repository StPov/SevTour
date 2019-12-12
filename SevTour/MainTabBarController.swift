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
        
        view.backgroundColor = .white
        
//        let photosVC = PhotosCollectionViewController(collectionViewLayout: WaterfallLayout())
        
//        let likesVC = LikesCollectionViewController(collectionViewLayout: UICollectionViewFlowLayout())
       
        let listVC = ListVC(collectionViewLayout: UICollectionViewFlowLayout())
        let secondVC = MapVC()
        let thirdVC = CameraVC()
        let fourthVC = AboutCityVC()
        let fifthVC = TourVC()
        
        viewControllers = [
//            generateNavigationController(rootViewController: photosVC, title: "Photos", image: #imageLiteral(resourceName: "photos")),
//            generateNavigationController(rootViewController: likesVC, title: "Favourites", image: #imageLiteral(resourceName: "heart"))
            generateNavigationController(rootViewController: fourthVC, title: "City", image: #imageLiteral(resourceName: "info")),
            generateNavigationController(rootViewController: listVC, title: "List", image: #imageLiteral(resourceName: "list")),
            generateNavigationController(rootViewController: thirdVC, title: "Camera", image: #imageLiteral(resourceName: "camera")),
            generateNavigationController(rootViewController: secondVC, title: "Map", image: #imageLiteral(resourceName: "map")),
            generateNavigationController(rootViewController: fifthVC, title: "Tours", image: #imageLiteral(resourceName: "guide"))
            
        ]
    }
    
    private func generateNavigationController(rootViewController: UIViewController, title: String, image: UIImage) -> UIViewController {
        let navigationVC = UINavigationController(rootViewController: rootViewController)
        navigationVC.tabBarItem.title = title
        navigationVC.tabBarItem.image = image
        return navigationVC
    }
}
