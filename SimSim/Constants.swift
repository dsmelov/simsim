import Foundation
import Cocoa

//----------------------------------------------------------------------------
class Constants: NSObject
{
    static let iconSize = 16
    static let maxRecentSimulators = 5
    
    static let githubUrl = "https://github.com/dsmelov/simsim"

    struct Paths
    {
        static let finderApp = "/System/Library/CoreServices/Finder.app"
        static let terminalApp = "/Applications/Utilities/Terminal.app"
        static let iTermApp = "/Applications/iTerm.app"
        static let commanderOneApp = "/Applications/Commander One.app"
        static let commanderOneProApp = "/Applications/Commander One PRO.app"
        static let realmApp = "/Applications/Realm Browser.app"
    }
    
    struct Actions
    {
        static let finder = "Finder"
        static let terminal = "Terminal"
        static let iTerm = "iTerm"
        static let commanderOne = "Commander One"
        static let clipboard = "Copy path to Clipboard"
        static let reset = "Reset application data"
        static let login = "Start at Login"
        static let quit = "Quit"
    }
    
    struct Realm
    {
        static let appName = "Realm Browser"
        static let appUrl = "http://itunes.apple.com/es/app/realm-browser/id1007457278"
        static let dbPaths: Array = ["Documents", "Library/Caches", nil]
    }
    
    struct Other
    {
        static let commanderOnePlist = "Library/Preferences/com.eltima.cmd1.plist"
        static let dsStore = ".DS_Store"
        static let iTermBundle = "com.googlecode.iterm2"
    }
    
    struct Simulator
    {
        static let deviceProperties = "device.plist"
        static let rootPath = "Library/Developer/CoreSimulator/Devices"
    }
}
