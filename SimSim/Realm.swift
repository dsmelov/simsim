import Foundation
import Cocoa

//============================================================================
class RealmFile: NSObject
{
    var fileName = ""
    var path = ""
    {
        didSet
        {
            // Make sure that path always ends with a slash
            if !path.hasSuffix("/")
            {
                path += "/"
            }
        }
    }

    //----------------------------------------------------------------------------
    func fullPath() -> String?
    {
        return path + fileName
    }
}

//============================================================================
class Realm: NSObject
{
    //----------------------------------------------------------------------------
    class func insertInstallerItem(for menu: NSMenu, withHotKey hotkey: NSNumber)
    {
        // There is at least one realm file but no realmbrowser installed
        let item = NSMenuItem(title: "Install Realm Studio", action: #selector(Realm.installRealmBrowser(_:)), keyEquivalent: "\(hotkey)")
        
        item.target = self
        item.representedObject = Constants.Realm.appUrl

        menu.addItem(item)
    }
    
    //----------------------------------------------------------------------------
    class func insertRealmFiles(files: NSArray, forPath aPath: String, for menu: NSMenu,
                                withHotKey hotkey: NSNumber, icon: NSImage)
    {
        var item: NSMenuItem
        
        if files.count == 1
        {
            // There is exactly one realm file
            item = NSMenuItem(title: "Realm Studio", action: #selector(Realm.openRealmFile(_:)), keyEquivalent: "\(hotkey)")
            item.representedObject = aPath
            item.image = icon
            item.target = self
            
            item.representedObject = (files.firstObject as! RealmFile).fullPath()
        }
        else
        {
            // There is more than one realm file
            item = NSMenuItem(title: "Realm Studio", action: nil, keyEquivalent: "\(hotkey)")
            item.representedObject = aPath
            item.image = icon
            
            let menuRealm = NSMenu(title: "Realm Studio")
            menuRealm.autoenablesItems = false
            
            let browserInstalled = isRealmBrowserAvailable()
            for file in files
            {
                let realmFile = file as! RealmFile
                let menuItem = NSMenuItem(title: realmFile.fileName as String, action: #selector(Realm.openRealmFile(_:)), keyEquivalent: "")
                menuItem.target = self
                menuItem.representedObject = realmFile.fullPath()
                menuItem.isEnabled = browserInstalled
                menuRealm.addItem(menuItem)
            }
            menu.setSubmenu(menuRealm, for: item)
        }
        menu.addItem(item)
    }
    
    //----------------------------------------------------------------------------
    class func generateRealmMenu(forPath aPath: String, for menu: NSMenu, withHotKey hotkey: NSNumber, icon: NSImage)
    {
        let files = findRealmFiles(aPath)!
        
        if files.count == 0
        {
            return
        }
        
        // Skip if there are no realm files
        if !isRealmBrowserAvailable()
        {
            insertInstallerItem(for: menu, withHotKey: hotkey)
        }
        else
        {
            insertRealmFiles(files: files, forPath: aPath, for: menu, withHotKey: hotkey, icon: icon)
        }

    }

    //----------------------------------------------------------------------------
    @objc
    class func openRealmFile(_ sender: NSMenuItem)
    {
        open(inRealmBrowser: sender.representedObject as! String)
    }
    
    //----------------------------------------------------------------------------
    @objc
    class func installRealmBrowser(_ sender: NSMenuItem)
    {
        openUrl(sender.representedObject as! String)
    }
    
    //----------------------------------------------------------------------------
    class func openUrl(_ aUrl: String)
    {
        if let anUrl = URL(string: aUrl)
        {
            NSWorkspace.shared.open(anUrl)
        }
    }

    //----------------------------------------------------------------------------
    class func findRealmFiles(_ aPath: String) -> NSArray?
    {
        let files = NSMutableArray()
        for realmPath: String? in Constants.Realm.dbPaths
        {
            guard realmPath != nil else
            {
                break
            }
            
            let folderPath = aPath + realmPath!
            
            let allFilesOfFolder = Tools.getSortedFiles(fromFolder: folderPath)
            
            for file in allFilesOfFolder
            {
                let fileName = Tools.getName(from: file) as NSString
                
                if (fileName.pathExtension == "realm")
                {
                    let realmFile = RealmFile()
                    realmFile.fileName = fileName as String
                    realmFile.path = folderPath
                    files.add(realmFile)
                }
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
        NSWorkspace.shared.openFile(aPath, withApplication: Constants.Realm.appName)
    }
}
