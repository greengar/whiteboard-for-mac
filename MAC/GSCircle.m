//
//  GSCircle.m
//  Whiteboard
//
//  Created by GreenGar Studios on 1/21/10.
//  Copyright 2010-2011 Greengar Studios. All rights reserved.
//

#import "GSCircle.h"
//#import APP_DELEGATE


@implementation GSCircle

static CGColorRef CGColorCreateFromNSColor (NSColor *color_)
{
	NSColor *deviceColor = [color_ colorUsingColorSpaceName: NSDeviceRGBColorSpace];
	
	CGFloat components[4];
	[deviceColor getRed: &components[0] green: &components[1] blue: &components[2] alpha: &components[3]];
	
	return CGColorCreate (CGColorSpaceCreateDeviceRGB(), components);
}

- (id)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
//		self.opaque = NO;
		//self.clipsToBounds = NO;
		opacity = 1.0f;
    }
    return self;
}

- (void)setColor:(NSColor *)c {
	if (![color isEqual:c]) {
		[color release];
		color = [c retain];
		[self setNeedsDisplay:YES];
	}
}

- (void)setOpacity:(float)o {
	if (opacity != o) {
		opacity = o;
		[self setNeedsDisplay:YES];
	}
}


// Assumes color is in UIDeviceRGBColorSpace
// Assumes opacity is effective opacity
// Return value has a retain count of 1, and must be released by the caller
- (CGColorRef)CGColorFromUIColor:(NSColor *)color_ opacity:(float)o {
	//const CGFloat *c = CGColorGetComponents(color_.CGColor);
	CGFloat previewComponents[4];
	[color getComponents:previewComponents];
	previewComponents[3] = o; //effectiveOpacityFromOpacity;
	CGColorRef newColor = CGColorCreate(CGColorSpaceCreateDeviceRGB(), previewComponents);
	return newColor;
}

- (CGColorRef)CGColorFromNSColor:(NSColor *)color_ {
	//const CGFloat *c = CGColorGetComponents(color_.CGColor);
	CGFloat previewComponents[4];
	[color getComponents:previewComponents];
	CGColorRef newColor = CGColorCreate(CGColorSpaceCreateDeviceRGB(), previewComponents);
	return newColor;
}

- (void)drawRect:(NSRect)rect {
    // Drawing code	
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	//CGContextSetBlendMode(context, kCGBlendModeNormal);
		
	CGContextSetLineWidth(context, 0.0f);
	CGFloat diameter = 40.0f;
	//CGContextSetStrokeColorWithColor(context, [[UIColor whiteColor] CGColor]);
	
	CGContextSetFillColorWithColor(context, CGColorCreateFromNSColor([NSColor whiteColor]));
	CGRect currentRect = CGRectMake(self.bounds.size.width/2 - diameter/2 - 1, self.bounds.size.height/2 - diameter/2 - 1, diameter, diameter);
	
	CGContextAddEllipseInRect(context, currentRect);
	CGContextDrawPath(context, kCGPathFill);
	
//	CGContextSetFillColorWithColor(context, CGColorCreateFromNSColor([NSColor whiteColor]));
//	currentRect = CGRectMake(1, 1, diameter, diameter);
//	CGContextAddEllipseInRect(context, currentRect);
//	CGContextDrawPath(context, kCGPathFill);
	
	//CGColorRef color = CGColorCreate(CGColorSpaceCreateDeviceRGB(), <#const CGFloat [] components#>)
	CGColorRef colorRef = [self CGColorFromUIColor:color opacity:opacity]; //color.CGColor; //[[UIColor redColor] CGColor];
	//CGContextSetStrokeColorWithColor(context, color);
	CGContextSetFillColorWithColor(context, colorRef);
	currentRect = CGRectMake(self.bounds.size.width/2 - diameter/2, self.bounds.size.height/2 - diameter/2, 38, 38);
	CGContextAddEllipseInRect(context, currentRect);
	CGContextDrawPath(context, kCGPathFillStroke);
	
	CGColorRelease(colorRef);
}


- (void)dealloc {
    [super dealloc];
}


@end
