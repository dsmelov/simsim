//
//  AppDelegate.m
//  SimSim
//
//  Created by Daniil Smelov 2016.04.18
//  Copyright (c) 2016 Daniil Smelov. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@property (strong, nonatomic) NSStatusItem *statusItem;

@end

@implementation AppDelegate


//----------------------------------------------------------------------------
-(NSArray*)getSortedFilesFromFolder: (NSString*)folderPath
{
    NSError *error = nil;
    NSArray* filesArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:&error];
    
    // sort by creation date
    NSMutableArray* filesAndProperties = [NSMutableArray arrayWithCapacity:[filesArray count]];
    
    for(NSString* file in filesArray)
    {
        
        if (![file isEqualToString:@".DS_Store"])
        {
            NSString* filePath = [folderPath stringByAppendingPathComponent:file];
            NSDictionary* properties = [[NSFileManager defaultManager]
                                        attributesOfItemAtPath:filePath
                                        error:&error];
            NSDate* modDate = [properties objectForKey:NSFileModificationDate];
            
            [filesAndProperties addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                           file, @"path",
                                           modDate, @"lastModDate",
                                           nil]];
            
        }
    }
    
    // Sort using a block - order inverted as we want latest date first
    NSArray* sortedFiles =
    [filesAndProperties sortedArrayUsingComparator:
    ^(id path1, id path2)
    {
        NSComparisonResult comp = [[path1 objectForKey:@"lastModDate"] compare:
                                   [path2 objectForKey:@"lastModDate"]];
        // invert ordering
        if (comp == NSOrderedDescending)
        {
            comp = NSOrderedAscending;
        }
        else
            if(comp == NSOrderedAscending)
        {
            comp = NSOrderedDescending;
        }
        return comp;
    }];
    
    return sortedFiles;
    
}

//----------------------------------------------------------------------------
-(NSString*)getApplicationFolderFromPath:(NSString*)folderPath
{
    NSError *error = nil;
    NSArray* filesArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:&error];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF EndsWith '.app'"];
    filesArray =  [filesArray filteredArrayUsingPredicate:predicate];
    
    return filesArray[0];
    
}

//----------------------------------------------------------------------------
- (NSImage*)scaleImage:(NSImage*)anImage toSize:(NSSize)size
{
    NSImage *sourceImage = anImage;
    [sourceImage setScalesWhenResized:YES];

    if (![sourceImage isValid])
    {
        NSLog(@"Invalid Image");
    }
    else
    {
        NSImage *smallImage = [[NSImage alloc] initWithSize: size];
        [smallImage lockFocus];
        [sourceImage setSize: size];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [sourceImage drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, size.width, size.height) operation:NSCompositeCopy fraction:1.0];
        [smallImage unlockFocus];
        return smallImage;
    }
    
    return nil;
}

