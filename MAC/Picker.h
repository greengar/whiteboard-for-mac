/*

File: Picker.h
Abstract: 
 A view that displays both the currently advertised game name and a list of
other games
 available on the local network (discovered & displayed by
BrowserViewController).

*/

#import "TabType.h"
#import "MySlider.h"

#define OPAQUE_HEXCOLOR(c) [NSColor colorWithCalibratedRed:((c>>16)&0xFF)/255.0 \
green:((c>>8)&0xFF)/255.0 \
blue:(c&0xFF)/255.0 \
alpha:1.0]

#define kDefaultOpacity			0.95//(1.0 / 3.0)
#define kSliderHeight			22.0//14.0//7.0
#define kMinPointSize			1.0
#define kMaxPointSize			32.0
#define kEraseButtonWidth		100.0//105.0//125.0

#define kPickerHeight 76
#define kPickerWidth  760

@interface Picker : NSImageView  {
	
	NSImageView *tabbedBackgroundLeft;
	NSImageView *selectedTab;
	NSImageView *tabbedBackgroundRight;
	
	NSMutableArray *tabArray;
	int selectedTabIndex;
	NSMutableArray *tabTouchArray;
	
	// EraserTab
	
	int tabY;
	
	BOOL isHorizontal;
}

@property (nonatomic) int selectedTabIndex;

+ (Picker *)sharedPicker;
- (id)initWithFrame:(NSRect)frame;
- (void)opacityChanged;
- (void)displayTabType:(TabType)type;
- (void)pickedColor:(NSColor*)color;
- (void)pickedBrushSize:(float)s;
- (void)pickedOpacity:(double)o;

- (void)setSelectedTab:(int)tab;	
- (void)setHorizontal:(BOOL)h;

+ (NSString *)opacityKeyForTabIndex:(int)index;
+ (NSString *)pointSizeKeyForTabIndex:(int)index;
+ (NSString *)colorKeyForTabIndex:(int)index;


@end
