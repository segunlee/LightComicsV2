//
//  FinderViewController.swift
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

protocol FinderDisplayLogic: AnyObject {
    func displayFiles(viewModel: Finder.FetchFiles.ViewModel)
}

class FinderViewController: UITableViewController, FinderDisplayLogic {
    var interactor: FinderBusinessLogic?
    var router: (NSObjectProtocol & FinderRoutingLogic & FinderDataPassing)?
    
    // MARK: Object lifecycle
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    // MARK: Setup
    
    private func setup() {
        let viewController = self
        let interactor = FinderInteractor()
        let presenter = FinderPresenter()
        let router = FinderRouter()
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        presenter.viewController = viewController
        router.viewController = viewController
        router.dataStore = interactor
    }
    
    // MARK: Routing
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let scene = segue.identifier {
            let selector = NSSelectorFromString("routeTo\(scene)WithSegue:")
            if let router = router, router.responds(to: selector) {
                router.perform(selector, with: segue)
            }
        }
    }
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = true
        view.backgroundColor = .systemGray6
        configureTableView()
        configureNavigationBarButtonItem()
        configureToolBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchFiles()
    }
    
    
    // MARK: - UI Configurations
    private func configureTableView() {
        tableView.separatorStyle = .singleLine
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "A")
        tableView.allowsMultipleSelectionDuringEditing = true
    }
    
    
    // MARK: UIBarButtonItems
    private let contextBBI = UIBarButtonItem()
    
    private func configureNavigationBarButtonItem() {
        contextBBI.image = UIImage(systemName: "ellipsis.circle")
        contextBBI.primaryAction = nil
        contextBBI.menu = contextMenu()
        navigationItem.rightBarButtonItems = [contextBBI]
    }
    
    private func updateContextMenu() {
        contextBBI.menu = contextMenu()
    }
    
    
    // MARK: UIToolBar
    private let renameBBI = UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: nil, action: nil)
    private let moveBBI = UIBarButtonItem(image: UIImage(systemName: "arrowshape.turn.up.right"), style: .plain, target: nil, action: nil)
    private let trashBBI = UIBarButtonItem(image: UIImage(systemName: "trash.fill"), style: .plain, target: nil, action: nil)
    private let shareBBI = UIBarButtonItem(barButtonSystemItem: .action, target: nil, action: nil)
    
    private func configureToolBar() {
        self.toolbarItems = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), renameBBI,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), moveBBI,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), trashBBI,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), shareBBI,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        ]
        updateToolBarItems()
        
        renameBBI.actionClosure = { [weak self] in
            guard let indexPath = self?.tableView.indexPathForSelectedRow else { return }
            guard let path = self?.viewModel.indexPathForPath(indexPath) else { return }
            
            var alertTextField: UITextField?
            let alert = UIAlertController(title: R.string.RENAME, message: nil, preferredStyle: .alert)
            let actionConfirm = UIAlertAction(title: R.string.DONE, style: .destructive) { [weak self] (_) in
                guard let newName = alertTextField?.text else { return }
                self?.interactor?.renameFile(request: .init(newName: newName, targetPath: path))
            }
            let actionCancel = UIAlertAction(title: R.string.CANCEL, style: .cancel, handler: nil)
            alert.addAction(actionConfirm)
            alert.addAction(actionCancel)
            alert.addTextField { (tf: UITextField) in
                alertTextField = tf
                alertTextField?.text = path.fileName
            }
            self?.present(alert, animated: true, completion: nil)
        }
        
        moveBBI.actionClosure = {
            
        }
        
        trashBBI.actionClosure = { [weak self] in
            guard let indexPaths = self?.tableView.indexPathsForSelectedRows else { return }
            let paths = indexPaths
                .compactMap { self?.viewModel.indexPathForPath($0) }
            self?.interactor?.moveTrash(request: .init(paths: paths))
        }
        
        shareBBI.actionClosure = { [weak self] in
            guard let indexPaths = self?.tableView.indexPathsForSelectedRows else { return }
            let paths = indexPaths
                .compactMap { self?.viewModel.indexPathForPath($0) }
            
            self?.interactor?.share(request: .init(paths: paths))
            // NOTE: 굳이 인터렉터 -> 프레젠터 -> 컨트롤러까지 돌아가면서 UIActivityViewController를 띄워야 되는건가...
            
            
            // NOTE: 일단 바로 넘기기
            let activityItems: [Any] = paths
                .compactMap { URL(fileURLWithPath: $0.rawValue) }
            let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            if let popover = vc.popoverPresentationController {
                popover.barButtonItem = self?.shareBBI
            }
            self?.present(vc, animated: true, completion: nil)
        }
    }
    
    private func updateToolBarItems() {
        renameBBI.isEnabled = tableView.numberOfSelectedItemsCount == 1
        moveBBI.isEnabled = tableView.isAnySelectedItems
        trashBBI.isEnabled = tableView.isAnySelectedItems
        shareBBI.isEnabled = tableView.isAnySelectedItems
    }
    
    
    
    
    
    // MARK: - UITableView Edit Stuff
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
        navigationController?.setToolbarHidden(!editing, animated: true)
    }
    
    
    private func contextMenu() -> UIMenu {
        var firstRows = [
            UIAction(title: R.string.SELECT, image: UIImage(systemName: "checkmark.circle"), handler: { [weak self] (_) in
                guard let isEditing = self?.isEditing else { return }
                self?.setEditing(!isEditing, animated: true)
                self?.updateContextMenu()
                self?.updateToolBarItems()
            })
        ]
        
        if isEditing {
            let editRows = [
                UIAction(title: R.string.SELECT_ALL, handler: { [weak self] (_) in
                    self?.tableView.selectAllRows()
                    self?.updateContextMenu()
                    self?.updateToolBarItems()
                }),
                UIAction(title: R.string.DESELECT_ALL, handler: { [weak self] (_) in
                    self?.tableView.deselectAllRows()
                    self?.updateContextMenu()
                    self?.updateToolBarItems()
                })
            ]
            
            firstRows.first?.title = R.string.DONE
            firstRows.first?.image = nil
            firstRows.append(contentsOf: editRows)
            
            return UIMenu(title: R.string.DOCUMENTS, image: nil, identifier: nil, options: .destructive, children: [
                UIMenu(title: "", options: .displayInline, children: firstRows)
            ])
        }
        
        let secondRows = [
            UIAction(title: R.string.CREATE_DIRECTORY, image: UIImage(systemName: "folder.badge.plus"), handler: { [weak self] (_) in
                var alertTextField: UITextField?
                let alert = UIAlertController(title: R.string.CREATE_DIRECTORY, message: nil, preferredStyle: .alert)
                let actionConfirm = UIAlertAction(title: R.string.CREATE, style: .destructive) { [weak self] (_) in
                    guard let dirName = alertTextField?.text else { return }
                    guard let parent = self?.router?.dataStore?.currentPath else { return }
                    self?.interactor?.makeDirectory(request: .init(parent: parent, dirName: dirName))
                }
                let actionCancel = UIAlertAction(title: R.string.CANCEL, style: .cancel, handler: nil)
                alert.addAction(actionConfirm)
                alert.addAction(actionCancel)
                alert.addTextField { (tf: UITextField) in
                    alertTextField = tf
                    alertTextField?.placeholder = R.string.DIRECTORY_NAME
                }
                self?.present(alert, animated: true, completion: nil)
            })
        ]
        
        let sortOrderArrowImage = UIImage(systemName: Finder.currentSortOrder.isASC ? "arrow.down" : "arrow.up")
        let thirdRows = [
            UIAction(title: R.string.SORT_NAME,
                     image: Finder.currentSortRule.isName ? sortOrderArrowImage : nil,
                     state: Finder.currentSortRule.isName ? .on : .off,
                     handler: { [weak self] (_) in
                         self?.interactor?.updateSortRule(request: .init(rule: .Name))
                         self?.updateContextMenu()
                     }),
            UIAction(title: R.string.SORT_DATE,
                     image: Finder.currentSortRule.isDate ? sortOrderArrowImage : nil,
                     state: Finder.currentSortRule.isDate ? .on : .off,
                     handler: { [weak self] (_) in
                         self?.interactor?.updateSortRule(request: .init(rule: .Date))
                         self?.updateContextMenu()
                     }),
            UIAction(title: R.string.SORT_SIZE,
                     image: Finder.currentSortRule.isSize ? sortOrderArrowImage : nil,
                     state: Finder.currentSortRule.isSize ? .on : .off,
                     handler: { [weak self] (_) in
                         self?.interactor?.updateSortRule(request: .init(rule: .Size))
                         self?.updateContextMenu()
                     })
        ]
        
        return UIMenu(title: R.string.DOCUMENTS, image: nil, identifier: nil, options: .destructive, children: [
            UIMenu(title: "", options: .displayInline, children: firstRows),
            UIMenu(title: "", options: .displayInline, children: secondRows),
            UIMenu(title: "", options: .displayInline, children: thirdRows)
        ])
    }
    
    
    // MARK: - Fetch Files
    var viewModel: Finder.FetchFiles.ViewModel = .init(directories: [], files: []) {
        didSet { tableView.reloadData() }
    }
    
    func fetchFiles() {
        interactor?.fetchFiles(request: .init(path: router?.dataStore?.currentPath ?? Path.userDocuments))
    }
    
    func displayFiles(viewModel: Finder.FetchFiles.ViewModel) {
        if isEditing { setEditing(!isEditing, animated: true) }
        self.viewModel = viewModel
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Finder.FetchFiles.ViewModel.Section(rawValue: section) {
        case Finder.FetchFiles.ViewModel.Section.Dirs?:
            return viewModel.directories.count
        case Finder.FetchFiles.ViewModel.Section.Files?:
            return viewModel.files.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Finder.FetchFiles.ViewModel.Section(rawValue: section)?.stringValue
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "A", for: indexPath)
        
        guard let path = viewModel.indexPathForPath(indexPath) else { return cell }
        
        cell.selectionStyle = .blue
        cell.textLabel?.text = path.fileName
        cell.accessoryType = path.isDirectory ? .disclosureIndicator : .none
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !isEditing else {
            updateToolBarItems()
            return
        }
        
        guard let path = viewModel.indexPathForPath(indexPath) else { return }
        
        if path.isDirectory {
            router?.routeToFinder(segue: nil)
        }
        else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard !isEditing else {
            updateToolBarItems()
            return
        }
    }
    
}
