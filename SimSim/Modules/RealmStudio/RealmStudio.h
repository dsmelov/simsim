//
//  RealmStudio.h
//  SimSim
//
//  Created by David Whetstone on 26/02/2018.
//  Based on code by Jesus Lopez on 25/04/2017.
//  Copyright © 2017 DaniilSmelov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSMenu;

NS_ASSUME_NONNULL_BEGIN

@interface RealmStudio : NSObject

+ (BOOL)isRealmStudioAvailable;
+ (NSString *)applicationPath;
+ (void)openInRealmStudio:(NSString *)aPath;

- (void)generateRealmMenuForPath:(NSString *)aPath forMenu:(NSMenu *)menu withHotKey:(NSNumber *)hotkey icon:(NSImage *)icon;

@end

NS_ASSUME_NONNULL_END

