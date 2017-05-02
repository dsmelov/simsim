//
//  Realm.m
//  SimSim
//
//  Created by Jesus Lopez on 25/04/2017.
//  Copyright © 2017 DaniilSmelov. All rights reserved.
//

#import "Realm.h"
#import <Cocoa/Cocoa.h>
#import "FileManager.h"

#define PATH_REALM_FILES        @"Library/Caches"
#define REALM_APP_NAME          @"Realm Browser"
#define REALM_APP_URL           @"http://itunes.apple.com/es/app/realm-browser/id1007457278"

@implementation Realm


- (NSMenu *)generateRealmMenuForPath:(NSString *)aPath {
    
    NSMenu* menuRealm = [[NSMenu alloc] initWithTitle:@"Realm Browser"];
    [menuRealm setAutoenablesItems:NO];
    NSArray *realmFiles = [[self class] findRealmFiles:aPath];
    
    BOOL isRealmBrowserInstalled = [[self class] isRealmBrowserAvailable];
    
    for (NSString *fileName in realmFiles) {
        NSMenuItem* menuItem = [[NSMenuItem alloc] initWithTitle:fileName action:@selector(openRealmFile:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:[NSString stringWithFormat:@"%@/%@/%@", aPath, PATH_REALM_FILES, fileName]];
        [menuItem setEnabled:isRealmBrowserInstalled];;
        [menuRealm addItem:menuItem];
    }
    
    if (!isRealmBrowserInstalled) {
        NSMenuItem* realmBrowserInstallMenuItem = [[NSMenuItem alloc] initWithTitle:@"Install Realm Browser" action:@selector(installRealmBrowser:) keyEquivalent:@""];
        [realmBrowserInstallMenuItem setTarget:self];
        [realmBrowserInstallMenuItem setRepresentedObject:REALM_APP_URL];
        [menuRealm addItem:realmBrowserInstallMenuItem];
    }
    
    return menuRealm;
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
    NSArray *allFiles = [FileManager getSortedFilesFromFolder:[NSString stringWithFormat:@"%@/%@", aPath, PATH_REALM_FILES]];
    for (NSDictionary *file in allFiles) {
        [files addObject:file[KEY_FILE]];
    }
    return [self removeNonRealmObject:files];
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
