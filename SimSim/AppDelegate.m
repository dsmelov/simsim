//
//  AppDelegate.m
//  SimSim
//
//  Created by Daniil Smelov 2016.04.18
//  Copyright (c) 2016 Daniil Smelov. All rights reserved.
//

#import "AppDelegate.h"
#import "CommanderOne.h"
#import "Settings.h"

#define KEY_FILE                    @"file"
#define KEY_MODIFICATION_DATE       @"modificationDate"
#define HIDE_SUBMENUS_PREFERENCE    @"hideSubMenus"
#define ALREADY_LAUNCHED_PREFERENCE @"alreadyLaunched"

//============================================================================
@interface AppDelegate ()

@property (strong, nonatomic) NSStatusItem* statusItem;
@property (nonatomic) BOOL hideSubMenus;

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
    
    BOOL firstLaunch = ![[NSUserDefaults standardUserDefaults] boolForKey:ALREADY_LAUNCHED_PREFERENCE];
    
    if (firstLaunch)
    {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:HIDE_SUBMENUS_PREFERENCE];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:ALREADY_LAUNCHED_PREFERENCE];
    }
    
    self.hideSubMenus = [[NSUserDefaults standardUserDefaults] boolForKey:HIDE_SUBMENUS_PREFERENCE];
}

