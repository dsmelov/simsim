//
//  AppDelegate.m
//  SimSim
//
//  Created by Daniil Smelov 2016.04.18
//  Copyright (c) 2016 Daniil Smelov. All rights reserved.
//

#import "AppDelegate.h"
#import "CommanderOne.h"
#include <pwd.h>
#import "FileManager.h"
#import "Settings.h"
#import "Realm.h"

#include <Cocoa/Cocoa.h>
#include <CoreGraphics/CGWindow.h>

#import <NetFS/NetFS.h>

#define ALREADY_LAUNCHED_PREFERENCE @"alreadyLaunched"

//============================================================================
@interface AppDelegate ()

@property (strong, nonatomic) NSStatusItem* statusItem;
@property (strong, nonatomic) Realm *realmModule;

@end

//============================================================================
@implementation AppDelegate



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
- (BOOL) simulatorRunning
{
    NSArray* windows = (NSArray *)CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListExcludeDesktopElements, kCGNullWindowID));
    
    for(NSDictionary *window in windows)
    {
        NSString* windowOwner = [window objectForKey:(NSString *)kCGWindowOwnerName];
        NSString* windowName = [window objectForKey:(NSString *)kCGWindowName];

        if ([windowOwner containsString:@"Simulator"] &&
            ([windowName containsString:@"iOS"] || [windowName containsString:@"watchOS"] || [windowName containsString:@"tvOS"]))
        {
            return YES;
        }
    }
    
    return NO;
}

#define ACTION_ICON_SIZE 16

// TODO: make it less hardcoded :)

#define FINDER_ICON_PATH @"/System/Library/CoreServices/Finder.app"
#define TERMINAL_ICON_PATH @"/Applications/Utilities/Terminal.app"
#define ITERM_ICON_PATH @"/Applications/iTerm.app"
#define CMDONE_ICON_PATH @"/Applications/Commander One.app"

