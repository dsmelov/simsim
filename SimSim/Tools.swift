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
class Tools: NSObject
{
    //----------------------------------------------------------------------------
    struct Keys
    {
        static let fileName = "fileName"
        static let fileDate = "modificationDate"
        static let fileType = "fileType"
    }

    //----------------------------------------------------------------------------
    class func homeDirectoryPath() -> String
    {
        return NSHomeDirectory()
    }

    //----------------------------------------------------------------------------
    class func simulatorRootPath(byUUID uuid: String) -> String
    {
        return Tools.homeDirectoryPath() + "/Library/Developer/CoreSimulator/Devices/\(uuid)/"
    }

    
    //----------------------------------------------------------------------------
    class func getSimulatorProperties() -> NSDictionary
    {
        let path = Tools.homeDirectoryPath() + "/Library/Preferences/com.apple.iphonesimulator.plist"
        return NSDictionary(contentsOfFile: path)!
    }
    
    //----------------------------------------------------------------------------
    class func simulatorPaths() -> Set<String>
    {
        let properties = getSimulatorProperties()
        
        let uuid = properties["CurrentDeviceUDID"] as! String
        let devicePreferences = properties["DevicePreferences"] as? NSDictionary
        
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
    class func activeSimulators() -> [Simulator]
    {
        let paths = self.simulatorPaths()
        var simulators = [Simulator]()
    
        for path in paths
        {
            let properties = NSDictionary(contentsOfFile: path + "device.plist")

            // skip "empty" properties
            guard properties != nil else
            {
                continue
            }
            
            let simulator = Simulator(dictionary: properties as? [AnyHashable: Any], path: path)!
            
            simulators.append(simulator)
        }
        return simulators
    }

    //----------------------------------------------------------------------------
    class func installedApps(on simulator: Simulator?) -> [Application]?
    {
        let installedApplicationsDataPath = (simulator?.path)! + ("data/Containers/Data/Application/")
        let installedApplications = Tools.getSortedFiles(fromFolder: installedApplicationsDataPath)
        var userApplications = [Application]()
        
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
        return userApplications
    }

    //----------------------------------------------------------------------------
    class func commanderOneAvailable() -> Bool
    {
        let fileManager = FileManager.default
        
        // Check for App Store version
        let isApplicationExist: Bool = fileManager.fileExists(atPath: Constants.Paths.commanderOneApp)
        let isApplicationProExist: Bool = fileManager.fileExists(atPath: Constants.Paths.commanderOneProApp)
        
        if isApplicationExist || isApplicationProExist
        {
            return true
        }
        
        // Check for version from Web
        let plistPath = "\(NSHomeDirectory())/Library/Preferences/com.eltima.cmd1.plist"
        let isPlistExist: Bool = fileManager.fileExists(atPath: plistPath)
        return isPlistExist
    }

    //----------------------------------------------------------------------------
    class func allFilesAt(path: String) -> [String]
    {
        let files = try? FileManager.default.contentsOfDirectory(atPath: path)
        return files!
    }
    
    //----------------------------------------------------------------------------
    class func getFiles(fromFolder folderPath: String) -> NSArray
    {
        let files = allFilesAt(path: folderPath)
        let filesAndProperties = NSMutableArray()
        
        for file in files
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
    class func getName(from file: NSDictionary) -> NSString
    {
        return file.object(forKey: Keys.fileName) as! NSString
    }
    
    //----------------------------------------------------------------------------
    class func getSortedFiles(fromFolder folderPath: String) -> [Any]
    {
        let filesAndProperties = getFiles(fromFolder: folderPath)
        
        let sortedFiles = filesAndProperties.sortedArray(comparator:
        {
            (path1, path2) -> ComparisonResult in
            
            let date1 = (path1 as! NSDictionary)[Keys.fileDate] as! Date
            let date2 = (path2 as! NSDictionary)[Keys.fileDate] as! Date
            
            var comp: ComparisonResult = date1.compare(date2)
            
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
    class func getApplicationFolder(fromPath folderPath: String) -> String
    {
        var files = allFilesAt(path: folderPath)
        let predicate = NSPredicate(format: "SELF EndsWith '.app'")
        files = ((files as NSArray).filtered(using: predicate) as! [String])
        return files[0]
    }
}

