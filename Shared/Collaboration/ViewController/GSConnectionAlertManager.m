//
//  GSConnectionAlertManager.m
//  Whiteboard
//
//  Created by Cong Vo on 1/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GSConnectionAlertManager.h"


@implementation GSConnectionAlertManager
@synthesize alerts = _alerts;

- (id)init {
	if ((self = [super init])) {
		_alerts = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc {
    [_alerts release];
    [super dealloc];
}


- (BOOL)isAlert:(GSConnectionAlert *)currentAlert forSamePeerWithAlert:(GSConnectionAlert *)newAlert {
	DLog(@"currentAlert %@\n newAlert: %@", currentAlert, newAlert);
	
	// same type of connection?
	if (currentAlert.affectedPeer.type != newAlert.affectedPeer.type) {
		return NO;
	}
	
	//KONG: an alert that affected multiple ppl, in most cases, should not be dismiss 
	if (currentAlert.secondAffectedPeer != nil || newAlert.secondAffectedPeer != nil) {
		return NO;
	}
	
	// same name?
	if ([currentAlert.affectedPeer.name isEqualToString:newAlert.affectedPeer.name]) {
		return YES;
	}
	
	
//	if (currentAlert.affectedPeer.type == GSConnectionTypeLocal) {
//	// local connection
//		
//		
//		
//	} else {
//	// internetConnection
//		
//	}

	
	return NO;
}

- (void)showAlertView:(GSConnectionAlert *)alert {
	// Check if there has already an alert view for same peer, action
	for (GSConnectionAlert *currentAlert in _alerts) {
		if ([self isAlert:currentAlert forSamePeerWithAlert:alert]) {
			// dismiss current alert
			DLog(@"dismissed alertView: %@", currentAlert);
			[currentAlert dismissWithClickedButtonIndex:-1 animated:YES];
		}
	}
	
	
	[alert show];
	[_alerts addObject:alert];
}

- (BOOL)isAlert:(GSConnectionAlert *)currentAlert forSamePeer:(GSWhiteboard *)affectedPeer action:(AlertAction)action {
//	DLog(@"currentAlert %@\n newAlert: %@", currentAlert, newAlert);
	
	// same type of connection?
	if (currentAlert.affectedPeer.type != affectedPeer.type) {
		return NO;
	}
	
		
	//KONG: an alert that affected multiple ppl, in most cases, should not be dismiss 
	if (currentAlert.secondAffectedPeer != nil) {
		return NO;
	}
	
	// same action?
	if (currentAlert.action != action) {
		return NO;
	}
	
	
	// same name?
	if ([currentAlert.affectedPeer.name isEqualToString:affectedPeer.name]) {
		return YES;
	}
	
	
	//	if (currentAlert.affectedPeer.type == GSConnectionTypeLocal) {
	//	// local connection
	//		
	//		
	//		
	//	} else {
	//	// internetConnection
	//		
	//	}
	
	
	return NO;
}


// dismiss all alert view that affect a single person + action
- (void)dismissAllSingleAlertViewFor:(GSWhiteboard *)affectedPeer action:(AlertAction)action {
	for (GSConnectionAlert *currentAlert in _alerts) {
		if ([self isAlert:currentAlert forSamePeer:affectedPeer action:action]) {
			// dismiss current alert
			DLog(@"dismissed alertView: %@", currentAlert);
			[currentAlert dismissWithClickedButtonIndex:-1 animated:YES];
		}
	}	
}

- (void)alertView:(GSAlert *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	// check if we want to dismiss other alerts
	GSConnectionAlert *dismissedAlertView = (GSConnectionAlert *)alertView;
	
	
	//KONG: if user choose to dismiss an alert view, buttonIndex >= 0
	// and we make an assumption that OK button has index >= 1
	// and that alert affects more than 1 person
	if (buttonIndex >= 1 && dismissedAlertView.secondAffectedPeer != nil) {
		[self dismissAllSingleAlertViewFor:dismissedAlertView.affectedPeer action:dismissedAlertView.action];
		// TODO: KONG - check to dismiss alert view for second affected peer 
	}
	
	
	DLog(@"removed alertView: %@", alertView);
	[_alerts removeObject:alertView];
	DLog(@"current alerts: %@", _alerts);
}

@end
