//
//  PreviewArea.m
//  Whiteboard
//
//  Created by Elliot Lee on 1/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PreviewArea.h"


@implementation PreviewArea


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
	NSLog(@"drawRect:%@", NSStringFromCGRect(rect));
	//[super drawRect:rect];
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(context, 0.0);
	
	CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
	CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
	CGRect currentRect = CGRectMake(0, 0, kPreviewAreaSize, kPreviewAreaSize); // runningY
	CGContextAddEllipseInRect(context, currentRect);
	CGContextDrawPath(context, kCGPathFillStroke);
	
	CGColorRef color = [(AppController*)[[UIApplication sharedApplication] delegate] myColor];
	CGContextSetStrokeColorWithColor(context, color);
	CGContextSetFillColorWithColor(context, color);
	/*CGRect */currentRect = CGRectMake(0, 0, kPreviewAreaSize, kPreviewAreaSize); // runningY
	CGContextAddEllipseInRect(context, currentRect);
	CGContextDrawPath(context, kCGPathFillStroke);
	
	//[self setNeedsDisplay];
}


- (void)dealloc {
    [super dealloc];
}


@end
