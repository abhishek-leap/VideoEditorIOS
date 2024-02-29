//
//  BaseViewController.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 01/09/22.
//

import UIKit

open class BaseViewController: UIViewController {
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) { overrideUserInterfaceStyle = .light }
    }
}
