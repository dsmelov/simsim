//
//  Realm.h
//  SimSim
//
//  Created by Jesus Lopez on 25/04/2017.
//  Copyright © 2017 DaniilSmelov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSMenu;

@interface Realm : NSObject

+ (BOOL)isRealmBrowserAvailable;
+ (NSString *__nonnull)applicationPath;
+ (BOOL)isRealmAvailableForPath:(NSString *__nonnull)aPath;
+ (void)openInRealmBrowser:(NSString *__nonnull)aPath;


- (NSMenu *__nullable)generateRealmMenuForPath:(NSString *__nonnull)aPath;

@end
