//
//  AppDelegate.m
//  SimSim
//
//  Created by Daniil Smelov 2016.04.18
//  Copyright (c) 2016 Daniil Smelov. All rights reserved.
//

#import "AppDelegate.h"

#define KEY_FILE                @"file"
#define KEY_MODIFICATION_DATE   @"modificationDate"

//============================================================================
@interface AppDelegate ()

@property (strong, nonatomic) NSStatusItem* statusItem;

@end

//============================================================================
@implementation AppDelegate

//----------------------------------------------------------------------------
- (NSArray*) getSortedFilesFromFolder:(NSString*)folderPath
{
    NSArray* filesArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];

    // sort by creation date
    NSMutableArray* filesAndProperties = [NSMutableArray arrayWithCapacity:filesArray.count];

    for (NSString* file in filesArray)
    {
        if (![file isEqualToString:@".DS_Store"])
        {
            NSString* filePath = [folderPath stringByAppendingPathComponent:file];
            NSDictionary* properties = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
            NSDate* modificationDate = properties[NSFileModificationDate];

            [filesAndProperties addObject:@
            {
                KEY_FILE              : file,
                KEY_MODIFICATION_DATE : modificationDate
            }];
        }
    }

    // Sort using a block - order inverted as we want latest date first
    NSArray* sortedFiles = [filesAndProperties sortedArrayUsingComparator:^(NSDictionary* path1, NSDictionary* path2)
    {
        NSComparisonResult comp = [path1[@"modificationDate"] compare:path2[@"modificationDate"]];
        // invert ordering
        if (comp == NSOrderedDescending)
        {
            comp = NSOrderedAscending;
        }
        else if (comp == NSOrderedAscending)
        {
            comp = NSOrderedDescending;
        }
        return comp;
    }];

    return sortedFiles;
}

//----------------------------------------------------------------------------
- (NSString*) getApplicationFolderFromPath:(NSString*)folderPath
{
    NSArray* filesArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"SELF EndsWith '.app'"];
    filesArray = [filesArray filteredArrayUsingPredicate:predicate];

    return filesArray[0];
}

//----------------------------------------------------------------------------
- (NSImage*) scaleImage:(NSImage*)anImage toSize:(NSSize)size
{
    NSImage* sourceImage = anImage;

    if ([sourceImage isValid])
    {
        NSImage* smallImage = [[NSImage alloc] initWithSize:size];
        [smallImage lockFocus];
        [sourceImage setSize:size];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [sourceImage drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, size.width, size.height) operation:NSCompositeCopy fraction:1.0];
        [smallImage unlockFocus];

        return smallImage;
    }

    return nil;
}

//----------------------------------------------------------------------------
- (void) applicationDidFinishLaunching:(NSNotification*)aNotification
{
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

    _statusItem.image = [NSImage imageNamed:@"BarIcon"];
    _statusItem.image.template = YES;
    _statusItem.highlightMode = YES;
    _statusItem.action = @selector(presentApplicationMenu);
    _statusItem.enabled = YES;
}

