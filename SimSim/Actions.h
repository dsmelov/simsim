//
//  Actions.h
//  SimSim
//
//  Created by Daniil Smelov on 05.04.18.
//  Copyright © 2018 Daniil Smelov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface Actions : NSObject

+ (void) copyToPasteboard:(id)sender;
+ (void) takeScreenshot:(id)sender;
+ (void) resetApplication:(id)sender;
+ (void) openInFinder:(id)sender;
+ (void) openInTerminal:(id)sender;
+ (void) openIniTerm:(id)sender;
+ (void) openInCommanderOne:(id)sender;
+ (void) exitApp:(id)sender;
+ (void) handleStartAtLogin:(id)sender;
+ (void) aboutApp:(id)sender;

@end
