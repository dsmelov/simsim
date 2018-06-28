// ***************************************************************************

import Foundation

//============================================================================
class Settings
{
    //----------------------------------------------------------------------------
    class var isStartAtLoginEnabled: Bool
    {
        //----------------------------------------------------------------------------
        get
        {
            let appPath = Bundle.main.bundlePath
            
            var result = false
            
            if let loginItems = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil)?.takeRetainedValue()
            {
                let loginItemsArray = LSSharedFileListCopySnapshot(loginItems, nil).takeRetainedValue() as! [LSSharedFileListItem]
                
                for item in loginItemsArray
                {
                    guard let url = LSSharedFileListItemCopyResolvedURL(item, 0, nil)?.takeRetainedValue() as NSURL? else
                    {
                        continue
                    }
                    
                    if url.path == appPath
                    {
                        result = true
                    }
                }
            }
            
            return result
        }
        //----------------------------------------------------------------------------
        set
        {
            let appURL = Bundle.main.bundleURL
            
            if let loginItems = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil)?.takeRetainedValue()
            {
                if newValue
                {
                    LSSharedFileListInsertItemURL(loginItems,
                                                  nil, nil, nil,
                                                  appURL as CFURL, nil, nil).release()
                }
                else
                {
                    let loginItemsArray = LSSharedFileListCopySnapshot(loginItems, nil).takeRetainedValue() as! [LSSharedFileListItem]
                    
                    for item in loginItemsArray
                    {
                        if let url = LSSharedFileListItemCopyResolvedURL(item, 0, nil)?.takeRetainedValue() as URL?
                        {
                            if appURL.absoluteURL == url.absoluteURL
                            {
                                LSSharedFileListItemRemove(loginItems, item)
                            }
                        }
                    }
                }
            }
        }
    }
}
