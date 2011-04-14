/*

File: Picker.m
Abstract: 
 A view that displays both the currently advertised whiteboard name and a list of
other whiteboards available on the local network (discovered & displayed by
BrowserViewController).
 
Known issue:
 A remote client can connect to you without appearing in your list of services.
 When this occurs, the server (you) has no way to disconnect from the client
 because the client doesn't appear in the list of services.

*/

#import "Picker.h"
#import "WhiteboardMacAppDelegate.h"
#import "GSTab.h"
#import "NSColor+String.h"
#import "MainPaintingView.h"
#import "Constants.h"

//#define kScreenWidth  1024
//#define kScreenHeight 768
#define kDefaultPointSize		9.0


@interface Picker ()

- (void)setSelectedTab:(int)tab;
- (void)showEraserTab;
- (void)hideEraserTab;

@end


@implementation Picker

@synthesize selectedTabIndex;

const int tabWidth = 64;

static Picker *sharedPicker = nil;

+ (Picker *)sharedPicker
{
    if (sharedPicker == nil) {
        DLog(@"WARNING: sharedPicker == nil");
    }
    return sharedPicker;
}


- (id)initWithFrame:(NSRect)frame {
	if (sharedPicker) {
		DLog(@"WARNING: sharedPicker already exists");
		return nil;
	}
	
	if ((self = [super initWithFrame:frame])) {
		
		isHorizontal = TRUE;
		
		[self setAutoresizesSubviews:YES];
		[self setImage:[NSImage imageNamed:@"Gray-background2.gif"]];
		[self setImageScaling:NSImageScaleAxesIndependently];
		sharedPicker = self;
		
		tabTouchArray = [[NSMutableArray alloc] initWithCapacity:5]; // max 5 touches

		//
		//  Tabbed Color Picker
		//
		
		// tabY is set in -layoutForPortrait and -layoutForLandscape
		
		selectedTab = [[NSImageView alloc] init];
		[selectedTab setImage:[NSImage imageNamed:@"SelectedTab.png"]];
		[selectedTab setImageScaling:NSImageScaleAxesIndependently];

		[self addSubview:selectedTab];
		
		// technically, these tab objects should be autoreleased (or released)
		
#define kDefaultOpacityValue 0.75		
		tabArray = [[NSMutableArray alloc] initWithObjects:
						[[GSTab alloc] initWithType:MarkerTab pointSize:kDefaultPointSize opacity:kDefaultOpacityValue color:OPAQUE_HEXCOLOR(0x0000FF)],//[NSColor blueColor]],
						[[GSTab alloc] initWithType:MarkerTab pointSize:kDefaultPointSize opacity:kDefaultOpacityValue color:OPAQUE_HEXCOLOR(0xE78383)], // red
						[[GSTab alloc] initWithType:MarkerTab pointSize:kDefaultPointSize opacity:kDefaultOpacityValue color:OPAQUE_HEXCOLOR(0xFF6600)], // orange
						[[GSTab alloc] initWithType:MarkerTab pointSize:kDefaultPointSize opacity:kDefaultOpacityValue color:OPAQUE_HEXCOLOR(0xFFCC00)], // yellow (USC Gold)
						[[GSTab alloc] initWithType:MarkerTab pointSize:kDefaultPointSize opacity:kDefaultOpacityValue color:OPAQUE_HEXCOLOR(0xA4FBB8)], // gree
						[[GSTab alloc] initWithType:MarkerTab pointSize:kDefaultPointSize opacity:kDefaultOpacityValue color:OPAQUE_HEXCOLOR(0x8BB4F8)], // blue
						[[GSTab alloc] initWithType:MarkerTab pointSize:kDefaultPointSize opacity:kDefaultOpacityValue color:OPAQUE_HEXCOLOR(0xA020F0)], // purple
						[[GSTab alloc] initWithType:MarkerTab pointSize:kDefaultPointSize opacity:kDefaultOpacityValue color:OPAQUE_HEXCOLOR(0xFFC0CB)], // pink
						[[GSTab alloc] initWithType:MarkerTab pointSize:kDefaultPointSize opacity:kDefaultOpacityValue color:OPAQUE_HEXCOLOR(0xA52A2A)], // brown
						[[GSTab alloc] initEraserWithPointSize:17], //WithType:EraserTab
                    
// Hector: Remove Pan and Zoom on Picker
//						[[GSTab alloc] initZoom],
//						[[GSTab alloc] initPan],
                    
//						[[GSTab alloc] initWithType:MarkerTab pointSize:kDefaultPointSize opacity:0.995 color:OPAQUE_HEXCOLOR(0xBEBEBE)], // grey
//						hideShowButtonTab,
//						[[GSTab alloc] initWithType:MarkerTab pointSize:kDefaultPointSize opacity:0.995 color:OPAQUE_HEXCOLOR(0xCCCCCC)], // light grey
//						[[GSTab alloc] initWithType:MarkerTab pointSize:kDefaultPointSize opacity:0.995 color:OPAQUE_HEXCOLOR(0x990000)], // dark red
//						[[GSTab alloc] initWithType:MarkerTab pointSize:kDefaultPointSize opacity:0.995 color:OPAQUE_HEXCOLOR(0xFFFF00)], // yellow
//						[[GSTab alloc] initWithType:MarkerTab pointSize:kDefaultPointSize opacity:0.995 color:OPAQUE_HEXCOLOR(0x006600)], // dark green
						nil];
		
		
		for (int i=0; i<[tabArray count]; i++) {
			GSTab *tab = [tabArray objectAtIndex:i];
			NSRect f                  = tab.view.frame;
			tab.view.frame            = NSMakeRect((i * kPickerHeight) + f.origin.x, 0, f.size.width, f.size.height);
			//[tab.view setAutoresizingMask:kCALayerWidthSizable | kCALayerHeightSizable];
			[self addSubview:tab.view];

			// load tab data from persistent store
			[tab setIndex:i];
		}
		
		// initial tab selection: load from persistent store
		selectedTabIndex = 0;
		
		selectedTab.frame           = NSMakeRect(0, 0, kPickerHeight, kPickerHeight);
		
	}
	return self;
} // init

