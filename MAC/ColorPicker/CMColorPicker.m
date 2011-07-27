//
//  CMColorWheelView.m
//  colorPickerTest
//
//  Created by Alex Restrepo on 4/23/10.
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
#import "CMColorPicker.h"
#import "CMColorPickerHSWheel.h"
#import "CMColorPickerBrightnessSlider.h"
#import "HSV.h"
#import "Picker.h"
#import "WhiteboardMacAppDelegate.h"

//@interface CMColorPicker()
//@property (nonatomic, retain) CMColorPickerHSWheel *colorWheel;
//@property (nonatomic, retain) CMColorPickerBrightnessSlider *brightnessSlider;
//@property (nonatomic, retain) NSSlider *opacitySlider;

//@end


@implementation CMColorPicker
@synthesize colorWheel;
@synthesize brightnessSlider;
@synthesize opacitySlider;
@synthesize brushSizeSlider;
@synthesize selectedColor;

static CMColorPicker *sharedColorSelector = nil;

+ (CMColorPicker *)sharedColorSelector
{
    if (sharedColorSelector == nil) {
        DLog(@"WARNING: sharedPicker == nil");
    }
    return sharedColorSelector;
}

- (void) setup
{
	// set the frame to a fixed 300 x 238
	//self.frame = NSMakeRect(self.frame.origin.x, self.frame.origin.y, 0, 0);
	//self.backgroundColor = [NSColor clearColor];
	
	// HS wheel
	CMColorPickerHSWheel *wheel = [[CMColorPickerHSWheel alloc] initAtOrigin:CGPointMake(16, 106)];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorWheelColorChanged:) name:@"kColorPickerColorChangedNotification" object:nil];
	
	[self addSubview:wheel];
	self.colorWheel = wheel;
	[wheel release];
	
	// brightness slider
	CMColorPickerBrightnessSlider *slider = [[CMColorPickerBrightnessSlider alloc] initWithFrame:NSMakeRect(240, 106, 38, 236)];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(brightnessChanged:) name:@"kColorPickerBrightnessChangedNotification" object:nil];
	[self addSubview:slider];
	self.brightnessSlider = slider;
	[slider release];
	
	NSText *brushSizeText = [[NSText alloc] initWithFrame:NSMakeRect(16, 45, 100, 44)];
	[brushSizeText setString:@"Width:"];
	[brushSizeText setEditable:NO];
	[brushSizeText setSelectable:NO];
    [brushSizeText setTextColor:[NSColor whiteColor]];
	[brushSizeText setBackgroundColor:[NSColor clearColor]];
	[self addSubview:brushSizeText];
	
	brushSizeSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(16, 52, 230, 20)];
	[brushSizeSlider setMinValue:kMinPointSize];
	[brushSizeSlider setMaxValue:kMaxPointSize];
	[brushSizeSlider setFloatValue:NSAppDelegate.pointSize];
//	[brushSizeSlider setTarget:NSAppDelegate];
//	[brushSizeSlider setAction:@selector(localBrushSizeChanged:)];
	
	[brushSizeSlider setTarget:self];
	[brushSizeSlider setAction:@selector(brushSizeChanged:)];
	
	[self addSubview:brushSizeSlider];
	
	NSText *opacityValueText = [[NSText alloc] initWithFrame:NSMakeRect(16, 5, 100, 44)];
	[opacityValueText setString:@"Opacity:"];
	[opacityValueText setEditable:NO];
	[opacityValueText setSelectable:NO];
    [opacityValueText setTextColor:[NSColor whiteColor]];     
	[opacityValueText setBackgroundColor:[NSColor clearColor]];
	[self addSubview:opacityValueText];
	
	opacitySlider = [[NSSlider alloc] initWithFrame:NSMakeRect(16, 9, 230, 20)];
	[opacitySlider setMinValue:0.0];
	[opacitySlider setMaxValue:1.0];
	[opacitySlider setFloatValue:1.0];
	[opacitySlider setTarget:self];
	[opacitySlider setAction:@selector(opacityChanged:)];
	[self addSubview:opacitySlider];
	
	self.selectedColor = [NSColor whiteColor];//[UIColor colorWithRed:0.349 green:0.613 blue:0.378 alpha:1.000];
}

