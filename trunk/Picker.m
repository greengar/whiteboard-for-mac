/*

File: Picker.m
Abstract: 
 A view that displays both the currently advertised whiteboard name and a list of
other whiteboards available on the local network (discovered & displayed by
BrowserViewController).

*/

#import "Picker.h"

#import "AppController.h"

#define kOffset 5.0
#define kTableHeight 110



/*
@interface Picker ()
@property (nonatomic, retain, readwrite) BrowserViewController* bvc;
@property (nonatomic, retain, readwrite) UILabel* gameNameLabel;
@end
 */

@implementation Picker

@synthesize bvc = _bvc;
@synthesize gameNameLabel = _gameNameLabel;

- (id)initWithFrame:(CGRect)frame type:(NSString*)type {
	if ((self = [super initWithFrame:frame])) {
		self.bvc = [[BrowserViewController alloc] initWithTitle:nil showDisclosureIndicators:NO/*YES looks like > on the right*/ showCancelButton:NO];
		[self.bvc setSearchingForServicesString:@"Searching for other whiteboards..."];
		[self.bvc searchForServicesOfType:type inDomain:@"local"];
		
		self.opaque = NO; // allows us to have brush preview. at what performance cost?
		//self.backgroundColor = [UIColor blackColor];
		
		UIImageView* img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg.png"]];
		[self addSubview:img];
		[img release];
		
		CGFloat runningY = kOffset;
		CGFloat width = self.bounds.size.width - 2 * kOffset;
		
		UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
		[label setTextAlignment:UITextAlignmentCenter];
		[label setFont:[UIFont boldSystemFontOfSize:15.0]];
		[label setTextColor:[UIColor whiteColor]];
		[label setShadowColor:[UIColor colorWithWhite:0.0 alpha:0.75]];
		[label setShadowOffset:CGSizeMake(1,1)];
		[label setBackgroundColor:[UIColor clearColor]];
		label.text = @"Waiting for others to join whiteboard:";
		label.numberOfLines = 1;
		[label sizeToFit];
		label.frame = CGRectMake(kOffset, runningY, width, label.frame.size.height);
		
		label.tag = kWaitingTag;
		
		[self addSubview:label];
		
		runningY += label.bounds.size.height;
		[label release];
		
		self.gameNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		[self.gameNameLabel setTextAlignment:UITextAlignmentCenter];
		[self.gameNameLabel setFont:[UIFont boldSystemFontOfSize:24.0]];
		[self.gameNameLabel setLineBreakMode:UILineBreakModeTailTruncation];
		[self.gameNameLabel setTextColor:[UIColor whiteColor]];
		[self.gameNameLabel setShadowColor:[UIColor colorWithWhite:0.0 alpha:0.75]];
		[self.gameNameLabel setShadowOffset:CGSizeMake(1,1)];
		[self.gameNameLabel setBackgroundColor:[UIColor clearColor]];
		[self.gameNameLabel setText:@"Default Name"];
		[self.gameNameLabel sizeToFit];
		[self.gameNameLabel setFrame:CGRectMake(kOffset, runningY, width, self.gameNameLabel.frame.size.height)];
		[self.gameNameLabel setText:@""];
		[self addSubview:self.gameNameLabel];
		
		runningY += self.gameNameLabel.bounds.size.height + kOffset * 2;
		
		label = [[UILabel alloc] initWithFrame:CGRectZero];
		[label setTextAlignment:UITextAlignmentCenter];
		[label setFont:[UIFont boldSystemFontOfSize:15.0]];
		[label setTextColor:[UIColor whiteColor]];
		[label setShadowColor:[UIColor colorWithWhite:0.0 alpha:0.75]];
		[label setShadowOffset:CGSizeMake(1,1)];
		[label setBackgroundColor:[UIColor clearColor]];
		label.text = @"Or, join a different whiteboard:";
		label.numberOfLines = 1;
		[label sizeToFit];
		label.frame = CGRectMake(kOffset, runningY, width, label.frame.size.height);
		
		label.tag = kOrJoinTag;
		
		[self addSubview:label];
		
		runningY += label.bounds.size.height + 2;
		
		[label release]; // added. should I do this or not? NO!
		
		[self.bvc.view setFrame:CGRectMake(0, runningY, self.bounds.size.width, kTableHeight)]; //self.bounds.size.height - runningY
		[self addSubview:self.bvc.view];
		
		runningY += kTableHeight;
		
		darkenedArea = [[UIView alloc] initWithFrame:CGRectZero];
		darkenedArea.frame = CGRectMake(0, runningY, self.bounds.size.width, self.bounds.size.height - runningY);
		[darkenedArea setBackgroundColor:[UIColor blackColor]];
		[darkenedArea setAlpha:/*0.0*/0.5];
		[self addSubview:darkenedArea];
		
		//[self sendSubviewToBack:darkenedArea];
		
		/* // Doesn't work - needs a different blend mode - maybe subtract?
		[darkenedArea release];
		
		darkenedArea = [[UIView alloc] initWithFrame:CGRectZero];
		darkenedArea.frame = CGRectMake(0, runningY, self.bounds.size.width, self.bounds.size.height - runningY);
		[darkenedArea setBackgroundColor:[UIColor whiteColor]];
		[darkenedArea setAlpha:0.5];
		[self addSubview:darkenedArea];		
		*/
		
		runningY += 57; //110
		
		/** Preview **/
		
		previewAreaY = runningY;
		
		//previewArea = [[PreviewArea alloc] initWithFrame:CGRectMake(kOffset, previewAreaY, kPreviewAreaSize, kPreviewAreaSize)];
		//[self addSubview:previewArea];
		
		/*
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGContextSetLineWidth(context, 2.0);
		CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
		CGContextSetFillColorWithColor(context, [UIColor redColor].CGColor);
		//CGRect currentRect = CGRectMake(0, 0, kPreviewAreaSize, kPreviewAreaSize);
		CGRect currentRect = CGRectMake(kOffset, 200, kPreviewAreaSize, kPreviewAreaSize); // runningY
		CGContextAddEllipseInRect(context, currentRect);
		CGContextDrawPath(context, kCGPathFillStroke);
		[self setNeedsDisplayInRect:currentRect];
		*/
		
		/** End Preview **/
		
		label = [[UILabel alloc] initWithFrame:CGRectZero];
		[label setTextAlignment:UITextAlignmentLeft];
		[label setFont:[UIFont boldSystemFontOfSize:15.0]];
		[label setTextColor:[UIColor whiteColor]];
		[label setShadowColor:[UIColor colorWithWhite:0.0 alpha:0.75]];
		[label setShadowOffset:CGSizeMake(1,1)];
		[label setBackgroundColor:[UIColor clearColor]];
		label.text = @"Width:";
		label.numberOfLines = 1;
		[label sizeToFit];
		
		#define kLabelIndent 5.0
		
		label.frame = CGRectMake(kOffset + kPreviewAreaSize + kLabelIndent, runningY, width - kPreviewAreaSize - kLabelIndent, label.frame.size.height);
		[self addSubview:label];
		
		runningY += label.frame.size.height;
		
		CGRect frame = CGRectMake(kOffset + kPreviewAreaSize,
								  runningY,
								  width - kPreviewAreaSize,
								  kSliderHeight);
		UISlider* pointSizeSlider = [[UISlider alloc] initWithFrame:frame];
		
		// in case the parent view draws with a custom color or gradient, use a transparent color
		pointSizeSlider.backgroundColor = [UIColor clearColor];
		pointSizeSlider.minimumValue = kMinPointSize;
		pointSizeSlider.maximumValue = kMaxPointSize;
		// Make this continuous, but spare us the network traffic!
		pointSizeSlider.continuous = NO;
		
		//UIImage *minImage = [UIImage imageNamed:@"smallSize.png"];
		//UIImage *maxImage = [UIImage imageNamed:@"bigSize.png"];
		
		//pointSizeSlider.minimumValueImage = minImage;
		//pointSizeSlider.maximumValueImage = maxImage;
		
		//[pointSizeSlider sizeToFit];
		//pointSizeSlider.frame = CGRectMake(kOffset, runningY, width, pointSizeSlider.frame.size.height);
		//pointSizeSlider.userInteractionEnabled = YES;
		[pointSizeSlider addTarget:(AppController*)[[UIApplication sharedApplication] delegate] action:@selector(changePointSize:) forControlEvents:UIControlEventValueChanged];
		//[pointSizeSlider setValue:0.5 animated:NO];
		[pointSizeSlider setValue:kMaxPointSize / 3.0];
		[(AppController*)[[UIApplication sharedApplication] delegate] changePointSize:pointSizeSlider];
		
		[self addSubview:pointSizeSlider];
		[pointSizeSlider release];
		
		//[self bringSubviewToFront:pointSizeSlider];
		
		runningY += 35;
		
		/** Create a gray UIButton **/

		UIImage *buttonBackground = [UIImage imageNamed:@"blueButton.png"];
		UIImage *buttonBackgroundPressed = [UIImage imageNamed:@"whiteButton.png"];
		
		//CGRect frame = CGRectMake(0.0, 0.0, kStdButtonWidth+200.0, kStdButtonHeight);

		#define kStdButtonHeight		40.0
		#define kEraseButtonWidth		125.0
		
		UIButton *eraseButton = [[UIButton alloc] initWithFrame:CGRectMake(kOffset + width - kEraseButtonWidth, runningY, kEraseButtonWidth/*width*/, kStdButtonHeight/*eraseButton.frame.size.height*/)];
		// or you can do this:
		//		UIButton *button = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
		//		button.frame = frame;
			
		//button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		//button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
		
		
		[eraseButton setFont:[UIFont boldSystemFontOfSize:20.0]];
		//[eraseButton setLineBreakMode:UILineBreakModeTailTruncation];
		[eraseButton setTitleShadowColor:[UIColor colorWithWhite:0.0 alpha:0.75] forState:UIControlStateNormal];
		[eraseButton setTitleShadowOffset:CGSizeMake(0,-1)];
		//reversesTitleShadowWhenHighlighted
		//eraseButton.showsTouchWhenHighlighted = YES;
		//[eraseButton setBackgroundColor:[UIColor clearColor]];
		
			
		[eraseButton setTitle:@"Start Over" forState:UIControlStateNormal];

		//[eraseButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		[eraseButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
			
		UIImage *newImage = [buttonBackground stretchableImageWithLeftCapWidth:12.0 topCapHeight:0.0];
		[eraseButton setBackgroundImage:newImage forState:UIControlStateNormal];
			
		UIImage *newPressedImage = [buttonBackgroundPressed stretchableImageWithLeftCapWidth:12.0 topCapHeight:0.0];
		[eraseButton setBackgroundImage:newPressedImage forState:UIControlStateHighlighted];
			
		//[button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
			
		// in case the parent view draws with a custom color or gradient, use a transparent color
		eraseButton.backgroundColor = [UIColor clearColor];
			
		//UIButton* eraseButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		//[eraseButton sizeToFit];

		[eraseButton addTarget:(AppController*)[[UIApplication sharedApplication] delegate] action:@selector(erase:) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:eraseButton];
		//[eraseButton release];
		
		MyAdMobView *ad = [[MyAdMobView alloc] initWithFrame:CGRectMake(0, 432 - 20/* status bar height */, 320, 48)];
		[self addSubview:ad];
		//[ad release];
	}

	return self;
}