// Continuous output of the Width slider
//- (void)pointSizeSliderChanged {
//	NSSlider* slider = pointSizeSlider;
//	
//	// Set the new Width
//	previewArea.widthRadius = [slider floatValue];
//	NSAppDelegate.pointSize = [slider floatValue];
//	
//	// The effective opacity needs to be updated due to the changed Width
//	[self opacityChanged];
//}

+ (NSString *)opacityKeyForTabIndex:(int)index {
	return [NSString stringWithFormat:kOpacityKeyFormat, index];
}

+ (NSString *)toolKeyForTabIndex:(int)index {
	return [NSString stringWithFormat:kToolKeyFormat, index];
}


- (void)opacityChanged {

	CGFloat tmp[4];
	tmp[0] = [NSAppDelegate getRedValue];
	tmp[1] = [NSAppDelegate getGreenValue];
	tmp[2] = [NSAppDelegate getBlueValue];
	
	double opacity = [[tabArray objectAtIndex:selectedTabIndex] getBrushOpacity];
	tmp[3] = (CGFloat)opacity;
	
	[NSAppDelegate setTrueColorAndOpacity:tmp];
	
	[NSAppDelegate sendMyColor];

}

+ (NSString *)pointSizeKeyForTabIndex:(int)index {
	return [NSString stringWithFormat:kPointSizeKeyFormat, index];
}

- (void)setTabPointSize:(float)pointSize {
	[[tabArray objectAtIndex:selectedTabIndex] setPointSize:pointSize];
	
	// persist point size (width)
	//[NSDEF setObject:[NSNumber numberWithFloat:pointSize] forKey:[Picker pointSizeKeyForTabIndex:selectedTabIndex]];
	
}


