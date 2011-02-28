//
//  PreviewArea.m
//  Whiteboard
//
//  Created by Elliot Lee on 1/7/09.
//  Copyright 2010-2011 Greengar Studios. All rights reserved.
//

#import "PreviewArea.h"
#import "WhiteboardMacAppDelegate.h"
#import "Picker.h"

@implementation PreviewArea

@synthesize widthRadius;

- (id)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
		widthRadius = kDefaultPointSize;//16.0f; // TODO: fix
    }
    return self;
}


- (void)setWidthRadius:(CGFloat)radius {
	DLog(@"setWidthRadius:");
	if (widthRadius != radius) {
		widthRadius = radius;
		[self setNeedsDisplay:YES];
	}
}


- (void)drawRect:(NSRect)rect {
	
//	if (AppDelegate.currentDrawingTool == kBrushTool) {

		//DLog(@"drawRect:%@", NSStringFromCGRect(rect));
		//[super drawRect:rect];
		
		//#define kMaxDiameter kMaxPointSize * 2
		
		CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
		CGContextSetLineWidth(context, 0.0);
		CGFloat previewOffset = kMaxPointSize - widthRadius;//(kMaxDiameter - diameter) / 2;
		CGFloat diameter = widthRadius * 2;
		
		//CGContextSetStrokeColorWithColor(context, [[NSColor whiteColor] co.CGColor);
		//CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
		CGRect currentRect = CGRectMake(previewOffset, previewOffset, diameter, diameter); // runningY
		CGContextAddEllipseInRect(context, currentRect);
		CGContextDrawPath(context, kCGPathFillStroke);
		
		CGColorRef color = [NSAppDelegate myColor];
		CGContextSetStrokeColorWithColor(context, color);
		CGContextSetFillColorWithColor(context, color);
		currentRect = CGRectMake(previewOffset, previewOffset, diameter, diameter);
		
		// Thanks to Jay's formula, we only need to draw once
		CGContextAddEllipseInRect(context, currentRect);
		CGContextDrawPath(context, kCGPathFillStroke);
		
		//[self setNeedsDisplay];
		
		// Fix a 528-byte memory leak. The matching CGColorCreate() is in AppDelegate.myColor
		CGColorRelease(color);
/*		
	} else if (AppDelegate.currentDrawingTool == kSprayTool) {
		
		// TODO: no icon yet
		
	} else if (AppDelegate.currentDrawingTool == kTextTool) {
		
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGContextTranslateCTM (context, self.bounds.size.width/2-AppDelegate.pointSize/2, self.bounds.size.height - 20);
		CGContextSelectFont(context, "ArialRoundedMTBold", AppDelegate.pointSize*2, kCGEncodingMacRoman);
		CGContextSetTextDrawingMode(context, kCGTextFill);
		
		CGColorRef color = [AppDelegate myColor];
		const CGFloat *comps = CGColorGetComponents(color);
		
		CGContextSetRGBFillColor(context, comps[0], comps[1], comps[2], 1.0f);
		CGAffineTransform xform = CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0);
		CGContextSetTextMatrix(context, xform);
		CGContextShowTextAtPoint(context, 1, 1, "T", 1);
		
	}
*/
}


//- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
//{
//	// No longer necessary to bringColorPickerToFront
//	DLog(@"test");
//	[AppDelegate cycleDrawingTool];
//	[self setNeedsDisplay];
//}

- (void)dealloc {
    [super dealloc];
}


@end
