//
//  GSTab.m
//  Whiteboard
//
//  Created by GreenGar Studios on 1/21/10.
//  Copyright 2010-2011 Greengar Studios. All rights reserved.
//

#import "GSTab.h"
#import "GSCircle.h"
#import "WhiteboardMacAppDelegate.h"
#import "Picker.h"
#import "NSColor+String.h"
#import "Constants.h"
//#import "NSCursor+CustomCursors.h"

#define kTabSelectedNotification @"Tab Selected Notification"

static CGColorRef CGColorCreateFromNSColor (NSColor *color_)
{
	NSColor *deviceColor = [color_ colorUsingColorSpaceName: NSDeviceRGBColorSpace];
	
	CGFloat components[4];
	[deviceColor getComponents:components];
	
	return CGColorCreate (CGColorSpaceCreateDeviceRGB(), components);
}

@implementation GSTab

@synthesize color = color_;
@synthesize drawingToolMode;


// NOTE: This is the circle displayed on the tab itself (not on the colorSpectrum!)
- (GSCircle *)circle {
//	if (self.view
	// if we wanted to be defensive, we could make sure self.view is a member of the GSCircle class, and return nil if it's not
	// (and print a warning, and perhaps log a subBeacon)
	return (GSCircle *)self.view;
}

- (id)initEraserWithPointSize:(float)w {
	return [self initWithType:EraserTab pointSize:w opacity:1.0 color:nil]; // color is set in -setSelected
}

- (id)initPan {
	return [self initWithType:PanTab pointSize:0 opacity:0.0 color:nil];
}

- (id)initZoom {
	return [self initWithType:ZoomTab pointSize:0 opacity:0.0 color:nil];
}

- (id)initWithType:(TabType)t pointSize:(float)w opacity:(float)o color:(NSColor *)c {
	if ((self = [super init])) {
		
		x_ = -50; // put x and y
		y_ = -50; // off-screen
		
		type = t;
		pointSize = w;
		opacity = o;
		self.color = c;
		
		if (t == MarkerTab) {
			
			//DLog(@"tab color: %@", self.color);
			[[self circle] setColor:self.color];
			[[self circle] setOpacity:o];
			
			drawingToolMode = kBrushTool;
			
		} else if (t == EraserTab) {
			//[self view];
		} else {
			DLog(@"WARNING: Unsupported tab type initialized");
		}
	}
	return self;
}

- (void)setDrawingToolMode:(int)mode {
	drawingToolMode = mode;
}

- (void)setColor:(NSColor *)c x:(float)x y:(float)y {
	//DLog(@"x=%f y=%f", x, y);
	if ([[self circle] respondsToSelector:@selector(setColor:)]) {
		self.color = c;
		[[self circle] setColor:self.color]; //opacity:opacity
		x_ = x;
		y_ = y;
	} else {
		// this occurs when the user updates from a previous version of Whiteboard,
		// in which the Undo tab used to be another brush tab.
		// (Tab colors are persisted across app launches.)
		DLog(@"WARNING: circle doesn't respond to -setColor:");
	}
}

- (void)setOpacity:(float)o {
	if (type == MarkerTab) {
		opacity = o;
		[[self circle] setOpacity:(1 - sqrtf(1-opacity))]; //setColor:self.color
	}
}

- (double)getBrushOpacity {
	return opacity;
}


- (void)setBrushOpacity:(double)o {
	opacity = o;
}

- (void)setBrushSize2:(float)s {
	pointSize = s;
}

- (NSView *)view {
	// NOTE: Tab doesn't register to be notified when it's deselected (when some other tab is selected) until -view is called!
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabSelectedNotification:) name:kTabSelectedNotification object:nil];
	if (type == MarkerTab) {
		if (!circle) {
			
			circle = [[GSCircle alloc] initWithFrame:NSMakeRect(0, 0, 76, 76)];
			
		}
		return circle;
	} else if (type == EraserTab) {
		if (!imageView) {
			imageView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 76, 76)];
			
			NSImageView* imgView = [[NSImageView alloc] initWithFrame:NSMakeRect(16, 16, 40, 40)];
			[imgView setImageScaling:NSImageScaleProportionallyUpOrDown];
			[imgView setImage:[NSImage imageNamed:@"eraser_v3-icon.png"]]; // 24x24 image, 27x21 actually // +2 in x, +3 in y

			[imageView addSubview:imgView];
		}
		return imageView;
	} else if (type == PanTab) {
		if (!imageView) {
			imageView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 76, 76)];
			
			NSImageView* imgView = [[NSImageView alloc] initWithFrame:NSMakeRect(16, 16, 40, 40)];
			[imgView setImageScaling:NSImageScaleProportionallyUpOrDown];
			[imgView setImage:[NSImage imageNamed:@"Pan_Icon.png"]]; // 24x24 image, 27x21 actually // +2 in x, +3 in y
			
			[imageView addSubview:imgView];
		}
		return imageView;
	} else if (type == ZoomTab) {
		if (!imageView) {
			imageView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 76, 76)];
			
			NSImageView* imgView = [[NSImageView alloc] initWithFrame:NSMakeRect(16, 16, 40, 40)];
			[imgView setImageScaling:NSImageScaleProportionallyUpOrDown];
			[imgView setImage:[NSImage imageNamed:@"Zoom_Icon.png"]]; // 24x24 image, 27x21 actually // +2 in x, +3 in y
			
			[imageView addSubview:imgView];
		}
		return imageView;
	}
	return nil;
}

