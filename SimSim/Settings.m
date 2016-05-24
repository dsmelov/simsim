//
//  Settings.m
//  SimSim
//
//  Created by Artem Kirienko on 22.04.16.
//  Copyright © 2016 DaniilSmelov. All rights reserved.
//

#import "Settings.h"

@implementation Settings

//----------------------------------------------------------------------------
+ (void) setStartAtLoginEnabled:(BOOL)isEnabled
{
    NSString* appPath = [[NSBundle mainBundle] bundlePath];
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
    
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
    if (loginItems)
    {
        if (isEnabled)
        {
            //Insert an item to the list.
            LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems,
                                                                         kLSSharedFileListItemLast, NULL, NULL,
                                                                         url, NULL, NULL);
            if (item)
            {
                CFRelease(item);
            }
            
        }
        else
        {
            UInt32 seedValue;
            CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(loginItems, &seedValue);
            
            for (id item in (__bridge NSArray *)loginItemsArray)
            {
                LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
                url = LSSharedFileListItemCopyResolvedURL(itemRef, 0, NULL);
                if (url)
                {
                    NSString* urlPath = [(__bridge NSURL*)url path];
                    if ([urlPath compare:appPath] == NSOrderedSame)
                    {
                        LSSharedFileListItemRemove(loginItems, itemRef);
                    }
                    CFRelease(url);
                }
            }
            CFRelease(loginItemsArray);
        }
        
        CFRelease(loginItems);
    }
    
}

//----------------------------------------------------------------------------
+ (BOOL) isStartAtLoginEnabled
{
    NSString* appPath = [[NSBundle mainBundle] bundlePath];
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
    BOOL ret = NO;
    
    if (loginItems)
    {
        UInt32 seedValue;
        //Retrieve the list of Login Items and cast them to
        // a NSArray so that it will be easier to iterate.
        
        CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(loginItems, &seedValue);
        
        for (id item in (__bridge NSArray*)loginItemsArray)
        {
            LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
            //Resolve the item with URL
            url = LSSharedFileListItemCopyResolvedURL(itemRef, 0, NULL);
            if (url)
            {
                NSString* urlPath = [(__bridge NSURL*)url path];
                if ([urlPath compare:appPath] == NSOrderedSame)
                {
                    ret = YES;
                }
                CFRelease(url);
            }
        }
        CFRelease(loginItemsArray);
        CFRelease(loginItems);
    }
    
    return ret;
}

@end
