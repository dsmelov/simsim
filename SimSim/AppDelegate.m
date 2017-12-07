//
//  AppDelegate.m
//  SimSim
//
//  Created by Daniil Smelov 2016.04.18
//  Copyright (c) 2016 Daniil Smelov. All rights reserved.
//

#import "AppDelegate.h"
#import "FileManagerSupport/CommanderOne.h"
#import "FileManager.h"
#import "Settings.h"
#import "Realm.h"
#import "Simulator.h"
#import "Application.h"

//============================================================================
@interface AppDelegate ()

@property (strong, nonatomic) NSStatusItem* statusItem;
@property (strong, nonatomic) Realm *realmModule;

@end

//============================================================================
@implementation AppDelegate

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
    
    NSNumber* hotkey = @1;
    
    NSMenuItem* finder =
    [[NSMenuItem alloc] initWithTitle:@"Finder" action:@selector(openInFinder:) keyEquivalent:[hotkey stringValue]];
    [finder setRepresentedObject:path];
    
    icon = [[NSWorkspace sharedWorkspace] iconForFile:FINDER_ICON_PATH];
    [icon setSize: NSMakeSize(ACTION_ICON_SIZE, ACTION_ICON_SIZE)];
    [finder setImage:icon];
    
    [subMenu addItem:finder];

    hotkey = @([hotkey intValue] + 1);

    NSMenuItem* terminal =
    [[NSMenuItem alloc] initWithTitle:@"Terminal" action:@selector(openInTerminal:) keyEquivalent:[hotkey stringValue]];
    [terminal setRepresentedObject:path];
    
    icon = [[NSWorkspace sharedWorkspace] iconForFile:TERMINAL_ICON_PATH];
    [icon setSize: NSMakeSize(ACTION_ICON_SIZE, ACTION_ICON_SIZE)];
    [terminal setImage:icon];
    
    [subMenu addItem:terminal];
    
    hotkey = @([hotkey intValue] + 1);
    
    if ([Realm isRealmAvailableForPath:path])
    {

        if (self.realmModule == nil) {
            self.realmModule = [Realm new];
        }

        icon = [[NSWorkspace sharedWorkspace] iconForFile:[Realm applicationPath]];
        [icon setSize: NSMakeSize(ACTION_ICON_SIZE, ACTION_ICON_SIZE)];

        [self.realmModule generateRealmMenuForPath:path forMenu:subMenu withHotKey:hotkey icon:icon];

        hotkey = @([hotkey intValue] + 1);
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
        hotkey = @([hotkey intValue] + 1);

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
        hotkey = @([hotkey intValue] + 1);
    }

    [subMenu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem* pasteboard =
    [[NSMenuItem alloc] initWithTitle:@"Copy path to Clipboard" action:@selector(copyToPasteboard:) keyEquivalent:[hotkey stringValue]];
    [pasteboard setRepresentedObject:path];
    [subMenu addItem:pasteboard];
    
    hotkey = @([hotkey intValue] + 1);

    if ([self simulatorRunning])
    {
        NSMenuItem* screenshot =
        [[NSMenuItem alloc] initWithTitle:@"Take Screenshot" action:@selector(takeScreenshot:) keyEquivalent:[hotkey stringValue]];
        [screenshot setRepresentedObject:path];
        [subMenu addItem:screenshot];
        
        hotkey = @([hotkey intValue] + 1);
    }
    
    NSMenuItem* resetApplication =
    [[NSMenuItem alloc] initWithTitle:@"Reset application data" action:@selector(resetApplication:) keyEquivalent:[hotkey stringValue]];
    [resetApplication setRepresentedObject:path];
    [subMenu addItem:resetApplication];
    
    [item setSubmenu:subMenu];
}

//----------------------------------------------------------------------------
- (void) addApplication:(Application*)application toMenu:(NSMenu*)menu
{
    NSString* title =
        [NSString stringWithFormat:@"%@ (%@)", application.bundleName, application.version];

    // This path will be opened on click
    NSString* applicationContentPath = application.contentPath;

    NSMenuItem* item =
        [[NSMenuItem alloc] initWithTitle:title action:@selector(openInWithModifier:)
            keyEquivalent:@""];

    [item setRepresentedObject:applicationContentPath];
    [item setImage:application.icon];

    [self addSubMenusToItem:item usingPath:applicationContentPath];

    [menu addItem:item];
}

//----------------------------------------------------------------------------
- (void) addApplications:(NSArray<Application*>*)installedApplicationsData toMenu:(NSMenu*)menu
{
    for (NSUInteger i = 0; i < [installedApplicationsData count]; i++)
    {
        Application* application = installedApplicationsData[i];

        [self addApplication:application toMenu:menu];
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
        // we're running on xcode 9
        for (NSString* uuid in [devicePreferences allKeys])
        {
            [simulatorPaths addObject:[self simulatorRootPathByUUID:uuid]];
        }
    }
    
    return simulatorPaths;
}

