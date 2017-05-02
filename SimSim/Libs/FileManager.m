//
//  FileManager.m
//  SimSim
//
//  Created by Jesus Lopez on 25/04/2017.
//  Copyright © 2017 DaniilSmelov. All rights reserved.
//

#import "FileManager.h"

@implementation FileManager

+ (NSArray*) getSortedFilesFromFolder:(NSString*)folderPath
{
    NSArray* filesArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
    
    // sort by creation date
    NSMutableArray* filesAndProperties = [NSMutableArray arrayWithCapacity:filesArray.count];
    
    for (NSString* file in filesArray)
    {
        if (![file isEqualToString:@".DS_Store"])
        {
            NSString* filePath = [folderPath stringByAppendingPathComponent:file];
            NSDictionary* properties = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
            NSDate* modificationDate = properties[NSFileModificationDate];
            NSString *fileType = properties[NSFileType];
            
            [filesAndProperties addObject:@
             {
                 KEY_FILE              : file,
                 KEY_MODIFICATION_DATE : modificationDate,
                 KEY_FILE_TYPE         : fileType
             }];
        }
    }
    
    // Sort using a block - order inverted as we want latest date first
    NSArray* sortedFiles = [filesAndProperties sortedArrayUsingComparator:^(NSDictionary* path1, NSDictionary* path2)
                            {
                                NSComparisonResult comp = [path1[@"modificationDate"] compare:path2[@"modificationDate"]];
                                // invert ordering
                                if (comp == NSOrderedDescending)
                                {
                                    comp = NSOrderedAscending;
                                }
                                else if (comp == NSOrderedAscending)
                                {
                                    comp = NSOrderedDescending;
                                }
                                return comp;
                            }];
    
    return sortedFiles;
}

//----------------------------------------------------------------------------
+ (NSString*) getApplicationFolderFromPath:(NSString*)folderPath
{
    NSArray* filesArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"SELF EndsWith '.app'"];
    filesArray = [filesArray filteredArrayUsingPredicate:predicate];
    
    return filesArray[0];
}

@end
