//
//  Menus.swift
//  SimSim
//
//  Created by Daniil Smelov on 13/04/2018.
//  Copyright © 2018 Daniil Smelov. All rights reserved.
//

import Foundation
import Cocoa

//============================================================================
class Menus: NSObject
{
    private static var realm = Realm()
    
    //----------------------------------------------------------------------------
    class func addAction(_ title: String, toSubmenu submenu: NSMenu,
                         forPath path: String, withIcon iconPath: String,
                         andHotkey hotkey: NSNumber,
                         does selector: Selector) -> NSNumber
    {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: hotkey.stringValue)
        item.target = Actions.self
        item.representedObject = path
        
        item.image = NSWorkspace.shared.icon(forFile: iconPath)
        item.image?.size = NSMakeSize(CGFloat(Constants.iconSize), CGFloat(Constants.iconSize))
        
        submenu.addItem(item)
        
        return NSNumber(value: hotkey.intValue + 1)
    }
    
    //----------------------------------------------------------------------------
    class func addAction(_ title: String, toSubmenu submenu: NSMenu,
                               forPath path: String, withHotkey hotkey: NSNumber,
                               does selector: Selector) -> NSNumber
    {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: hotkey.stringValue)

        item.target = Actions.self
        item.representedObject = path
        
        submenu.addItem(item)
        return NSNumber(value: hotkey.intValue + 1)
    }

    //----------------------------------------------------------------------------
    class func realmModule() -> Realm
    {
        return realm
    }

    //----------------------------------------------------------------------------
    class func addActionForRealm(to menu: NSMenu, forPath path: String,
                                 withHotkey hotkey: NSNumber) -> NSNumber
    {
        guard Realm.isRealmAvailable(forPath: path) else
        {
            return hotkey
        }
        
        let icon = NSWorkspace.shared.icon(forFile: Realm.applicationPath())
        icon.size = NSMakeSize(CGFloat(Constants.iconSize), CGFloat(Constants.iconSize))
        Realm.generateRealmMenu(forPath: path, for: menu, withHotKey: hotkey, icon: icon)
        return NSNumber(value: hotkey.intValue + 1)
    }

    //----------------------------------------------------------------------------
    class func addActionForiTerm(to menu: NSMenu, forPath path: String, withHotkey hotkey: NSNumber) -> NSNumber
    {
        let iTermAppURLs = LSCopyApplicationURLsForBundleIdentifier(Constants.Other.iTermBundle as CFString, nil)
        
        guard iTermAppURLs != nil else {
            return hotkey
        }
        
        let newkey = addAction(Constants.Actions.iTerm, toSubmenu: menu, forPath: path, withIcon: Constants.Paths.iTermApp,
                               andHotkey: hotkey, does: #selector(Actions.openIniTerm(_:)))
        
        return NSNumber(value: newkey.intValue + 1)
    }
    
    //----------------------------------------------------------------------------
    class func addSubMenus(to item: NSMenuItem, usingPath path: String)
    {
        let subMenu = NSMenu()
        var hotkey = NSNumber(value: 1)
        
        
        hotkey = addAction(Constants.Actions.finder, toSubmenu: subMenu, forPath: path, withIcon: Constants.Paths.finderApp, andHotkey: hotkey, does: #selector(Actions.open(inFinder:)))
        
        hotkey = addAction(Constants.Actions.terminal, toSubmenu: subMenu, forPath: path, withIcon: Constants.Paths.terminalApp, andHotkey: hotkey, does: #selector(Actions.open(inTerminal:)))

        hotkey = addActionForRealm(to: subMenu, forPath: path, withHotkey: hotkey)
        hotkey = addActionForiTerm(to: subMenu, forPath: path, withHotkey: hotkey)
        
        if Tools.commanderOneAvailable()
        {
            hotkey = addAction(Constants.Actions.commanderOne, toSubmenu: subMenu, forPath: path, withIcon: Constants.Paths.commanderOneApp, andHotkey: hotkey, does: #selector(Actions.open(inCommanderOne:)))
        }

        subMenu.addItem(NSMenuItem.separator())
        hotkey = addAction(Constants.Actions.clipboard, toSubmenu: subMenu, forPath: path, withHotkey: hotkey, does: #selector(Actions.copy(toPasteboard:)))
        
        hotkey = addAction(Constants.Actions.reset, toSubmenu: subMenu, forPath: path, withHotkey: hotkey, does: #selector(Actions.resetApplication(_:)))
        item.submenu = subMenu
    }
    
    //----------------------------------------------------------------------------
    class func add(_ application: Application, to menu: NSMenu)
    {
        let title = "\(application.bundleName ?? "nil") \(application.version ?? "nil")"
        // This path will be opened on click
        let applicationContentPath = application.contentPath
        let item = NSMenuItem(title: title, action: #selector(Actions.openIn(withModifier:)), keyEquivalent: "\0")
        item.target = Actions.self
        item.representedObject = applicationContentPath
        item.image = application.icon
        self.addSubMenus(to: item, usingPath: applicationContentPath)
        menu.addItem(item)
    }

    //----------------------------------------------------------------------------
    class func add(_ applications: [Application], to menu: NSMenu)
    {
        for application in applications
        {
            add(application, to: menu)
        }
    }

    //----------------------------------------------------------------------------
    class func add(appGroup: AppGroup, to menu: NSMenu)
    {
        let item = NSMenuItem(title: appGroup.identifier, action: #selector(Actions.openIn(withModifier:)), keyEquivalent: "\0")
        item.target = Actions.self
        item.representedObject = appGroup.path

        self.addSubMenus(to: item, usingPath: appGroup.path)

        menu.addItem(item)
    }
    
    //----------------------------------------------------------------------------
    class func add(appExtension: AppExtension, to menu: NSMenu)
    {
        let item = NSMenuItem(title: appExtension.identifier, action: #selector(Actions.openIn(withModifier:)), keyEquivalent: "\0")
        item.target = Actions.self
        item.representedObject = appExtension.path
        
        self.addSubMenus(to: item, usingPath: appExtension.path)
        
        menu.addItem(item)
    }

    //----------------------------------------------------------------------------
    class func addServiceItems(to menu: NSMenu)
    {
        /*
         Start at login API was changed, so this feature needs to be updated:
         https://jogendra.dev/implementing-launch-at-login-feature-in-macos-apps

         let startAtLogin = NSMenuItem(title: Constants.Actions.login, action: #selector(Actions.handleStart(atLogin:)), keyEquivalent: "")
         startAtLogin.target = Actions.self
         let isStartAtLoginEnabled = Settings.isStartAtLoginEnabled

         startAtLogin.state = isStartAtLoginEnabled ? .on : .off
         startAtLogin.representedObject = isStartAtLoginEnabled
         menu.addItem(startAtLogin)
         */

        let appVersion = "About \(NSRunningApplication.current.localizedName ?? "") \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")"
        
        let about = NSMenuItem(title: appVersion, action: #selector(Actions.aboutApp(_:)), keyEquivalent: "I")
        about.target = Actions.self
        menu.addItem(about)
        
        let quit = NSMenuItem(title: Constants.Actions.quit, action: #selector(Actions.exitApp(_:)), keyEquivalent: "Q")
        quit.target = Actions.self
        menu.addItem(quit)
    }
    
    //----------------------------------------------------------------------------
    class func updateApplicationMenu(_ menu: NSMenu, at statusItem: NSStatusItem) -> Void
    {
        menu.removeAllItems()

        let simulators = Tools.activeSimulators()
        
        if simulators.isEmpty
        {
            let noSimulatorsItem = NSMenuItem(title: "No Simulators", action: nil, keyEquivalent: "")
            noSimulatorsItem.isEnabled = false
            menu.addItem(noSimulatorsItem)
        }

        let recentSimulators = simulators
            .sorted { $0.date > $1.date }
            .prefix(Constants.maxRecentSimulators)

        for simulator in recentSimulators
        {
            let installedApplications = Tools.installedApps(on: simulator)
            let sharedAppGroups = Tools.sharedAppGroups(on: simulator)
            let appExtensions = Tools.appExtensions(on: simulator)
            
            guard installedApplications.count != 0 else
            {
                continue
            }
            
            let simulatorTitle = simulator.name + " " + simulator.os
            let simulatorMenuItem = NSMenuItem(title: simulatorTitle, action: nil, keyEquivalent: "")
            simulatorMenuItem.isEnabled = false
            menu.addItem(simulatorMenuItem)
            add(installedApplications, to: menu)
            sharedAppGroups.forEach { add(appGroup: $0, to: menu) }
            appExtensions.forEach { add(appExtension: $0, to: menu) }
        }
        menu.addItem(NSMenuItem.separator())
        addServiceItems(to: menu)
    }
}


























