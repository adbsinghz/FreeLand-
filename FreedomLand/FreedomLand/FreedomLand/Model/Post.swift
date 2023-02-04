//
//  Post.swift
//  FreedomLand
//
//  Created by Arshdeep Singh on 1/25/23.
//

import SwiftUI
import FirebaseFirestoreSwift

struct Post: Identifiable,Codable, Equatable, Hashable {
    @DocumentID var id: String?
        var text: String
        var imageURL: URL?
        var imageReferenceID: String = ""
        var publishedDate: Date = Date()
        var likedIDs: [String] = []
        var dislikedIDs: [String] = []
        var userName: String
        var userUID: String
        var userProfileURL: URL

        enum CodingKeys: CodingKey {
            case id
            case text
            case imageURL
            case imageReferenceID
            case publishedDate
            case likedIDs
            case dislikedIDs
            case userName
            case userUID
            case userProfileURL
        }
 
}
