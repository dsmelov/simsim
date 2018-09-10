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
        return Tools.homeDirectoryPath() + "/" + Constants.Simulator.rootPath + "/" + uuid + "/"
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
            let propertiesPath = path + Constants.Simulator.deviceProperties
            guard let properties = NSDictionary(contentsOfFile: propertiesPath) as? [AnyHashable : Any] else
            {
                continue
            }
            
            let simulator = Simulator(dictionary: properties, path: path)
            
            simulators.append(simulator)
        }
        return simulators
    }

    //----------------------------------------------------------------------------
    class func validApplication(application: Application?) -> Bool
    {
        guard application != nil else
        {
            return false
        }
            
        guard application?.bundleName != nil else
        {
            return false
        }

        guard application?.version != nil else
        {
            return false
        }

        guard (application?.isAppleApplication)! == false else
        {
            return false
        }
        
        return true
    }
    
    //----------------------------------------------------------------------------
    class func installedApps(on simulator: Simulator) -> [Application]
    {
        let installedApplicationsDataPath = simulator.path + ("data/Containers/Data/Application/")
        let installedApplications = Tools.getSortedFiles(fromFolder: installedApplicationsDataPath)
        var userApplications = [Application]()
        
        for app in installedApplications
        {
            let application = Application(dictionary: app, simulator: simulator)
            
            if validApplication(application: application)
            {
                userApplications.append(application!)
            }
        }

        return userApplications
    }

    //----------------------------------------------------------------------------
    class func sharedAppGroups(on simulator: Simulator) -> [AppGroup]
    {
        let appGroupsDataPath = simulator.path + ("data/Containers/Shared/AppGroup/")
        let appGroups = Tools.getSortedFiles(fromFolder: appGroupsDataPath)

        return appGroups.compactMap({ AppGroup(dictionary: $0 as! [AnyHashable: Any], simulator: simulator) })
            .filter { !$0.isAppleAppGroup }
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
        let plistPath = NSHomeDirectory() + "/" + Constants.Other.commanderOnePlist
        let isPlistExist: Bool = fileManager.fileExists(atPath: plistPath)
        return isPlistExist
    }

    //----------------------------------------------------------------------------
    class func allFilesAt(path: String) -> [String]
    {
        let files = try? FileManager.default.contentsOfDirectory(atPath: path)
        return files ?? []
    }
    
    //----------------------------------------------------------------------------
    class func getFiles(fromFolder folderPath: String) -> [NSDictionary]
    {
        let files = allFilesAt(path: folderPath)
        var filesAndProperties: [NSDictionary] = []
        
        for file in files
        {
            if !(file == Constants.Other.dsStore)
            {
                let filePath = folderPath + "/" + file
                let properties = try? FileManager.default.attributesOfItem(atPath: filePath)
                let modificationDate = properties![.modificationDate] as! Date
                let fileType = properties![.type] as! String
                
                filesAndProperties.append([
                    Keys.fileName : file,
                    Keys.fileDate : modificationDate,
                    Keys.fileType : fileType
                ])
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
    class func getSortedFiles(fromFolder folderPath: String) -> [NSDictionary]
    {
        let filesAndProperties = getFiles(fromFolder: folderPath)
        
        let sortedFiles = filesAndProperties.sorted(by:
        {
            path1, path2 in
            
            guard let date1 = path1[Keys.fileDate] as? Date,
                  let date2 = path2[Keys.fileDate] as? Date else
            {
                return false
            }
            
            return date1 < date2
        })
        
        return sortedFiles
    }
    
    //----------------------------------------------------------------------------
    class func getApplicationFolder(fromPath folderPath: String) -> String
    {
        return allFilesAt(path: folderPath)
               .first(where: { URL(fileURLWithPath: $0).pathExtension == "app" })!
    }
}