//----------------------------------------------------------------------------
- (void) presentApplicationMenu
{
    NSMenu* menu = [NSMenu new];

    NSString* simulatorPropertiesPath =
        [NSString stringWithFormat:@"%@/Library/Preferences/com.apple.iphonesimulator.plist", NSHomeDirectory()];

    NSDictionary* simulatorProperties = [NSDictionary dictionaryWithContentsOfFile:simulatorPropertiesPath];

    NSString* simulatorUUID = simulatorProperties[@"CurrentDeviceUDID"];

    NSString* simulatorRootPath = [NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices/%@/", NSHomeDirectory(), simulatorUUID];

    NSString* simulatorDetailsPath = [simulatorRootPath stringByAppendingString:@"device.plist"];

    NSDictionary* simulatorDetails = [NSDictionary dictionaryWithContentsOfFile:simulatorDetailsPath];

    NSString* installedApplicationsDataPath = [simulatorRootPath stringByAppendingString:@"data/Containers/Data/Application/"];

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

        NSString* applicationRootPath = [simulatorRootPath stringByAppendingFormat:@"data/Containers/Data/Application/%@/", appDataUUID];

        NSString* applicationDataPropertiesPath = [applicationRootPath stringByAppendingString:@".com.apple.mobile_container_manager.metadata.plist"];

        NSDictionary* applicationDataProperties = [NSDictionary dictionaryWithContentsOfFile:applicationDataPropertiesPath];

        NSString* applicationBundleIdentifierFromData = applicationDataProperties[@"MCMMetadataIdentifier"];

        if (applicationDataProperties && ![applicationBundleIdentifierFromData hasPrefix:@"com.apple"])
        {
            NSString* installedApplicationsBundlePath = [simulatorRootPath stringByAppendingString:@"data/Containers/Bundle/Application/"];

            NSArray* installedApplicationsBundle = [self getSortedFilesFromFolder:installedApplicationsBundlePath];

            NSString* applicationVersion = @"";
            NSString* applicationBundleName = @"";
            NSImage* icon;

            for (NSUInteger j = 0; j < [installedApplicationsBundle count]; j++)
            {
                NSString* appBundleUUID = installedApplicationsBundle[j][KEY_FILE];

                NSString* applicationRootBundlePath = [simulatorRootPath stringByAppendingFormat:@"data/Containers/Bundle/Application/%@/", appBundleUUID];

                NSString* applicationBundlePropertiesPath = [applicationRootBundlePath stringByAppendingString:@".com.apple.mobile_container_manager.metadata.plist"];

                NSDictionary* applicationBundleProperties = [NSDictionary dictionaryWithContentsOfFile:applicationBundlePropertiesPath];

                NSString* bundleIdentifier = applicationBundleProperties[@"MCMMetadataIdentifier"];

                if ([bundleIdentifier isEqualToString:applicationBundleIdentifierFromData])
                {
                    NSString* applicationFolderName = [self getApplicationFolderFromPath:applicationRootBundlePath];

                    NSString* applicationFolderPath = [applicationRootBundlePath stringByAppendingFormat:@"%@/", applicationFolderName];

                    NSString* applicationPlistPath = [applicationFolderPath stringByAppendingString:@"Info.plist"];

                    NSDictionary* applicationPlist = [NSDictionary dictionaryWithContentsOfFile:applicationPlistPath];

                    applicationVersion = applicationPlist[@"CFBundleVersion"];
                    applicationBundleName = applicationPlist[@"CFBundleName"];

                    icon = [self getIconForApplicationWithPlist:applicationPlist folder:applicationFolderPath];

                    break;
                }
            }

            NSString* title = [NSString stringWithFormat:@"%@ (%@)", applicationBundleName, applicationVersion];

            // This path will be opened on click
            NSString* applicationContentPath = applicationRootPath;

            NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:title action:@selector(openInWithModifier:) keyEquivalent:[NSString stringWithFormat:@"Alt-%lu", (unsigned long)i]];
            [item setRepresentedObject:applicationContentPath];

            [item setImage:icon];
            
            if (!self.hideSubMenus)
            {
                NSMenu* subMenu = [NSMenu new];
                
                NSMenuItem* terminal = [[NSMenuItem alloc] initWithTitle:@"Terminal" action:@selector(openInTerminal:) keyEquivalent:@"1"];
                [terminal setRepresentedObject:applicationContentPath];
                [subMenu addItem:terminal];
                
                NSMenuItem* finder = [[NSMenuItem alloc] initWithTitle:@"Finder" action:@selector(openInFinder:) keyEquivalent:@"2"];
                [finder setRepresentedObject:applicationContentPath];
                [subMenu addItem:finder];
                
                if ([CommanderOne isCommanderOneAvailable])
                {
                    NSMenuItem* commanderOne = [[NSMenuItem alloc] initWithTitle:@"Commander One" action:@selector(openInCommanderOne:) keyEquivalent:@"3"];
                    [commanderOne setRepresentedObject:applicationContentPath];
                    [subMenu addItem:commanderOne];
                }
                
                [item setSubmenu:subMenu];
            }

            [menu addItem:item];
        }
    }

    
    NSString* devicesPropertiesPath = [NSString stringWithFormat:@"%@/Library/Preferences/com.dsmelov.devices.plist", NSHomeDirectory()];
    
    NSDictionary* devicesList = [NSDictionary dictionaryWithContentsOfFile:devicesPropertiesPath];
    
    NSArray* deviceURLS = devicesList[@"Devices"];
    
    if ([deviceURLS count])
    {
        [menu addItem:[NSMenuItem separatorItem]];

        for (NSDictionary* device in deviceURLS)
        {
            NSString* hostname = device[@"name"];
            NSString* url = device[@"url"];
            NSMenuItem* webdavDevice = [[NSMenuItem alloc] initWithTitle:hostname action:@selector(openWebDav:) keyEquivalent:@""];
            [webdavDevice setRepresentedObject:url];
            [menu addItem:webdavDevice];
        }
    }
    
    
    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem* startAtLogin = [[NSMenuItem alloc] initWithTitle:@"Start at Login" action:@selector(handleStartAtLogin:) keyEquivalent:@""];
    BOOL isStartAtLoginEnabled = [Settings isStartAtLoginEnabled];
    if (isStartAtLoginEnabled)
    {
        [startAtLogin setState:NSOnState];
    }
    else
    {
        [startAtLogin setState:NSOffState];
    }
    [startAtLogin setRepresentedObject:@(isStartAtLoginEnabled)];
    [menu addItem:startAtLogin];

    NSMenuItem* hideSubMenusItem = [[NSMenuItem alloc] initWithTitle:@"Hide Submenus" action:@selector(handleHideSubMenus:) keyEquivalent:@""];
    if (self.hideSubMenus)
    {
        [hideSubMenusItem setState:NSOnState];
    }
    else
    {
        [hideSubMenusItem setState:NSOffState];
    }
    [hideSubMenusItem setRepresentedObject:@(self.hideSubMenus)];
    [menu addItem:hideSubMenusItem];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    NSString* appVersion = [NSString stringWithFormat:@"About %@ %@", [[NSRunningApplication currentApplication] localizedName], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    NSMenuItem* about = [[NSMenuItem alloc] initWithTitle:appVersion action:@selector(aboutApp:) keyEquivalent:@"I"];
    [menu addItem:about];
    
    NSMenuItem* quit = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(exitApp:) keyEquivalent:@"Q"];
    [menu addItem:quit];

    [_statusItem popUpStatusItemMenu:menu];
}

