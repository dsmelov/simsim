//
//  Simulator.m
//  SimSim
//
//  Created by Artem Kirienko on 29.09.2017.
//  Copyright © 2017 DaniilSmelov. All rights reserved.
//

#import "Simulator.h"

//============================================================================
@interface Simulator ()

@property (nonatomic, strong) NSDictionary* properties;
@property (nonatomic, strong) NSString* path;

@end


//============================================================================
@implementation Simulator

//----------------------------------------------------------------------------
+ (instancetype)simulatorWithDictionary:(NSDictionary*)dictionary path:(NSString*)path
{
    return [[[self class] alloc] initWithDictionary:dictionary path:path];
}

//----------------------------------------------------------------------------
- (instancetype) initWithDictionary:(NSDictionary*)dictionary path:(NSString*)path
{
    self = [super init];
    
    if (self)
    {
        self.properties = dictionary;
        self.path = path;
    }
    
    return self;
}

//----------------------------------------------------------------------------
- (NSString*) name
{
    return self.properties[@"name"];
}

//----------------------------------------------------------------------------
- (NSString*)os
{
    NSString* runtime = [self.properties[@"runtime"] stringByReplacingOccurrencesOfString:@"com.apple.CoreSimulator.SimRuntime." withString:@""];
    runtime = [runtime stringByReplacingOccurrencesOfString:@"OS-" withString:@"OS "];
    runtime = [runtime stringByReplacingOccurrencesOfString:@"-" withString:@"."];
    return runtime;
}

@end
