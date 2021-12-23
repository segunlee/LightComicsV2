//
//  Foundation+.swift
//  LightComicsV2
//
//  Created by LeeSeGun on 2021/12/22.
//

import Foundation
import UIKit

// MARK: - Array
extension Array {
    subscript (safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}


// MARK: - UITableView
extension UITableView {
    func selectAllRows(animated: Bool = true, scrollPosition: UITableView.ScrollPosition = .none) {
        for section in 0..<numberOfSections {
            for row in 0..<numberOfRows(inSection: section) {
                selectRow(at: IndexPath(row: row, section: section), animated: animated, scrollPosition: .none)
            }
        }
    }
    
    func deselectAllRows(animated: Bool = true) {
        for section in 0..<numberOfSections {
            for row in 0..<numberOfRows(inSection: section) {
                deselectRow(at: IndexPath(row: row, section: section), animated: animated)
            }
        }
    }
    
    var isAnySelectedItems: Bool {
        return numberOfSelectedItemsCount > 0 && numberOfItemsCount != 0
    }
    
    var isAllSelectedItems: Bool {
        return numberOfItemsCount == numberOfSelectedItemsCount && numberOfItemsCount != 0
    }
    
    var numberOfItemsCount: Int {
        var value = 0
        for section in 0..<numberOfSections {
            value += numberOfRows(inSection: section)
        }
        return value
    }
    
    var numberOfSelectedItemsCount: Int {
        return indexPathsForSelectedRows?.count ?? 0
    }
}


// MARK: - UIBarButtonItem
extension UIBarButtonItem {
    private struct AssociatedObject {
        static var key = "action_closure_key"
    }

    var actionClosure: (() -> Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociatedObject.key) as? () -> Void
        }
        set {
            objc_setAssociatedObject(self, &AssociatedObject.key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            target = self
            action = #selector(didTapButton(sender:))
        }
    }

    @objc func didTapButton(sender: Any) {
        actionClosure?()
    }
}


// MARK: - UIBarButtonItem
extension UIBarButtonItem {
    class func flexibleSpace() -> UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    }
}
