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
    
    @IBOutlet weak var coilMenu: NSMenu!
    
    /// Menu handlers (these just call the AppController functions of the same name
    @IBAction func handleOpenFile(_ sender: AnyObject) {
        
        appController.handleOpenFile()
        
        // appController.getDataFromFile()
        
         DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: {
                self.appController.getDataFromFile()
        });
        
        DLog("We have reached here")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        appController.graphView = (self.window.contentView?.subviews[0] as! PCH_GraphView)
        appController.graphView?.theController = appController
        
        appController.coilMenuContents = coilMenu
    }
    
    func handleCoilChange(_ sender: AnyObject)
    {
        DLog("Change coil in AppDelegate")
        
        appController.currentCoilChoice?.state = NSOffState
        appController.currentCoilChoice = sender as? NSMenuItem
        appController.currentCoilChoice?.state = NSOnState
        
        appController.graphView?.needsDisplay = true
    }
    
    @IBAction func handleShoot(_ sender: AnyObject)
    {
        appController.handleShoot()
    }
    
    @IBAction func handleSaveMaxVoltages(_ sender: AnyObject)
    {
        appController.handleSaveMaxVoltages()
    }

    @IBAction func handleSaveMaxInterdiskV(_ sender: AnyObject)
    {
        appController.handleMaxInterdiskV()
    }
    
    @IBAction func handleSaveInitialDistribution(_ sender: AnyObject)
    {
        appController.handleInitialDistribution()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

