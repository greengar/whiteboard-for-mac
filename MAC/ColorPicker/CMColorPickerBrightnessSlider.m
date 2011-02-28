//
//  CMColorPickerBrightnessSlider.m
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

#import "CMColorPickerBrightnessSlider.h"
#import "CMColorPickerSliderGradient.h"

@interface CMColorPickerBrightnessSlider()
@property (nonatomic, retain) CMColorPickerSliderGradient *gradient;
@property (nonatomic, retain) NSImageView *sliderKnobView;
@end


@implementation CMColorPickerBrightnessSlider
@synthesize gradient;
@synthesize sliderKnobView;

- (id)initWithFrame:(NSRect)frame 
{
    if ((self = [super initWithFrame:frame])) 
	{		
        // Initialization code
		
		// gradient view
		CMColorPickerSliderGradient *background = [[CMColorPickerSliderGradient alloc] initWithFrame:NSMakeRect(6,
																												18,
																												26,
																												frame.size.height - 36)];		
		[self addSubview:background];
		self.gradient = background;
		[background release];		
		
		// knob view
		NSImageView *knob = [[NSImageView alloc] initWithFrame:NSMakeRect(-10, 0, 35, 35)];
		[knob setImage:[NSImage imageNamed:@"colorPickerKnob.png"]];
		
		[background addSubview:knob positioned:NSWindowAbove relativeTo:nil];	
		
		self.sliderKnobView = knob;
		[knob release];
		
//		self.backgroundColor = [NSColor clearColor];
//		self.userInteractionEnabled = YES;
		self.value = 0.0;
		[self setKeyColor:[NSColor whiteColor]];
    }
    return self;
}

- (void)dealloc 
{
	[gradient release];
	[sliderKnobView release];
    [super dealloc];
}

- (void) setKeyColor:(NSColor *)c
{
	[gradient setKeyColor:c];
}

- (CGFloat) value
{
	return value;
}

- (void) setValue:(CGFloat)val
{	
	value = MAX(MIN(val, 1.0), 0.0); //cap value to [0.0 - 1.0]
	
	// update UI
	//CGFloat x = roundf((self.bounds.size.width - self.sliderKnobView.bounds.size.width) * 0.5) + self.sliderKnobView.bounds.size.width * 0.5;
	CGFloat x = 12;
	CGFloat y = roundf((1 - value) * (gradient.frame.size.height - 40) - self.sliderKnobView.bounds.size.height * 0.5) + self.sliderKnobView.bounds.size.height * 0.5;
	NSSize s = self.sliderKnobView.bounds.size;
	[self.sliderKnobView setFrameOrigin:NSMakePoint(x - s.width/2, y + 20 - s.height/2)];
}

- (void) mapPointToBrightness:(NSPoint)point
{
	// map a point on the slider to a value
	CGFloat val = 1 - ((point.y - 20) / (self.frame.size.height - 40)); 
	self.value = val;
	
	// raise event
	[[NSNotificationCenter defaultCenter] postNotificationName:@"kColorPickerBrightnessChangedNotification" object:self];
}

- (void)mouseDown:(NSEvent *)theEvent {
	if (![self isEnabled]) {
		return;
	}
	
	[self mapPointToBrightness:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
	[super mouseDown:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent {
	if (![self isEnabled]) {
		return;
	}
	
	[self mapPointToBrightness:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
	[super mouseDragged:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent {
	if (![self isEnabled]) {
		return;
	}
	
	//[self continueTrackingWithTouch:touch withEvent:event];
}

@end
