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
}
