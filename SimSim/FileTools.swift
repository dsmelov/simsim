//
//  FileTools.swift
//  SimSim
//
//  Created by Daniil Smelov on 16/04/2018.
//  Copyright © 2018 Daniil Smelov. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------
@objc class FileTools: NSObject
{
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


