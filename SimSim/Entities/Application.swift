// ***************************************************************************

import Foundation
import AppKit

//============================================================================
struct Application
{
    let uuid: String
    private(set) var bundleName: String? = nil
    private(set) var version: String? = nil
    private(set) var icon: NSImage? = nil
    let contentPath: String
    private let properties: NSDictionary
    
    //----------------------------------------------------------------------------
    init?(dictionary: NSDictionary, simulator: Simulator)
    {
        self.uuid = Tools.getName(from: dictionary) as String
        
        guard let (contentPath, properties) = Application.getApplicationProperties(byUUID: uuid, rootPath: simulator.path) else
        {
            return nil
        }

        self.contentPath = contentPath
        self.properties = properties
        
        buildMetadata(forBundle: self.bundleIdentifier, rootPath: simulator.path)
    }

    //----------------------------------------------------------------------------
    var isAppleApplication: Bool
    {
        return bundleIdentifier.hasPrefix("com.apple")
    }
    
    //----------------------------------------------------------------------------
    var bundleIdentifier: String
    {
        return properties["MCMMetadataIdentifier"] as? String ?? "unknown.bundle.identifier"
    }
    
    // MARK: - Private
    //----------------------------------------------------------------------------
    private static func applicationRootPath(byUUID uuid: String, rootPath: String) -> String
    {
        return rootPath.appendingFormat("data/Containers/Data/Application/%@/", uuid)
    }
    
    //----------------------------------------------------------------------------
    private static func getApplicationProperties(byUUID uuid: String, rootPath: String) -> (String, NSDictionary)?
    {
        let contentPath = applicationRootPath(byUUID: uuid, rootPath: rootPath)
    
        let applicationDataPropertiesPath = contentPath.appending(".com.apple.mobile_container_manager.metadata.plist")

        guard let dictionary = NSDictionary(contentsOfFile: applicationDataPropertiesPath) else
        {
            return nil
        }
    
        return (contentPath, dictionary)
    }
    
    //----------------------------------------------------------------------------
    private mutating func buildMetadata(forBundle applicationBundleIdentifier: String, rootPath simulatorRootPath: String)
    {
        let installedApplicationsBundlePath = simulatorRootPath.appending("data/Containers/Bundle/Application/")
    
        let installedApplicationsBundle = Tools.getSortedFiles(fromFolder: installedApplicationsBundlePath)

        process(bundles: installedApplicationsBundle,
                usingRootPath: simulatorRootPath,
                bundleIdentifier: applicationBundleIdentifier)
        {
            applicationRootBundlePath in
            
            let applicationFolderName = Tools.getApplicationFolder(fromPath: applicationRootBundlePath)

            let applicationFolderPath = applicationRootBundlePath.appendingFormat("%@/", applicationFolderName)

            let applicationPlistPath = applicationFolderPath.appending("Info.plist")

            guard let applicationPlist = NSDictionary(contentsOfFile: applicationPlistPath) else
            {
                return
            }

            let applicationVersion = applicationPlist["CFBundleVersion"] as? String
            var applicationBundleName = applicationPlist["CFBundleName"] as? String

            if applicationBundleName == nil || applicationBundleName?.count == 0
            {
                applicationBundleName = applicationPlist["CFBundleDisplayName"] as? String
            }

            let icon = getIconForApplication(withPlist: applicationPlist, folder: applicationFolderPath)

            self.bundleName = applicationBundleName
            self.version = applicationVersion
            self.icon = icon
        }
    }
    
