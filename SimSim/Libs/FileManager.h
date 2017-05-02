//
//  FileManager.h
//  SimSim
//
//  Created by Jesus Lopez on 25/04/2017.
//  Copyright © 2017 DaniilSmelov. All rights reserved.
//

#import <Foundation/Foundation.h>

#define KEY_FILE                    @"file"
#define KEY_MODIFICATION_DATE       @"modificationDate"
#define KEY_FILE_TYPE               @"fileType"

@interface FileManager : NSObject

+ (NSArray *) getSortedFilesFromFolder:(NSString *)folderPath;
+ (NSString *) getApplicationFolderFromPath:(NSString *)folderPath;

@end
