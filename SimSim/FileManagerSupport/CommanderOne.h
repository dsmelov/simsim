/***************************************************************************
* Copyright (c) 2016 Artem Kirienko. All rights reserved.
****************************************************************************/
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>


@interface CommanderOne : NSObject

+ (BOOL) isCommanderOneAvailable;
+ (void) openInCommanderOne:(NSString*)path;

@end