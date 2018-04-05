//
//  Tools.h
//  SimSim
//
//  Created by Daniil Smelov on 05.04.18.
//  Copyright © 2018 Daniil Smelov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Entities/Simulator.h"
#import "Entities/Application.h"

@interface Tools : NSObject

+ (NSString*) homeDirectoryPath;
+ (BOOL) simulatorRunning;
+ (NSString*) simulatorRootPathByUUID:(NSString*)uuid;
+ (NSMutableSet*) simulatorPaths;
+ (NSMutableArray<Simulator*>*) activeSimulators;
+ (NSArray<Application*>*) installedAppsOnSimulator:(Simulator*)simulator;

@end
