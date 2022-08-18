//
//  SessionResponse.swift
//  TheMovieManager
//
//  Created by Perla Jimenez on 15/08/2022.
//

import Foundation

struct SessionResponse: Codable {
    
    let success: Bool
    let sessionId: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case sessionId = "session_id"
    }
    
}
