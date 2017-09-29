//
//  AddUpdate.m
//  SimSim
//
//  Created by Artem Kirienko on 29.09.2017.
//

#import "AppUpdate.h"

//============================================================================
@interface AppUpdate ()

@property (nonatomic, strong) dispatch_queue_t updateCheckQueue;

- (BOOL) isUpdateAvailable;
- (void) presentUpdateNotification;

@end


//============================================================================
@implementation AppUpdate

//----------------------------------------------------------------------------
- (instancetype) init
{
    self = [super init];
    
    if (self)
    {
        self.updateCheckQueue = dispatch_queue_create("SimSim Update Check Queue", nil);
    }
    
    return self;
}

//----------------------------------------------------------------------------
- (BOOL) isUpdateAvailable
{
    // TODO: Check if update is actially available here using GitHub API
    return YES;
}

//----------------------------------------------------------------------------
- (void) scheduleCheck
{
    dispatch_async(self.updateCheckQueue, ^
    {
        if ([self isUpdateAvailable])
        {
            [self presentUpdateNotification];
        }
    });
}

//----------------------------------------------------------------------------
- (void) presentUpdateNotification
{
    NSUserNotification* notification = [NSUserNotification new];
    notification.title = @"SimSim update is available";
    notification.informativeText = @"New version released";
    notification.soundName = NSUserNotificationDefaultSoundName;
    notification.deliveryDate = [NSDate date];
    
    // TODO: Banner is not presented for some reason (although a notification appears in the notification center)
    NSUserNotificationCenter* center = [NSUserNotificationCenter defaultUserNotificationCenter];
    [center deliverNotification:notification];
}

@end