- (void)setSelected {
	DLog();
	
	if (!isSelected) {
		DLog();
		isSelected = YES;
		self.view.frame = NSMakeRect(self.view.frame.origin.x, self.view.frame.origin.y-1, self.view.frame.size.width, self.view.frame.size.height);
		
		if (type == MarkerTab) {
			// Enable Normal Mode
			[NSAppDelegate setMode:normalMode];
			[NSAppDelegate setCGColor:CGColorCreateFromNSColor(self.color)];
			
			[NSAppDelegate changePointSize:pointSize]; // also sends opacity
			
		} else if (type == EraserTab) {
			// Enable Normal Mode
			[NSAppDelegate setMode:normalMode];
			//NSColor * w = [NSColor colorWithCalibratedHue:0 saturation:0 brightness:1 alpha:1]; // white
			//NSColor * w = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0];
			[NSAppDelegate setWhiteCGColor]; 
			
			[NSAppDelegate changePointSize:pointSize]; // also sends opacity
			
		} else if (type == PanTab) {
			// Enable Pan Mode
			[NSAppDelegate setMode:panMode];
		} else if (type == ZoomTab) {
			// Enable Zoom Mode
			[NSAppDelegate setMode:zoomMode];
		} else {
			DLog(@"WARNING: Unsupported tab type");
		}
		[[Picker sharedPicker] displayTabType:type]; // important!
		[[NSNotificationCenter defaultCenter] postNotificationName:kTabSelectedNotification object:self];
	}
}

- (void)showCustomColorPicker {
	if (type == MarkerTab) {
		
		[NSAppDelegate showColorPicker:self.color];
		[self updateCustomColorPicker];
		
	} else if (type == EraserTab) {
		//NSColor * w = [NSColor colorWithCalibratedHue:0 saturation:0 brightness:1 alpha:1]; // white
		NSColor * w = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0];
		[NSAppDelegate showColorPicker:w];
		
		[self updateCustomColorPicker];
	}
}

- (void)updateCustomColorPicker {
	if (type == MarkerTab) {
		
		[[CMColorPicker sharedColorSelector] setSelectedColor:self.color animated:YES];
		[[CMColorPicker sharedColorSelector] setBrushSize:pointSize]; // doesn't cause any control events to fire
		[[CMColorPicker sharedColorSelector] setOpacity:opacity]; // doesn't cause any control events to fire
		
		
		
		[[CMColorPicker sharedColorSelector].colorWheel setEnabled:YES];
		[[CMColorPicker sharedColorSelector].brightnessSlider setEnabled:YES];
		[[CMColorPicker sharedColorSelector].opacitySlider setEnabled:YES]; // previously-selected tab may be EraserTab
		
	} else if (type == EraserTab) {
//		NSColor * w = [NSColor colorWithCalibratedHue:0 saturation:0 brightness:1 alpha:1]; // white
		NSColor * w = [NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
		[[CMColorPicker sharedColorSelector] setSelectedColor:w animated:YES];
		[[CMColorPicker sharedColorSelector].colorWheel setEnabled:NO];
		[[CMColorPicker sharedColorSelector].brightnessSlider setEnabled:NO];
		[[CMColorPicker sharedColorSelector].opacitySlider setEnabled:NO]; // prevent opacity from being changed from 1
		
	}
}

- (void)tabSelectedNotification:(NSNotification *)notification {
	if ([notification object] != self && isSelected) {
		// deselect tab
		isSelected = NO;
		self.view.frame = NSMakeRect(self.view.frame.origin.x, self.view.frame.origin.y+1, self.view.frame.size.width, self.view.frame.size.height);
	}
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[circle release], circle = nil;		  // t == MarkerType
	[imageView release], imageView = nil; // t == EraserType
	[super dealloc];
}

// load data from persistent store
- (void)setIndex:(int)index {
	/*NSNumber *number = [NSDEF objectForKey:[Picker pointSizeKeyForTabIndex:index]];
	if (number) {
		[self setPointSize:[number floatValue]];
	}
	number = [NSDEF objectForKey:[Picker opacityKeyForTabIndex:index]];
	if (number) {
		[self setOpacity:[number floatValue]];
	}
	NSString *colorString = [NSDEF objectForKey:[Picker colorKeyForTabIndex:index]];
	if (colorString) {
		float x, y;
		UIColor *color = [UIColor colorFromString:colorString x:&x y:&y];
		if (color) {
			[self setColor:color x:x y:y];
		}
	}*/
}

@end