- (void)dealloc {
	
	// Cleanup any running resolve and free memory
	//[self.gameNameLabel release];
	
	[tabArray release], tabArray = nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark Tabs

// runs on app launch (x=0):
- (void)setSelectedTabX:(float)x {
	
	NSRect frame = selectedTab.frame;
	frame.origin.x = x;
	frame.origin.y = 0;
	selectedTab.frame = frame;
}

- (void)setSelectedTabY:(float)y {
	
	NSRect frame = selectedTab.frame;
	frame.origin.x = 0;
	frame.origin.y = y;
	selectedTab.frame = frame;
}

- (void)setSelectedTab:(int)tab {
	DLog();
	
	int realTab;
	
	if (isHorizontal) {
		realTab = [tabArray count] - 1 - tab;
	}
	else {
		realTab = tab;
	}
	
	if (tab >= [tabArray count])
		return;
	
	BOOL needShowCustomColorPicker = NO;
	BOOL needUpdateCustomColorPicker = NO;
	
	if (realTab == selectedTabIndex) {
		needShowCustomColorPicker = YES;
	} else {
		
		if (NSAppDelegate.isCustomColorPickerOn) {
			// update color on custom color picker
			needUpdateCustomColorPicker = YES;
		} else {
			// do nothing, color update is already done in [tabObject setSelected]; above
		}
		
	}
	
	

	GSTab *tabObject = [tabArray objectAtIndex:realTab];
	selectedTabIndex = realTab;
	[tabObject setSelected];
	
	if (needShowCustomColorPicker) {
		[tabObject showCustomColorPicker];
	} else {
		
		if (needUpdateCustomColorPicker) {
			// update color on custom color picker
			[tabObject updateCustomColorPicker];
		} else {
			// do nothing, color update is already done in [tabObject setSelected]; above
			[tabObject setSelected];
		}

	}

	
	//selectedTabIndex = tab;
	
	int lastTabIndex;
	
	lastTabIndex = [tabArray count] - 1;
	
	if (isHorizontal) {
		if (tab == lastTabIndex) { // not necessary because the last tab is a button now
			[self setSelectedTabX:(tab * kPickerHeight + 1)];
		} else {
			[self setSelectedTabX:(tab * kPickerHeight)];
		}		
	} else {
		if (tab == lastTabIndex) { // not necessary because the last tab is a button now
			[self setSelectedTabY:(tab * kPickerHeight + 1)];
		} else {
			[self setSelectedTabY:(tab * kPickerHeight)];
		}
	}

	
}

#pragma mark -
#pragma mark Color Spectrum

+ (NSString *)colorKeyForTabIndex:(int)index {
	return [NSString stringWithFormat:kColorKeyFormat, index];
}

//+ (NSString *)colorCoordinateKeyForTabIndex:(int)index {
//	return [NSString stringWithFormat:kColorCoordinateKeyFormat, index];
//}

static CGColorRef CGColorCreateFromNSColor (NSColor *color_)
{
	NSColor *deviceColor = [color_ colorUsingColorSpaceName: NSDeviceRGBColorSpace];
	
	CGFloat components[4];
	[deviceColor getRed: &components[0] green: &components[1] blue: &components[2] alpha: &components[3]];
	
	return CGColorCreate (CGColorSpaceCreateDeviceRGB(), components);
}

- (void) pickedColor:(NSColor*)color {
	
	[[tabArray objectAtIndex:selectedTabIndex] setColor:color x:0 y:0];
	
	[NSAppDelegate setCGColor:CGColorCreateFromNSColor(color)];
	
}

- (void) pickedOpacity:(double)o {
	
	DLog(@"_____________________ %f", o);
	
	[[tabArray objectAtIndex:selectedTabIndex] setBrushOpacity:o];
	
}

- (void) pickedBrushSize:(float)s {
	
	[[tabArray objectAtIndex:selectedTabIndex] setBrushSize2:s];
//	[NSAppDelegate changePointSize:s];
}

//- (void)setColorSpectrumHidden:(BOOL)hidden {
- (void)displayTabType:(TabType)type {
	DLog();
	//BOOL hidden; // whether the colorSpectrum should be hidden
	if (type == EraserTab) {
		[self showEraserTab];
	} else {
		[self hideEraserTab];
	}
}

- (void)showEraserTab {
	DLog();
	
	//[[NSNotificationCenter defaultCenter] postNotificationName:@"kMyColorPickerValueChangedNotification" object:nil];
	
	
	/*
	//hidden = YES;
	// show options...
	
	const float iPhoneFrameHeight = 460;
//#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 30200
	const float leftMargin = IS_IPAD ?  (kOffset + kPreviewAreaSize + kLabelIndent) : 10;
//#else
//	const float leftMargin = 10;
//#endif
	const float xMargin = leftMargin * 2; // left AND right
	const float parentViewHeight = brushToolsView.frame.size.height;
	
	if (shakeLabel == nil) {
		// from iPhone:
#if GOLD
		const float yToBottomDist = iPhoneFrameHeight - 308 + 20; // SCREEN_HEIGHT
#else
		const float yToBottomDist = iPhoneFrameHeight - 308; // SCREEN_HEIGHT
#endif
		shakeLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, parentViewHeight - yToBottomDist, self.bounds.size.width - xMargin, 21)];
		shakeLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
		[shakeLabel setTextAlignment:UITextAlignmentLeft];
		shakeLabel.font = [UIFont systemFontOfSize:15.0];
		shakeLabel.textColor = [UIColor blackColor];
		// OPAQUE_HEXCOLOR(0xE4E4E4) = 0.894117647
		shakeLabel.shadowColor = [UIColor colorWithRed:0.89 green:0.89 blue:0.89 alpha:0.5];
		[shakeLabel setShadowOffset:CGSizeMake(0,1)];
		[shakeLabel setBackgroundColor:[UIColor clearColor]];
		shakeLabel.text = @"Shake Action:";
		shakeLabel.numberOfLines = 1;
		[brushToolsView addSubview:shakeLabel];
	} else {
		shakeLabel.hidden = NO;
	}
	//[label release];
	if (shakeControl == nil) {
		shakeControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Start Over", @"Undo", @"None", nil]];
		shakeControl.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
		// select current setting
		//[NSDEF integerForKey:kShakePreference]
		[shakeControl setSelectedSegmentIndex:shakeAction]; // shakeAction is set on app launch
		DLog(@"set selected SEGMENT INDEX: %d", shakeAction);
		[shakeControl addTarget:self action:@selector(shakeControlChanged:) forControlEvents:UIControlEventValueChanged];
#if GOLD
		const float yToBottomDist = iPhoneFrameHeight - 334 + 20;
#else
		const float yToBottomDist = iPhoneFrameHeight - 334;
#endif
		
		shakeControl.frame = CGRectMake(leftMargin, parentViewHeight - yToBottomDist,  300, 44);
		//ALog(@"shakeControl.frame = %@", NSStringFromCGRect(shakeControl.frame)); //{{10, 334}, {300, 44}}
		[brushToolsView addSubview:shakeControl];
	} else {
		[shakeControl setSelectedSegmentIndex:shakeAction];
		shakeControl.hidden = NO;
	}
	if (confirmationLabel == nil) {
#if GOLD
		const float yToBottomDist = iPhoneFrameHeight - (388+20) + 35;
#else
		const float yToBottomDist = iPhoneFrameHeight - (388+20);
#endif
		confirmationLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, parentViewHeight - yToBottomDist, 196, 21)];
		confirmationLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
		[confirmationLabel setTextAlignment:UITextAlignmentLeft];
		confirmationLabel.font = [UIFont systemFontOfSize:15.0];
		confirmationLabel.textColor = [UIColor blackColor];
		confirmationLabel.shadowColor = [UIColor colorWithRed:0.89 green:0.89 blue:0.89 alpha:0.5];
		[confirmationLabel setShadowOffset:CGSizeMake(0,1)];
		[confirmationLabel setBackgroundColor:[UIColor clearColor]];
		confirmationLabel.text = @"Start Over Confirmation Alert";
		confirmationLabel.numberOfLines = 1;
		[brushToolsView addSubview:confirmationLabel];
	} else {
		confirmationLabel.hidden = NO;
	}
	if (confirmationSwitch == nil) {
#if GOLD
		const float yToBottomDist = iPhoneFrameHeight - (385+20) + 35;
#else
		const float yToBottomDist = iPhoneFrameHeight - (385+20);
#endif
		const float leftPadding = 216 - 10 ;
		confirmationSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(leftMargin + leftPadding, parentViewHeight - yToBottomDist, 94, 27)];
		confirmationSwitch.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
		// select current setting
		[confirmationSwitch setOn:shouldConfirmStartOver]; // set on app launch (Picker -initWithFrame:)
		// IBAction equivalent
		[confirmationSwitch addTarget:self action:@selector(confirmationSwitchChanged:) forControlEvents:UIControlEventValueChanged];
		[brushToolsView addSubview:confirmationSwitch];
	} else {
		confirmationSwitch.hidden = NO;
	}
	
	//hidden = NO;
	//		
//		shakeLabel.hidden = YES;
//		shakeControl.hidden = YES;
//		confirmationLabel.hidden = YES;
//		confirmationSwitch.hidden = YES;
	//}
	BOOL hidden = YES;
	colorSpectrum.hidden = hidden;
	whiteArea.hidden = hidden;
	colorPickerTitleBar.hidden = hidden;*/
}

- (void)hideEraserTab {
//	BOOL hidden = NO;
//	//		
//	shakeLabel.hidden = YES;
//	shakeControl.hidden = YES;
//	confirmationLabel.hidden = YES;
//	confirmationSwitch.hidden = YES;
//	//	}
//	colorSpectrum.hidden = hidden;
//	whiteArea.hidden = hidden;
//	colorPickerTitleBar.hidden = hidden;
}

- (void)mouseMoved:(NSEvent *)theEvent {
	[super mouseMoved:theEvent];
	[[self window] orderFront:nil];
}

- (void)mouseUp:(NSEvent *)theEvent {

	[super mouseDragged:theEvent];
	
	if (isHorizontal) {
		
		tabY = 0;
		NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		const int tabHeight = kPickerHeight;
		if (location.y > tabY && location.y < tabY+tabHeight) {
			int tab = location.x / kPickerHeight;
			
			[self setSelectedTab:tab];
		}
		
	} else {
		
		int tabX = 0;
		NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		const int tabHeight = kPickerHeight;
		if (location.x > tabX && location.x < tabX+tabHeight) {
			int tab = location.y / kPickerHeight;
			
			[self setSelectedTab:tab];
		}
		
	}

}

- (void)setHorizontal:(BOOL)h {
	
	if (isHorizontal == h) {
		return;
	}
	
	isHorizontal = h;
	
	if (isHorizontal) {
		
		for (int i=[tabArray count]-1; i>=0; i--) {
			GSTab *tab = [tabArray objectAtIndex:i];
			NSRect f                  = tab.view.frame;
			tab.view.frame            = NSMakeRect((([tabArray count] - 1 - i) * kPickerHeight) + f.origin.x, 0, f.size.width, f.size.height);
		}
		[self setSelectedTabX:( ([tabArray count]-selectedTabIndex - 1) * kPickerHeight + 1)];
		
	} else {
		
		for (int i=0; i<[tabArray count]; i++) {
			GSTab *tab = [tabArray objectAtIndex:i];
			NSRect f                  = tab.view.frame;
			tab.view.frame            = NSMakeRect(0, (i * kPickerHeight) + f.origin.y, f.size.width, f.size.height);
		}
		
		[self setSelectedTabY:(selectedTabIndex * kPickerHeight + 1)];
	}

	
}

-(void)reshape {
	DLog(@"reshape %f", [self frame].size.height);
}
@end