- (void)redrawPreview {
	[self setNeedsDisplayInRect:CGRectMake(kOffset, previewAreaY, kPreviewAreaSize, kPreviewAreaSize)];
}


/*
- (void)drawRect:(CGRect)rect {
	NSLog(@"drawRect:%@", NSStringFromCGRect(rect));
	//[super drawRect:rect];

	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(context, 0.0);

	CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
	CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
	CGRect currentRect = CGRectMake(kOffset, previewAreaY, kPreviewAreaSize, kPreviewAreaSize); // runningY
	CGContextAddEllipseInRect(context, currentRect);
	CGContextDrawPath(context, kCGPathFillStroke);

	CGColorRef color = [(AppController*)[[UIApplication sharedApplication] delegate] myColor];
	CGContextSetStrokeColorWithColor(context, color);
	CGContextSetFillColorWithColor(context, color);
	currentRect = CGRectMake(kOffset, previewAreaY, kPreviewAreaSize, kPreviewAreaSize); // runningY
	CGContextAddEllipseInRect(context, currentRect);
	CGContextDrawPath(context, kCGPathFillStroke);
	
	//[self setNeedsDisplay];
}
*/


- (void)dealloc {
	// Cleanup any running resolve and free memory
	[self.bvc release];
	[self.gameNameLabel release];
	
	[super dealloc];
}


