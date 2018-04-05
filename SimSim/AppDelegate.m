//
//  AppDelegate.m
//  SimSim
//
//  Created by Daniil Smelov 2016.04.18
//  Copyright (c) 2016 Daniil Smelov. All rights reserved.
//

#import "AppDelegate.h"
#import "FileManager.h"
#import "Settings.h"
#import "Realm.h"
#import "Simulator.h"
#import "Application.h"
#import "Tools.h"
#import "Actions.h"
#import "FileManagerSupport/CommanderOne.h"

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


#define ACTION_ICON_SIZE 16

// TODO: make it less hardcoded :)

#define FINDER_ICON_PATH @"/System/Library/CoreServices/Finder.app"
#define TERMINAL_ICON_PATH @"/Applications/Utilities/Terminal.app"
#define ITERM_ICON_PATH @"/Applications/iTerm.app"
#define CMDONE_ICON_PATH @"/Applications/Commander One.app"


//----------------------------------------------------------------------------
- (NSNumber*) addAction:(NSString*)title
              toSubmenu:(NSMenu*)submenu
                forPath:(NSString*)path
               withIcon:(NSString*)iconPath
              andHotkey:(NSNumber*)hotkey
                   does:(nullable SEL)selector
{
    NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:title
                                                  action:selector
                                           keyEquivalent:[hotkey stringValue]];
    [item setTarget:[Actions class]];
    [item setRepresentedObject:path];
    
    NSImage* icon = [[NSWorkspace sharedWorkspace] iconForFile:iconPath];
    [icon setSize: NSMakeSize(ACTION_ICON_SIZE, ACTION_ICON_SIZE)];
    [item setImage:icon];
    
    [submenu addItem:item];

    return @([hotkey intValue] + 1);
}

//----------------------------------------------------------------------------
- (NSNumber*) addAction:(NSString*)title
              toSubmenu:(NSMenu*)submenu
                forPath:(NSString*)path
              withHotkey:(NSNumber*)hotkey
                    does:(nullable SEL)selector
{
    NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:title
                                                  action:selector
                                           keyEquivalent:[hotkey stringValue]];
    
    [item setTarget:[Actions class]];
    
    [item setRepresentedObject:path];
    [submenu addItem:item];

    return @([hotkey intValue] + 1);
}

//----------------------------------------------------------------------------
- (void) addSubMenusToItem:(NSMenuItem*)item usingPath:(NSString*)path
{
    NSImage* icon = nil;
    NSMenu* subMenu = [NSMenu new];
    
    NSNumber* hotkey = @1;

    hotkey = [self addAction:@"Finder" toSubmenu:subMenu forPath:path
                    withIcon:FINDER_ICON_PATH andHotkey:hotkey
                        does:@selector(openInFinder:)];
    
    hotkey = [self addAction:@"Terminal" toSubmenu:subMenu forPath:path
                    withIcon:TERMINAL_ICON_PATH andHotkey:hotkey
                        does:@selector(openInTerminal:)];
    
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
        hotkey = [self addAction:@"iTerm" toSubmenu:subMenu forPath:path
                        withIcon:ITERM_ICON_PATH andHotkey:hotkey
                            does:@selector(openIniTerm:)];

        CFRelease(iTermAppURLs);
    }

    CFRelease(iTermBundleID);

    if ([CommanderOne isCommanderOneAvailable])
    {
        hotkey = [self addAction:@"Commander One" toSubmenu:subMenu forPath:path
                        withIcon:CMDONE_ICON_PATH andHotkey:hotkey
                            does:@selector(openInCommanderOne:)];
    }

    [subMenu addItem:[NSMenuItem separatorItem]];
    
    hotkey = [self addAction:@"Copy path to Clipboard" toSubmenu:subMenu forPath:path
                  withHotkey:hotkey
                        does:@selector(copyToPasteboard:)];
    
    if ([Tools simulatorRunning])
    {
        hotkey = [self addAction:@"Take Screenshot" toSubmenu:subMenu forPath:path
                      withHotkey:hotkey
                            does:@selector(takeScreenshot:)];
    }

    hotkey = [self addAction:@"Reset application data" toSubmenu:subMenu forPath:path
                  withHotkey:hotkey
                        does:@selector(resetApplication:)];
    
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
            keyEquivalent:@"\0"];

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
- (NSString*) simulatorRootPathByUUID:(NSString*)uuid
{
    return
    [NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices/%@/", [Tools homeDirectoryPath], uuid];
}

//----------------------------------------------------------------------------
// Since we dont want duplicates, simulatorPaths is now a Set
- (NSMutableSet*) simulatorPaths
{
    NSString* simulatorPropertiesPath =
    [NSString stringWithFormat:@"%@/Library/Preferences/com.apple.iphonesimulator.plist", [Tools homeDirectoryPath]];
    
    NSDictionary* simulatorProperties = [NSDictionary dictionaryWithContentsOfFile:simulatorPropertiesPath];

    NSString* uuid = simulatorProperties[@"CurrentDeviceUDID"];
    
    NSDictionary* devicePreferences = simulatorProperties[@"DevicePreferences"];
    
    NSMutableSet* simulatorPaths = [NSMutableSet new];

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
    NSMutableSet* simulatorPaths = [self simulatorPaths];
    
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

        // BundleName and version cant be nil
        if (application && application.bundleName && application.version)
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
        [Actions openInTerminal:sender];
    }
    else if ([event modifierFlags] & NSControlKeyMask)
    {
        if ([CommanderOne isCommanderOneAvailable])
        {
            [Actions openInCommanderOne:sender];
        }
    }
    else
    {
        [Actions openInFinder:sender];
    }
}


@end
