//
//  Application.swift
//  SimSim
//
//  Created by Daniil Smelov on 19/04/2018.
//  Copyright © 2018 Daniil Smelov. All rights reserved.
//

import Cocoa

//============================================================================
class AppDelegate: NSObject
{
    var statusItem: NSStatusItem?

    private func killSimSimHelperIfNeeded()
    {
        let launcherAppId = "com.dsmelov.SimSimHelper"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == launcherAppId }.isEmpty

        if isRunning
        {
            DistributedNotificationCenter.default().post(name: .killLauncher, object: Bundle.main.bundleIdentifier!)
        }
    }
}

//============================================================================
extension AppDelegate
{
    @objc
    func quit(sender: NSMenuItem)
    {
        NSApp.terminate(self)
    }
}

//============================================================================
extension AppDelegate: NSApplicationDelegate
{
    // ----------------------------------------------------------------------------
    func applicationDidFinishLaunching(_ notification: Notification)
    {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        item.image = NSImage(named: "BarIcon")
        item.image?.isTemplate = true
        item.highlightMode = true
        item.isEnabled = true

        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu

        statusItem = item

        killSimSimHelperIfNeeded()
    }
}

//============================================================================
extension AppDelegate: NSMenuDelegate
{
    //----------------------------------------------------------------------------
    func menuNeedsUpdate(_ menu: NSMenu) {
        Menus.updateApplicationMenu(menu, at: self.statusItem!)
    }
}

//============================================================================
extension Notification.Name
{
    static let killLauncher = Notification.Name("killLauncher")
}
