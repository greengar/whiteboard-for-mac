//
//  GSCircle.h
//  Whiteboard
//
//  Created by GreenGar Studios on 1/21/10.
//  Copyright 2010-2011 Greengar Studios. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GSCircle : NSView {
	NSColor *color;
	float opacity;
}

- (void)setColor:(NSColor *)c;
//- (void)setColor:(UIColor *)c opacity:(float)o;
- (void)setOpacity:(float)o;

@end
