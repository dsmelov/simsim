import Cocoa

extension Notification.Name {
  static let killLauncher = Notification.Name("killLauncher")
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let mainAppIdentifier = "com.dsmelov.SimSim"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == mainAppIdentifier }.isEmpty

        if isRunning {
            terminate()
            return
        }

        DistributedNotificationCenter.default()
            .addObserver(
                self,
                selector: #selector(terminate),
                name: .killLauncher,
                object: mainAppIdentifier
            )

        var components = (Bundle.main.bundlePath as NSString).pathComponents
        components.removeLast()
        components.removeLast()
        components.removeLast()
        components.removeLast()

        let applicationPath = NSString.path(withComponents: components)
        let applicationURL = URL(fileURLWithPath: applicationPath)
        if #available(macOS 10.15, *) {
            NSWorkspace.shared.openApplication(at: applicationURL, configuration: NSWorkspace.OpenConfiguration())
        } else {
            NSWorkspace.shared.launchApplication(applicationPath as String)
        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    @objc func terminate() {
        NSApp.terminate(nil)
    }
}
