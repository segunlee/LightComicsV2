//
//  Localized.swift
//  LightComicsV2
//
//  Created by LeeSeGun on 2021/12/22.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}
