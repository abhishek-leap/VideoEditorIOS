//
//  CollectionModel.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 10/10/22.
//

import Foundation

// MARK: - CollectionModel
struct CollectionModel: Codable {
    let pagination: Pagination
    let collections: [Collection]
    let links: Links
}

// MARK: - Collection
struct Collection: Codable {
    let availableTracks: Int
    let images: Images
    let name, id: String
    let tracks: [Track]
}

// MARK: - CollectionImages
struct Images: Codable {
    let imagesDefault: String

    enum CodingKeys: String, CodingKey {
        case imagesDefault = "default"
    }
}

// MARK: - Track
class Track: Codable {
    let images: Images
    let isExplicit: Bool
    let added: String
    let length: TimeInterval
    let moods: [Mood]
    let mainArtists, featuredArtists: [String]
    let title: String
    let hasVocals: Bool
    let waveformURL: String
    let isPreviewOnly: Bool
    let genres: [Genre]
    let id: String
    let bpm: Int
    var soundURL: URL?
    var state = 0

    enum CodingKeys: String, CodingKey {
        case images, isExplicit, added, length, moods, mainArtists, featuredArtists, title, hasVocals
        case waveformURL = "waveformUrl"
        case isPreviewOnly, genres, id, bpm
    }
}

// MARK: - Genre
struct Genre: Codable {
    let parent: Mood?
    let name, id: String
}

// MARK: - Mood
struct Mood: Codable {
    let name, id: String
}

// MARK: - Links
struct Links: Codable {
    let next, prev: String?
}

// MARK: - Pagination
struct Pagination: Codable {
    let limit, page: Int
    let offset: Int?
}
