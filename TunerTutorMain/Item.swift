//
//  Item.swift
//  test app 1
//
//  Created by Yvann Kouassi on 23/06/2025.
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
