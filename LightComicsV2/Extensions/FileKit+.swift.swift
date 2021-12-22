//
//  FileKit+.swift.swift
//  LightComicsV2
//
//  Created by LeeSeGun on 2021/12/21.
//

import Foundation
import FileKit

//extension Array where Iterator.Element == Path {
//    mutating func sort() {
//
//    }
//}
extension Path {
    var tildify: String {
        return NSString(string: self.rawValue).abbreviatingWithTildeInPath
    }
}
