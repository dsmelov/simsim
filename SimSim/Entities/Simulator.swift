//
//  Simulator.swift
//  SimSim
//

import Foundation

//============================================================================
struct Simulator
{
    var path: String
    var date: Date
    private let properties: [AnyHashable : Any]
    
    //----------------------------------------------------------------------------
    init(dictionary: [AnyHashable : Any], path: String)
    {
        self.properties = dictionary
        self.path = path
        
        if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
           let modificationDate = attrs[FileAttributeKey.modificationDate] as? Date
        {
            self.date = modificationDate
        }
        else
        {
            self.date = Date()
        }
    }
    
    //----------------------------------------------------------------------------
    var name: String
    {
        return properties["name"] as? String ?? "Unknown Simulator"
    }
    
    //----------------------------------------------------------------------------
    var os: String
    {
        guard let runtime = properties["runtime"] as? String else
        {
            return "Unknown OS"
        }
        
        return runtime.replacingOccurrences(of: "com.apple.CoreSimulator.SimRuntime.", with: "")
            .replacingOccurrences(of: "OS-", with: "OS ")
            .replacingOccurrences(of: "-", with: ".")
    }
    
    //----------------------------------------------------------------------------
    func pathForAppGroup(withUUID uuid: String) -> String
    {
        return path + "data/Containers/Shared/AppGroup/\(uuid)/"
    }
}