//----------------------------------------------------------------------------
- (void) addSubMenusToItem:(NSMenuItem*)item usingPath:(NSString*)path
{
    NSImage* icon = nil;
    NSMenu* subMenu = [NSMenu new];
    
    NSNumber* hotkey = [NSNumber numberWithInt:1];
    
    NSMenuItem* finder =
    [[NSMenuItem alloc] initWithTitle:@"Finder" action:@selector(openInFinder:) keyEquivalent:[hotkey stringValue]];
    [finder setRepresentedObject:path];
    
    icon = [[NSWorkspace sharedWorkspace] iconForFile:FINDER_ICON_PATH];
    [icon setSize: NSMakeSize(ACTION_ICON_SIZE, ACTION_ICON_SIZE)];
    [finder setImage:icon];
    
    [subMenu addItem:finder];

    hotkey = [NSNumber numberWithInt:[hotkey intValue] + 1];

    NSMenuItem* terminal =
    [[NSMenuItem alloc] initWithTitle:@"Terminal" action:@selector(openInTerminal:) keyEquivalent:[hotkey stringValue]];
    [terminal setRepresentedObject:path];
    
    icon = [[NSWorkspace sharedWorkspace] iconForFile:TERMINAL_ICON_PATH];
    [icon setSize: NSMakeSize(ACTION_ICON_SIZE, ACTION_ICON_SIZE)];
    [terminal setImage:icon];
    
    [subMenu addItem:terminal];
    
    hotkey = [NSNumber numberWithInt:[hotkey intValue] + 1];
    
    if ([Realm isRealmAvailableForPath:path]) {

        if (self.realmModule == nil) {
            self.realmModule = [Realm new];
        }

        icon = [[NSWorkspace sharedWorkspace] iconForFile:[Realm applicationPath]];
        [icon setSize: NSMakeSize(ACTION_ICON_SIZE, ACTION_ICON_SIZE)];

        [self.realmModule generateRealmMenuForPath:path forMenu:subMenu withHotKey:hotkey icon:icon];

        hotkey = [NSNumber numberWithInt:[hotkey intValue] + 1];
    }
    
    CFStringRef iTermBundleID = CFStringCreateWithCString(CFAllocatorGetDefault(), "com.googlecode.iterm2", kCFStringEncodingUTF8);
    CFArrayRef iTermAppURLs = LSCopyApplicationURLsForBundleIdentifier(iTermBundleID, NULL);

    if (iTermAppURLs)
    {
        NSMenuItem* iTerm =
        [[NSMenuItem alloc] initWithTitle:@"iTerm" action:@selector(openIniTerm:) keyEquivalent:[hotkey stringValue]];
        [iTerm setRepresentedObject:path];
        
        icon = [[NSWorkspace sharedWorkspace] iconForFile:ITERM_ICON_PATH];
        [icon setSize: NSMakeSize(ACTION_ICON_SIZE, ACTION_ICON_SIZE)];
        [iTerm setImage:icon];
        
        [subMenu addItem:iTerm];
        hotkey = [NSNumber numberWithInt:[hotkey intValue] + 1];

        CFRelease(iTermAppURLs);
    }

    CFRelease(iTermBundleID);

    if ([CommanderOne isCommanderOneAvailable])
    {
        NSMenuItem* commanderOne =
        [[NSMenuItem alloc] initWithTitle:@"Commander One" action:@selector(openInCommanderOne:) keyEquivalent:[hotkey stringValue]];
        [commanderOne setRepresentedObject:path];
        
        icon = [[NSWorkspace sharedWorkspace] iconForFile:CMDONE_ICON_PATH];
        [icon setSize: NSMakeSize(ACTION_ICON_SIZE, ACTION_ICON_SIZE)];
        [commanderOne setImage:icon];
        
        [subMenu addItem:commanderOne];
        hotkey = [NSNumber numberWithInt:[hotkey intValue] + 1];
    }

    [subMenu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem* pasteboard =
    [[NSMenuItem alloc] initWithTitle:@"Copy path to Clipboard" action:@selector(copyToPasteboard:) keyEquivalent:[hotkey stringValue]];
    [pasteboard setRepresentedObject:path];
    [subMenu addItem:pasteboard];
    
    hotkey = [NSNumber numberWithInt:[hotkey intValue] + 1];

    if ([self simulatorRunning])
    {
        NSMenuItem* screenshot =
        [[NSMenuItem alloc] initWithTitle:@"Take Screenshot" action:@selector(takeScreenshot:) keyEquivalent:[hotkey stringValue]];
        [screenshot setRepresentedObject:path];
        [subMenu addItem:screenshot];
        
        hotkey = [NSNumber numberWithInt:[hotkey intValue] + 1];
    }
    
    NSMenuItem* resetApplication =
    [[NSMenuItem alloc] initWithTitle:@"Reset application data" action:@selector(resetApplication:) keyEquivalent:[hotkey stringValue]];
    [resetApplication setRepresentedObject:path];
    [subMenu addItem:resetApplication];
    
    hotkey = [NSNumber numberWithInt:[hotkey intValue] + 1];
    
    [item setSubmenu:subMenu];
}

//----------------------------------------------------------------------------
- (void) processBundles:(NSArray*)bundles
          usingRootPath:(NSString*)simulatorRootPath
    andBundleIdentifier:(NSString*)applicationBundleIdentifier
         withFinalBlock:(void(^)(NSString* applicationRootBundlePath))block
{
    for (NSUInteger j = 0; j < [bundles count]; j++)
    {
        NSString* appBundleUUID = bundles[j][KEY_FILE];
        
        NSString* applicationRootBundlePath =
            [simulatorRootPath stringByAppendingFormat:@"data/Containers/Bundle/Application/%@/", appBundleUUID];
        
        NSString* applicationBundlePropertiesPath =
            [applicationRootBundlePath stringByAppendingString:@".com.apple.mobile_container_manager.metadata.plist"];
        
        NSDictionary* applicationBundleProperties =
        [NSDictionary dictionaryWithContentsOfFile:applicationBundlePropertiesPath];
        
        NSString* bundleIdentifier = applicationBundleProperties[@"MCMMetadataIdentifier"];
        
        if ([bundleIdentifier isEqualToString:applicationBundleIdentifier])
        {
            block(applicationRootBundlePath);
            break;
        }
    }
}

//----------------------------------------------------------------------------
- (NSDictionary*) getMetadataForBundle:(NSString*)applicationBundleIdentifier
                         usingRootPath:(NSString*)simulatorRootPath
{
    __block NSMutableDictionary* metadata = nil;

    NSString* installedApplicationsBundlePath =
        [simulatorRootPath stringByAppendingString:@"data/Containers/Bundle/Application/"];
    
    NSArray* installedApplicationsBundle =
        [FileManager getSortedFilesFromFolder:installedApplicationsBundlePath];
    
    [self processBundles:installedApplicationsBundle
           usingRootPath:simulatorRootPath
     andBundleIdentifier:applicationBundleIdentifier
         withFinalBlock:^(NSString* applicationRootBundlePath)
    {
        NSString* applicationFolderName = [FileManager getApplicationFolderFromPath:applicationRootBundlePath];
        
        NSString* applicationFolderPath = [applicationRootBundlePath stringByAppendingFormat:@"%@/", applicationFolderName];
        
        NSString* applicationPlistPath = [applicationFolderPath stringByAppendingString:@"Info.plist"];
        
        NSDictionary* applicationPlist = [NSDictionary dictionaryWithContentsOfFile:applicationPlistPath];
        
        NSString* applicationVersion = applicationPlist[@"CFBundleVersion"];
        NSString* applicationBundleName = applicationPlist[@"CFBundleName"];
        
        if (applicationBundleName.length == 0)
        {
            applicationBundleName = applicationPlist[@"CFBundleDisplayName"];
        }
        
        NSImage* icon = [self getIconForApplicationWithPlist:applicationPlist folder:applicationFolderPath];
        
        metadata = [NSMutableDictionary new];
        
        metadata[@"applicationBundleName"] = applicationBundleName;
        metadata[@"applicationVersion"] = applicationVersion;
        metadata[@"applicationIcon"] = icon;
    }];
    
    return metadata;
}

//----------------------------------------------------------------------------
- (void) addApplication:(NSDictionary*)application
                 toMenu:(NSMenu*)menu
          usingRootPath:(NSString*)simulatorRootPath
             andAppUUID:(NSString*)uuid
                atIndex:(NSUInteger)i
{
    NSString* applicationBundleIdentifier = application[@"MCMMetadataIdentifier"];
    
    NSDictionary* metadata =
        [self getMetadataForBundle:applicationBundleIdentifier
                     usingRootPath:simulatorRootPath];
    
    if (metadata)
    {
        NSString* title =
        [NSString stringWithFormat:@"%@ (%@)", metadata[@"applicationBundleName"], metadata[@"applicationVersion"]];
        
        // This path will be opened on click
        NSString* applicationContentPath = [self applicationRootPathByUUID:uuid andRootPath:simulatorRootPath];
        
        NSMenuItem* item =
        [[NSMenuItem alloc] initWithTitle:title action:@selector(openInWithModifier:)
                            keyEquivalent:[NSString stringWithFormat:@"Alt-%lu", (unsigned long)i]];

        [item setRepresentedObject:applicationContentPath];
        [item setImage:metadata[@"applicationIcon"]];
        
        [self addSubMenusToItem:item usingPath:applicationContentPath];
        
        
        [menu addItem:item];
    }
}

//----------------------------------------------------------------------------
- (NSString*) applicationRootPathByUUID:(NSString*)uuid
                            andRootPath:(NSString*)simulatorRootPath
{
    return
    [simulatorRootPath stringByAppendingFormat:@"data/Containers/Data/Application/%@/", uuid];
}

//----------------------------------------------------------------------------
- (NSDictionary*) getApplicationPropertiesByUUID:(NSString*)uuid
                                     andRootPath:(NSString*)simulatorRootPath
{
    NSString* applicationRootPath =
    [self applicationRootPathByUUID:uuid andRootPath:simulatorRootPath];
    
    NSString* applicationDataPropertiesPath =
    [applicationRootPath stringByAppendingString:@".com.apple.mobile_container_manager.metadata.plist"];
    
    return
    [NSDictionary dictionaryWithContentsOfFile:applicationDataPropertiesPath];
}

//----------------------------------------------------------------------------
- (BOOL) isAppleApplication:(NSDictionary*)applicationProperties
{
    NSString* applicationBundleIdentifier = applicationProperties[@"MCMMetadataIdentifier"];
    
    return [applicationBundleIdentifier hasPrefix:@"com.apple"];
}

//----------------------------------------------------------------------------
- (void) addSimulatorApplications:(NSArray*)installedApplicationsData
                    usingRootPath:(NSString*)simulatorRootPath
                           toMenu:(NSMenu*)menu
{
    for (NSUInteger i = 0; i < [installedApplicationsData count]; i++)
    {
        NSString* uuid = installedApplicationsData[i][KEY_FILE];

        NSDictionary* applicationDataProperties =
        [self getApplicationPropertiesByUUID:uuid andRootPath:simulatorRootPath];
        
        if (applicationDataProperties)
        {
            if (![self isAppleApplication:applicationDataProperties])
            {
                [self addApplication:applicationDataProperties
                              toMenu:menu
                       usingRootPath:simulatorRootPath
                          andAppUUID:uuid
                             atIndex:i];
            }
        }
    }
}

//----------------------------------------------------------------------------
- (NSString*) homeDirectoryPath
{
    return NSHomeDirectory();
}

//----------------------------------------------------------------------------
- (NSString*) simulatorRootPathByUUID:(NSString*)uuid
{
    return
    [NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices/%@/", [self homeDirectoryPath], uuid];
}

//----------------------------------------------------------------------------
- (NSMutableArray*) simulatorPaths
{
    NSString* simulatorPropertiesPath =
    [NSString stringWithFormat:@"%@/Library/Preferences/com.apple.iphonesimulator.plist", [self homeDirectoryPath]];
    
    NSDictionary* simulatorProperties = [NSDictionary dictionaryWithContentsOfFile:simulatorPropertiesPath];

    NSString* uuid = simulatorProperties[@"CurrentDeviceUDID"];
    
    NSDictionary* devicePreferences = simulatorProperties[@"DevicePreferences"];
    
    NSMutableArray* simulatorPaths = [NSMutableArray new];

    [simulatorPaths addObject:[self simulatorRootPathByUUID:uuid]];
    
    if (devicePreferences != nil)
    {
        NSString* uuid = nil;
        // we're running on xcode 9
        for (uuid in [devicePreferences allKeys])
        {
            [simulatorPaths addObject:[self simulatorRootPathByUUID:uuid]];
        }
    }
    
    return simulatorPaths;
}

//----------------------------------------------------------------------------
- (NSMutableArray*) activeSimulatorProperties
{
    NSMutableArray* simulatorPaths = [self simulatorPaths];
    
    NSMutableArray* simulatorProperties = [NSMutableArray new];
    
    int i = 0;
    for (NSString* path in simulatorPaths)
    {
        NSString* simulatorDetailsPath = [path stringByAppendingString:@"device.plist"];
        
        NSDictionary* properties = [NSDictionary dictionaryWithContentsOfFile:simulatorDetailsPath];
        
        [simulatorProperties insertObject:properties atIndex:i]; // to be sure in index correlation
        i++;
    }
    
    return simulatorProperties;
}

//----------------------------------------------------------------------------
- (NSString*) activeSimulatorName:(NSDictionary*)properties
{
    return
    properties[@"name"];
}

//----------------------------------------------------------------------------
- (NSString*) activeSimulatorRuntime:(NSDictionary*)properties
{
    NSString* runtime = [properties[@"runtime"] stringByReplacingOccurrencesOfString:@"com.apple.CoreSimulator.SimRuntime." withString:@""];
    
    runtime = [runtime stringByReplacingOccurrencesOfString:@"OS-" withString:@"OS "];
    runtime = [runtime stringByReplacingOccurrencesOfString:@"-" withString:@"."];
    return runtime;
}

//----------------------------------------------------------------------------
- (NSArray*) installedAppsOnSimulator:(NSString*)simulatorRootPath
{
    NSString* installedApplicationsDataPath =
    [simulatorRootPath stringByAppendingString:@"data/Containers/Data/Application/"];
    
    NSArray* installedApplications =
    [FileManager getSortedFilesFromFolder:installedApplicationsDataPath];
    
    return installedApplications;
}

//----------------------------------------------------------------------------
- (NSArray*) getDevices
{
    NSString* devicesPropertiesPath =
    [NSString stringWithFormat:@"%@/Library/Preferences/com.dsmelov.devices.plist", [self homeDirectoryPath]];
    
    NSDictionary* devicesList = [NSDictionary dictionaryWithContentsOfFile:devicesPropertiesPath];
    
    return
    devicesList[@"Devices"];
}

//----------------------------------------------------------------------------
- (void) addDevices:(NSArray*)devices toMenu:(NSMenu*)menu
{
    if ([devices count])
    {
        [menu addItem:[NSMenuItem separatorItem]];
        
        for (NSDictionary* device in devices)
        {
            NSString* hostname = device[@"name"];
            NSMenuItem* webdavDevice = [[NSMenuItem alloc] initWithTitle:hostname action:@selector(openWebDav:) keyEquivalent:@""];
            [webdavDevice setRepresentedObject:device];
            [menu addItem:webdavDevice];
        }
    }
}

//----------------------------------------------------------------------------
- (void) addServiceItemsToMenu:(NSMenu*)menu
{
    NSMenuItem* startAtLogin =
    [[NSMenuItem alloc] initWithTitle:@"Start at Login" action:@selector(handleStartAtLogin:) keyEquivalent:@""];
    
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
    
    NSString* appVersion = [NSString stringWithFormat:@"About %@ %@", [[NSRunningApplication currentApplication] localizedName], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    NSMenuItem* about = [[NSMenuItem alloc] initWithTitle:appVersion action:@selector(aboutApp:) keyEquivalent:@"I"];
    [menu addItem:about];
    
    NSMenuItem* quit = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(exitApp:) keyEquivalent:@"Q"];
    [menu addItem:quit];
}

//----------------------------------------------------------------------------
- (void) presentApplicationMenu
{
    NSMenu* menu = [NSMenu new];

    NSMutableArray* simulatorPaths = [self simulatorPaths];
    NSMutableArray* simulatorDetails = [self activeSimulatorProperties];
    
    for (int i = 0; i < [simulatorPaths count]; i++)
    {
        NSString* simulatorRootPath = [simulatorPaths objectAtIndex:i];
        NSDictionary* details = [simulatorDetails objectAtIndex:i];
        
        NSString* simulator_title = [NSString stringWithFormat:@"%@ (%@)",
                                     [self activeSimulatorName:details],
                                     [self activeSimulatorRuntime:details]];
        
        NSMenuItem* simulator = [[NSMenuItem alloc] initWithTitle:simulator_title action:nil keyEquivalent:@""];
        [simulator setEnabled:NO];
        [menu addItem:simulator];
        
        NSArray* installedApplications = [self installedAppsOnSimulator:simulatorRootPath];
        [self addSimulatorApplications:installedApplications usingRootPath:simulatorRootPath toMenu:menu];
    }
    
    [self addDevices:[self getDevices] toMenu:menu];
    
    [menu addItem:[NSMenuItem separatorItem]];

    [self addServiceItemsToMenu:menu];

    [_statusItem popUpStatusItemMenu:menu];
}

//----------------------------------------------------------------------------
- (NSImage*)roundCorners:(NSImage *)image
{
    
    NSImage *existingImage = image;
    NSSize existingSize = [existingImage size];
    NSSize newSize = NSMakeSize(existingSize.width, existingSize.height);
    NSImage *composedImage = [[NSImage alloc] initWithSize:newSize];
    
    [composedImage lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    
    NSRect imageFrame = NSRectFromCGRect(CGRectMake(0, 0, existingSize.width, existingSize.height));
    NSBezierPath *clipPath = [NSBezierPath bezierPathWithRoundedRect:imageFrame xRadius:3 yRadius:3];
    [clipPath setWindingRule:NSEvenOddWindingRule];
    [clipPath addClip];
    
    [image drawAtPoint:NSZeroPoint fromRect:NSMakeRect(0, 0, newSize.width, newSize.height) operation:NSCompositeSourceOver fraction:1];
    
    [composedImage unlockFocus];
    
    return composedImage;
}

//----------------------------------------------------------------------------
- (NSImage*) getIconForApplicationWithPlist:(NSDictionary*)applicationPlist folder:(NSString*)applicationFolderPath
{
    NSString* iconPath;
    NSString* applicationIcon  = applicationPlist[@"CFBundleIconFile"];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
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
        if (applicationPrimaryIcons && [applicationPrimaryIcons isKindOfClass:[NSDictionary class]]) {
            NSArray* iconFiles = nil;
            NS_DURING
            iconFiles = applicationPrimaryIcons[@"CFBundleIconFiles"];
            NS_HANDLER
            NS_ENDHANDLER
            
            if (iconFiles && iconFiles.count > 0) {
                applicationIcon = [iconFiles lastObject];
                
                iconPath = [applicationFolderPath stringByAppendingFormat:@"%@%@.png", applicationIcon, postfix];
                
                if (![fileManager fileExistsAtPath:iconPath])
                {
                    iconPath = [applicationFolderPath stringByAppendingFormat:@"%@@2x%@.png", applicationIcon, postfix];
                }
            }
            else {
                iconPath = nil;
            }
        }
        else {
            iconPath = nil;
        }
    }

    if (![fileManager fileExistsAtPath:iconPath])
    {
        iconPath = nil;
    }
    
    NSImage* icon = nil;
    if (iconPath == nil)
    {
        icon = [NSImage imageNamed:@"empty_icon"];
    }
    else
    {
        icon = [[NSImage alloc] initWithContentsOfFile:iconPath];
    }

    icon = [self roundCorners:[self scaleImage:icon toSize:NSMakeSize(24, 24)]];
    
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
- (void) mount:(NSURL *)networkShare usingName:(NSString*)name inApp:(NSString*)app
{
    NSURL *mountPath = [NSURL URLWithString:[NSString stringWithFormat:@"/Volumes/%@/", name]];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:[mountPath absoluteString]
                              withIntermediateDirectories:NO attributes:nil error:nil];
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    AsyncRequestID requestID = NULL;
    
    /*
     * The following dictionary keys for open_options are supported:
     *
     *	kNetFSUseGuestKey:			Login as a guest user.
     *
     *	kNetFSAllowLoopbackKey			Allow a loopback mount.
     *
     *	kNAUIOptionKey = UIOption		Suppress authentication dialog UI.
     *      kNAUIOptionNoUI
     *      kNAUIOptionAllowUI
     *      kNAUIOptionForceUI
     */
    
    /*
     *  The following dictionary keys for mount_options are supported:
     *
     *	kNetFSMountFlagsKey = MNT_DONTBROWSE 	No browsable data here (see <sys/mount.h>).
     *	kNetFSMountFlagsKey = MNT_RDONLY	A read-only mount (see <sys/mount.h>).
     *	kNetFSAllowSubMountsKey = true		Allow a mount from a dir beneath the share point.
     *	kNetFSSoftMountKey = true		Mount with "soft" failure semantics.
     *	kNetFSMountAtMountDirKey = true		Mount on the specified mountpath instead of below it.
     *
     * Note that if kNetFSSoftMountKey isn't set, then it's set to TRUE.
     *
     */
    
    NSMutableDictionary *openOptions =
    [@{ (__bridge NSString *)kNAUIOptionKey : (__bridge NSString *)kNAUIOptionNoUI,} mutableCopy ];
    
    NSMutableDictionary *mountOptions =
    [@{ (__bridge NSString *)kNetFSAllowSubMountsKey : @YES, (__bridge NSString *)kNetFSMountAtMountDirKey : @YES,} mutableCopy ];
        
    int rc =
    NetFSMountURLAsync((__bridge CFURLRef)networkShare,
        (__bridge CFURLRef)mountPath,
        (__bridge CFStringRef)(@""), // user
        (__bridge CFStringRef)(@""), // password
        (__bridge CFMutableDictionaryRef)(openOptions),
        (__bridge CFMutableDictionaryRef)(mountOptions),
        &requestID,
        queue,
        ^(int status, AsyncRequestID requestID, CFArrayRef mountpoints)
        {
            NSArray *mounts = CFBridgingRelease(mountpoints);
            NSLog(@"Mounting status code: %d %@", status, mounts);
            [[NSWorkspace sharedWorkspace] openFile:mounts[0] withApplication:app];
        });
    
    NSLog(@"Request status code: %d", rc);
}

//----------------------------------------------------------------------------
- (void) openWebDav:(id)sender
{
    NSDictionary* device = (NSDictionary*)[sender representedObject];
    NSString* path = device[@"url"];
    NSString* name = device[@"name"];
    
    [self mount:[NSURL URLWithString: path] usingName:name inApp:@"Finder"];
}

//----------------------------------------------------------------------------
- (void) copyToPasteboard:(id)sender
{
    NSString* path = (NSString*)[sender representedObject];
    
    NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
    
    [pasteboard declareTypes:[NSArray arrayWithObject:NSPasteboardTypeString] owner:nil];
    [pasteboard setString:path forType:NSPasteboardTypeString];
}

//----------------------------------------------------------------------------
- (void) takeScreenshot:(id)sender
{
    NSArray* windows = (NSArray *)CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListExcludeDesktopElements, kCGNullWindowID));
    
    for(NSDictionary *window in windows)
    {
        NSString* windowOwner = [window objectForKey:(NSString *)kCGWindowOwnerName];
        NSString* windowName = [window objectForKey:(NSString *)kCGWindowName];

        if ([windowOwner containsString:@"Simulator"] &&
            ([windowName containsString:@"iOS"] || [windowName containsString:@"watchOS"] || [windowName containsString:@"tvOS"]))
        {
            NSNumber* windowID = [window objectForKey:(NSString *)kCGWindowNumber];
            
            NSString *dateComponents = @"yyyyMMdd_HHmmss_SSSS";
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
            [dateFormatter setDateFormat:dateComponents];
            
            NSDate *date = [NSDate date];
            NSString *dateString = [dateFormatter stringFromDate:date];

            NSString* screenshotPath =
            [NSString stringWithFormat:@"%@/Desktop/Screen Shot at %@.png", [self homeDirectoryPath], dateString];

            CGRect bounds;
            CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)[window objectForKey:(NSString*)kCGWindowBounds], &bounds);
            
            CGImageRef image = CGWindowListCreateImage(bounds, kCGWindowListOptionIncludingWindow, [windowID intValue], kCGWindowImageDefault);
            NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithCGImage:image];
            
            NSData *data = [bitmap representationUsingType: NSPNGFileType properties:@{}];
            [data writeToFile: screenshotPath atomically:NO];
            
            CGImageRelease(image);
        }
    }
}

//----------------------------------------------------------------------------
- (void) resetFolder:(NSString*)folder inRoot:(NSString*)root
{
    NSString* path = [root stringByAppendingPathComponent:folder];
    
    NSFileManager* fm = [NSFileManager new];
    NSDirectoryEnumerator* en = [fm enumeratorAtPath:path];
    NSError* error = nil;
    BOOL result = NO;
    
    NSString* file;
    
    while (file = [en nextObject])
    {
        result = [fm removeItemAtPath:[path stringByAppendingPathComponent:file] error:&error];
        if (result == NO && error)
        {
            NSLog(@"Something went wrong: %@", error);
        }
    }
}

//----------------------------------------------------------------------------
- (void) resetApplication:(id)sender
{
    NSString* path = (NSString*)[sender representedObject];
    
    [self resetFolder:@"Documents" inRoot:path];
    [self resetFolder:@"Library" inRoot:path];
    [self resetFolder:@"tmp" inRoot:path];
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
- (void) openIniTerm:(id)sender
{
    NSString* path = (NSString*)[sender representedObject];

    [[NSWorkspace sharedWorkspace] openFile:path withApplication:@"iTerm"];
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
