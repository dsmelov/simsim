//
// Realm.h
// SimSim
//
// Created by David Whetstone on 2/26/18.
// Copyright (c) 2018 DaniilSmelov. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RealmFile : NSObject

@property (assign) NSString * fileName;
@property (assign) NSString * path;

- (NSString *)fullPath;
+ (BOOL)isRealmAvailableForPath:(NSString *)aPath;
+ (NSArray *)findRealmFiles:(NSString *)aPath;

@end

NS_ASSUME_NONNULL_END