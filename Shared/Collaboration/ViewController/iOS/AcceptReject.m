//
//  AcceptReject.m
//  Whiteboard
//
//  Created by Elliot Lee on 12/30/08.
//  Copyright 2008 GreenGar Studios <http://www.greengar.com/>. All rights reserved.
//

#import "AcceptReject.h"
#import "AppController.h"
#import "GSConnectionController.h"

@implementation AcceptReject

@synthesize name;
@synthesize delegate = _delegate, questionType = _questionType, callbackObj = _callbackObj;

- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	//alertView:<UIAlertView: 0x148060; frame = (242 454; 284 137); opaque = NO; layer = <CALayer: 0x19e8c0>> clickedButtonAtIndex:1
	
	
	//assert(acceptRejectAlertView == alertView);
	
	// buttonIndex == 0 : Don't Allow (reject)
	// buttonIndex == 1 : OK (accept)
	// buttonIndex == 2 : disconnected
	DLog(@"alertView:%@ clickedButtonAtIndex:%d", alertView, buttonIndex);
	
	//[acceptRejectAlertView release];
	//acceptRejectAlertView = nil;
	
	//[alertView release];
	//alertView = nil;
		
	if (self.delegate == nil) { // old usage for AcceptReject
		if (buttonIndex == 2) {
			return;
		}
		#pragma mark TODO: remove this relationship
//		[[(AppController*)[[UIApplication sharedApplication] delegate] connection] acceptPendingRequest:((buttonIndex == 0) ? NO : YES) withName:name];	
		
	} else { // a better way to use AcceptReject
		// an object carrier for YES/NO question with delegate and callback
		[self.delegate acceptReject:self
						   didClickedButton:buttonIndex
							forQuestionType:self.questionType
					 callbackObject:self.callbackObj];
	}
}

/*
- (void)setName:(NSString*)newName
{
	name = [newName copy];//[NSString stringWithString:newName];
}
 */

- (id)initWithQuestionType:(NSString *)type 
				  delegate:(id)delegate 
					object:(id)callbackObj {
	if ((self = [super init])) {
		_questionType = [type retain];
		_delegate = delegate;
		_callbackObj = [callbackObj retain];
	}
	return self;
}

- (void) dealloc {
	[name release];
	[_questionType release];
	[_callbackObj release];
	[super dealloc];
}

@end
