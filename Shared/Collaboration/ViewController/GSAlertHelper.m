//
//  GSObjectAlert.m
//  Whiteboard
//
//  Created by Cong Vo on 1/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GSAlertHelper.h"


@implementation GSAlertHelper
@synthesize delegate = _delegate, callbackObject = _callbackObject, questionType = _questionType;


- (id)initWithQuestionType:(NSString *)type 
				  delegate:(id)delegate 
			callbackObject:(id)object {
	if ((self = [super init])) {
		_questionType = [type retain];
		_delegate = delegate;
		_callbackObject = [object retain];
	}
	return self;
}

- (void) dealloc {
	[_questionType release];
	[_callbackObject release];
	[super dealloc];
}

- (void)alertView:(GSAlert *)alert clickedButtonAtIndex:(NSUInteger)buttonIndex {
	[_delegate alertHelper:self didClickedButton:buttonIndex
		  forQuestionType:_questionType
		   callbackObject:_callbackObject];
}

@end
