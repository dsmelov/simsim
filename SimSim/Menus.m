//
//  Menus.m
//  SimSim
//
//  Created by Daniil Smelov on 05.04.18.
//  Copyright © 2018 Daniil Smelov. All rights reserved.
//

#import "Menus.h"
#import "Actions.h"
#import "Realm.h"
#import "Settings.h"
#import "Tools.h"
#import "CommanderOne.h"

@implementation Menus

#define ACTION_ICON_SIZE 16

// TODO: make it less hardcoded :)

#define FINDER_ICON_PATH @"/System/Library/CoreServices/Finder.app"
#define TERMINAL_ICON_PATH @"/Applications/Utilities/Terminal.app"
#define ITERM_ICON_PATH @"/Applications/iTerm.app"
#define CMDONE_ICON_PATH @"/Applications/Commander One.app"

//----------------------------------------------------------------------------
+ (NSNumber*) addAction:(NSString*)title
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
+ (NSNumber*) addAction:(NSString*)title
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
+ (Realm*) realmModule
{
    static Realm * realm = nil;
    
    if (realm == nil)
        realm = [Realm new];
    
    return realm;
}

//----------------------------------------------------------------------------
+ (NSNumber*) addActionForRealmTo:(NSMenu*)menu
                          forPath:(NSString*)path
                       withHotkey:(NSNumber*)hotkey
{
    if ([Realm isRealmAvailableForPath:path])
    {
        NSImage* icon = [[NSWorkspace sharedWorkspace] iconForFile:[Realm applicationPath]];
        [icon setSize: NSMakeSize(ACTION_ICON_SIZE, ACTION_ICON_SIZE)];
        
        [[self realmModule] generateRealmMenuForPath:path forMenu:menu withHotKey:hotkey icon:icon];
        
        return @([hotkey intValue] + 1);
    }
    
    return hotkey;
}

//----------------------------------------------------------------------------
+ (NSNumber*) addActionForiTermTo:(NSMenu*)menu
                          forPath:(NSString*)path
                       withHotkey:(NSNumber*)hotkey
{
    CFStringRef iTermBundleID = CFStringCreateWithCString(CFAllocatorGetDefault(), "com.googlecode.iterm2", kCFStringEncodingUTF8);
    CFArrayRef iTermAppURLs = LSCopyApplicationURLsForBundleIdentifier(iTermBundleID, NULL);
    
    if (iTermAppURLs)
    {
        hotkey = [self addAction:@"iTerm" toSubmenu:menu forPath:path
                        withIcon:ITERM_ICON_PATH andHotkey:hotkey
                            does:@selector(openIniTerm:)];
        
        CFRelease(iTermAppURLs);
        return @([hotkey intValue] + 1);
    }
    
    CFRelease(iTermBundleID);

    return hotkey;
}

//----------------------------------------------------------------------------
+ (void) addSubMenusToItem:(NSMenuItem*)item usingPath:(NSString*)path
{
    NSMenu* subMenu = [NSMenu new];
    
    NSNumber* hotkey = @1;
    
    hotkey = [self addAction:@"Finder" toSubmenu:subMenu forPath:path
                    withIcon:FINDER_ICON_PATH andHotkey:hotkey
                        does:@selector(openInFinder:)];
    
    hotkey = [self addAction:@"Terminal" toSubmenu:subMenu forPath:path
                    withIcon:TERMINAL_ICON_PATH andHotkey:hotkey
                        does:@selector(openInTerminal:)];

    hotkey = [self addActionForRealmTo:subMenu forPath:path withHotkey:hotkey];
    hotkey = [self addActionForiTermTo:subMenu forPath:path withHotkey:hotkey];
    
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
+ (void) addApplication:(Application*)application toMenu:(NSMenu*)menu
{
    NSString* title =
    [NSString stringWithFormat:@"%@ (%@)", application.bundleName, application.version];
    
    // This path will be opened on click
    NSString* applicationContentPath = application.contentPath;
    
    NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:title action:@selector(openInWithModifier:) keyEquivalent:@"\0"];
    [item setTarget:[Actions class]];

    [item setRepresentedObject:applicationContentPath];
    [item setImage:application.icon];
    
    [self addSubMenusToItem:item usingPath:applicationContentPath];
    
    [menu addItem:item];
}

//----------------------------------------------------------------------------
+ (void) addApplications:(NSArray<Application*>*)installedApplicationsData toMenu:(NSMenu*)menu
{
    for (NSUInteger i = 0; i < [installedApplicationsData count]; i++)
    {
        Application* application = installedApplicationsData[i];
        
        [self addApplication:application toMenu:menu];
    }
}

//----------------------------------------------------------------------------
+ (void) addServiceItemsToMenu:(NSMenu*)menu
{
    NSMenuItem* startAtLogin =
    [[NSMenuItem alloc] initWithTitle:@"Start at Login" action:@selector(handleStartAtLogin:) keyEquivalent:@""];
    
    BOOL isStartAtLoginEnabled = [Settings isStartAtLoginEnabled];
    
    [startAtLogin setState: isStartAtLoginEnabled ? NSOnState : NSOffState];
    
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
+ (NSMenu*) createApplicationMenuAt:(NSStatusItem*)statusItem
{
    NSMenu* menu = [NSMenu new];
    
    NSMutableArray* simulators = [Tools activeSimulators];
    
    NSArray* recentSimulators = [simulators sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
    {
        NSDate* l = [(Simulator*)a date];
        NSDate* r = [(Simulator*)b date];
        return [r compare:l];
    }];
    
    int simulatorsCount = 0;
    for (Simulator* simulator in recentSimulators)
    {
        NSArray<Application*>* installedApplications = [Tools installedAppsOnSimulator:simulator];
        
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
    
    return menu;
}


@end
