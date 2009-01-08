/*

File: Picker.h
Abstract: 
 A view that displays both the currently advertised game name and a list of
other games
 available on the local network (discovered & displayed by
BrowserViewController).

*/

#import <UIKit/UIKit.h>
#import "BrowserViewController.h"
//#import "AppController.h"
#import "MyAdMobView.h"

#define kSliderHeight			7.0
#define kMinPointSize			2.0
#define kMaxPointSize			32.0

//@class PreviewArea;

@interface Picker : UIView {

@private
	UILabel* _gameNameLabel;
	UIView* darkenedArea;
	BrowserViewController* _bvc;
	
	//UIView* previewArea;
	
	CGFloat previewAreaY;
}

@property (nonatomic, assign) id<BrowserViewControllerDelegate> delegate;
@property (nonatomic, copy) NSString* gameName;

@property (nonatomic, retain, readwrite) BrowserViewController* bvc;
@property (nonatomic, retain, readwrite) UILabel* gameNameLabel;

- (id)initWithFrame:(CGRect)frame type:(NSString *)type;

- (void)redrawPreview;

@end
