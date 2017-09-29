//
//  NotificationsHandler.h
//  SimSim
//
//  Created by Artem Kirienko on 29.09.2017.
//

#import <Foundation/Foundation.h>

//============================================================================
@interface NotificationsHandler : NSObject <NSUserNotificationCenterDelegate>

+ (instancetype) handler;

@end
