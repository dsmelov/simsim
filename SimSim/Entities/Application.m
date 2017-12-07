//
//  Application.m
//  SimSim
//
//  Created by Artem Kirienko on 07.12.2017.
//

#import <AppKit/AppKit.h>
#import "Application.h"
#import "Simulator.h"
#import "FileManager.h"

//============================================================================
@interface Application ()

@property (nonatomic, strong) NSString* uuid;
@property (nonatomic, strong) NSString* bundleName;
@property (nonatomic, strong) NSString* version;
@property (nonatomic, strong) NSImage* icon;
@property (nonatomic, strong) NSString* contentPath;
@property (nonatomic, strong) NSDictionary* properties;

@end


//============================================================================
@implementation Application

//----------------------------------------------------------------------------
+ (instancetype) applicationWithDictionary:(NSDictionary*)dictionary simulator:(Simulator*)simulator
{
    return [(Application*)[[self class] alloc] initWithDictionary:dictionary simulator:simulator];
}

//----------------------------------------------------------------------------
- (instancetype) initWithDictionary:(NSDictionary*)dictionary simulator:(Simulator*)simulator;
{
    self = [super init];

    if (self)
    {
        self.uuid = dictionary[KEY_FILE];
        self.properties = [self getApplicationPropertiesByUUID:self.uuid andRootPath:simulator.path];

        [self buildMetadataForBundle:self.bundleIdentifier usingRootPath:simulator.path];
    }

    return self;
}

//----------------------------------------------------------------------------
- (BOOL) isAppleApplication
{
    return [self.bundleIdentifier hasPrefix:@"com.apple"];
}

//----------------------------------------------------------------------------
- (NSString*) bundleIdentifier
{
    return self.properties[@"MCMMetadataIdentifier"];
}

#pragma mark - Private
//----------------------------------------------------------------------------
- (NSString*) applicationRootPathByUUID:(NSString*)uuid
                            andRootPath:(NSString*)simulatorRootPath
{
    return
        [simulatorRootPath stringByAppendingFormat:@"data/Containers/Data/Application/%@/", uuid];
}

//----------------------------------------------------------------------------
- (NSDictionary*) getApplicationPropertiesByUUID:(NSString*)uuid
                                     andRootPath:(NSString*)simulatorRootPath
{
    self.contentPath = [self applicationRootPathByUUID:uuid andRootPath:simulatorRootPath];

    NSString* applicationDataPropertiesPath =
        [self.contentPath stringByAppendingString:@".com.apple.mobile_container_manager.metadata.plist"];

    return [NSDictionary dictionaryWithContentsOfFile:applicationDataPropertiesPath];
}

//----------------------------------------------------------------------------
- (void) buildMetadataForBundle:(NSString*)applicationBundleIdentifier
                  usingRootPath:(NSString*)simulatorRootPath
{
    NSString* installedApplicationsBundlePath =
        [simulatorRootPath stringByAppendingString:@"data/Containers/Bundle/Application/"];

    NSArray* installedApplicationsBundle =
        [FileManager getSortedFilesFromFolder:installedApplicationsBundlePath];

    [self processBundles:installedApplicationsBundle
        usingRootPath:simulatorRootPath
        andBundleIdentifier:applicationBundleIdentifier
        withFinalBlock:^(NSString* applicationRootBundlePath)
        {
            NSString* applicationFolderName = [FileManager getApplicationFolderFromPath:applicationRootBundlePath];

            NSString* applicationFolderPath = [applicationRootBundlePath stringByAppendingFormat:@"%@/", applicationFolderName];

            NSString* applicationPlistPath = [applicationFolderPath stringByAppendingString:@"Info.plist"];

            NSDictionary* applicationPlist = [NSDictionary dictionaryWithContentsOfFile:applicationPlistPath];

            NSString* applicationVersion = applicationPlist[@"CFBundleVersion"];
            NSString* applicationBundleName = applicationPlist[@"CFBundleName"];

            if (applicationBundleName.length == 0)
            {
                applicationBundleName = applicationPlist[@"CFBundleDisplayName"];
            }

            NSImage* icon = [self getIconForApplicationWithPlist:applicationPlist folder:applicationFolderPath];

            self.bundleName = applicationBundleName;
            self.version = applicationVersion;
            self.icon = icon;
        }];
}

