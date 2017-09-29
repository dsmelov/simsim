//
//  NotificationsHandler.m
//  SimSim
//
//  Created by Artem Kirienko on 29.09.2017.
//

#import "NotificationsHandler.h"
#import <Cocoa/Cocoa.h>

//============================================================================
@implementation NotificationsHandler

//----------------------------------------------------------------------------
+ (instancetype)handler
{
    return [self new];
}

//----------------------------------------------------------------------------
- (void) userNotificationCenter:(NSUserNotificationCenter*)center didActivateNotification:(NSUserNotification*)notification
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/dsmelov/simsim/releases"]];
}

@end
