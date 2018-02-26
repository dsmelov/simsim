//
//  RealmBrowser.h
//  SimSim
//
//  Created by Jesus Lopez on 25/04/2017.
//  Copyright © 2017 DaniilSmelov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSMenu;

NS_ASSUME_NONNULL_BEGIN

@interface RealmBrowser : NSObject

+ (BOOL)isRealmBrowserAvailable;
+ (NSString *)applicationPath;
+ (void)openInRealmBrowser:(NSString *)aPath;

- (void)generateRealmMenuForPath:(NSString *)aPath forMenu:(NSMenu *)menu withHotKey:(NSNumber *)hotkey icon:(NSImage *)icon;

@end

NS_ASSUME_NONNULL_END
