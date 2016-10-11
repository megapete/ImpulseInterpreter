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
    @IBOutlet weak var timeElapsedField: NSTextField!
   
    @IBOutlet weak var bottomLabel: NSTextField!
    @IBOutlet weak var topLabel: NSTextField!
    
    // @IBOutlet weak var loadFileProgInd: NSProgressIndicator!
    @IBOutlet weak var loadFileProgInd: NSProgressIndicator!
    
    /// Menu handlers (these just call the AppController functions of the same name
    @IBAction func handleOpenFile(_ sender: AnyObject) {
        
        appController.handleOpenFile()
        
        // appController.getDataFromFile()
        
        self.loadFileProgInd.startAnimation(self)
        
        // The godamned open dialog will cause a big white space to appear and stay there until the file is actually finished being read, UNLESS we do the read in a background thread.
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: {
            
                self.appController.getDataFromFile()
            
            // progress indicator calls MUST be done on the main queue, so this is the way to do it
            DispatchQueue.main.async {
                self.loadFileProgInd.stopAnimation(self)
            }
        });
 
        
        DLog("We have reached here")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        appController.graphView = (self.window.contentView?.subviews[0] as! PCH_GraphView)
        appController.graphView?.theController = appController
        
        appController.graphView?.bottomLabel = self.bottomLabel
        appController.graphView?.topLabel = self.topLabel
        
        appController.coilMenuContents = coilMenu
        appController.elapsedTimeIndicator = timeElapsedField
        
        appController.loadingProgress = loadFileProgInd
    }
    
    func handleCoilChange(_ sender: AnyObject)
    {
        DLog("Change coil in AppDelegate")
        
        appController.currentCoilChoice?.state = NSOffState
        appController.currentCoilChoice = sender as? NSMenuItem
        appController.currentCoilChoice?.state = NSOnState
        
        appController.graphView?.ZoomAll()
        appController.graphView?.needsDisplay = true
    }
    
    @IBAction func handleShoot(_ sender: AnyObject)
    {
        appController.handleShoot()
    }
    
    @IBAction func handleShowInitDist(_ sender: AnyObject)
    {
        appController.handleInitialDistribution(saveValues: false)
    }

    @IBAction func handleShowMaxInterDiskV(_ sender: AnyObject) {
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
        appController.handleInitialDistribution(saveValues: true)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

