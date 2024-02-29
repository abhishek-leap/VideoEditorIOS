//
//  LensItem.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 31/08/22.
//

import Foundation

struct LensItem {
    
    /// id for carousel item
    public let id: String

    /// lens id
    public let lensId: String

    /// group id lens belongs to
    public let groupId: String
    
    /// image url for lens icon
    let iconURL: URL?
    
    /// lens name
    let name: String
    
    init(lensId: String, groupId: String, iconURL: URL?, name: String) {
        self.id = lensId + groupId
        self.lensId = lensId
        self.groupId = groupId
        self.iconURL = iconURL
        self.name = name
    }
}
