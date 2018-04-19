import Foundation
import Cocoa

//----------------------------------------------------------------------------
class RealmFile: NSObject
{
    var fileName = ""
    var path = ""

    //----------------------------------------------------------------------------
    func fullPath() -> String?
    {
        return path + fileName
    }
}

//----------------------------------------------------------------------------
class Realm: NSObject
{
    //----------------------------------------------------------------------------
    class func generateRealmMenu(forPath aPath: String, for menu: NSMenu, withHotKey hotkey: NSNumber, icon: NSImage)
    {
        let realmFiles = findRealmFiles(aPath)
        
        if realmFiles?.count == 0
        {
            return
        }
        
        // Skip if there are no realm files
        let isRealmBrowserInstalled = isRealmBrowserAvailable()
        var realmMenuItem: NSMenuItem? = nil
        if isRealmBrowserInstalled == false
        {
            // There is at least one realm file but no realmbrowser installed
            realmMenuItem = NSMenuItem(title: "Install Realm Browser", action: #selector(Realm.installRealmBrowser(_:)), keyEquivalent: "\(hotkey)")
            realmMenuItem?.target = self
            realmMenuItem?.representedObject = Constants.Realm.appUrl
        }
        else if realmFiles?.count == 1 {
            // There is exactly one realm file
            realmMenuItem = NSMenuItem(title: "Realm", action: #selector(Realm.openRealmFile(_:)), keyEquivalent: "\(hotkey)")
            realmMenuItem?.representedObject = aPath
            realmMenuItem?.image = icon
            realmMenuItem?.target = self
            
            realmMenuItem?.representedObject = (realmFiles?.firstObject as! RealmFile).fullPath()
        }
        else
        {
            // There is more than one realm file
            realmMenuItem = NSMenuItem(title: "Realm", action: nil, keyEquivalent: "\(hotkey)")
            realmMenuItem?.representedObject = aPath
            realmMenuItem?.image = icon
            let menuRealm = NSMenu(title: "Realm Browser")
            menuRealm.autoenablesItems = false
            for file in realmFiles! {
                let realmFile = file as! RealmFile
                let menuItem = NSMenuItem(title: realmFile.fileName as String, action: #selector(Realm.openRealmFile(_:)), keyEquivalent: "")
                menuItem.target = self
                menuItem.representedObject = realmFile.fullPath()
                menuItem.isEnabled = isRealmBrowserInstalled
                menuRealm.addItem(menuItem)
            }
            menu.setSubmenu(menuRealm, for: realmMenuItem!)
        }

        menu.addItem(realmMenuItem!)
    }

    //----------------------------------------------------------------------------
    class func openRealmFile(_ sender: NSMenuItem)
    {
        open(inRealmBrowser: sender.representedObject as! String)
    }
    
    //----------------------------------------------------------------------------
    class func installRealmBrowser(_ sender: NSMenuItem)
    {
        openUrl(sender.representedObject as! String)
    }
    
    //----------------------------------------------------------------------------
    class func openUrl(_ aUrl: String)
    {
        if let anUrl = URL(string: aUrl)
        {
            NSWorkspace.shared().open(anUrl)
        }
    }

    //----------------------------------------------------------------------------
    class func findRealmFiles(_ aPath: String) -> NSArray?
    {
        let files = NSMutableArray()
        for realmPath: String? in Constants.Realm.dbPaths
        {
            if realmPath == nil
            {
                break
            }
            
            let folderPath = aPath + realmPath!
            
            let allFilesOfFolder = Tools.getSortedFiles(fromFolder: folderPath)
            
            for file in allFilesOfFolder
            {
                let fileName = Tools.getName(from: file as! NSDictionary)
                if (URL(fileURLWithPath: fileName as String).pathExtension == "realm") == false
                {
                    continue
                }
                
                // Skip if not a realm file
                let realmFile = RealmFile()
                realmFile.fileName = fileName as String
                realmFile.path = folderPath as String
                files.add(realmFile)
            }
        }
        return files
    }

    //----------------------------------------------------------------------------
    class func removeNonRealmObject(_ allFiles: NSArray) -> NSArray
    {
        let endsRealm = NSPredicate(format: "self ENDSWITH '.realm'")
        return allFiles.filtered(using: endsRealm) as NSArray
    }

    //----------------------------------------------------------------------------
    class func isRealmBrowserAvailable() -> Bool
    {
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: applicationPath())
    }
    
    //----------------------------------------------------------------------------
    class func applicationPath() -> String
    {
        return Constants.Paths.realmApp
    }
    
    //----------------------------------------------------------------------------
    class func isRealmAvailable(forPath aPath: String) -> Bool
    {
        let realmFiles = findRealmFiles(aPath)
        return realmFiles != nil && realmFiles!.count > 0
    }
    
    //----------------------------------------------------------------------------
    class func open(inRealmBrowser aPath: String)
    {
        NSWorkspace.shared().openFile(aPath, withApplication: Constants.Realm.appName)
    }

}
