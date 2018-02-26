//
//  RealmStudio.m
//  SimSim
//
//  Created by David Whetstone on 26/02/2018.
//  Based on code by Jesus Lopez on 25/04/2017.
//  Copyright © 2017 DaniilSmelov. All rights reserved.
//

#import "RealmFile.h"
#import "RealmStudio.h"
#import <Cocoa/Cocoa.h>

#define REALM_APP_NAME @"Realm Studio"
#define REALM_APP_URL  @"https://realm.io/products/realm-studio/"

@implementation RealmStudio


- (void)generateRealmMenuForPath:(NSString *)aPath
                         forMenu:(NSMenu *)menu
                      withHotKey:(NSNumber *)hotkey
                            icon:(NSImage *)icon
{

    NSArray *realmFiles = [RealmFile findRealmFiles:aPath];

    if ([realmFiles count] == 0) { return; }  // Skip if there are no realm files

    BOOL isRealmStudioInstalled = [[self class] isRealmStudioAvailable];
    NSMenuItem *realmMenuItem = nil;

    if (isRealmStudioInstalled == false) // There is at least one realm file but no Realm Studio installed
    {
        realmMenuItem = [[NSMenuItem alloc] initWithTitle:@"Install Realm Studio"
                                                   action:@selector(installRealmStudio:)
                                            keyEquivalent:[hotkey stringValue]];
        [realmMenuItem setTarget:self];
        [realmMenuItem setRepresentedObject:REALM_APP_URL];
    }
    else if ([realmFiles count] == 1) // There is exactly one realm file
    {
        realmMenuItem = [[NSMenuItem alloc] initWithTitle:@"Realm Studio"
                                                   action:@selector(openRealmFile:)
                                            keyEquivalent:[hotkey stringValue]];
        [realmMenuItem setRepresentedObject:aPath];
        [realmMenuItem setImage:icon];
        [realmMenuItem setTarget:self];
        [realmMenuItem setRepresentedObject:[[realmFiles firstObject] fullPath]];
    }
    else // There is more than one realm file
    {
        realmMenuItem = [[NSMenuItem alloc] initWithTitle:@"Realm Studio"
                                                   action:nil
                                            keyEquivalent:[hotkey stringValue]];
        [realmMenuItem setRepresentedObject:aPath];
        [realmMenuItem setImage:icon];

        NSMenu *menuRealm = [[NSMenu alloc] initWithTitle:@"Realm Studio"];
        [menuRealm setAutoenablesItems:NO];

        for (RealmFile *realmFile in realmFiles)
        {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[realmFile fileName]
                                                              action:@selector(openRealmFile:)
                                                       keyEquivalent:@""];
            [menuItem setTarget:self];
            [menuItem setRepresentedObject:[realmFile fullPath]];
            [menuItem setEnabled:isRealmStudioInstalled];;
            [menuRealm addItem:menuItem];
        }

        [menu setSubmenu:menuRealm forItem:realmMenuItem];
    }

    [menu addItem:realmMenuItem];
}


- (void)openRealmFile:(id)sender
{
    [[self class] openInRealmStudio:[sender representedObject]];
}

- (void)installRealmStudio:(id)sender
{
    [self openUrl:[sender representedObject]];
}

- (void)openUrl:(NSString *)aUrl
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:aUrl]];
}

#pragma mark - Public Statics methods

+ (BOOL)isRealmStudioAvailable
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:[[self class] applicationPath]];
}

+ (NSString *)applicationPath
{
    return [NSString stringWithFormat:@"/Applications/%@.app", REALM_APP_NAME];
}

+ (void)openInRealmStudio:(NSString *)aPath
{
    [[NSWorkspace sharedWorkspace] openFile:aPath withApplication:REALM_APP_NAME];
}

@end

