//
//  Item.swift
//  Hyppo
//
//  Created by Nicolas Delahousse on 13/01/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