//----------------------------------------------------------------------------
- (NSMutableArray<Simulator*>*) activeSimulators
{
    NSMutableArray* simulatorPaths = [self simulatorPaths];
    
    NSMutableArray* simulators = [NSMutableArray new];
    
    for (NSString* path in simulatorPaths)
    {
        NSString* simulatorDetailsPath = [path stringByAppendingString:@"device.plist"];
        
        NSDictionary* properties = [NSDictionary dictionaryWithContentsOfFile:simulatorDetailsPath];

        if (properties == nil) { continue; } // skip "empty" properties
        
        Simulator* simulator = [Simulator simulatorWithDictionary:properties path:path];
        [simulators addObject:simulator];
    }
    
    return simulators;
}

//----------------------------------------------------------------------------
- (NSArray<Application*>*) installedAppsOnSimulator:(Simulator*)simulator
{
    NSString* installedApplicationsDataPath =
    [simulator.path stringByAppendingString:@"data/Containers/Data/Application/"];
    
    NSArray* installedApplications =
    [FileManager getSortedFilesFromFolder:installedApplicationsDataPath];
    
    NSMutableArray* userApplications = [NSMutableArray new];
    
    for (NSDictionary* app in installedApplications)
    {
        Application* application = [Application applicationWithDictionary:app simulator:simulator];
        
        if (application)
        {
            if (!application.isAppleApplication)
            {
                [userApplications addObject:application];
            }
        }

    }
    
    return userApplications;
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

#define MAX_RECENT_SIMULATORS 5

//----------------------------------------------------------------------------
- (void) presentApplicationMenu
{
    NSMenu* menu = [NSMenu new];

    NSMutableArray* simulators = [self activeSimulators];
    
    NSArray* recentSimulators = [simulators sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
    {
        NSDate* l = [(Simulator*)a date];
        NSDate* r = [(Simulator*)b date];
        return [r compare:l];
    }];
    
    int simulatorsCount = 0;
    for (Simulator* simulator in recentSimulators)
    {
        NSArray<Application*>* installedApplications = [self installedAppsOnSimulator:simulator];

        if ([installedApplications count])
        {
            NSString* simulator_title = [NSString stringWithFormat:@"%@ (%@)",
                                         simulator.name,
                                         simulator.os];
            
            NSMenuItem* simulatorMenuItem = [[NSMenuItem alloc] initWithTitle:simulator_title action:nil keyEquivalent:@""];
            [simulatorMenuItem setEnabled:NO];
            [menu addItem:simulatorMenuItem];
            [self addApplications:installedApplications toMenu:menu];
            
            simulatorsCount++;
            if (simulatorsCount >= MAX_RECENT_SIMULATORS)
                break;
        }
    }
    
    [menu addItem:[NSMenuItem separatorItem]];

    [self addServiceItemsToMenu:menu];

    [_statusItem popUpStatusItemMenu:menu];
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
- (void) copyToPasteboard:(id)sender
{
    NSString* path = (NSString*)[sender representedObject];
    
    NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];

    [pasteboard declareTypes:@[ NSPasteboardTypeString ] owner:nil];
    [pasteboard setString:path forType:NSPasteboardTypeString];
}

//----------------------------------------------------------------------------
- (void) takeScreenshot:(id)sender
{
    NSArray* windows = (NSArray *)CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListExcludeDesktopElements, kCGNullWindowID));
    
    for(NSDictionary *window in windows)
    {
        NSString* windowOwner = window[(NSString*)kCGWindowOwnerName];
        NSString* windowName = window[(NSString*)kCGWindowName];

        if ([windowOwner containsString:@"Simulator"] &&
            ([windowName containsString:@"iOS"] || [windowName containsString:@"watchOS"] || [windowName containsString:@"tvOS"]))
        {
            NSNumber* windowID = window[(NSString*)kCGWindowNumber];
            
            NSString *dateComponents = @"yyyyMMdd_HHmmss_SSSS";
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
            [dateFormatter setDateFormat:dateComponents];
            
            NSDate *date = [NSDate date];
            NSString *dateString = [dateFormatter stringFromDate:date];

            NSString* screenshotPath =
            [NSString stringWithFormat:@"%@/Desktop/Screen Shot at %@.png", [self homeDirectoryPath], dateString];

            CGRect bounds;
            CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)window[(NSString*)kCGWindowBounds], &bounds);
            
            CGImageRef image = CGWindowListCreateImage(bounds, kCGWindowListOptionIncludingWindow, (CGWindowID)[windowID intValue], kCGWindowImageDefault);
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
        if (!result && error)
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
