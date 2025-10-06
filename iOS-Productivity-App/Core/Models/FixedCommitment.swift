//
//  FixedCommitment.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-06.
//

import Foundation
import FirebaseFirestoreSwift

struct FixedCommitment: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var title: String
    var startTime: Date
    var endTime: Date
}