//----------------------------------------------------------------------------
- (NSImage*) getIconForApplicationWithPlist:(NSDictionary*)applicationPlist folder:(NSString*)applicationFolderPath
{
    NSString* iconPath;
    NSString* applicationIcon  = applicationPlist[@"CFBundleIconFile"];
    NSFileManager* fileManager = [NSFileManager defaultManager];

    if (applicationIcon != nil)
    {
        iconPath = [applicationFolderPath stringByAppendingString:applicationIcon];
    }
    else
    {
        NSDictionary* applicationIcons = applicationPlist[@"CFBundleIcons"];

        NSString* postfix = @"";

        if (!applicationIcons)
        {
            applicationIcons = applicationPlist[@"CFBundleIcons~ipad"];
            postfix = @"~ipad";
        }

        NSDictionary* applicationPrimaryIcons = applicationIcons[@"CFBundlePrimaryIcon"];
        if (applicationPrimaryIcons && [applicationPrimaryIcons isKindOfClass:[NSDictionary class]]) {
            NSArray* iconFiles = nil;
            NS_DURING
                iconFiles = applicationPrimaryIcons[@"CFBundleIconFiles"];
            NS_HANDLER
            NS_ENDHANDLER

            if (iconFiles && iconFiles.count > 0)
            {
                applicationIcon = [iconFiles lastObject];

                iconPath = [applicationFolderPath stringByAppendingFormat:@"%@%@.png", applicationIcon, postfix];

                if (![fileManager fileExistsAtPath:iconPath])
                {
                    iconPath = [applicationFolderPath stringByAppendingFormat:@"%@@2x%@.png", applicationIcon, postfix];
                }
            }
            else
            {
                iconPath = nil;
            }
        }
        else
        {
            iconPath = nil;
        }
    }

    if (![fileManager fileExistsAtPath:iconPath])
    {
        iconPath = nil;
    }

    NSImage* icon = nil;
    if (iconPath == nil)
    {
        icon = [NSImage imageNamed:@"empty_icon"];
    }
    else
    {
        icon = [[NSImage alloc] initWithContentsOfFile:iconPath];
    }

    icon = [self roundCorners:[self scaleImage:icon toSize:NSMakeSize(24, 24)]];

    return icon;
}

//----------------------------------------------------------------------------
- (NSImage*) scaleImage:(NSImage*)anImage toSize:(NSSize)size
{
    NSImage* sourceImage = anImage;

    if ([sourceImage isValid])
    {
        NSImage* smallImage = [[NSImage alloc] initWithSize:size];
        [smallImage lockFocus];
        [sourceImage setSize:size];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [sourceImage drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, size.width, size.height) operation:NSCompositeCopy fraction:1.0];
        [smallImage unlockFocus];

        return smallImage;
    }

    return nil;
}

//----------------------------------------------------------------------------
- (void) processBundles:(NSArray*)bundles
          usingRootPath:(NSString*)simulatorRootPath
    andBundleIdentifier:(NSString*)applicationBundleIdentifier
         withFinalBlock:(void(^)(NSString* applicationRootBundlePath))block
{
    for (NSUInteger j = 0; j < [bundles count]; j++)
    {
        NSString* appBundleUUID = bundles[j][KEY_FILE];

        NSString* applicationRootBundlePath =
            [simulatorRootPath stringByAppendingFormat:@"data/Containers/Bundle/Application/%@/", appBundleUUID];

        NSString* applicationBundlePropertiesPath =
            [applicationRootBundlePath stringByAppendingString:@".com.apple.mobile_container_manager.metadata.plist"];

        NSDictionary* applicationBundleProperties =
            [NSDictionary dictionaryWithContentsOfFile:applicationBundlePropertiesPath];

        NSString* bundleIdentifier = applicationBundleProperties[@"MCMMetadataIdentifier"];

        if ([bundleIdentifier isEqualToString:applicationBundleIdentifier])
        {
            block(applicationRootBundlePath);
            break;
        }
    }
}

//----------------------------------------------------------------------------
- (NSImage*)roundCorners:(NSImage*)image
{
    NSImage* existingImage = image;
    NSSize existingSize = [existingImage size];
    NSSize newSize = NSMakeSize(existingSize.width, existingSize.height);
    NSImage* composedImage = [[NSImage alloc] initWithSize:newSize];

    [composedImage lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];

    NSRect imageFrame = NSRectFromCGRect(CGRectMake(0, 0, existingSize.width, existingSize.height));
    NSBezierPath* clipPath = [NSBezierPath bezierPathWithRoundedRect:imageFrame xRadius:3 yRadius:3];
    [clipPath setWindingRule:NSEvenOddWindingRule];
    [clipPath addClip];

    [image drawAtPoint:NSZeroPoint fromRect:NSMakeRect(0, 0, newSize.width, newSize.height) operation:NSCompositeSourceOver fraction:1];

    [composedImage unlockFocus];

    return composedImage;
}

@end
