//
//  Tools.m
//  SimSim
//
//  Created by Daniil Smelov on 05.04.18.
//  Copyright © 2018 Daniil Smelov. All rights reserved.
//

#import "Tools.h"
#import "FileManager.h"

@implementation Tools

//----------------------------------------------------------------------------
+ (NSString*) homeDirectoryPath
{
    return NSHomeDirectory();
}

//----------------------------------------------------------------------------
+ (BOOL) simulatorRunning
{
    NSArray* windows = (NSArray *)CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListExcludeDesktopElements, kCGNullWindowID));
    
    for (NSDictionary* window in windows)
    {
        NSString* windowOwner = window[(NSString*)kCGWindowOwnerName];
        NSString* windowName = window[(NSString*)kCGWindowName];
        
        if ([windowOwner containsString:@"Simulator"] &&
            ([windowName containsString:@"iOS"] || [windowName containsString:@"watchOS"] || [windowName containsString:@"tvOS"]))
        {
            return YES;
        }
    }
    
    return NO;
}

//----------------------------------------------------------------------------
+ (NSString*) simulatorRootPathByUUID:(NSString*)uuid
{
    return
    [NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices/%@/", [Tools homeDirectoryPath], uuid];
}

//----------------------------------------------------------------------------
// Since we dont want duplicates, simulatorPaths is now a Set
+ (NSMutableSet*) simulatorPaths
{
    NSString* simulatorPropertiesPath =
    [NSString stringWithFormat:@"%@/Library/Preferences/com.apple.iphonesimulator.plist", [Tools homeDirectoryPath]];
    
    NSDictionary* simulatorProperties = [NSDictionary dictionaryWithContentsOfFile:simulatorPropertiesPath];
    
    NSString* uuid = simulatorProperties[@"CurrentDeviceUDID"];
    
    NSDictionary* devicePreferences = simulatorProperties[@"DevicePreferences"];
    
    NSMutableSet* simulatorPaths = [NSMutableSet new];
    
    [simulatorPaths addObject:[self simulatorRootPathByUUID:uuid]];
    
    if (devicePreferences != nil)
    {
        // we're running on xcode 9
        for (NSString* uuid in [devicePreferences allKeys])
        {
            [simulatorPaths addObject:[self simulatorRootPathByUUID:uuid]];
        }
    }
    
    return simulatorPaths;
}

//----------------------------------------------------------------------------
+ (NSMutableArray<Simulator*>*) activeSimulators
{
    NSMutableSet* simulatorPaths = [self simulatorPaths];
    
    NSMutableArray* simulators = [NSMutableArray new];
    
    for (NSString* path in simulatorPaths)
    {
        NSString* simulatorDetailsPath = [path stringByAppendingString:@"device.plist"];
        
        NSDictionary* properties = [NSDictionary dictionaryWithContentsOfFile:simulatorDetailsPath];
        
        if (properties == nil) { continue; } // skip "empty" properties
        
        Simulator* simulator = [Simulator simulatorWithDictionary:properties path:path];
        [simulators addObject:simulator];
    }
    
    return simulators;
}

//----------------------------------------------------------------------------
+ (NSArray<Application*>*) installedAppsOnSimulator:(Simulator*)simulator
{
    NSString* installedApplicationsDataPath =
    [simulator.path stringByAppendingString:@"data/Containers/Data/Application/"];
    
    NSArray* installedApplications =
    [FileManager getSortedFilesFromFolder:installedApplicationsDataPath];
    
    NSMutableArray* userApplications = [NSMutableArray new];
    
    for (NSDictionary* app in installedApplications)
    {
        Application* application = [Application applicationWithDictionary:app simulator:simulator];
        
        // BundleName and version cant be nil
        if (application && application.bundleName && application.version)
        {
            if (!application.isAppleApplication)
            {
                [userApplications addObject:application];
            }
        }
        
    }
    
    return userApplications;
}


@end
