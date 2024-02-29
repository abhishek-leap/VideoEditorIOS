//
//  Models.swift
//  LeapVideoEditor
//
//  Created by bigstep on 20/10/22.
//

import Foundation

class VideoFilterModel {
    let filter: CIFilter?
    let filterName: String
    let thumbnail: UIImage
    let filterLabel: String
    
    init(filter: CIFilter?, filterName: String, thumbnail: UIImage, filterLabel: String) {
        self.filter = filter
        self.filterName = filterName
        self.thumbnail = thumbnail
        self.filterLabel = filterLabel
    }
}
