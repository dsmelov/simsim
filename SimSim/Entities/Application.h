//
//  Application.h
//  SimSim
//
//  Created by Artem Kirienko on 07.12.2017.
//

#import <Foundation/Foundation.h>

@class Simulator;

//============================================================================
@interface Application : NSObject

+ (instancetype) applicationWithDictionary:(NSDictionary*)dictionary simulator:(Simulator*)simulator;

- (instancetype) initWithDictionary:(NSDictionary*)dictionary simulator:(Simulator*)simulator;

@property (nonatomic, readonly) NSString* uuid;
@property (nonatomic, readonly) NSString* bundleIdentifier;
@property (nonatomic, readonly) NSString* bundleName;
@property (nonatomic, readonly) NSString* version;
@property (nonatomic, readonly) NSImage* icon;
@property (nonatomic, readonly) NSString* contentPath;
@property (nonatomic, readonly) BOOL isAppleApplication;

@end
