// ***************************************************************************

import Foundation
import ServiceManagement

//============================================================================
class Settings
{
    // ----------------------------------------------------------------------------

    class var isStartAtLoginEnabled: Bool
    {
        get
        {
            return UserDefaults.standard.bool(forKey: Settings.SM_LOGIN_ENABLED)
        }
        set
        {
            SMLoginItemSetEnabled("com.dsmelov.SimSimHelper" as CFString, newValue)
            UserDefaults.standard.set(newValue, forKey: Settings.SM_LOGIN_ENABLED)
        }
    }

    private static let SM_LOGIN_ENABLED = "SM_LOGIN_ENABLED"
}
