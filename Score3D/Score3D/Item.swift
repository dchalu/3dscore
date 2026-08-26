//
//  Item.swift
//  Score3D
//
//  Created by DeltaCharlie on 26/08/2026.
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
