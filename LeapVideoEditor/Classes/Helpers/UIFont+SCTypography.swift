//
//  UIFont+SCTypography.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 19/08/22.
//

import UIKit

/// Provides access to Snapchat typography in all supported weights.
extension UIFont {

    static func sc_ultraLightFont(size: CGFloat) -> UIFont? {
        UIFont(name: "AvenirNext-UltraLight", size: size)
    }

    static func sc_regularFont(size: CGFloat) -> UIFont? {
        UIFont(name: "AvenirNext-Regular", size: size)
    }

    static func sc_mediumFont(size: CGFloat) -> UIFont? {
        UIFont(name: "AvenirNext-Medium", size: size)
    }

    static func sc_demiBoldFont(size: CGFloat) -> UIFont? {
        UIFont(name: "AvenirNext-DemiBold", size: size)
    }

    static func sc_boldFont(size: CGFloat) -> UIFont? {
        UIFont(name: "AvenirNext-Bold", size: size)
    }

    static func sc_heavyFont(size: CGFloat) -> UIFont? {
        UIFont(name: "AvenirNext-Heavy", size: size)
    }

}
