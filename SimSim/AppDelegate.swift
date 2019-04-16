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
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        item.image = NSImage(named: "BarIcon")
        item.image?.isTemplate = true
        item.highlightMode = true
        item.action = #selector(self.presentApplicationMenu)
        item.isEnabled = true
        
        statusItem = item
    }

    //----------------------------------------------------------------------------
    @objc
    func presentApplicationMenu()
    {
        let menu: NSMenu? = Menus.createApplicationMenu(at: statusItem!)
        if let aMenu = menu
        {
            statusItem?.popUpMenu(aMenu)
        }
    }
}


