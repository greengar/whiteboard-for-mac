//
//  GSAlert.m
//  Whiteboard
//
//  Created by Cong Vo on 1/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GSAlert.h"
#import APP_DELEGATE

@implementation GSAlert

- (id)initWithDelegate:(id)delegate 
				 title:(NSString *)title message:(NSString *)message
		 defaultButton:(NSString *)defaultButtonTitle otherButton:(NSString *)otherButtonTitle {
	
#if TARGET_OS_IPHONE
	if ((self = [super initWithTitle:title
							  message:message
							 delegate:delegate
					cancelButtonTitle:defaultButtonTitle
					otherButtonTitles:otherButtonTitle, nil])) {
		
	}
#else
//	if ((self = [super init])) {
//		if (otherButtonTitle) {
//			[self addButtonWithTitle:otherButtonTitle];			
//		}
//		
//		[self addButtonWithTitle:defaultButtonTitle];
//		
//		if (title) {
//			[self setMessageText:title];
//		}
//		if (message) {
//			[self setInformativeText:message];			
//		}
//
//		[self setAlertStyle:NSWarningAlertStyle];
//		[self setIcon:[NSImage imageNamed:kAlertIcon]];
////		[self setDelegate:delegate];
//		
//		DLog(@"alert buttons: %@", self.buttons);
//	}
	
//	if ((self = [[NSAlert alertWithMessageText:title
//								 defaultButton:defaultButtonTitle
//							   alternateButton:nil
//								   otherButton:otherButtonTitle
//					 informativeTextWithFormat:message] retain])) {
//		self.delegate = delegate;
//	}
#endif
	return self;
}

+ (id)alertWithDelegate:(id)delegate 
						 title:(NSString *)title message:(NSString *)message
				 defaultButton:(NSString *)defaultButtonTitle otherButton:(NSString *)otherButtonTitle {
	
#if TARGET_OS_IPHONE	
	 id gsAlert = [[[[self class] alloc] initWithDelegate:delegate
													title:title
												  message:message 
											defaultButton:otherButtonTitle
											  otherButton:defaultButtonTitle] autorelease];
	return gsAlert;
#else
	return [super alertWithDelegate:delegate
							  title:title
							message:message
					  defaultButton:defaultButtonTitle
						otherButton:otherButtonTitle];
#endif	
	
}




//- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
//	DLog(@"clicked: %d", returnCode);
//	
//	if (returnCode == -1000) { // manually call dismiss
//		return;
//	}
//	
////	[NSApp orderOut:self];
//	// call delegate
//
////	[NSApp endSheet:[self window]];
////	[[self window] orderOut:AppDelegate.window];	
//	
//	if ([self.delegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)]) {
//		[self.delegate alertView:self clickedButtonAtIndex:1001 - returnCode];
//	}
//	
//	[self dismissWithClickedButtonIndex:1001 - returnCode animated:NO];
//	
//}


+ (NSString *)notificationStringToAlertTag:(NSInteger)alertTag selector:(SEL)selector{
	DLog(@"kDismissAlertNotification:tag=%d:action=%@", 
		 alertTag, NSStringFromSelector(selector));
	return [NSString stringWithFormat:@"kDismissAlertNotification:tag=%d:action=%@", 
			alertTag, NSStringFromSelector(selector)];
}


//#pragma mark dismiss notification 
//+ (void)postDismissNotificationForAlertTag:(NSInteger)alertTag {
//	[[NSNotificationCenter defaultCenter] postNotificationName:[[self class] notificationStringWithTag:alertTag]
//														object:self];
//}
//
//- (void)registerForDismissNotification {
//	[[NSNotificationCenter defaultCenter] addObserver:self 
//											 selector:@selector(receivedDismissNotification:) 
//												 name:[[self class] notificationStringWithTag:self.tag] object:nil];
//}
//
//- (void)receivedDismissNotification:(id)notification {
//	DLog();
//	[[NSNotificationCenter defaultCenter] removeObserver:self];
//	[self dismissWithClickedButtonIndex:-1 animated:YES];
//}

#pragma mark change message notification 

- (void)registerToReceiveNotificationForSelector:(SEL)selector {
	DLog();
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:selector 
												 name:[[self class] notificationStringToAlertTag:self.tag selector:selector]
											   object:nil];
	
}

+ (void)postNotificationToAlertTag:(NSInteger)alertTag selector:(SEL)selector object:(id)object {
	DLog();
	[[NSNotificationCenter defaultCenter] postNotificationName:[[self class] notificationStringToAlertTag:alertTag
																								 selector:selector]
														object:object];

}


- (void)dismiss {
	DLog();
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self dismissWithClickedButtonIndex:-1 animated:YES];	
}

- (void)changeMessage:(NSNotification *)notification {
	NSString *newMessage = [notification object];
	DLog(@"change alert tag: %d message: %@", self.tag, newMessage);
	[self setMessage:newMessage];
}

- (void)dealloc {
//	DLog(@"tag: %d", self.tag);
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

#if TARGET_OS_IPHONE
- (void)addSpinnerForName:(NSString *)name {
	if (name == nil)
		name = @"";
	
	// Create the activity indicator and add it to the alert
	UIActivityIndicatorView* activityView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
	// -22 y if name is 6 chars or less
	activityView.frame = CGRectMake(244.0f, ([name length] <= 6) ? 46.0f : 68.0f, kProgressIndicatorSize, kProgressIndicatorSize); //30.0f, 68.0f, 225.0f, 13.0f); //139.0f-18.0f, 80.0f, 37.0f, 37.0f);
	[self addSubview:activityView];
	[activityView startAnimating];
}
#endif

@end
