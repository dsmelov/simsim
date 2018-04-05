//
//  Menus.h
//  SimSim
//
//  Created by Daniil Smelov on 05.04.18.
//  Copyright © 2018 Daniil Smelov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "Entities/Application.h"
#import "Entities/Simulator.h"

@interface Menus : NSObject

+ (NSNumber*_Nonnull) addAction:(NSString* _Nonnull)title
              toSubmenu:(NSMenu* _Nonnull)submenu
                forPath:(NSString* _Nonnull)path
               withIcon:(NSString*_Nonnull)iconPath
              andHotkey:(NSNumber* _Nonnull)hotkey
                   does:(nullable SEL)selector;

+ (NSNumber* _Nonnull) addAction:(NSString*_Nonnull)title
              toSubmenu:(NSMenu*_Nonnull)submenu
                forPath:(NSString*_Nonnull)path
             withHotkey:(NSNumber*_Nonnull)hotkey
                   does:(nullable SEL)selector;

+ (void) addSubMenusToItem:(NSMenuItem*_Nonnull)item usingPath:(NSString*_Nonnull)path;
+ (void) addApplication:(Application*_Nonnull)application toMenu:(NSMenu*_Nonnull)menu;
+ (void) addApplications:(NSArray<Application* >* _Nonnull)installedApplicationsData toMenu:(NSMenu*_Nonnull)menu;
+ (NSMenu* _Nonnull) createApplicationMenuAt:(NSStatusItem* _Nonnull)statusItem;
+ (void) addServiceItemsToMenu:(NSMenu*_Nonnull)menu;


@end