//----------------------------------------------------------------------------
- (NSImage*) getIconForApplicationWithPlist:(NSDictionary*)applicationPlist folder:(NSString*)applicationFolderPath
{
    NSString* iconPath;
    NSString* applicationIcon = applicationPlist[@"CFBundleIconFile"];

    if (applicationIcon != nil)
    {
        iconPath = [applicationFolderPath stringByAppendingString:applicationIcon];
    }
    else
    {
        NSDictionary* applicationIcons = applicationPlist[@"CFBundleIcons"];

        NSString* postfix = @"";

        if (!applicationIcons)
        {
            applicationIcons = applicationPlist[@"CFBundleIcons~ipad"];
            postfix = @"~ipad";
        }

        NSDictionary* applicationPrimaryIcons = applicationIcons[@"CFBundlePrimaryIcon"];

        NSArray* iconFiles = applicationPrimaryIcons[@"CFBundleIconFiles"];

        applicationIcon = [iconFiles lastObject];

        iconPath = [applicationFolderPath stringByAppendingFormat:@"%@%@.png", applicationIcon, postfix];

        NSFileManager* fileManager = [NSFileManager defaultManager];

        if (![fileManager fileExistsAtPath:iconPath])
        {
            iconPath = [applicationFolderPath stringByAppendingFormat:@"%@@2x%@.png", applicationIcon, postfix];

            if (![fileManager fileExistsAtPath:iconPath])
            {
                iconPath = nil;
            }
        }
    }

    NSImage* icon;
    if (iconPath == nil)
    {
        icon = [NSImage imageNamed:@"DefaultIcon"];
    }
    else
    {
        icon = [[NSImage alloc] initWithContentsOfFile:iconPath];
        icon = [self scaleImage:icon toSize:NSMakeSize(16, 16)];
    }

    return icon;
}

//----------------------------------------------------------------------------
- (void) openInWithModifier:(id)sender
{
    NSEvent* event = [NSApp currentEvent];
    
    if ([event modifierFlags] & NSAlternateKeyMask)
    {
        [self openInTerminal:sender];
    }
    else if ([event modifierFlags] & NSControlKeyMask)
    {
        if ([CommanderOne isCommanderOneAvailable])
        {
            [self openInCommanderOne:sender];
        }
    }
    else
    {
        [self openInFinder:sender];
    }
}

//----------------------------------------------------------------------------
- (void) openWebDav:(id)sender
{
    NSString* path = (NSString*)[sender representedObject];
    
    NSURL *url = [NSURL URLWithString: path];
    NSString *host = [url host];
    NSString *address = [[NSHost hostWithName:host] address];
    
    NSString* mountCommand = [NSString stringWithFormat:@"mount volume \"%@\"", path];
    
    NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource: mountCommand];
    
    [scriptObject executeAndReturnError: nil];
    
    [[NSWorkspace sharedWorkspace] openFile:[NSString stringWithFormat:@"/Volumes/%@", address] withApplication:@"Finder"];
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
- (void) openInCommanderOne:(id)sender
{
    NSString* path = (NSString*)[sender representedObject];

    [CommanderOne openInCommanderOne:path];
}

//----------------------------------------------------------------------------
- (void) exitApp:(id)sender
{
    [[NSApplication sharedApplication] terminate:self];
}

//----------------------------------------------------------------------------
- (void) handleHideSubMenus:(id)sender
{
    self.hideSubMenus = ![[sender representedObject] boolValue];
    
    [[NSUserDefaults standardUserDefaults] setBool:self.hideSubMenus forKey:HIDE_SUBMENUS_PREFERENCE];
}

//----------------------------------------------------------------------------
- (void) handleStartAtLogin:(id)sender
{
    BOOL isEnabled = [[sender representedObject] boolValue];
    
    [Settings setStartAtLoginEnabled:!isEnabled];
    
    [sender setRepresentedObject:@(!isEnabled)];
    
    if (isEnabled)
    {
        [sender setState:NSOffState];
    }
    else
    {
        [sender setState:NSOnState];
    }
}

//----------------------------------------------------------------------------
- (void) aboutApp:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/dsmelov/simsim"]];
}

@end
