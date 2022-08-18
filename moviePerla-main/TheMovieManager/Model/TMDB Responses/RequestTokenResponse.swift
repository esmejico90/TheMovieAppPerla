//
//  RequestTokenResponse.swift
//  TheMovieManager
//
//  Created by Perla Jimenez on 15/08/2022.
//

import Foundation

struct RequestTokenResponse: Codable {
    
    let success: Bool
    let expiresAt: String
    let requestToken: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case expiresAt = "expires_at"
        case requestToken = "request_token"
    }
}
