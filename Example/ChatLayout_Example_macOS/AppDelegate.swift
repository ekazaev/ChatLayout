//
//  AppDelegate.swift
//  ChatLayout_Example_macOS
//
//  Created by JH on 2024/9/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        window.contentViewController = ChatViewControllerBuilder().build()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

