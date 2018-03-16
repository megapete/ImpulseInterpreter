//
//  PCH_ImpulseViewController.swift
//  ImpulseInterpreter
//
//  Created by Peter Huber on 2018-02-14.
//  Copyright © 2018 Huberis Technologies. All rights reserved.
//

import Cocoa

class PCH_ImpulseViewController: NSViewController {
    
    var impulseView:PCH_ImpulseView? = nil

    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do view setup here.
        
        guard let impView = self.view as? PCH_ImpulseView else
        {
            ALog("The impossible has happened!")
            return
        }
        
        self.impulseView = impView
        
    }
    
}
