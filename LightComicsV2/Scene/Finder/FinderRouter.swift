//
//  FinderRouter.swift
//  LightComicsV2
//
//  Created by LeeSeGun on 2021/12/20.
//  Copyright (c) 2021 ___ORGANIZATIONNAME___. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

@objc protocol FinderRoutingLogic {
    //func routeToSomewhere(segue: UIStoryboardSegue?)
    func routeToFinder(segue: UIStoryboardSegue?)
}

protocol FinderDataPassing {
    var dataStore: FinderDataStore? { get }
}

class FinderRouter: NSObject, FinderRoutingLogic, FinderDataPassing {
    weak var viewController: FinderViewController?
    var dataStore: FinderDataStore?
    
    
    // MARK: Routing
    func routeToFinder(segue: UIStoryboardSegue?) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let destinationVC = storyboard.instantiateViewController(withIdentifier: "FinderViewController") as? FinderViewController else { return }
        guard var destinationDS = destinationVC.router?.dataStore else { return }
        guard let dataStore = dataStore else { return }
        guard let viewController = viewController else { return }
        
        passDataToFinder(source: dataStore, destination: &destinationDS)
        navigateToFinder(source: viewController, destination: destinationVC)
    }
    
    
    // MARK: Navigation
    func navigateToFinder(source: FinderViewController, destination: FinderViewController) {
        source.show(destination, sender: nil)
    }
    
    
    // MARK: Passing data
    func passDataToFinder(source: FinderDataStore, destination: inout FinderDataStore) {
        guard let indexPath = viewController?.tableView.indexPathForSelectedRow else { return }
        guard let path = viewController?.viewModel.indexPathForPath(indexPath) else { return }
        destination.currentPath = path
    }

    
    //func routeToSomewhere(segue: UIStoryboardSegue?)
    //{
    //  if let segue = segue {
    //    let destinationVC = segue.destination as! SomewhereViewController
    //    var destinationDS = destinationVC.router!.dataStore!
    //    passDataToSomewhere(source: dataStore!, destination: &destinationDS)
    //  } else {
    //    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    //    let destinationVC = storyboard.instantiateViewController(withIdentifier: "SomewhereViewController") as! SomewhereViewController
    //    var destinationDS = destinationVC.router!.dataStore!
    //    passDataToSomewhere(source: dataStore!, destination: &destinationDS)
    //    navigateToSomewhere(source: viewController!, destination: destinationVC)
    //  }
    //}
    
    // MARK: Navigation
    
    //func navigateToSomewhere(source: FinderViewController, destination: SomewhereViewController)
    //{
    //  source.show(destination, sender: nil)
    //}
    
    // MARK: Passing data
    
    //func passDataToSomewhere(source: FinderDataStore, destination: inout SomewhereDataStore)
    //{
    //  destination.name = source.name
    //}
}


/*
 다른 화면으로 전환해야 하는 경우 사용한다.
 넘겨주어야 하는 데이터가 있는 경우 Router를 통해 화면 전환할 때 함께 보내준다.

 */
