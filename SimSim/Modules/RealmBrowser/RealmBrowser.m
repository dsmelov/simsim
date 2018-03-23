//
//  RealmBrowser.m
//  SimSim
//
//  Created by Jesus Lopez on 25/04/2017.
//  Copyright © 2017 DaniilSmelov. All rights reserved.
//

#import "RealmFile.h"
#import "RealmBrowser.h"
#import <Cocoa/Cocoa.h>

#define REALM_APP_NAME @"Realm Browser"
#define REALM_APP_URL  @"http://itunes.apple.com/es/app/realm-browser/id1007457278"

@implementation RealmBrowser


- (void)generateRealmMenuForPath:(NSString *)aPath
                         forMenu:(NSMenu *)menu
                      withHotKey:(NSNumber *)hotkey
                            icon:(NSImage *)icon
{

    NSArray *realmFiles = [RealmFile findRealmFiles:aPath];

    if ([realmFiles count] == 0) { return; }  // Skip if there are no realm files

    BOOL isRealmBrowserInstalled = [[self class] isRealmBrowserAvailable];
    NSMenuItem *realmMenuItem = nil;

    if (isRealmBrowserInstalled == false) // There is at least one realm file but no Realm Browser installed
    {
        realmMenuItem = [[NSMenuItem alloc] initWithTitle:@"Install Realm Browser"
                                                   action:@selector(installRealmBrowser:)
                                            keyEquivalent:[hotkey stringValue]];
        [realmMenuItem setTarget:self];
        [realmMenuItem setRepresentedObject:REALM_APP_URL];
    }
    else if ([realmFiles count] == 1) // There is exactly one realm file
    {
        realmMenuItem = [[NSMenuItem alloc] initWithTitle:@"Realm Browser"
                                                   action:@selector(openRealmFile:)
                                            keyEquivalent:[hotkey stringValue]];
        [realmMenuItem setRepresentedObject:aPath];
        [realmMenuItem setImage:icon];
        [realmMenuItem setTarget:self];
        [realmMenuItem setRepresentedObject:[[realmFiles firstObject] fullPath]];
    }
    else // There is more than one realm file
    {
        realmMenuItem = [[NSMenuItem alloc] initWithTitle:@"Realm Browser"
                                                   action:nil
                                            keyEquivalent:[hotkey stringValue]];
        [realmMenuItem setRepresentedObject:aPath];
        [realmMenuItem setImage:icon];

        NSMenu *menuRealm = [[NSMenu alloc] initWithTitle:@"Realm Browser"];
        [menuRealm setAutoenablesItems:NO];

        for (RealmFile *realmFile in realmFiles)
        {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[realmFile fileName]
                                                              action:@selector(openRealmFile:)
                                                       keyEquivalent:@""];
            [menuItem setTarget:self];
            [menuItem setRepresentedObject:[realmFile fullPath]];
            [menuItem setEnabled:isRealmBrowserInstalled];;
            [menuRealm addItem:menuItem];
        }

        [menu setSubmenu:menuRealm forItem:realmMenuItem];
    }

    [menu addItem:realmMenuItem];
}


- (void)openRealmFile:(id)sender
{
    [[self class] openInRealmBrowser:[sender representedObject]];
}

- (void)installRealmBrowser:(id)sender
{
    [self openUrl:[sender representedObject]];
}

- (void)openUrl:(NSString *)aUrl
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:aUrl]];
}

#pragma mark - Public Statics methods

+ (BOOL)isRealmBrowserAvailable
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:[[self class] applicationPath]];
}

+ (NSString *)applicationPath
{
    return [NSString stringWithFormat:@"/Applications/%@.app", REALM_APP_NAME];
}

+ (void)openInRealmBrowser:(NSString *)aPath
{
    [[NSWorkspace sharedWorkspace] openFile:aPath withApplication:REALM_APP_NAME];
}

@end

