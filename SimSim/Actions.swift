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
        let path = sender.representedObject as? String
        let pasteboard = NSPasteboard.general
        pasteboard().declareTypes([NSPasteboardTypeString], owner: nil)
        pasteboard().setString(path!, forType: NSPasteboardTypeString)
    }

    //----------------------------------------------------------------------------
    @objc class func takeScreenshot(_ sender: NSMenuItem)
    {
//        let windows = CGWindowListCopyWindowInfo(.excludeDesktopElements, kCGNullWindowID) as NSArray? as? [[String: AnyObject]]
//        for window in windows!
//        {
//            let windowOwner = window[kCGWindowOwnerName as String]
//            let windowName = window[kCGWindowName as String]
//            if (windowOwner?.contains("Simulator"))! && ((windowName?.contains("iOS"))! ||
//                (windowName?.contains("watchOS"))! || (windowName?.contains("tvOS"))!)
//            {
//                let windowID = window[kCGWindowNumber as String]
//
//                var dateComponents = "yyyyMMdd_HHmmss_SSSS"
//                var dateFormatter = DateFormatter()
//                dateFormatter.timeZone = NSTimeZone.local
//                dateFormatter.dateFormat = dateComponents
//                var date = Date()
//                var dateString = dateFormatter.string(from: date)
//
//                var screenshotPath = "\(Tools.homeDirectoryPath())/Desktop/Screen Shot at \(dateString).png"
//                var bounds = CGRect.zero
//                CGRectMakeWithDictionaryRepresentation((window[kCGWindowBounds as String] as? CFDictionary?)!, &bounds)
//                var image = CGWindowListCreateImage(bounds, .optionIncludingWindow, CGWindowID(windowID), [])
//                var bitmap = NSBitmapImageRep(cgImage: image)
//                var data: Data? = bitmap.representation(using: NSPNGFileType, properties: [:])
//                data?.write(to: screenshotPath, options: false)
//                CGImageRelease(image)
//            }
//        }
    }
    //----------------------------------------------------------------------------
    @objc class func resetFolder(_ folder: String, inRoot root: String!)
    {
        let path = URL(fileURLWithPath: root ).appendingPathComponent(folder).absoluteString
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
        let path = sender.representedObject as? String
        NSWorkspace.shared().openFile(path!, withApplication: "Finder")
    }
    
    //----------------------------------------------------------------------------
    @objc class func open(inTerminal sender: NSMenuItem)
    {
        let path = sender.representedObject as? String
        NSWorkspace.shared().openFile(path!, withApplication: "Terminal")
    }

    //----------------------------------------------------------------------------
    @objc class func openIniTerm(_ sender: NSMenuItem)
    {
        let path = sender.representedObject as? String
        NSWorkspace.shared().openFile(path ?? "", withApplication: "iTerm")
    }
    
    //----------------------------------------------------------------------------
    @objc class func open(inCommanderOne sender: NSMenuItem)
    {
        let path = sender.representedObject as? String
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
        } else
        {
            sender.state = NSOnState
        }
    }

    //----------------------------------------------------------------------------
    @objc class func aboutApp(_ sender: NSMenuItem)
    {
        if let aString = URL(string: "https://github.com/dsmelov/simsim") {
            NSWorkspace.shared().open(aString)
        }
    }

    //----------------------------------------------------------------------------
    @objc class func openIn(withModifier sender: NSMenuItem)
    {
        let event: NSEvent? = NSApp.currentEvent
        if (UInt8((event?.modifierFlags)!.rawValue) & UInt8(NSAlternateKeyMask.rawValue) != 0)
        {
            Actions.open(inTerminal: sender)
        }
        else
        if (UInt8((event?.modifierFlags)!.rawValue) & UInt8(NSControlKeyMask.rawValue) != 0)
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


























