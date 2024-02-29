//
//  DraftVideoProtocol.swift
//  LeapVideoEditor
//
//  Created by bigstep on 10/10/22.
//

import Foundation

// MARK: protocol to select/delete draft video

protocol DraftVideoProtocol: AnyObject {
    func didSelectDraftVideo(_ video: DraftVideoModel, index: Int)
    func emptyDraft()
}
