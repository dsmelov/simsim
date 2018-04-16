//
//  AppDelegate.m
//  SimSim
//
//  Created by Daniil Smelov 2016.04.18
//  Copyright (c) 2016 Daniil Smelov. All rights reserved.
//

#import "AppDelegate.h"
#import "Settings.h"
#import "Simulator.h"
#import "Application.h"
#import "Tools.h"
#import "SimSim-Swift.h"

//============================================================================
@interface AppDelegate ()

@property (strong, nonatomic) NSStatusItem* statusItem;

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
- (void) presentApplicationMenu
{
    NSMenu* menu = [Menus createApplicationMenuAt:_statusItem];
    
    [_statusItem popUpStatusItemMenu:menu];
}

@end
