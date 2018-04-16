//
//  Menus.swift
//  SimSim
//
//  Created by Daniil Smelov on 13/04/2018.
//  Copyright © 2018 Daniil Smelov. All rights reserved.
//

import Foundation
import Cocoa

//----------------------------------------------------------------------------
@objc class Menus: NSObject
{
    private static var realm = Realm()
    
    //----------------------------------------------------------------------------
    @objc class func addAction(_ title: String, toSubmenu submenu: NSMenu,
                               forPath path: String, withIcon iconPath: String,
                               andHotkey hotkey: NSNumber,
                               does selector: Selector) -> NSNumber
    {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: hotkey.stringValue)
        item.target = Actions.self
        item.representedObject = path
        
        item.image = NSWorkspace.shared().icon(forFile: iconPath)
        item.image?.size = NSMakeSize(CGFloat(ConfigSys.iconSize), CGFloat(ConfigSys.iconSize))
        
        submenu.addItem(item)
        
        return NSNumber(value: hotkey.intValue + 1)
    }
    
    //----------------------------------------------------------------------------
    @objc class func addAction(_ title: String, toSubmenu submenu: NSMenu,
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
    @objc class func realmModule() -> Realm
    {
        return realm
    }

    //----------------------------------------------------------------------------
    @objc class func addActionForRealm(to menu: NSMenu, forPath path: String,
                                       withHotkey hotkey: NSNumber) -> NSNumber
    {
        guard Realm.isRealmAvailable(forPath: path) else
        {
            return hotkey
        }
        
        let icon = NSWorkspace.shared().icon(forFile: Realm.applicationPath())
        icon.size = NSMakeSize(CGFloat(ConfigSys.iconSize), CGFloat(ConfigSys.iconSize))
        realm.generateMenu(forPath: path, for: menu, withHotKey: hotkey, icon: icon)
        return NSNumber(value: hotkey.intValue + 1)
    }

    //----------------------------------------------------------------------------
    @objc class func addActionForiTerm(to menu: NSMenu, forPath path: String, withHotkey hotkey: NSNumber) -> NSNumber
    {
        let iTermAppURLs = LSCopyApplicationURLsForBundleIdentifier("com.googlecode.iterm2" as CFString, nil)
        
        guard iTermAppURLs != nil else {
            return hotkey
        }
        
        let newkey = addAction("iTerm", toSubmenu: menu, forPath: path, withIcon: ConfigSys.Paths.iTermApp,
                               andHotkey: hotkey, does: #selector(Actions.openIniTerm(_:)))
        
        return NSNumber(value: newkey.intValue + 1)
    }
    
    //----------------------------------------------------------------------------
    @objc class func addSubMenus(to item: NSMenuItem, usingPath path: String)
    {
        let subMenu = NSMenu()
        var hotkey = NSNumber(value: 1)
        
        
        hotkey = addAction("Finder", toSubmenu: subMenu, forPath: path, withIcon: ConfigSys.Paths.finderApp, andHotkey: hotkey, does: #selector(Actions.open(inFinder:)))
        
        hotkey = addAction("Terminal", toSubmenu: subMenu, forPath: path, withIcon: ConfigSys.Paths.terminalApp, andHotkey: hotkey, does: #selector(Actions.open(inTerminal:)))

        hotkey = addActionForRealm(to: subMenu, forPath: path, withHotkey: hotkey)
        hotkey = addActionForiTerm(to: subMenu, forPath: path, withHotkey: hotkey)
        
        if Tools.commanderOneAvailable()
        {
            hotkey = addAction("Commander One", toSubmenu: subMenu, forPath: path, withIcon: ConfigSys.Paths.commanderOneApp, andHotkey: hotkey, does: #selector(Actions.open(inCommanderOne:)))
        }

        subMenu.addItem(NSMenuItem.separator())
        hotkey = addAction("Copy path to Clipboard", toSubmenu: subMenu, forPath: path, withHotkey: hotkey, does: #selector(Actions.copy(toPasteboard:)))
        
        hotkey = addAction("Reset application data", toSubmenu: subMenu, forPath: path, withHotkey: hotkey, does: #selector(Actions.resetApplication(_:)))
        item.submenu = subMenu
    }
    
    //----------------------------------------------------------------------------
    @objc class func add(_ application: Application?, to menu: NSMenu)
    {
        let title = "\(application?.bundleName ?? "") (\(application?.version ?? ""))"
        // This path will be opened on click
        let applicationContentPath = application?.contentPath
        let item = NSMenuItem(title: title, action: #selector(Actions.openIn(withModifier:)), keyEquivalent: "\0")
        item.target = Actions.self
        item.representedObject = applicationContentPath
        item.image = application?.icon
        self.addSubMenus(to: item, usingPath: applicationContentPath!)
        menu.addItem(item)
    }

    //----------------------------------------------------------------------------
    @objc class func addApplications(_ installedApplicationsData: [Application], to menu: NSMenu)
    {
        for i in 0..<installedApplicationsData.count
        {
            let application: Application? = installedApplicationsData[i]
            self.add(application, to: menu)
        }
    }

    //----------------------------------------------------------------------------
    @objc class func addServiceItems(to menu: NSMenu)
    {
        let startAtLogin = NSMenuItem(title: "Start at Login", action: #selector(Actions.handleStart(atLogin:)), keyEquivalent: "")
        startAtLogin.target = Actions.self
        let isStartAtLoginEnabled: Bool = Settings.isStartAtLoginEnabled()
        
        startAtLogin.state = isStartAtLoginEnabled ? NSOnState : NSOffState
        startAtLogin.representedObject = isStartAtLoginEnabled
        menu.addItem(startAtLogin)
        let appVersion = "About \(NSRunningApplication.current().localizedName ?? "") \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")"
        
        let about = NSMenuItem(title: appVersion, action: #selector(Actions.aboutApp(_:)), keyEquivalent: "I")
        about.target = Actions.self
        menu.addItem(about)
        
        let quit = NSMenuItem(title: "Quit", action: #selector(Actions.exitApp(_:)), keyEquivalent: "Q")
        quit.target = Actions.self
        menu.addItem(quit)
    }
    
    //----------------------------------------------------------------------------
    @objc class func createApplicationMenu(at statusItem: NSStatusItem) -> NSMenu
    {
        let menu = NSMenu()
        let simulators = Tools.activeSimulators()

        let recentSimulators = simulators.sorted { $0.date > $1.date }
        
        var simulatorsCount: Int = 0
        for simulator in recentSimulators
        {
            let installedApplications = Tools.installedApps(on: simulator)!
            
            if installedApplications.count != 0
            {
                let simulator_title = "\(simulator.name ?? "") (\(simulator.os ?? ""))"
                let simulatorMenuItem = NSMenuItem(title: simulator_title, action: nil, keyEquivalent: "")
                simulatorMenuItem.isEnabled = false
                menu.addItem(simulatorMenuItem)
                addApplications(installedApplications, to: menu)
                simulatorsCount += 1
            
                if simulatorsCount >= ConfigSys.maxRecentSimulators
                {
                    break
                }
            }
        }
        menu.addItem(NSMenuItem.separator())
        addServiceItems(to: menu)
        return menu

    }
}


