- (id)initAtOrigin:(CGPoint)origin	
{
	return [self initWithFrame:NSMakeRect(origin.x, origin.y, 0, 0)];
}

- (id)initWithFrame:(NSRect)rect	
{
    if ((self = [super initWithFrame:rect])) 
	{
		sharedColorSelector = self;
        // Initialization code
		[self setup];
    }
    return self;
}

- (void)dealloc 
{
	[selectedColor release];
	[colorWheel release];
	[brightnessSlider release];
    [super dealloc];
}

- (void) awakeFromNib
{
	[self setup];
}

// function to extract rgb components from a color...
// http://arstechnica.com/apple/guides/2009/02/iphone-development-accessing-uicolor-components.ars
RGBType rgbWithUIColor(NSColor *color)
{
	CGFloat components[4];
	[color getComponents:components];
	
	CGFloat r,g,b;
	
	r = components[0];
	g = components[1];
	b = components[2];
	
	return RGBTypeMake(r, g, b);
}

- (void) setSelectedColor:(NSColor *)color animated:(BOOL)animated
{
	if (animated) 
	{
		//[NSView beginAnimations:nil context:nil];
		self.selectedColor = color;
		//[UIView commitAnimations];
	}
	else 
	{
		self.selectedColor = color;
	}	
}

- (void) setSelectedColor:(NSColor *)c
{
	[c retain];
	[selectedColor release];
	selectedColor = c;
	
	CGFloat components[4];
	[c getComponents:components];
	
	// extract rgb then hsv components
	RGBType rgb = rgbWithUIColor(c);
	HSVType hsv = RGB_to_HSV(rgb);
	
	// set the wheel and slider values.
	self.colorWheel.currentHSV = hsv;
	self.brightnessSlider.value = hsv.v;	
	[self.opacitySlider setFloatValue:components[3]];
	[colorWheel setOpacity:components[3]];	
	// background color for brightness slider
//	[self.brightnessSlider setKeyColor:[NSColor colorWithCalibratedHue:hsv.h 
//													 saturation:hsv.s
//													 brightness:1.0
//														  alpha:1.0]];

	[self.brightnessSlider setKeyColor:c];
	
	//self.colorWheel.backgroundColor = selectedColor;
	
//	DLog(@"selected color: %@", selectedColor);
//	if ([c alphaComponent]  > 0.8) {
//		DLog(@"KONG: error here");
//	}	
}

- (void)setBrushSize:(CGFloat)s {
	[brushSizeSlider setFloatValue:s];
}

- (void)setOpacity:(CGFloat)o {
	[opacitySlider setFloatValue:o];
	[colorWheel setOpacity:o];
}


- (void) colorWheelColorChanged:(CMColorPickerHSWheel *)wheel
{
	HSVType hsv = self.colorWheel.currentHSV;
	self.selectedColor = [NSColor colorWithCalibratedHue:hsv.h
									saturation:hsv.s
									brightness:self.brightnessSlider.value
										 alpha:[opacitySlider floatValue]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"kMyColorPickerValueChangedNotification" object:self];
}

- (void) brightnessChanged:(CMColorPickerBrightnessSlider *)slider
{
	HSVType hsv = self.colorWheel.currentHSV;
	
	self.selectedColor = [NSColor colorWithCalibratedHue:hsv.h
									saturation:hsv.s
									brightness:self.brightnessSlider.value
										 alpha:[opacitySlider floatValue]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"kMyColorPickerValueChangedNotification" object:self];
}

- (void) brushSizeChanged:(id)slider {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"kMyColorPickerValueChangedNotification" object:self];
}

- (void) opacityChanged:(id)slider
{
	HSVType hsv = self.colorWheel.currentHSV;
	float opacityValue = [opacitySlider floatValue];//(1.0 - powf(1.0 - [opacitySlider floatValue], NSAppDelegate.pointSize*2));
		
	self.selectedColor = [NSColor colorWithCalibratedHue:hsv.h
											  saturation:hsv.s
											  brightness:self.brightnessSlider.value
												   alpha:opacityValue];
	
	[colorWheel setOpacity:opacityValue];	
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"kMyColorPickerValueChangedNotification" object:self];
}

// fix the frame to 300 x 238 px
//- (void) setFrame:(CGRect)rect
//{
//	super.frame = CGRectMake(rect.origin.x, rect.origin.y, 300, 238);
//}

@end
