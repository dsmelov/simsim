//
//  AppGroup.swift
//  SimSim
//

import Foundation

class AppGroup {
    private let uuid: String
    let path: String
    let identifier: String

    var isAppleAppGroup: Bool {
        return identifier.starts(with: "com.apple") || identifier.starts(with: "group.com.apple")
    }

    private init(uuid: String, path: String, identifier: String) {
        self.uuid = uuid
        self.path = path
        self.identifier = identifier
    }

    convenience init?(dictionary: [AnyHashable : Any], simulator: Simulator) {
        guard let uuid = dictionary[Tools.Keys.fileName] as? String else {
            return nil
        }
        
        let path = simulator.pathForAppGroup(withUUID: uuid)

        let plistPath = path + ".com.apple.mobile_container_manager.metadata.plist"
        guard let plistData = try? Data(contentsOf: URL(fileURLWithPath: plistPath)) else {
            return nil
        }
        guard let metadataPlist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as! [String: Any] else {
            return nil
        }

        let identifier = metadataPlist["MCMMetadataIdentifier"] as! String

        self.init(uuid: uuid, path: path, identifier: identifier)
    }
}
