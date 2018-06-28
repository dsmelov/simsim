//
//  Simulator.swift
//  SimSim
//

import Foundation

extension Simulator {
    func pathForAppGroup(withUUID uuid: String) -> String {
        return path + "data/Containers/Shared/AppGroup/\(uuid)/"
    }
}
