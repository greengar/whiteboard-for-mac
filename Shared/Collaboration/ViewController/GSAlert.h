//
//  GSAlert.h
//  Whiteboard
//
//  Created by Cong Vo on 1/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
    
#else
	#import "GSMacAlert.h"
#endif


typedef enum {
	AlertTagDefault = 0,
	AlertTagImageSend = 10,
	AlertTagReceiveImage = 11,
	
    AlertTagStartOverSend = 12,
	AlertTagStartOverReceive = 13,
	AlertTagStartOverWithoutConnection = 14,
    
    AlertTagUploadImageNeedAthenticated = 15,
	
	AlertTagCollaborationConnectionRequest = 100, // [RE] Connection REquest
	AlertTagCollaborationDisconnect = 101 // [dC] disConnect
	
} AlertTag;

@class GSAlert;

@protocol GSAlertDelegate
- (void)alertView:(GSAlert *)alert clickedButtonAtIndex:(NSUInteger)buttonIndex;
@end


@interface GSAlert : 
#if TARGET_OS_IPHONE
UIAlertView {
}
- (void)addSpinnerForName:(NSString *)name;
#else
GSMacAlert {
}	
#endif

+ (id)alertWithDelegate:(id)delegate 
				  title:(NSString *)title message:(NSString *)message
		  defaultButton:(NSString *)defaultButtonTitle otherButton:(NSString *)otherButtonTitle;

/* KONG:
 Use notification to tell an alert view, which we do not keep a pointer to, do something.
*/
- (void)registerToReceiveNotificationForSelector:(SEL)selector;
+ (void)postNotificationToAlertTag:(NSInteger)alertTag selector:(SEL)selector object:(id)object;

/* KONG:
 Selector that can be use via post notification,
 You can use these selector to tell an alert with specific tag do something
 */
- (void)dismiss;
- (void)changeMessage:(NSNotification *)notification; // please pass message as object of notification

	
@end
