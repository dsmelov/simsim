import Foundation
import Cocoa

//----------------------------------------------------------------------------
@objc class ConfigSys: NSObject
{
    static let iconSize = 16
    static let maxRecentSimulators = 5

    struct Paths
    {
        static let finderApp = "/System/Library/CoreServices/Finder.app"
        static let terminalApp = "/Applications/Utilities/Terminal.app"
        static let iTermApp = "/Applications/iTerm.app"
        static let commanderOneApp = "/Applications/Commander One.app"
    }
}
