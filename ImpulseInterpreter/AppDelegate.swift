//
//  AppDelegate.swift
//  ImpulseInterpreter
//
//  Created by Peter Huber on 2015-12-21.
//  Copyright © 2015 Huberis Technologies. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    /// The AppController object for the instance
    let appController = PCH_AppController()

    @IBOutlet weak var window: NSWindow!

    /// Menu handlers (these just call the AppController functions of the same name
    @IBAction func handleOpenFile(sender: AnyObject) {
        
        appController.handleOpenFile()
        
        appController.getDataFromFile()
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

