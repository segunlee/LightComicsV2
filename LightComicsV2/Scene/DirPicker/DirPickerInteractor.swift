//
//  DirPickerInteractor.swift
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
import FileKit

protocol DirPickerBusinessLogic {
    func doSomething(request: DirPicker.Something.Request)
}

protocol DirPickerDataStore {
    var selectedPath: Path? { get set }
}

class DirPickerInteractor: DirPickerBusinessLogic, DirPickerDataStore {
    var presenter: DirPickerPresentationLogic?
    var worker: DirPickerWorker?
    var selectedPath: Path?
    
    // MARK: Do something
    
    func doSomething(request: DirPicker.Something.Request) {
        worker = DirPickerWorker()
        worker?.doSomeWork()
        
        let response = DirPicker.Something.Response()
        presenter?.presentSomething(response: response)
    }
}
