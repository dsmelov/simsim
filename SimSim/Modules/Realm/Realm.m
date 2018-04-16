//
//  Realm.m
//  SimSim
//
//  Created by Jesus Lopez on 25/04/2017.
//  Copyright © 2017 DaniilSmelov. All rights reserved.
//

#import "Realm.h"
#import <Cocoa/Cocoa.h>
#import "SimSim-Swift.h"

#define PATHS_REALM_FILES  [NSArray arrayWithObjects: @"Documents", @"Library/Caches", nil]
#define REALM_APP_NAME          @"Realm Browser"
#define REALM_APP_URL           @"http://itunes.apple.com/es/app/realm-browser/id1007457278"

@implementation Realm


- (void)generateRealmMenuForPath:(NSString *)aPath forMenu:(NSMenu *)menu withHotKey:(NSNumber *)hotkey icon:(NSImage *)icon {

    NSArray *realmFiles = [[self class] findRealmFiles:aPath];

    if ([realmFiles count] == 0) { return; }  // Skip if there are no realm files

    BOOL isRealmBrowserInstalled = [[self class] isRealmBrowserAvailable];
    NSMenuItem* realmMenuItem = nil;

    if (isRealmBrowserInstalled == false) { // There is at least one realm file but no realmbrowser installed
        realmMenuItem = [[NSMenuItem alloc] initWithTitle:@"Install Realm Browser" action:@selector(installRealmBrowser:) keyEquivalent:[hotkey stringValue]];
        [realmMenuItem setTarget:self];
        [realmMenuItem setRepresentedObject:REALM_APP_URL];
    }
    else if ([realmFiles count] == 1) { // There is exactly one realm file
        realmMenuItem = [[NSMenuItem alloc] initWithTitle:@"Realm" action:@selector(openRealmFile:) keyEquivalent:[hotkey stringValue]];
        [realmMenuItem setRepresentedObject:aPath];
        [realmMenuItem setImage:icon];
        [realmMenuItem setTarget:self];
        [realmMenuItem setRepresentedObject:[[realmFiles firstObject] fullPath]];
    }
    else {  // There is more than one realm file
        realmMenuItem = [[NSMenuItem alloc] initWithTitle:@"Realm" action:nil keyEquivalent:[hotkey stringValue]];
        [realmMenuItem setRepresentedObject:aPath];
        [realmMenuItem setImage:icon];


        NSMenu* menuRealm = [[NSMenu alloc] initWithTitle:@"Realm Browser"];
        [menuRealm setAutoenablesItems:NO];

        for (RealmFile *realmFile in realmFiles) {
            NSMenuItem* menuItem = [[NSMenuItem alloc] initWithTitle:[realmFile fileName] action:@selector(openRealmFile:) keyEquivalent:@""];
            [menuItem setTarget:self];
            [menuItem setRepresentedObject:[realmFile fullPath]];
            [menuItem setEnabled:isRealmBrowserInstalled];;
            [menuRealm addItem:menuItem];
        }
        
        [menu setSubmenu:menuRealm forItem:realmMenuItem];
    }
    
    [menu addItem:realmMenuItem];
}


- (void)openRealmFile:(id)sender {
    [[self class] openInRealmBrowser:[sender representedObject]];
}

- (void)installRealmBrowser:(id)sender {
    [self openUrl:[sender representedObject]];
}

- (void)openUrl:(NSString *)aUrl {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:aUrl]];
}

#pragma mark - Statics methods

+ (NSArray *)findRealmFiles:(NSString *)aPath {
    NSMutableArray *files = [NSMutableArray new];

    for (NSString *realmPath in PATHS_REALM_FILES) {
        NSString *folderPath = [NSString stringWithFormat:@"%@/%@", aPath, realmPath];
        NSArray *allFilesOfFolder = [Tools getSortedFilesFromFolder: folderPath];

        for (NSDictionary *file in allFilesOfFolder)
        {
            NSString *fileName = [Tools getNameFrom:file];

            if ([[fileName pathExtension] isEqualToString: @"realm"] == false) { continue; }    // Skip if not a realm file

            RealmFile *realmFile = [[RealmFile alloc] init];
            realmFile.fileName = fileName;
            realmFile.path = folderPath;

            [files addObject: realmFile];
        }
    }

    return files;
}

+ (NSArray *)removeNonRealmObject:(NSArray *)allFiles {
    NSPredicate *endsRealm = [NSPredicate predicateWithFormat:@"self ENDSWITH '.realm'"];
    return [allFiles filteredArrayUsingPredicate:endsRealm];
}

#pragma mark - Public Statics methods

+ (BOOL)isRealmBrowserAvailable {
    NSFileManager* fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:[[self class] applicationPath]];
}

+ (NSString *)applicationPath {
    return [NSString stringWithFormat:@"/Applications/%@.app", REALM_APP_NAME];
}

+ (BOOL)isRealmAvailableForPath:(NSString *)aPath {
    NSArray *realmFiles = [[self class] findRealmFiles:aPath];
    return (realmFiles != nil && [realmFiles count] > 0);
}

+ (void)openInRealmBrowser:(NSString *)aPath {
    [[NSWorkspace sharedWorkspace] openFile:aPath withApplication:REALM_APP_NAME];
}

@end


@implementation RealmFile
- (NSString *)fullPath {
    return [NSString stringWithFormat:@"%@/%@", [self path], [self fileName]];
}
@end


