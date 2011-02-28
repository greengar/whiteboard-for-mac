//
//  UIConnectionAlertView.m
//  Whiteboard
//
//  Created by Cong Vo on 1/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GSConnectionAlert.h"


@implementation GSConnectionAlert

@synthesize action = _action;
@synthesize affectedPeer = _affectedPeer;

@synthesize secondAction = _secondAction;
@synthesize secondAffectedPeer = _secondAffectedPeer;

//+ (GSConnectionAlert *)alertWithDelegate:(id)delegate 
//								   title:(NSString *)title message:(NSString *)message
//						   defaultButton:(NSString *)defaultButtonTitle otherButton:(NSString *)otherButtonTitle {
//	return (GSConnectionAlert *)[super alertWithDelegate:delegate
//												   title:title
//												 message:message
//										   defaultButton:defaultButtonTitle
//											 otherButton:otherButtonTitle];
//}


- (NSString *)actionString {
	/*
	 AlertActionNone,
	 AlertActionDecideToDisconnect,
	 AlertActionAskForConnect,
	 AlertActionDisconnected,
	 AlertActionRejected
	 */
	switch (_action) {
		case AlertActionNone:
			return @"AlertActionNone";
		case AlertActionDecideToDisconnect:
			return @"AlertActionDecideToDisconnect";
			
		case AlertActionAskForConnect:
			return @"AlertActionAskForConnect";

		case AlertActionDisconnected:
			return @"AlertActionDisconnected";
		case AlertActionRejected:
			return @"AlertActionRejected";		
		case AlertActionAccepted:
			return @"AlertActionAccepted";
		case AlertActionSwitch:
			return @"AlertActionSwitch";	
	}
	return nil;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@\n action: %@ peer: %@",[super description], [self actionString], _affectedPeer];
}


- (void)setAffectedPeer:(GSWhiteboard *)whiteboard {
	if (whiteboard.name == nil) {
#if TARGET_OS_IPHONE		
		DLog(@"setAffected Peer: nil: %@", self.title);
#endif
	}
	[_affectedPeer release];
	_affectedPeer = [whiteboard retain];
}


- (void)dealloc {
	DLog();
	[_affectedPeer release];
	[_secondAffectedPeer release];
	[super dealloc];
}

@end
