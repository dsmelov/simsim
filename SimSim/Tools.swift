//
//  Tools.swift
//  SimSim
//
//  Created by Daniil Smelov on 16/04/2018.
//  Copyright © 2018 Daniil Smelov. All rights reserved.
//

import Foundation
import Cocoa

//----------------------------------------------------------------------------
@objc class Tools: NSObject
{
    //----------------------------------------------------------------------------
    @objc class func homeDirectoryPath() -> String
    {
        return NSHomeDirectory()
    }

    //----------------------------------------------------------------------------
    @objc class func simulatorRootPath(byUUID uuid: String) -> String
    {
        return Tools.homeDirectoryPath() + "/Library/Developer/CoreSimulator/Devices/\(uuid)/"
    }

    //----------------------------------------------------------------------------
    @objc class func simulatorPaths() -> Set<String>
    {
        let simulatorPropertiesPath = Tools.homeDirectoryPath() + "/Library/Preferences/com.apple.iphonesimulator.plist"
        let simulatorProperties = NSDictionary(contentsOfFile: simulatorPropertiesPath)!
        let uuid = simulatorProperties["CurrentDeviceUDID"] as! String
        let devicePreferences = simulatorProperties["DevicePreferences"] as? NSDictionary
        
        var simulatorPaths = Set<String>()
        _ = simulatorPaths.insert(simulatorRootPath(byUUID: uuid))
        
        if devicePreferences != nil
        {
            // we're running on xcode 9
            for uuid: NSString in devicePreferences?.allKeys as! [NSString]
            {
                _ = simulatorPaths.insert(self.simulatorRootPath(byUUID: uuid as String))
            }
        }
        return simulatorPaths
    }

    //----------------------------------------------------------------------------
    @objc class func activeSimulators() -> [Simulator]
    {
        let simulatorPaths = self.simulatorPaths()
        var simulators = [AnyHashable]()
    
        for path in simulatorPaths
        {
            let simulatorDetailsPath = path + ("device.plist")
            let properties = NSDictionary(contentsOfFile: simulatorDetailsPath)
            if properties == nil
            {
                continue
            }
            
            // skip "empty" properties
            let simulator = Simulator(dictionary: properties as? [AnyHashable: Any], path: path)!
            simulators.append(simulator)
        }
        return simulators as! [Simulator]
    }

    //----------------------------------------------------------------------------
    @objc class func installedApps(on simulator: Simulator?) -> [Application]?
    {
        let installedApplicationsDataPath = (simulator?.path)! + ("data/Containers/Data/Application/")
        let installedApplications = Tools.getSortedFiles(fromFolder: installedApplicationsDataPath)
        var userApplications = [AnyHashable]()
        
        for app in installedApplications
        {
            let application = Application(dictionary: app as? [AnyHashable: Any], simulator: simulator)
            // BundleName and version cant be nil
            if application != nil && application?.bundleName != nil && application?.version != nil
            {
                if !(application?.isAppleApplication)!
                {
                    userApplications.append(application!)
                }
            }
        }
        return userApplications as? [Application]
    }

    //----------------------------------------------------------------------------
    @objc class func commanderOneAvailable() -> Bool
    {
        let fileManager = FileManager.default
        // Check for App Store version
        let isApplicationExist: Bool = fileManager.fileExists(atPath: "/Applications/Commander One.app")
        let isApplicationProExist: Bool = fileManager.fileExists(atPath: "/Applications/Commander One PRO.app")
        
        if isApplicationExist || isApplicationProExist
        {
            return true
        }
        
        // Check for version from Web
        let plistPath = "\(NSHomeDirectory())/Library/Preferences/com.eltima.cmd1.plist"
        let isPlistExist: Bool = fileManager.fileExists(atPath: plistPath)
        return isPlistExist
    }

    struct Keys
    {
        static let fileName = "fileName"
        static let fileDate = "modificationDate"
        static let fileType = "fileType"
    }
    
    //----------------------------------------------------------------------------
    @objc class func getFiles(fromFolder folderPath: String) -> NSArray
    {
        let filesArray = try? FileManager.default.contentsOfDirectory(atPath: folderPath)
        let filesAndProperties = NSMutableArray()
        
        for file: String in filesArray!
        {
            if !(file == ".DS_Store")
            {
                let filePath = folderPath + "/" + file
                let properties = try? FileManager.default.attributesOfItem(atPath: filePath)
                let modificationDate = properties![.modificationDate] as! Date
                let fileType = properties![.type] as! String
                
                filesAndProperties.add([Keys.fileName: file, Keys.fileDate: modificationDate, Keys.fileType: fileType])
            }
        }
        
        return filesAndProperties
    }
    
    //----------------------------------------------------------------------------
    @objc class func getName(from file: NSDictionary) -> NSString
    {
        return file.object(forKey: Keys.fileName) as! NSString
    }
    
    //----------------------------------------------------------------------------
    @objc class func getSortedFiles(fromFolder folderPath: String) -> [Any]
    {
        let filesAndProperties = getFiles(fromFolder: folderPath)
        
        let sortedFiles = filesAndProperties.sortedArray(comparator:
        {
            (object1, object2) -> ComparisonResult in
            
            let path1 : NSDictionary = object1 as! NSDictionary
            let path2 : NSDictionary = object2 as! NSDictionary
            
            let date1 = path1[Keys.fileDate] as! NSDate
            let date2 = path2[Keys.fileDate] as! NSDate
            
            var comp: ComparisonResult = (date1 as Date).compare(date2 as Date)
            
            if comp == .orderedDescending
            {
                comp = .orderedAscending
            }
            else
                if comp == .orderedAscending
                {
                    comp = .orderedDescending
            }
            
            return comp
        })
        
        return sortedFiles
    }
    
    //----------------------------------------------------------------------------
    @objc class func getApplicationFolder(fromPath folderPath: String) -> String
    {
        var filesArray = try? FileManager.default.contentsOfDirectory(atPath: folderPath)
        let predicate = NSPredicate(format: "SELF EndsWith '.app'")
        filesArray = ((filesArray as NSArray?)?.filtered(using: predicate) as! [String])
        return filesArray![0]
    }
}

