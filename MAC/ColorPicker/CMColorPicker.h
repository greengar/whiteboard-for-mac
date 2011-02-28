//
//  CMColorWheelView.h
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

#import <Cocoa/Cocoa.h>

@class CMColorPickerHSWheel;
@class CMColorPickerBrightnessSlider;

@interface CMColorPicker : NSControl
{
	CMColorPickerHSWheel			*colorWheel;
	CMColorPickerBrightnessSlider	*brightnessSlider;
	NSSlider						*brushSizeSlider;
	NSSlider						*opacitySlider;
	NSColor	*selectedColor;
}

@property (nonatomic, retain) NSColor *selectedColor;

@property (nonatomic, retain) CMColorPickerHSWheel			*colorWheel;
@property (nonatomic, retain) CMColorPickerBrightnessSlider	*brightnessSlider;
@property (nonatomic, retain) NSSlider						*brushSizeSlider;
@property (nonatomic, retain) NSSlider						*opacitySlider;


+ (CMColorPicker *)sharedColorSelector;

- (id)initAtOrigin:(CGPoint)origin;
- (void)setSelectedColor:(NSColor *)color animated:(BOOL)animated;
- (void)setBrushSize:(CGFloat)s;
- (void)setOpacity:(CGFloat)o;
@end
