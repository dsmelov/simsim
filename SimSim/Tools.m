//
//  Tools.m
//  SimSim
//
//  Created by Daniil Smelov on 05.04.18.
//  Copyright © 2018 Daniil Smelov. All rights reserved.
//

#import "Tools.h"

@implementation Tools

//----------------------------------------------------------------------------
+ (NSString*) homeDirectoryPath
{
    return NSHomeDirectory();
}

//----------------------------------------------------------------------------
+ (BOOL) simulatorRunning
{
    NSArray* windows = (NSArray *)CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListExcludeDesktopElements, kCGNullWindowID));
    
    for (NSDictionary* window in windows)
    {
        NSString* windowOwner = window[(NSString*)kCGWindowOwnerName];
        NSString* windowName = window[(NSString*)kCGWindowName];
        
        if ([windowOwner containsString:@"Simulator"] &&
            ([windowName containsString:@"iOS"] || [windowName containsString:@"watchOS"] || [windowName containsString:@"tvOS"]))
        {
            return YES;
        }
    }
    
    return NO;
}

@end
