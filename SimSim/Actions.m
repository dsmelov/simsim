//
//  Actions.m
//  SimSim
//
//  Created by Daniil Smelov on 05.04.18.
//  Copyright © 2018 Daniil Smelov. All rights reserved.
//

#import "Actions.h"
#import "Tools.h"
#import "Settings.h"
#import "FileManagerSupport/CommanderOne.h"

@implementation Actions

//----------------------------------------------------------------------------
+ (void) copyToPasteboard:(id)sender
{
    NSString* path = (NSString*)[sender representedObject];
    
    NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
    
    [pasteboard declareTypes:@[ NSPasteboardTypeString ] owner:nil];
    [pasteboard setString:path forType:NSPasteboardTypeString];
}

//----------------------------------------------------------------------------
+ (void) takeScreenshot:(id)sender
{
    NSArray* windows = (NSArray *)CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListExcludeDesktopElements, kCGNullWindowID));
    
    for(NSDictionary *window in windows)
    {
        NSString* windowOwner = window[(NSString*)kCGWindowOwnerName];
        NSString* windowName = window[(NSString*)kCGWindowName];
        
        if ([windowOwner containsString:@"Simulator"] &&
            ([windowName containsString:@"iOS"] || [windowName containsString:@"watchOS"] || [windowName containsString:@"tvOS"]))
        {
            NSNumber* windowID = window[(NSString*)kCGWindowNumber];
            
            NSString *dateComponents = @"yyyyMMdd_HHmmss_SSSS";
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
            [dateFormatter setDateFormat:dateComponents];
            
            NSDate *date = [NSDate date];
            NSString *dateString = [dateFormatter stringFromDate:date];
            
            NSString* screenshotPath =
            [NSString stringWithFormat:@"%@/Desktop/Screen Shot at %@.png", [Tools homeDirectoryPath], dateString];
            
            CGRect bounds;
            CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)window[(NSString*)kCGWindowBounds], &bounds);
            
            CGImageRef image = CGWindowListCreateImage(bounds, kCGWindowListOptionIncludingWindow, (CGWindowID)[windowID intValue], kCGWindowImageDefault);
            NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithCGImage:image];
            
            NSData *data = [bitmap representationUsingType: NSPNGFileType properties:@{}];
            [data writeToFile: screenshotPath atomically:NO];
            
            CGImageRelease(image);
        }
    }
}

//----------------------------------------------------------------------------
+ (void) resetFolder:(NSString*)folder inRoot:(NSString*)root
{
    NSString* path = [root stringByAppendingPathComponent:folder];
    
    NSFileManager* fm = [NSFileManager new];
    NSDirectoryEnumerator* en = [fm enumeratorAtPath:path];
    NSError* error = nil;
    BOOL result = NO;
    
    NSString* file;
    
    while (file = [en nextObject])
    {
        result = [fm removeItemAtPath:[path stringByAppendingPathComponent:file] error:&error];
        if (!result && error)
        {
            NSLog(@"Something went wrong: %@", error);
        }
    }
}

//----------------------------------------------------------------------------
+ (void) resetApplication:(id)sender
{
    NSString* path = (NSString*)[sender representedObject];
    
    [self resetFolder:@"Documents" inRoot:path];
    [self resetFolder:@"Library" inRoot:path];
    [self resetFolder:@"tmp" inRoot:path];
}

//----------------------------------------------------------------------------
+ (void) openInFinder:(id)sender
{
    NSString* path = (NSString*)[sender representedObject];
    
    [[NSWorkspace sharedWorkspace] openFile:path withApplication:@"Finder"];
}

//----------------------------------------------------------------------------
+ (void) openInTerminal:(id)sender
{
    NSString* path = (NSString*)[sender representedObject];
    
    [[NSWorkspace sharedWorkspace] openFile:path withApplication:@"Terminal"];
}

//----------------------------------------------------------------------------
+ (void) openIniTerm:(id)sender
{
    NSString* path = (NSString*)[sender representedObject];
    
    [[NSWorkspace sharedWorkspace] openFile:path withApplication:@"iTerm"];
}

//----------------------------------------------------------------------------
+ (void) openInCommanderOne:(id)sender
{
    NSString* path = (NSString*)[sender representedObject];
    
    [CommanderOne openInCommanderOne:path];
}

//----------------------------------------------------------------------------
+ (void) exitApp:(id)sender
{
    [[NSApplication sharedApplication] terminate:self];
}

//----------------------------------------------------------------------------
+ (void) handleStartAtLogin:(id)sender
{
    BOOL isEnabled = [[sender representedObject] boolValue];
    
    [Settings setStartAtLoginEnabled:!isEnabled];
    
    [sender setRepresentedObject:@(!isEnabled)];
    
    if (isEnabled)
    {
        [sender setState:NSOffState];
    }
    else
    {
        [sender setState:NSOnState];
    }
}

//----------------------------------------------------------------------------
+ (void) aboutApp:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/dsmelov/simsim"]];
}


@end
