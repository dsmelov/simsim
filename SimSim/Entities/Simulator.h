//
//  Simulator.h
//  SimSim
//
//  Created by Artem Kirienko on 29.09.2017.
//  Copyright © 2017 DaniilSmelov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Simulator : NSObject

+ (instancetype) simulatorWithDictionary:(NSDictionary*)dictionary path:(NSString*)path;

- (instancetype) initWithDictionary:(NSDictionary*)dictionary path:(NSString*)path;

@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) NSString* os;
@property (nonatomic, readonly) NSString* path;
@property (nonatomic, readonly) NSDate* date;

@end
