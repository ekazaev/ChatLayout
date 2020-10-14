//
//  FPSStatusBarWindow.swift
//  FPSCounter
//
//  Created by Markus Gasser on 15.06.18.
//  Copyright © 2018 konoma GmbH. All rights reserved.
//

import UIKit


class FPStatusBarWindow: UIWindow {

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // don't hijack touches from the main window
        return false
    }
}
