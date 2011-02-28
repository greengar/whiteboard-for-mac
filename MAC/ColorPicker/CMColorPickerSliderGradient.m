//
//  CMColorPickerSliderGradient.m
//  colorPickerTest
//
//  Created by Alex Restrepo on 4/25/10.
//  Copyright 2010 Colombiamug/KZLabs. All rights reserved.
//
//  This code is released under the creative commons attribution-share alike licence, meaning:
//
//	Attribution - You must attribute the work in the manner specified by the author or licensor 
//	(but not in any way that suggests that they endorse you or your use of the work).
//	In this case, simple credit somewhere in your app or documentation will suffice.
//
//	Share Alike - If you alter, transform, or build upon this work, you may distribute the resulting
//	work only under the same, similar or a compatible license.
//	Simply put, if you improve upon it, share!
//
//	http://creativecommons.org/licenses/by-sa/3.0/us/
//

#import <QuartzCore/QuartzCore.h>
#import "CMColorPickerSliderGradient.h"


@implementation CMColorPickerSliderGradient

- (id)initWithFrame:(NSRect)frame 
{
    if ((self = [super initWithFrame:frame])) 
	{
		[self setWantsLayer:YES];
		//self.userInteractionEnabled = NO;
    }
    return self;
}

- (void) dealloc
{
	[super dealloc];
}

static CGColorRef CGColorCreateFromNSColor (NSColor *color_)
{
	NSColor *deviceColor = [color_ colorUsingColorSpaceName: NSDeviceRGBColorSpace];
	
	CGFloat components[4];
	[deviceColor getComponents:components];
	 //getRed: &components[0] green: &components[1] blue: &components[2] alpha: &components[3]];
	
	return CGColorCreate (CGColorSpaceCreateDeviceRGB(), components);
}

- (void) setKeyColor:(NSColor *)c
{
	
	CAGradientLayer * backgroundLayer = [CAGradientLayer layer];
    
	CGColorRef c1 = CGColorCreateFromNSColor(c);
	CGColorRef c2 = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0);//CGColorCreateFromNSColor([NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:1.000]);
	
    NSArray *colors = [NSArray arrayWithObjects:	 
					   (id)c1,
					   (id)c2,
					   nil];
    
    CFRelease(c2);
    CFRelease(c1);
    
    [backgroundLayer setColors:colors];
 //   [backgroundLayer setCornerRadius:12.0f];
    
    CAConstraintLayoutManager *layout = [CAConstraintLayoutManager layoutManager];
    [backgroundLayer setLayoutManager:layout];
    
	[self setLayer:backgroundLayer];
}

@end
