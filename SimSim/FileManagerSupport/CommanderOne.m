/***************************************************************************
* Copyright (c) 2016 Artem Kirienko. All rights reserved.
****************************************************************************/
#import "CommanderOne.h"


@implementation CommanderOne

//----------------------------------------------------------------------------
+ (BOOL) isCommanderOneAvailable
{
    NSFileManager* fileManager = [NSFileManager defaultManager];

    // Check for App Store version
    BOOL isApplicationExist = [fileManager fileExistsAtPath:@"/Applications/Commander One.app"];
    BOOL isApplicationProExist = [fileManager fileExistsAtPath:@"/Applications/Commander One PRO.app"];
    if (isApplicationExist || isApplicationProExist)
    {
        return YES;
    }

    // Check for version from Web
    NSString* plistPath = [NSString stringWithFormat:@"%@/Library/Preferences/com.eltima.cmd1.plist", NSHomeDirectory()];
    BOOL isPlistExist = [fileManager fileExistsAtPath:plistPath];

    return isPlistExist;
}

//----------------------------------------------------------------------------
+ (void) openInCommanderOne:(NSString*)path
{
    // For some reason Commander One opens not the last folder in path
    path = [path stringByAppendingString:@"Library/"];

    NSPasteboard* pboard = [NSPasteboard generalPasteboard];
    [pboard clearContents];
    [pboard setPropertyList:@[path] forType:NSFilenamesPboardType];
    NSPerformService(@"reveal-in-commander1", pboard);
}

@end
