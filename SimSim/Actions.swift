//
//  Actions.swift
//  SimSim
//
//  Created by Daniil Smelov on 13/04/2018.
//  Copyright © 2018 DaniilSmelov. All rights reserved.
//

import Foundation
import Cocoa

//----------------------------------------------------------------------------
@objc class Actions: NSObject
{
    //----------------------------------------------------------------------------
    @objc class func copy(toPasteboard sender: NSMenuItem)
    {
        let path = sender.representedObject as! String
        let pasteboard = NSPasteboard.general
        pasteboard().declareTypes([NSPasteboardTypeString], owner: nil)
        pasteboard().setString(path, forType: NSPasteboardTypeString)
    }

    //----------------------------------------------------------------------------
    @objc class func takeScreenshot(_ sender: NSMenuItem)
    {
        let windows = CGWindowListCopyWindowInfo(.excludeDesktopElements, kCGNullWindowID) as! [[String: AnyObject]]
        for window in windows
        {
            let windowOwner = window[kCGWindowOwnerName as String] as! String
            guard let windowName = window[kCGWindowName as String] as? String else
            {
                continue
            }
            
            if (windowOwner.contains("Simulator")) &&
                (
                    windowName.contains("iPhone") ||
                    windowName.contains("iPad") ||
                    windowName.contains("Apple Watch") ||
                    windowName.contains("Apple TV")
                )
            {
                let windowID = window[kCGWindowNumber as String] as! CFNumber
                
                let boundsDictionary = window[kCGWindowBounds as String] as! CFDictionary
                guard let bounds = CGRect(dictionaryRepresentation: boundsDictionary),
                      let image = CGWindowListCreateImage(bounds, .optionIncludingWindow, CGWindowID(windowID), [])
                    else
                {
                    return
                }
                
                let dateComponents = "yyyyMMdd_HHmmss_SSSS"
                let dateFormatter = DateFormatter()
                dateFormatter.timeZone = NSTimeZone.local
                dateFormatter.dateFormat = dateComponents
                let dateString = dateFormatter.string(from: Date())
                let screenshotUrl = URL(fileURLWithPath: "\(Tools.homeDirectoryPath())/Desktop/Screen Shot at \(dateString).png")
                
                let bitmap = NSBitmapImageRep(cgImage: image)
                let data = bitmap.representation(using: NSPNGFileType, properties: [:])
                try? data?.write(to: screenshotUrl, options: [])
            }
        }
    }
    //----------------------------------------------------------------------------
    @objc class func resetFolder(_ folder: String, inRoot root: String!)
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
    @objc class func resetApplication(_ sender: NSMenuItem)
    {
        let path = sender.representedObject as? String
        
        self.resetFolder("Documents", inRoot: path)
        self.resetFolder("Library", inRoot: path)
        self.resetFolder("tmp", inRoot: path)
    }

    //----------------------------------------------------------------------------
    @objc class func open(inFinder sender: NSMenuItem)
    {
        guard let path = sender.representedObject as? String else { return }
        NSWorkspace.shared().openFile(path, withApplication: "Finder")
    }
    
    //----------------------------------------------------------------------------
    @objc class func open(inTerminal sender: NSMenuItem)
    {
        guard let path = sender.representedObject as? String else { return }
        NSWorkspace.shared().openFile(path, withApplication: "Terminal")
    }

    //----------------------------------------------------------------------------
    @objc class func openIniTerm(_ sender: NSMenuItem)
    {
        guard let path = sender.representedObject as? String else { return }
        NSWorkspace.shared().openFile(path, withApplication: "iTerm")
    }
    
    //----------------------------------------------------------------------------
    @objc class func open(inCommanderOne sender: NSMenuItem)
    {
        guard let path = sender.representedObject as? String else { return }
        CommanderOne.open(inCommanderOne: path)
    }
    
    //----------------------------------------------------------------------------
    @objc class func exitApp(_ sender: NSMenuItem)
    {
        NSApplication.shared().terminate(self)
    }

    //----------------------------------------------------------------------------
    @objc class func handleStart(atLogin sender: NSMenuItem)
    {
        let isEnabled: Bool = sender.representedObject != nil
        
        Settings.setStartAtLoginEnabled(!isEnabled)
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
    @objc class func aboutApp(_ sender: NSMenuItem)
    {
        let url = URL(string: "https://github.com/dsmelov/simsim")!
        NSWorkspace.shared().open(url)
    }

    //----------------------------------------------------------------------------
    @objc class func openIn(withModifier sender: NSMenuItem)
    {
        guard let event = NSApp.currentEvent else { return }
        
        if UInt8(event.modifierFlags.rawValue) & UInt8(NSAlternateKeyMask.rawValue) != 0
        {
            Actions.open(inTerminal: sender)
        }
        else if UInt8(event.modifierFlags.rawValue) & UInt8(NSControlKeyMask.rawValue) != 0
        {
            if CommanderOne.isCommanderOneAvailable()
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


























