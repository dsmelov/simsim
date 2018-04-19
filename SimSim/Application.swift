//
//  Application.swift
//  SimSim
//
//  Created by Daniil Smelov on 19/04/2018.
//  Copyright © 2018 Daniil Smelov. All rights reserved.
//

import Cocoa

//----------------------------------------------------------------------------
class AppDelegate: NSObject
{
    var statusItem: NSStatusItem? = nil
}

//----------------------------------------------------------------------------
extension AppDelegate
{
    @objc func quit(sender: NSMenuItem)
    {
        NSApp.terminate(self)
    }
}

//----------------------------------------------------------------------------
extension AppDelegate: NSApplicationDelegate
{
    //----------------------------------------------------------------------------
    func applicationDidFinishLaunching(_ notification: Notification)
    {
        statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
        statusItem?.image = NSImage(named: "BarIcon")
        statusItem?.image?.isTemplate = true
        statusItem?.highlightMode = true
        statusItem?.action = #selector(self.presentApplicationMenu)
        statusItem?.isEnabled = true
    }

    //----------------------------------------------------------------------------
    func presentApplicationMenu()
    {
        let menu: NSMenu? = Menus.createApplicationMenu(at: statusItem!)
        if let aMenu = menu
        {
            statusItem?.popUpMenu(aMenu)
        }
    }
}