//----------------------------------------------------------------------------
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    _statusItem.image = [NSImage imageNamed:@"switchIcon.png"];
    [_statusItem.image setTemplate:YES];

    _statusItem.highlightMode = YES;
    //_statusItem.toolTip = @"control-click to quit";
    
    NSMenu* menu = [[NSMenu alloc] init];
    
    [_statusItem setHighlightMode:NO];
    
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
    
    NSLog(@"%@", installedApplicationsData);
    
    for (int i = 0; i < [installedApplicationsData count]; i++)
    {
        NSString* appDataUUID = installedApplicationsData[i][@"path"];
        
        NSString* applicationDataPropertiesPath =
        [NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices/%@/data/Containers/Data/Application/%@/.com.apple.mobile_container_manager.metadata.plist", NSHomeDirectory(), simulatorUUID, appDataUUID];
        
        NSDictionary* applicationDataProperties = [NSDictionary dictionaryWithContentsOfFile:applicationDataPropertiesPath];
        
        NSString* applicationBundleIdentifierFromData = applicationDataProperties[@"MCMMetadataIdentifier"];
        
        if (applicationDataProperties != nil && ![applicationBundleIdentifierFromData hasPrefix:@"com.apple"])
        {
            NSLog(@"%@: %@ %@/%@", installedApplicationsData[i][@"lastModDate"], applicationBundleIdentifierFromData, appDataUUID, applicationDataProperties[@"MCMMetadataUUID"]);
            
            NSString* installedApplicationsBundlePath =
            [NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices/%@/data/Containers/Bundle/Application/", NSHomeDirectory(), simulatorUUID];
            
            NSArray* installedApplicationsBundle = [self getSortedFilesFromFolder:installedApplicationsBundlePath];
            
            NSString* applicationIcon = nil;
            NSString* applicationVersion = @"";
            NSString* applicationVersionShort = @"";
            NSString* applicationBundleName = @"";
            NSString* iconPath = @"";
            
            for (int j = 0; j < [installedApplicationsBundle count]; j++)
            {
                NSString* appBundleUUID = installedApplicationsBundle[j][@"path"];
                
                NSString* applicationBundlePropertiesPath =
                [NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices/%@/data/Containers/Bundle/Application/%@/.com.apple.mobile_container_manager.metadata.plist", NSHomeDirectory(), simulatorUUID, appBundleUUID];
                
                NSDictionary* applicationBundleProperties = [NSDictionary dictionaryWithContentsOfFile:applicationBundlePropertiesPath];
                
                NSString* bundleIdentifier = applicationBundleProperties[@"MCMMetadataIdentifier"];
                
                if ([bundleIdentifier isEqualToString:applicationBundleIdentifierFromData])
                {
                    NSString* applicationFolderName =
                    [self getApplicationFolderFromPath: [NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices/%@/data/Containers/Bundle/Application/%@/", NSHomeDirectory(), simulatorUUID, appBundleUUID]];
                    
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
                        NSDictionary* applicationPrimaryIcons = applicationIcons[@"CFBundlePrimaryIcon"];
                        
                        NSArray* iconFiles = applicationPrimaryIcons[@"CFBundleIconFiles"];
                        
                        applicationIcon = [iconFiles lastObject];

                        iconPath =
                        [NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices/%@/data/Containers/Bundle/Application/%@/%@/%@.png",
                         NSHomeDirectory(), simulatorUUID, appBundleUUID, applicationFolderName, applicationIcon];
                        
                        NSFileManager *fileManager = [NSFileManager defaultManager];
                        
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

            NSString* title = [NSString stringWithFormat:@"%@ (%@) on %@", applicationBundleName, applicationVersion, simulatorDetails[@"name"]];
            
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:@selector(exitApp:) keyEquivalent:[NSString stringWithFormat:@"Alt-%d", i] ];
            
            NSImage* icon = [[NSImage alloc] initWithContentsOfFile: iconPath];
            icon = [self scaleImage:icon toSize:NSMakeSize(16, 16)];
            [item setImage: icon];
            
            NSMenu *submenu = [[NSMenu alloc] init];
            
            NSString* applicationContentPath =
            [NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices/%@/data/Containers/Data/Application/%@/Library/Application Support/%@/",
             NSHomeDirectory(), simulatorUUID, appDataUUID, applicationBundleIdentifierFromData];
            
            NSMenuItem *terminal = [[NSMenuItem alloc] initWithTitle:@"Terminal" action:@selector(openInTerminal:) keyEquivalent:@"1" ];
            [terminal setRepresentedObject:applicationContentPath];
            [submenu addItem:terminal];
            
            NSMenuItem *finder = [[NSMenuItem alloc] initWithTitle:@"Finder" action:@selector(openInFinder:) keyEquivalent:@"2" ];
            [finder setRepresentedObject:applicationContentPath];
            [submenu addItem:finder];
            
            [item setSubmenu:submenu];
            
            [menu addItem:item];
            
        }
    }
    
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString* version = [infoDict objectForKey:@"CFBundleVersion"];

    NSString* appVersion = [NSString stringWithFormat:@"%@ %@",  [[NSRunningApplication currentApplication] localizedName], version ];
    NSMenuItem *about = [[NSMenuItem alloc] initWithTitle:appVersion action:@selector(aboutApp:) keyEquivalent:@"I"];
    [menu addItem:about];
    
    NSMenuItem *quit = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(exitApp:) keyEquivalent:@"Q"];
    [menu addItem:quit];
    
    [_statusItem setMenu:menu];
    [_statusItem setEnabled:YES];
}

//----------------------------------------------------------------------------
- (void)openInFinder:(id)sender
{
    NSString* path = (NSString*)[sender representedObject];
    
    [[NSWorkspace sharedWorkspace] openFile:path withApplication:@"Finder"];
}

//----------------------------------------------------------------------------
- (void)openInTerminal:(id)sender
{
    NSString* path = (NSString*)[sender representedObject];
    
    [[NSWorkspace sharedWorkspace] openFile:path withApplication:@"Terminal"];
}

//----------------------------------------------------------------------------
- (void)exitApp:(id)sender
{
    [[NSApplication sharedApplication] terminate:self];
}

//----------------------------------------------------------------------------
- (void)aboutApp:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/dsmelov/simsim"]];
}

//----------------------------------------------------------------------------
- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}

@end
