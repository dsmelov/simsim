//
//  Actions.swift
//  SimSim
//
//  Created by Daniil Smelov on 13/04/2018.
//  Copyright © 2018 Daniil Smelov. All rights reserved.
//

import Foundation
import Cocoa

//----------------------------------------------------------------------------
class Actions: NSObject
{
    //----------------------------------------------------------------------------
    class func copy(toPasteboard sender: NSMenuItem)
    {
        let path = sender.representedObject as! String
        let pasteboard = NSPasteboard.general
        pasteboard().declareTypes([NSPasteboardTypeString], owner: nil)
        pasteboard().setString(path, forType: NSPasteboardTypeString)
    }

    //----------------------------------------------------------------------------
    class func resetFolder(_ folder: String, inRoot root: String!)
    {
        let path = URL(fileURLWithPath: root).appendingPathComponent(folder).absoluteString
        let fm = FileManager()
        let en = fm.enumerator(atPath: path)
        while let file = en?.nextObject() as? String
        {
            do
            {
                try fm.removeItem(atPath: URL(fileURLWithPath: path).appendingPathComponent(file).absoluteString)
            }
            catch let error as NSError
            {
                print("Ooops! Something went wrong: \(error)")
            }
        }
    }

    //----------------------------------------------------------------------------
    class func resetApplication(_ sender: NSMenuItem)
    {
        let folders = ["Documents", "Library", "tmp"]
        
        for victim in folders
        {
            self.resetFolder(victim, inRoot: sender.representedObject as? String)
        }
    }

    //----------------------------------------------------------------------------
    class func open(item: NSMenuItem, with: String)
    {
        guard let path = item.representedObject as? String else { return }
        NSWorkspace.shared().openFile(path, withApplication: with)
    }
    
    //----------------------------------------------------------------------------
    class func open(inFinder sender: NSMenuItem)
    {
        open(item: sender, with: Constants.Actions.finder)
    }
    
    //----------------------------------------------------------------------------
    class func open(inTerminal sender: NSMenuItem)
    {
        open(item: sender, with: Constants.Actions.terminal)
    }

    //----------------------------------------------------------------------------
    class func openIniTerm(_ sender: NSMenuItem)
    {
        open(item: sender, with: Constants.Actions.iTerm)
    }
    
    //----------------------------------------------------------------------------
    class func open(inCommanderOne sender: NSMenuItem)
    {
        guard var path = sender.representedObject as? String else { return }
        
        // For some reason Commander One opens not the last folder in path
        path = path + ("Library/")
        let pasteboard = NSPasteboard.general
        pasteboard().clearContents()
        pasteboard().setPropertyList([path], forType: NSFilenamesPboardType)
        NSPerformService("reveal-in-commander1", pasteboard())
    }
    
    //----------------------------------------------------------------------------
    class func exitApp(_ sender: NSMenuItem)
    {
        NSApplication.shared().terminate(self)
    }

    //----------------------------------------------------------------------------
    class func handleStart(atLogin sender: NSMenuItem)
    {
        let isEnabled: Bool = sender.representedObject as! Bool
        
        Settings.isStartAtLoginEnabled = !isEnabled
        sender.representedObject = !isEnabled
        
        if isEnabled
        {
            sender.state = NSOffState
        }
        else
        {
            sender.state = NSOnState
        }
    }

    //----------------------------------------------------------------------------
    class func aboutApp(_ sender: NSMenuItem)
    {
        NSWorkspace.shared().open(URL(string: Constants.githubUrl)!)
    }

    //----------------------------------------------------------------------------
    class func openIn(withModifier sender: NSMenuItem)
    {
        guard let event = NSApp.currentEvent else { return }
        
        if event.modifierFlags.rawValue & NSAlternateKeyMask.rawValue != 0
        {
            Actions.open(inTerminal: sender)
        }
        else if event.modifierFlags.rawValue & NSControlKeyMask.rawValue != 0
        {
            if Tools.commanderOneAvailable()
            {
                Actions.open(inCommanderOne: sender)
            }
        }
        else
        {
            Actions.open(inFinder: sender)
        }
    }

}


























