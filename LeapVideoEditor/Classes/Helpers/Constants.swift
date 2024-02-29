//
//  Constants.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 10/10/22.
//

import Foundation

class Path {
    static var environment = ""
    static var getAccessToken: String {
        if Path.environment == "leapStaging" {
            return "https://authstg.playleap.io/sound/getAccessToken"
        }
        return "https://auth.playleap.io/sound/getAccessToken"
    }
}

class SoundPath {
    static var baseURL: String {
//        if Path.environment == "leapStaging" {
            return "https://partner-content-api-sandbox.epidemicsound.com/v0/" //for now always point to staging
//        }
//        return "https://partner-content-api.epidemicsound.com/v0/"
    }
    static let getCollections = "\(baseURL)collections"
    static let searchTrack = "\(baseURL)tracks/search"
    static let tracks = "\(baseURL)tracks/"
}
