//
//  DirPickerPresenter.swift
//  LightComicsV2
//
//  Created by LeeSeGun on 2021/12/23.
//  Copyright (c) 2021 ___ORGANIZATIONNAME___. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

protocol DirPickerPresentationLogic {
    func presentSomething(response: DirPicker.Something.Response)
}

class DirPickerPresenter: DirPickerPresentationLogic {
    weak var viewController: DirPickerDisplayLogic?
    
    // MARK: Do something
    
    func presentSomething(response: DirPicker.Something.Response) {
        let viewModel = DirPicker.Something.ViewModel()
        viewController?.displaySomething(viewModel: viewModel)
    }
}
