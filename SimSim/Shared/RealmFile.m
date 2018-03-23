//
// Realm.m
// SimSim
//
// Created by David Whetstone on 2/26/18.
// Copyright (c) 2018 DaniilSmelov. All rights reserved.
//

#import "RealmFile.h"
#import "FileManager.h"

#define PATHS_REALM_FILES  [NSArray arrayWithObjects: @"Documents", @"Library/Caches", nil]

@implementation RealmFile

- (NSString *)fullPath
{
    return [NSString stringWithFormat:@"%@/%@", [self path], [self fileName]];
}

+ (BOOL)isRealmAvailableForPath:(NSString *)aPath
{
    NSArray *realmFiles = [[self class] findRealmFiles:aPath];
    return (realmFiles != nil && [realmFiles count] > 0);
}

+ (NSArray *)findRealmFiles:(NSString *)aPath
{
    NSMutableArray *files = [NSMutableArray new];

    for (NSString *realmPath in PATHS_REALM_FILES)
    {
        NSString *folderPath       = [NSString stringWithFormat:@"%@/%@", aPath, realmPath];
        NSArray  *allFilesOfFolder = [FileManager getSortedFilesFromFolder:folderPath];

        for (NSDictionary *file in allFilesOfFolder)
        {
            NSString *fileName = file[KEY_FILE];

            if ([[fileName pathExtension] isEqualToString:@"realm"] == false) { continue; } // Skip if not a realm file

            RealmFile *realmFile = [[RealmFile alloc] init];
            realmFile.fileName = fileName;
            realmFile.path     = folderPath;

            [files addObject:realmFile];
        }
    }

    return files;
}

@end