    //----------------------------------------------------------------------------
    private func getIconForApplication(withPlist applicationPlist: NSDictionary, folder applicationFolderPath: String) -> NSImage
    {
        var iconPath: String?
        let fileManager = FileManager.default

        if let applicationIcon = applicationPlist["CFBundleIconFile"] as? String
        {
            iconPath = applicationFolderPath.appending(applicationIcon)
        }
        else
        {
            var applicationIcons = applicationPlist["CFBundleIcons"] as? NSDictionary

            var postfix = ""

            if applicationIcons == nil
            {
                applicationIcons = applicationPlist["CFBundleIcons~ipad"] as? NSDictionary
                postfix = "~ipad"
            }

            if let applicationPrimaryIcons = applicationIcons?["CFBundlePrimaryIcon"] as? NSDictionary
            {
                if let iconFiles = applicationPrimaryIcons["CFBundleIconFiles"] as? [String],
                   let applicationIcon = iconFiles.last
                {
                    iconPath = applicationFolderPath.appendingFormat("%@%@.png", applicationIcon, postfix)

                    if !fileManager.fileExists(atPath: iconPath!)
                    {
                        iconPath = applicationFolderPath.appendingFormat("%@@2x%@.png", applicationIcon, postfix)
                    }
                }
                else
                {
                    iconPath = nil
                }
            }
            else
            {
                iconPath = nil
            }
        }

        guard let path = iconPath,
              let icon = NSImage(contentsOfFile: path),
              let scaledIcon = scale(icon, toSize: NSMakeSize(24, 24)) else
        {
            return NSImage(named: "empty_icon")!
        }

        return roundCorners(scaledIcon)
    }
    
    //----------------------------------------------------------------------------
    private func scale(_ image: NSImage, toSize size: NSSize) -> NSImage?
    {
        let sourceImage = image
    
        if sourceImage.isValid
        {
            let smallImage = NSImage(size: size)
            smallImage.lockFocus()
            sourceImage.size = size
            NSGraphicsContext.current()?.imageInterpolation = .high
            sourceImage.draw(at: NSPoint.zero,
                    from: CGRect(x: 0, y: 0, width: size.width, height: size.height),
                    operation: NSCompositingOperation.copy,
                    fraction: 1)
            smallImage.unlockFocus()

            return smallImage
        }

        return nil
    }
    
    //----------------------------------------------------------------------------
    private func process(bundles: [NSDictionary],
                 usingRootPath simulatorRootPath: String,
                 bundleIdentifier applicationBundleIdentifier: String,
                 completion:(String) -> Void)
    {
        for bundle in bundles
        {
            let appBundleUUID = Tools.getName(from: bundle)

            let applicationRootBundlePath =
                    simulatorRootPath.appendingFormat("data/Containers/Bundle/Application/%@/", appBundleUUID)

            let applicationBundlePropertiesPath =
                    applicationRootBundlePath.appending(".com.apple.mobile_container_manager.metadata.plist")

            let applicationBundleProperties =
                NSDictionary(contentsOfFile: applicationBundlePropertiesPath)

            let bundleIdentifier = applicationBundleProperties?["MCMMetadataIdentifier"] as? String

            if bundleIdentifier == applicationBundleIdentifier
            {
                completion(applicationRootBundlePath)
                break
            }
        }
    }
    
    //----------------------------------------------------------------------------
    private func roundCorners(_ image: NSImage) -> NSImage
    {
        let existingImage = image
        let existingSize = existingImage.size
        let newSize = NSMakeSize(existingSize.width, existingSize.height)
        let composedImage = NSImage(size: newSize)
    
        composedImage.lockFocus()
        NSGraphicsContext.current()?.imageInterpolation = .high
    
        let imageFrame = NSRectFromCGRect(CGRect(x: 0, y: 0, width: existingSize.width, height: existingSize.height))
        let clipPath = NSBezierPath(roundedRect: imageFrame, xRadius: 3, yRadius: 3)
        clipPath.windingRule = .evenOddWindingRule
        clipPath.addClip()
    
        image.draw(at: NSZeroPoint,
                from: NSMakeRect(0, 0, newSize.width, newSize.height),
                operation:  NSCompositingOperation.sourceOver,
                fraction: 1)
    
        composedImage.unlockFocus()
    
        return composedImage
    }
}
