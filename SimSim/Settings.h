//
//  Settings.h
//  SimSim
//
//  Created by Artem Kirienko on 22.04.16.
//  Copyright © 2016 DaniilSmelov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Settings : NSObject

+ (void) setStartAtLoginEnabled:(BOOL)isEnabled;
+ (BOOL) isStartAtLoginEnabled;

@end