- (id<BrowserViewControllerDelegate>)delegate {
	return self.bvc.delegate;
}


- (void)setDelegate:(id<BrowserViewControllerDelegate>)delegate {
	[self.bvc setDelegate:delegate];
}

- (NSString *)gameName {
	return self.gameNameLabel.text;
}

// NOT on MainThread. Is that OK?
- (void)setGameName:(NSString *)string {
	[self.gameNameLabel setText:string];
	[string retain];
	// Moved to inStreamThread (where all access to services should be done)
	//[self.bvc performSelector:@selector(setOwnName:) onThread:[(AppController*)[[UIApplication sharedApplication] delegate] inStreamThread] withObject:string waitUntilDone:YES];
	// bvc stuff is done on the MainThread
	//[self.bvc setOwnName:string];
	
	[self.bvc performSelectorOnMainThread:@selector(setOwnName:)
						   withObject:string
						waitUntilDone:YES];
	
	[string release];
}

// Handles the start of a touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	NSLog(@"%s %@", _cmd, touches);
	if ([[touches anyObject] tapCount] == 2) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Collaborative Whiteboard"
														message:[NSString stringWithFormat:@"Version %@\n\nDeveloped by Elliot M. Lee\nelliot@gengarstudios.com", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]]
													   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
}

// Handles the continuation of a touch.
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	NSLog(@"%s %@", _cmd, touches);
}

// Handles the end of a touch event when the touch is a tap.
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	NSLog(@"%s %@", _cmd, touches);
	UITouch*			touch = [[event touchesForView:darkenedArea] anyObject];
	if (touch != nil)
		[(AppController*)[[UIApplication sharedApplication] delegate] hideTools];
}

// Handles the end of a touch event.
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	//NSLog(@"%s %@", _cmd, touches);
	// If appropriate, add code necessary to save the state of the application.
	// This application is not saving state.
}

@end
