//
//  FinderInteractor.swift
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
import FileKit

protocol FinderBusinessLogic {
    func fetchFiles(request: Finder.FetchFiles.Request)
    func updateSortRule(request: Finder.UpdateSortRule.Request)
    func makeDirectory(request: Finder.MakeDirectory.Request)
    func renameFile(request: Finder.RenameFile.Request)
    func moveFiles(request: Finder.MoveFiles.Request)
    func moveTrash(request: Finder.MoveTrash.Request)
    func share(request: Finder.Share.Request)
}

protocol FinderDataStore {
    var currentPath: Path { get set }
}

class FinderInteractor: FinderBusinessLogic, FinderDataStore {
    var presenter: FinderPresentationLogic?
    var worker: FinderWorker = FinderWorker()
    var currentPath: Path = Path.userDocuments
    
    
    // MARK: Fetch Files
    func fetchFiles(request: Finder.FetchFiles.Request) {
        print("Fetch files in \(request.path.tildify)")
        worker.fetchPathElements(in: request.path, completion: { [weak self] paths in
            self?.presenter?.presentFiles(response: .init(elements: paths))
        })
    }
    
    
    // MARK: Update Sort Rule
    func updateSortRule(request: Finder.UpdateSortRule.Request) {
        if Finder.currentSortRule == request.rule {
            Finder.currentSortOrder = Finder.currentSortOrder.isASC ? .DESC : .ASC
        } else {
            Finder.currentSortRule = request.rule
            Finder.currentSortOrder = .ASC
        }
        fetchFiles(request: .init(path: currentPath))
    }
    
    
    // MARK: Make Directory
    func makeDirectory(request: Finder.MakeDirectory.Request) {
        do {
            try worker.makeDirectory(in: request.parent, dirName: request.dirName)
            fetchFiles(request: .init(path: currentPath))
        } catch let error {
            print(error)
        }
    }
    
    
    // MARK: Rename File
    func renameFile(request: Finder.RenameFile.Request) {
        do {
            try worker.renameFile(path: request.targetPath, name: request.newName)
            fetchFiles(request: .init(path: currentPath))
        } catch let error {
            print(error)
        }
    }
    
    
    // MARK: Move Files
    func moveFiles(request: Finder.MoveFiles.Request) {
        do {
            try worker.moveFiles(to: request.moveDirectoryPath, filePaths: request.paths)
            fetchFiles(request: .init(path: currentPath))
        } catch let error {
            print(error)
        }
    }
    
    
    // MARK: Trash Files
    func moveTrash(request: Finder.MoveTrash.Request) {
        do {
            try request.paths.forEach { p in
                try worker.moveTrash(to: p)
                fetchFiles(request: .init(path: currentPath))
            }
        } catch let error {
            print(error)
        }
    }
    
    
    // MARK: Share
    func share(request: Finder.Share.Request) {
        let urls = request
            .paths
            .compactMap { $0.url }
        print(urls)
    }
}


/*
 ViewController는 Interactor에 있는 비즈니스 로직 호출을 할 때 Request에 필요한 데이터를 담아 넘겨준다.
 Interactor에서는 필요한 로직을 처리한 뒤에 그 결과값을 Response에 담아 Presenter에 넘겨준다.
 마지막으로 Presenter는 ViewController가 화면에 정상적으로 값을 표현할 수 있도록 Response의 데이터를 가공해 ViewModel에 담아 ViewController로 넘겨주면 ViewController에서 화면 갱신
 */
