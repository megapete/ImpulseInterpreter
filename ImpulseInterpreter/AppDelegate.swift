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
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), {
                self.appController.getDataFromFile()
            });
        
        DLog("We have reached here")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        appController.graphView = (self.window.contentView?.subviews[0] as! PCH_GraphView)
        appController.graphView?.theController = appController
    }
    
    @IBAction func handleShoot(sender: AnyObject)
    {
        appController.handleShoot()
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

