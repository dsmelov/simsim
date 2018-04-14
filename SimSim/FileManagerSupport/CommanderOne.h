/***************************************************************************
* Copyright (c) 2016 Artem Kirienko. All rights reserved.
****************************************************************************/
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>


@interface CommanderOne : NSObject

NS_ASSUME_NONNULL_BEGIN

+ (BOOL) isCommanderOneAvailable;
+ (void) openInCommanderOne:(NSString*)path;

NS_ASSUME_NONNULL_END

@end
