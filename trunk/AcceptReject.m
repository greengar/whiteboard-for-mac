//
//  AcceptReject.m
//  Whiteboard
//
//  Created by Elliot Lee on 12/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AcceptReject.h"
#import "AppController.h"

@implementation AcceptReject

@synthesize name;

- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	//assert(acceptRejectAlertView == alertView);
	
	// buttonIndex == 0 : Don't Allow (reject)
	// buttonIndex == 1 : OK (accept)
	// buttonIndex == 2 : disconnected
	NSLog(@"alertView:%@ clickedButtonAtIndex:%d", alertView, buttonIndex);
	
	//[acceptRejectAlertView release];
	//acceptRejectAlertView = nil;
	
	//[alertView release];
	//alertView = nil;
		
	if (buttonIndex == 2) {
		return;
	}
	
	[(AppController*)[[UIApplication sharedApplication] delegate] acceptPendingRequest:((buttonIndex == 0) ? NO : YES) withName:name];
}


/*
- (void)setName:(NSString*)newName
{
	name = [newName copy];//[NSString stringWithString:newName];
}
 */


@end
