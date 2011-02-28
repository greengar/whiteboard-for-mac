//
//  MySlider.m
//  WhiteboardMac
//
//  Created by Silvercast on 12/15/10.
//  Copyright 2010-2011 Greengar Studios. All rights reserved.
//

#import "MySlider.h"


@implementation MySlider

- (void)mouseUp:(NSEvent *)theEvent
{
	DLog(@"123123123123");
	// Call superclass mouseDown: to do even tracking
	[super mouseUp:theEvent];
	// Now do what I wanted to do after the mouse is released
}

- (void)setTouchUpTarget:(id)object action:(SEL)aSelector {
}

@end