//----------------------------------------------------------------------------
- (void) presentApplicationMenu
{
    NSMenu* menu = [NSMenu new];

    NSString* simulatorPropertiesPath =
        [NSString stringWithFormat:@"%@/Library/Preferences/com.apple.iphonesimulator.plist", NSHomeDirectory()];

    NSDictionary* simulatorProperties = [NSDictionary dictionaryWithContentsOfFile:simulatorPropertiesPath];

    NSString* simulatorUUID = simulatorProperties[@"CurrentDeviceUDID"];

    NSString* simulatorDetailsPath =
        [NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices/%@/device.plist", NSHomeDirectory(), simulatorUUID];

    NSDictionary* simulatorDetails = [NSDictionary dictionaryWithContentsOfFile:simulatorDetailsPath];

    NSString* installedApplicationsDataPath =
        [NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices/%@/data/Containers/Data/Application/", NSHomeDirectory(), simulatorUUID];

    NSArray* installedApplicationsData = [self getSortedFilesFromFolder:installedApplicationsDataPath];

    NSString* simulator_name = simulatorDetails[@"name"];
    NSString* simulator_runtime = [simulatorDetails[@"runtime"] stringByReplacingOccurrencesOfString:@"com.apple.CoreSimulator.SimRuntime." withString:@""];
    
    NSString* simulator_title = [NSString stringWithFormat:@"%@ (%@)", simulator_name, simulator_runtime];
    
    NSMenuItem* simulator = [[NSMenuItem alloc] initWithTitle:simulator_title action:nil keyEquivalent:@""];
    [simulator setEnabled:NO];
    [menu addItem:simulator];
    
    for (NSUInteger i = 0; i < [installedApplicationsData count]; i++)
    {
        NSString* appDataUUID = installedApplicationsData[i][KEY_FILE];

        NSString* applicationDataPropertiesPath =
            [NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices/%@/data/Containers/Data/Application/%@/.com.apple.mobile_container_manager.metadata.plist", NSHomeDirectory(), simulatorUUID, appDataUUID];

        NSDictionary* applicationDataProperties = [NSDictionary dictionaryWithContentsOfFile:applicationDataPropertiesPath];

        NSString* applicationBundleIdentifierFromData = applicationDataProperties[@"MCMMetadataIdentifier"];

        if (applicationDataProperties && ![applicationBundleIdentifierFromData hasPrefix:@"com.apple"])
        {
            NSString* installedApplicationsBundlePath =
                [NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices/%@/data/Containers/Bundle/Application/", NSHomeDirectory(), simulatorUUID];

            NSArray* installedApplicationsBundle = [self getSortedFilesFromFolder:installedApplicationsBundlePath];

            NSString* applicationIcon = nil;
            NSString* applicationVersion = @"";
            NSString* applicationVersionShort = @"";
            NSString* applicationBundleName = @"";
            NSString* iconPath = @"";

            for (NSUInteger j = 0; j < [installedApplicationsBundle count]; j++)
            {
                NSString* appBundleUUID = installedApplicationsBundle[j][KEY_FILE];

                NSString* applicationBundlePropertiesPath =
                    [NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices/%@/data/Containers/Bundle/Application/%@/.com.apple.mobile_container_manager.metadata.plist", NSHomeDirectory(), simulatorUUID, appBundleUUID];

                NSDictionary* applicationBundleProperties = [NSDictionary dictionaryWithContentsOfFile:applicationBundlePropertiesPath];

                NSString* bundleIdentifier = applicationBundleProperties[@"MCMMetadataIdentifier"];

                if ([bundleIdentifier isEqualToString:applicationBundleIdentifierFromData])
                {
                    NSString* applicationFolderName =
                        [self getApplicationFolderFromPath:[NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices/%@/data/Containers/Bundle/Application/%@/", NSHomeDirectory(), simulatorUUID, appBundleUUID]];

                    NSString* applicationPlistPath =
                        [NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices/%@/data/Containers/Bundle/Application/%@/%@/Info.plist",
                                                   NSHomeDirectory(), simulatorUUID, appBundleUUID, applicationFolderName];

                    NSDictionary* applicationPlist = [NSDictionary dictionaryWithContentsOfFile:applicationPlistPath];

                    applicationIcon = applicationPlist[@"CFBundleIconFile"];
                    applicationVersionShort = applicationPlist[@"CFBundleShortVersionString"];
                    applicationVersion = applicationPlist[@"CFBundleVersion"];
                    applicationBundleName = applicationPlist[@"CFBundleName"];

                    if (applicationIcon != nil)
                    {
                        iconPath =
                            [NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices/%@/data/Containers/Bundle/Application/%@/%@/%@",
                                                       NSHomeDirectory(), simulatorUUID, appBundleUUID, applicationFolderName, applicationIcon];
                    }
                    else
                    {
                        NSDictionary* applicationIcons = applicationPlist[@"CFBundleIcons"];
                        
                        if (!applicationIcons) {
                            applicationIcons = applicationPlist[@"CFBundleIcons~ipad"];
                        }
                        
                        NSDictionary* applicationPrimaryIcons = applicationIcons[@"CFBundlePrimaryIcon"];

                        NSArray* iconFiles = applicationPrimaryIcons[@"CFBundleIconFiles"];

                        applicationIcon = [iconFiles lastObject];

                        iconPath =
                            [NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices/%@/data/Containers/Bundle/Application/%@/%@/%@.png",
                                                       NSHomeDirectory(), simulatorUUID, appBundleUUID, applicationFolderName, applicationIcon];

                        NSFileManager* fileManager = [NSFileManager defaultManager];

                        if (![fileManager fileExistsAtPath:iconPath])
                        {
                            iconPath =
                                [NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices/%@/data/Containers/Bundle/Application/%@/%@/%@@2x.png",
                                                           NSHomeDirectory(), simulatorUUID, appBundleUUID, applicationFolderName, applicationIcon];
                        }
                    }

                    break;
                }
            }

            NSString* title = [NSString stringWithFormat:@"%@ (%@)",
                               applicationBundleName, applicationVersion];

            NSString* applicationContentPath =
            [NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices/%@/data/Containers/Data/Application/%@/",
             NSHomeDirectory(), simulatorUUID, appDataUUID];

            
            NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:title action:@selector(openInWithModifier:) keyEquivalent:[NSString stringWithFormat:@"Alt-%lu", (unsigned long)i]];
            [item setRepresentedObject:applicationContentPath];

            NSImage* icon = [[NSImage alloc] initWithContentsOfFile:iconPath];
            icon = [self scaleImage:icon toSize:NSMakeSize(16, 16)];
            [item setImage:icon];
            
            NSMenu* subMenu = [NSMenu new];
            
            NSMenuItem* terminal = [[NSMenuItem alloc] initWithTitle:@"Terminal" action:@selector(openInTerminal:) keyEquivalent:@"1"];
            [terminal setRepresentedObject:applicationContentPath];
            [subMenu addItem:terminal];
            
            NSMenuItem* finder = [[NSMenuItem alloc] initWithTitle:@"Finder" action:@selector(openInFinder:) keyEquivalent:@"2"];
            [finder setRepresentedObject:applicationContentPath];
            [subMenu addItem:finder];
            
            if ([self isCommanderOneAvailable])
            {
                NSMenuItem* commanderOne = [[NSMenuItem alloc] initWithTitle:@"Commander One" action:@selector(openInCommanderOne:) keyEquivalent:@"3"];
                [commanderOne setRepresentedObject:applicationContentPath];
                [subMenu addItem:commanderOne];
            }
            
            [item setSubmenu:subMenu];

            [menu addItem:item];
        }
    }

    [menu addItem:[NSMenuItem separatorItem]];

    NSString* appVersion = [NSString stringWithFormat:@"About %@ %@", [[NSRunningApplication currentApplication] localizedName], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    NSMenuItem* about = [[NSMenuItem alloc] initWithTitle:appVersion action:@selector(aboutApp:) keyEquivalent:@"I"];
    [menu addItem:about];

    NSMenuItem* quit = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(exitApp:) keyEquivalent:@"Q"];
    [menu addItem:quit];

    [_statusItem popUpStatusItemMenu:menu];
}

//----------------------------------------------------------------------------
- (void) openInWithModifier:(id)sender
{
    NSEvent *event = [NSApp currentEvent];
    
    if([event modifierFlags] & NSAlternateKeyMask)
    {
        [self openInTerminal:sender];
    }
    else
    if([event modifierFlags] & NSControlKeyMask)
    {
        if ([self isCommanderOneAvailable])
        {
            [self openInCommanderOne:sender];
        }
    }
    else
        [self openInFinder:sender];
}

//----------------------------------------------------------------------------
- (void) openInFinder:(id)sender
{
    NSString* path = (NSString*)[sender representedObject];
    
    [[NSWorkspace sharedWorkspace] openFile:path withApplication:@"Finder"];
}

//----------------------------------------------------------------------------
- (void) openInTerminal:(id)sender
{
    NSString* path = (NSString*)[sender representedObject];

    [[NSWorkspace sharedWorkspace] openFile:path withApplication:@"Terminal"];
}

//----------------------------------------------------------------------------
- (BOOL) isCommanderOneAvailable
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    // Check for App Store version
    NSString* applicationsPath = @"/Applications/Commander One.app";
    BOOL isApplicationExist = [fileManager fileExistsAtPath:applicationsPath];
    if (isApplicationExist)
    {
        return YES;
    }
    
    // Check for version from Web
    NSString* plistPath = [NSString stringWithFormat:@"%@/Library/Preferences/com.eltima.cmd1.plist", NSHomeDirectory()];
    BOOL isPlistExist = [fileManager fileExistsAtPath:plistPath];
    
    return isPlistExist;
}

//----------------------------------------------------------------------------
- (void) openInCommanderOne:(id)sender
{
    NSString* path = (NSString*)[sender representedObject];
    // For some reason Commander One opens not the last folder in path
    path = [path stringByAppendingString:@"Library/"];
    
    NSPasteboard* pboard = [NSPasteboard generalPasteboard];
    [pboard clearContents];
    [pboard setPropertyList:@[path] forType:NSFilenamesPboardType];
    NSPerformService(@"reveal-in-commander1", pboard);
}

//----------------------------------------------------------------------------
- (void) exitApp:(id)sender
{
    [[NSApplication sharedApplication] terminate:self];
}

//----------------------------------------------------------------------------
- (void) aboutApp:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/dsmelov/simsim"]];
}

@end
