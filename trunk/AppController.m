/*

File: AppController.m
Abstract: UIApplication's delegate class, the central controller of the
application.

*/

#import "AppController.h"
#import "Picker.h"

//CONSTANTS:

// Number of rectangles on one side
#define kNumPads			3

// The Bonjour application protocol, which must:
// 1) be no longer than 14 characters
// 2) contain only lower-case letters, digits, and hyphens
// 3) begin and end with lower-case letter or digit
// It should also be descriptive and human-readable
// See the following for more information:
// http://developer.apple.com/networking/bonjour/faq.html
#define kGameIdentifier		@"whiteboard"

// From GLPaint

#define kPaletteHeight					40//30
#define kPaletteSize				    5
//#define kAccelerometerFrequency			25 //Hz
//#define kFilteringFactor				0.1
#define kMinEraseInterval				0.5
//#define kEraseAccelerationThreshold		2.0

// Padding for margins
#define kLeftMargin				5.0//10.0//0.0
#define kTopMargin				(10.0 + 48.0)//AdMobView height
#define kRightMargin			5.0//10.0//0.0

#define segmentedControlTag		2//1 is taken by AdMobView

#define kRejectSilently			3

//FUNCTIONS:
/*
 HSL2RGB Converts hue, saturation, luminance values to the equivalent red, green and blue values.
 For details on this conversion, see Fundamentals of Interactive Computer Graphics by Foley and van Dam (1982, Addison and Wesley)
 You can also find HSL to RGB conversion algorithms by searching the Internet.
 See also http://en.wikipedia.org/wiki/HSV_color_space for a theoretical explanation
 */
static void HSL2RGB(float h, float s, float l, float* outR, float* outG, float* outB)
{
	float			temp1,
	temp2;
	float			temp[3];
	int				i;
	
	// Check for saturation. If there isn't any just return the luminance value for each, which results in gray.
	if(s == 0.0) {
		if(outR)
			*outR = l;
		if(outG)
			*outG = l;
		if(outB)
			*outB = l;
		return;
	}
	
	// Test for luminance and compute temporary values based on luminance and saturation 
	if(l < 0.5)
		temp2 = l * (1.0 + s);
	else
		temp2 = l + s - l * s;
	temp1 = 2.0 * l - temp2;
	
	// Compute intermediate values based on hue
	temp[0] = h + 1.0 / 3.0;
	temp[1] = h;
	temp[2] = h - 1.0 / 3.0;
	
	for(i = 0; i < 3; ++i) {
		
		// Adjust the range
		if(temp[i] < 0.0)
			temp[i] += 1.0;
		if(temp[i] > 1.0)
			temp[i] -= 1.0;
		
		
		if(6.0 * temp[i] < 1.0)
			temp[i] = temp1 + (temp2 - temp1) * 6.0 * temp[i];
		else {
			if(2.0 * temp[i] < 1.0)
				temp[i] = temp2;
			else {
				if(3.0 * temp[i] < 2.0)
					temp[i] = temp1 + (temp2 - temp1) * ((2.0 / 3.0) - temp[i]) * 6.0;
				else
					temp[i] = temp1;
			}
		}
	}
	
	// Assign temporary values to R, G, B
	if(outR)
		*outR = temp[0];
	if(outG)
		*outG = temp[1];
	if(outB)
		*outB = temp[2];
}

//INTERFACES:

@interface AppController ()
- (void) create:(id)useless;
//- (void) setup;
- (void) presentPicker:(NSString*)name;
//- (void) renderLineWithRect:(NSString*)strRect;
- (void) presentTools;
//- (void) erase:(id)sender;
- (void) destroyPicker;
@end

//CLASS IMPLEMENTATIONS:

@implementation AppController

@synthesize receivingRemoteColor;
@synthesize usingRemoteColor;
//@synthesize pointSize;
@synthesize receivingRemotePointSize;
@synthesize usingRemotePointSize;
@synthesize receivingRemoteName;

@synthesize acceptReject = _acceptReject;

@synthesize inStreamThread;

/*
- (BOOL) usingRemoteColor { NSLog(@"usingRemoteColor = %d", usingRemoteColor); return usingRemoteColor; }
- (void) setUsingRemoteColor:(BOOL)newValue { NSLog(@"setting usingRemoteColor to %d", newValue); usingRemoteColor = newValue; }
*/
//@synthesize colorLock;

- (void) _showAlert:(NSString*)title
{
	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:@"Check your networking configuration." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

- (void) applicationDidFinishLaunching:(UIApplication*)application
{
	/* // WiTap interface
	CGRect					rect;
	UIView*					view;
	NSUInteger				x,
							y;
	
	//Create a full-screen window
	_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	[_window setBackgroundColor:[UIColor darkGrayColor]];
	
	//Create the tap views and add them to the view controller's view
	rect = [[UIScreen mainScreen] applicationFrame];
	for(y = 0; y < kNumPads; ++y) {
		for(x = 0; x < kNumPads; ++x) {
			view = [[TapView alloc] initWithFrame:CGRectMake(rect.origin.x + x * rect.size.width / (float)kNumPads, rect.origin.y + y * rect.size.height / (float)kNumPads, rect.size.width / (float)kNumPads, rect.size.height / (float)kNumPads)];
			[view setMultipleTouchEnabled:NO];
			[view setBackgroundColor:[UIColor colorWithHue:((y * kNumPads + x) / (float)(kNumPads * kNumPads)) saturation:0.75 brightness:0.75 alpha:1.0]];
			[view setTag:(y * kNumPads + x + 1)];
			[_window addSubview:view];
			[view release];
		}
	}
	
	//Show the window
	[_window makeKeyAndVisible];
	*/
	
	CGRect					rect = [[UIScreen mainScreen] applicationFrame];
	//CGFloat					components[3];
	
	//Create a full-screen window
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	// 1 of 2 places to set the background color
	[window setBackgroundColor:[UIColor whiteColor]]; //blackColor
	
	//Create the OpenGL drawing view and add it to the window
	//NSLog(@"CGRectMake(%d, %d, %d, %d)", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
	drawingView = [[PaintingView alloc] initWithFrame:CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)]; // - kPaletteHeight 
	[window addSubview:drawingView];
	
	// Create a segmented control so that the user can choose the brush color.
	UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:
											[NSArray arrayWithObjects:
											 [UIImage imageNamed:@"Black.png"],
											 [UIImage imageNamed:@"Red.png"],
											 [UIImage imageNamed:@"Yellow.png"],
											 [UIImage imageNamed:@"Green.png"],
											 [UIImage imageNamed:@"Blue.png"],
											 [UIImage imageNamed:@"Purple.png"],
											 [UIImage imageNamed:@"WhiteEraser.png"],
											 nil]];
	
	// Compute a rectangle that is positioned correctly for the segmented control you'll use as a brush color palette
	///CGRect frame = CGRectMake(rect.origin.x + kLeftMargin, rect.size.height - kPaletteHeight - kTopMargin, rect.size.width - (kLeftMargin + kRightMargin), kPaletteHeight);
	
	CGRect frame = CGRectMake(rect.origin.x + kLeftMargin, rect.size.height - kPaletteHeight - kTopMargin, rect.size.width - (kLeftMargin + kRightMargin), kPaletteHeight);
	
	segmentedControl.frame = frame;
	// When the user chooses a color, the method changeBrushColor: is called.
	[segmentedControl addTarget:self action:@selector(changeBrushColor:) forControlEvents:UIControlEventValueChanged];
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBordered;//UISegmentedControlStylePlain;//UISegmentedControlStyleBar;
	// Make sure the color of the color complements the black background
	segmentedControl.tintColor = [UIColor darkGrayColor];
	// Set the third color (index values start at 0)
	segmentedControl.selectedSegmentIndex = 0; // this causes changeBrushColor: to be called!
	
	segmentedControl.tag = segmentedControlTag;
	
	// Add the control to the window
	[window addSubview:segmentedControl];
	// Now that the control is added, you can release it
	[segmentedControl release];
	
	// Already called above /////////////////
	
	// Create colorLock
	//colorLock = [[NSLock alloc] init];
    // Define a starting color 
	components[3] = kBrushOpacity; // default opacity
	//HSL2RGB((CGFloat) 2.0 / (CGFloat)kPaletteSize, kSaturation, kLuminosity, &components[0], &components[1], &components[2]);
	// Set the color using OpenGL
	//if ([colorLock tryLock]) {
		//glColor4f(components[0], components[1], components[2], kBrushOpacity);
		usingRemoteColor = NO;
		//[colorLock unlock];
	//} else {
		//NSLog(@"Warning! locking colorLock failed, color not set");
	//}
	receivingRemoteColor = NO;
	
	usingRemotePointSize = NO;
	receivingRemotePointSize = NO;
	receivingRemoteName = NO;
	
	pendingJoinRequest = NO;
	initializedWithPeers = YES; // No peers yet
	needToSendName = NO;
	
	writeBuffer = @"";
	
	firstHide = YES;
	
	//Show the window
	[window makeKeyAndVisible];	
	// Look in the Info.plist file and you'll see the status bar is hidden
	// Set the style to black so it matches the background of the application
	[application setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:NO];
	// Now show the status bar, but animate to the style.
	[application setStatusBarHidden:NO animated:YES];
	
	//Configure and enable the accelerometer
	//[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / kAccelerometerFrequency)];
	//[[UIAccelerometer sharedAccelerometer] setDelegate:self];
	
	//Load the sounds
	NSBundle *mainBundle = [NSBundle mainBundle];	
	erasingSound = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"Erase" ofType:@"caf"]];
	selectSound =  [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"Select" ofType:@"caf"]];
	
	// End GLPaint
	
	// Create namesForStreams NSDictionary
	namesForStreams = [[NSMutableDictionary dictionaryWithCapacity:2] retain];
	
	//[self create];
	inStreamThread = [[NSThread alloc] initWithTarget:self
											 selector:@selector(create:)
											   object:nil];
	[inStreamThread start];
	// Advertise a new game and discover other available games
	//[self setup];
	[self presentPicker:nil];
}

- (void) dealloc
{
	NSInputStream* _inStream;
	for(_inStream in _inStreams) {
		[_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		//[_inStream release];
		[_inStreams removeObject:_inStream];
	}

	NSOutputStream* _outStream;
	for(_outStream in _outStreams) {
		[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		//[_outStream release];
		[_outStreams removeObject:_outStream];
	}
	
	[_inStreams release];
	[_outStreams release];

	[_server release]; // this release was already here
	
	[self destroyPicker];
	
	[_picker release];
	
	// For GLPaint
	[selectSound release];
	[erasingSound release];
	[drawingView release];
	[window release];
	
	[super dealloc];
}

// This executes inStreamThread
- (void) create:(id)useless {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	//NSLog(@"inStreamThread started");
	
	// Destroy any existing server
	[_server release];
	_server = nil;
	
	// Create a new game
	//_server = [[TCPServer new] retain]; // added retain here
	_server = [TCPServer new];
	[_server setDelegate:self];
	
	// Create the _inStreams and _outStreams NSMutableArrays
	_inStreams = [[NSMutableArray arrayWithCapacity:1] retain];
	_outStreams = [[NSMutableArray arrayWithCapacity:1] retain];
	
	/*
	NSInputStream* _inStream;
	for(_inStream in _inStreams) {
		[_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[_inStream release];
		_inStream = nil;
	}
	*/
	_inReady = NO;
	
	/*
	NSOutputStream* _outStream;
	for(_outStream in _outStreams) {
		[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[_outStream release];
		_outStream = nil;
	}
	*/
	_outReady = NO;
	
	NSError* error;
	if(_server == nil || ![_server start:&error]) {
		NSLog(@"Failed creating server: %@", error);
		[self _showAlert:@"Failed creating server"];
		return;
	}
	
	//Start advertising to clients, passing nil for the name to tell Bonjour to pick use default name
	if(![_server enableBonjourWithDomain:@"local" applicationProtocol:[TCPServer bonjourTypeFromIdentifier:kGameIdentifier] name:nil]) {
		[self _showAlert:@"Failed advertising server"];
		return;
	}
	//NSLog(@"inStreamThread success");
	// Kick off the RunLoop
	[[NSRunLoop currentRunLoop] run];
	
	NSLog(@"inStreamThread pool release");
	[pool release];
}

/*
// Called at the end of a game (and at the very beginning)
- (void) setup {
	
	// moved stream creation to app launch
	
	// advertising already started on app launch

	[self presentPicker:nil];
}
*/
// Make sure to let the user know what name is being used for Bonjour advertisement.
// This way, other players can browse for and connect to this game.
// Note that this may be called while the alert is already being displayed, as
// Bonjour may detect a name conflict and rename dynamically.
// Note that it is also called after disconnect, because devices then begin advertising again.
- (void) presentPicker:(NSString*)name {
	//NSLog(@"%s", _cmd);
	if (!_picker) {
		CGRect rect = [[UIScreen mainScreen] applicationFrame];
		
		//CGRect frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height - 5 * kTopMargin);
		//NSLog(@"rect = %@, frame = %@, kTopMargin = %d", NSStringFromCGRect(rect), NSStringFromCGRect(frame), kTopMargin);
		_picker = [[Picker alloc] initWithFrame:rect type:[TCPServer bonjourTypeFromIdentifier:kGameIdentifier]]; // 
		_picker.delegate = self;
	}
	
	_picker.gameName = name;

	if (!_picker.superview) {
		//[_window addSubview:_picker];
		[window addSubview:_picker]; // For GLPaint
		
		// Bring up the color palette (ensure it's above the picker)
		UIView *segmentedControl = [window viewWithTag:segmentedControlTag];
		//segmentedControl.hidden = NO;
		[window bringSubviewToFront:segmentedControl];
	}
}

- (void) showPicker {
	//[[[_picker bvc] tableView] reloadData];
	
	// Show the status bar
	[[UIApplication sharedApplication] setStatusBarHidden:NO animated:YES];
	
	// Show the picker
	_picker.hidden = NO;
	
	// Bring up the color palette
	UIView *segmentedControl = [window viewWithTag:segmentedControlTag];
	segmentedControl.hidden = NO;
	[window bringSubviewToFront:segmentedControl];
}

- (void) hidePicker {
	// Hide the status bar
	[[UIApplication sharedApplication] setStatusBarHidden:YES animated:YES];
	
	// Hide the picker
	_picker.hidden = YES;
	
	// Hide the color palette
	[window viewWithTag:segmentedControlTag].hidden = YES;
	
	if (firstHide) {
		firstHide = NO;
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Drawing tools have been hidden"
														message:@"Touch the screen with 2 fingers to show them again."
													   delegate:nil cancelButtonTitle:@"Continue" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
}

- (BOOL) pickerIsHidden {
	return _picker.hidden;
}

- (void) destroyPicker {
	[_picker removeFromSuperview];
	[_picker release];
	_picker = nil;
}

// If we display an error or an alert that the remote disconnected,
// handle dismissal and return to setup
- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if ([[alertView title] hasSuffix:@"” would like to Start Over"]) {
		NSLog(@"alertView:%@ clickedButtonAtIndex:%d", alertView, buttonIndex);
		
		if (buttonIndex == 1) {
			// Yes
			[erasingSound play];
			[drawingView erase];
			
			// Send erase accept reply (a)
			[self send:@"a}}"];
		} else {
			// No
			
			// Send erase reject reply (j)
			[self send:@"j}}"];
		}
	} else if ([[alertView title] hasSuffix:@"” to Start Over"]) {
		// Cancel request (L)
		[self send:@"L"];
	} else if ([[alertView title] isEqualToString:@"Are you sure you want to Start Over?"]) {
		
		if (buttonIndex == 1) {
			// Yes
			[erasingSound play];
			[drawingView erase];
			[self presentTools];
		}
		
	} else {
	
		//NSLog(@"alertView:%@ clickedButtonAtIndex:%d", alertView, buttonIndex);
		// don't change tool status on disconnect
		//[self hidePicker]; // showPicker
	}
}

/** Executes on the server **/
// Accept (OK) or reject (Don't Allow) an incoming join request
- (void) acceptPendingRequest:(NSUInteger)response withName:(NSString*)name
{
	if (response != kRejectSilently) {
		// release memory used by the AlertView
		[acceptRejectAlertView release];
		acceptRejectAlertView = nil;
	}
	
	//[[_picker bvc] stopActivityIndicator];

	if (!pendingJoinRequest) {
		NSLog(@"Warning: acceptPendingRequest:%d && !pendingJoinRequest", response);
		return;
	}
	pendingJoinRequest = NO;
	amServer = YES; // moved from didAcceptConnection...

	if (response == YES) {
		
		[_server stop];
		
		if ([NSThread isMainThread]) {
			NSLog(@"%s on MainThread", _cmd);
		} else {
			NSLog(@"%s NOT on MainThread", _cmd);
		}
		
		//[[_picker bvc] performSelector:@selector(setConnectedName:) onThread:inStreamThread withObject:name waitUntilDone:YES];
		[[_picker bvc] setConnectedName:name];
		((UILabel*)[_picker viewWithTag:kWaitingTag]).text = @"Your whiteboard's name is:";
		((UILabel*)[_picker viewWithTag:kOrJoinTag]).text = @"Whiteboards on this network:";
		//[[[_picker bvc] tableView] reloadData];
		
		[self sendMyColor];
		[self sendMyPointSize];
		[self hideTools];
	} else {
		// Response is No
		NSLog(@"[namesForStreams count] == %d", [namesForStreams count]);
		
		NSArray* allStreams = [namesForStreams allKeysForObject:name];
		
		NSLog(@"[allStreams count] == %d", [allStreams count]);
		
		NSString* strStream;
		// Print streams
		for (strStream in allStreams) {
			NSLog(@"stream:%@", strStream);
		}
		
		/** Watch out! This is duplicated code from NSStreamEventEndEncountered! **/
		
		// Close streams
		NSInputStream* _inStream;
		NSOutputStream* _outStream;
		for (_outStream in _outStreams) {
			NSString* _outStreamDescription = [NSString stringWithString:[_outStream description]];
			if (_outStream && [allStreams containsObject:_outStreamDescription]) {
				if (![_outStream hasSpaceAvailable])
					NSLog(@"Warning: acceptPendingRequest: ![_outStream hasSpaceAvailable]");
				// Send a rejection message only to this _outStream
				[self send:@"s}}r}}" toOutStream:_outStream];
				
				// Close stream
				[_outStream close];
				[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
				//[_outStream release];
				//_outStream = nil;
				
				// Remove stream from NSMutableDictionary
				[namesForStreams removeObjectForKey:_outStreamDescription];

				// Remove stream?
				NSLog(@"removeObject:%@", _outStream);
				[_outStreams removeObject:_outStream];

				NSLog(@"acceptPendingRequest: Removed _outStream");
			}
		}
		
		NSLog(@"looking for _inStream");
		for (_inStream in _inStreams) {
			NSString* _inStreamDescription = [NSString stringWithString:[_inStream description]];
			if (_inStream && [allStreams containsObject:_inStreamDescription]) {
				
				// Close stream
				[_inStream close];
				[_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
				//[_inStream release];
				//_inStream = nil;
				
				// Remove stream from NSMutableDictionary
				[namesForStreams removeObjectForKey:_inStreamDescription];
				
				// Remove stream?
				NSLog(@"removeObject:%@", _inStream);
				[_inStreams removeObject:_inStream];
				
				NSLog(@"Removed _inStream");
			}
		}
		
		// Added this so acceptReject.name indicates that there's an ongoing incoming connection
		NSLog(@"[_acceptReject setName:nil];");
		[_acceptReject setName:nil];
		
		NSLog(@"[_outStreams count] == %d", [_outStreams count]);
		for (_outStream in _outStreams) {
			NSLog(@"_outStream:%@", _outStream);
		}

		NSLog(@"[_inStreams count] == %d", [_inStreams count]);
		for (_inStream in _inStreams) {
			NSLog(@"_inStream:%@", _inStream);
		}
	}
}

/*
- (void) send:(const uint8_t)message
{
	NSLog(@"%s%d", _cmd, message);
	NSOutputStream* _outStream;
	NSLog(@"[_outStreams count] == %u", [_outStreams count]);
	for(_outStream in _outStreams) {
		NSLog(@"sending to _outStream:%@", _outStream);
		if (_outStream && [_outStream hasSpaceAvailable]) {
			if([_outStream write:(const uint8_t *)&message maxLength:sizeof(const uint8_t)] == -1)
				[self _showAlert:@"Failed sending data to peer"];
		} else {
			//[self _showAlert:@"outStream has no available space"];
			NSLog(@"(_outStream && [_outStream hasSpaceAvailable]) == NO");
		}
	}
}
*/

- (void) send:(NSString*)message
{
	NSLog(@"%s%@, [_outStreams count] = %d", _cmd, message, [_outStreams count]);
	// Watch out for an infinite loop
	if ([writeBuffer length] > 0 && ![writeBuffer isEqualToString:message]) {
		[self send:writeBuffer];
		writeBuffer = @"";
		NSLog(@"back to %s%@", _cmd, message);
	}
	 
	const char *buff = [message UTF8String];
	NSUInteger buffLen = strlen(buff);
	NSInteger writtenLength = 0;
	
	NSOutputStream* _outStream;
	
	for(_outStream in _outStreams) {
		if (_outStream) {
			if ([_outStream hasSpaceAvailable]) {
				//NSLog(@"send:%@", message);
				writtenLength = [_outStream write:(const uint8_t *)buff maxLength:strlen(buff)];
				if (writtenLength != buffLen) {
					
					//[self _showAlert:@"Failed sending data to peer"];
					NSLog(@"Failed sending data to peer, writtenLength = %d, buffLen = %d", writtenLength, buffLen);

					buff += writtenLength;
					buffLen -= writtenLength;
					while (buffLen > 0 && writtenLength != -1) {
						writtenLength = [_outStream write:(const uint8_t *)buff maxLength:strlen(buff)];
						NSLog(@"successfully wrote %d bytes", writtenLength);
						buff += writtenLength;
						buffLen -= writtenLength;
					}
					
				} else {
					NSLog(@"write successful");
				}
			} else {
				NSLog(@"Warning: send: ![_outStream hasSpaceAvailable]");
				/*
				if ([NSThread isMainThread]) {
					// Tell inStreadThread to do it
					[self performSelector:@selector(sendToStream:) onThread:inStreamThread withObject:messageAndStream waitUntilDone:NO];
				*/
				//[self _showAlert:@"outStream has no available space"];
				
				// TODO: this is dangerous to do from the main thread (which is what we're doing...) so maybe do something else
				
				// Use the stream synchronously
				// https://devforums.apple.com/message/2902#2902
				// turn around and try to write the remaining data.  If buffer space hasn't become available, this will block.
				while (buffLen > 0 && writtenLength != -1) {
					writtenLength = [_outStream write:(const uint8_t *)buff maxLength:strlen(buff)];
					NSLog(@"successfully wrote %d bytes", writtenLength);
					buff += writtenLength;
					buffLen -= writtenLength;
				}
			}
			if (writtenLength == -1) {
				
				// This occurs if we try to do stuff at the point when we say Game Started!
				//[NSException raise:@"send: WriteFailure" format:@"writtenLength = %d, [_outStreams count] = %d, _outStream = %@", writtenLength, [_outStreams count], _outStream];
				
				// Put into a write buffer
				writeBuffer = [writeBuffer stringByAppendingString:message];

			}
		} else {
			NSLog(@"Warning: !_outStream");
		}
	}
	
	if ([writeBuffer isEqualToString:message]) {
		writeBuffer = @"";
	}
}


// TODO: make this writeBuffer-aware?
// Write to one specific outStream
- (void) send:(NSString*)message toOutStream:(NSOutputStream*)_outStream
{
	NSLog(@"send:%@ toOutStream:%@", message, _outStream);
	
	const char *buff = [message UTF8String];
	NSUInteger buffLen = strlen(buff);
	NSInteger writtenLength = 0;
	if (_outStream) {
		if ([_outStream hasSpaceAvailable]) {
			writtenLength = [_outStream write:(const uint8_t *)buff maxLength:strlen(buff)];
			if (writtenLength != buffLen) {
				NSLog(@"Failed sending data to peer, writtenLength = %d, buffLen = %d", writtenLength, buffLen);
				buff += writtenLength;
				buffLen -= writtenLength;
				while (buffLen > 0 && writtenLength != -1) {
					writtenLength = [_outStream write:(const uint8_t *)buff maxLength:strlen(buff)];
					NSLog(@"successfully wrote %d bytes", writtenLength);
					buff += writtenLength;
					buffLen -= writtenLength;
				}
			} else {
				//NSLog(@"write successful");
			}
		} else {
			NSLog(@"Warning: send:toOutStream: ![_outStream hasSpaceAvailable]");
			/*
			 if ([NSThread isMainThread]) {
			 // Tell inStreadThread to do it
			 [self performSelector:@selector(sendToStream:) onThread:inStreamThread withObject:messageAndStream waitUntilDone:NO];
			 */
			//[self _showAlert:@"outStream has no available space"];
			
			// TODO: this is dangerous to do from the main thread (which is what we're doing...) so maybe do something else
			
			// Use the stream synchronously
			// https://devforums.apple.com/message/2902#2902
			// turn around and try to write the remaining data.  If buffer space hasn't become available, this will block.
			while (buffLen > 0 && writtenLength != -1) {
				writtenLength = [_outStream write:(const uint8_t *)buff maxLength:strlen(buff)];
				NSLog(@"successfully wrote %d bytes", writtenLength);
				buff += writtenLength;
				buffLen -= writtenLength;
			}
		}
		if (writtenLength == -1) {
			// This occurs if we try to do stuff at the point when we say Game Started!
			[NSException raise:@"send:toOutStream: WriteFailure" format:@"writtenLength = %d, [_outStreams count] = %d, _outStream = %@", writtenLength, [_outStreams count], _outStream];
		}
	} else {
		NSLog(@"Warning: !_outStream");
	}
}


// Send start and end to our friend
- (void) sendLineFromPoint:(CGPoint)start toPoint:(CGPoint)end
{
	// props to go2_ on irc.freenode.net
	CGRect cgRect = CGRectMake(start.x, start.y, end.x, end.y);
	
	[self send:NSStringFromCGRect(cgRect)];
	
	/*
	const char *buff = [NSStringFromCGRect(cgRect) UTF8String];
	NSUInteger buffLen = strlen(buff);
	NSInteger writtenLength;
	
	NSOutputStream* _outStream;
	
	for(_outStream in _outStreams) {
		//NSLog(@"sending to _outStream:%@", _outStream);
		if (_outStream && [_outStream hasSpaceAvailable]) {
			writtenLength = [_outStream write:(const uint8_t *)buff maxLength:strlen(buff)];
			if (writtenLength != buffLen) {
				[NSException raise:@"WriteFailure" format:@""];
				//[self _showAlert:@"Failed sending data to peer"];
				NSLog(@"Failed sending data to peer");
			}
		} else {
			//[self _showAlert:@"outStream has no available space"];
			NSLog(@"(_outStream && [_outStream hasSpaceAvailable]) == NO");
		}
	}
	*/
}

- (void) sendMyColor
{
	CGPoint first2components = CGPointMake(components[0], components[1]);
	CGPoint second2components = CGPointMake(components[2], components[3]);
	// send c}}
	[self send:@"c}}"];
	// send the components
	[self sendLineFromPoint:first2components toPoint:second2components];
}

- (void) sendMyPointSize
{
	[self send:[NSString stringWithFormat:@"s}}%f}}", _pointSize]];
}

- (void) sendMyNameToOutStream:(NSOutputStream*)_outStream
{
	/*
	NSUInteger index = [_inStreams indexOfObject:_inStream];
	if (index == NSNotFound) {
		NSLog(@"Warning: %s _inStream %@ not found", _cmd, _inStream);
	} else {
		NSOutputStream* _outStream = [_outStreams objectAtIndex:index];
	 */
		[self send:[NSString stringWithFormat:@"n}}%@}}", [_picker gameName]] toOutStream:_outStream];
	//}
}

/*
- (void) activateView:(TapView*)view
{
	[self send:[view tag] | 0x80];
}

- (void) deactivateView:(TapView*)view
{
	[self send:[view tag] & 0x7f];
}
*/
- (void) openInStream:(NSInputStream*)_inStream withOutStream:(NSOutputStream*)_outStream
{
	[self performSelector:@selector(openStream:) onThread:inStreamThread withObject:_inStream waitUntilDone:YES];
	//NSLog(@"mainThread: inStreamThread opened _inStream");
	[self performSelector:@selector(openStream:) onThread:inStreamThread withObject:_outStream waitUntilDone:YES];
	//NSLog(@"mainThread: inStreamThread opened _outStream");
	/*
	_inStream.delegate = self;
	[_inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	//[_inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSEventTrackingRunLoopMode];
	[_inStream open];
	_outStream.delegate = self;
	[_outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	//[_outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSEventTrackingRunLoopMode];
	[_outStream open];
	*/
}

- (void) openStream:(NSStream*)stream
{
	stream.delegate = self;
	[stream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[stream open];
}

- (void) rejectAndCloseOutStream:(NSOutputStream*)ostr {
	
	//[self openInStream:istr withOutStream:ostr];
	
	if (![ostr hasSpaceAvailable])
		NSLog(@"Warning: rejectAndCloseOutStream: ![ostr hasSpaceAvailable]");
	// Send a rejection message only to this _outStream
	// If we want, in the future, we could add a new message that says "{remote peer} is currently busy. Try again later"
	// or something like that. It would be more true than saying they outright rejected it.
	[self send:@"s}}r}}" toOutStream:ostr];
	
	// Close stream
	[ostr close];
	[ostr removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	//[_outStream release];
	//_outStream = nil;
	
	/*
	// Close stream
	[_inStream close];
	[_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	//[_inStream release];
	//_inStream = nil;
	 */
}

// Executes on the client (the device on which we tap the server's name - the "guest")
- (void) browserViewController:(BrowserViewController*)bvc didResolveInstance:(NSNetService*)netService
{
	amServer = NO;
	
	if ([NSThread isMainThread]) {
		NSLog(@"%s on MainThread", _cmd);
	} else {
		NSLog(@"%s NOT on MainThread", _cmd);
	}
	
	if (!netService) {
		NSLog(@"Warning: %s but !netService", _cmd);
		//[self setup];
		[self showPicker];
		return;
	}

	NSInputStream* _inStream;
	NSOutputStream* _outStream;
	if (![netService getInputStream:&_inStream outputStream:&_outStream]) {
		[self _showAlert:@"Failed connecting to server"];
		return;
	}
	
	// Keep track of the netService names associated with each stream
	[namesForStreams setObject:[netService name] forKey:[_inStream description]];
	[namesForStreams setObject:[netService name] forKey:[_outStream description]];
	
	// Add _inStream and _outStream to their respective NSMutableArrays
	
	NSLog(@"[_inStreams addObject:%@];", _inStream);
	[_inStreams addObject:_inStream];
	
	NSLog(@"[_outStreams addObject:%@];", _outStream);
	[_outStreams addObject:_outStream];

	[self openInStream:_inStream withOutStream:_outStream];
	
	// need to send color and present tools, but it's not safe to do so here
	//initializedWithPeers = NO;
	
	needToSendName = YES;
	// wait until we get acceptance or rejection
	
}

- (void) renderRemoteColorLineWithRect:(NSString *)strRect
{
	//NSLog(@"%s", _cmd);
	if (!usingRemoteColor) {
		//NSLog(@"glColor4f remote %f %f %f %f", remoteComponents[0], remoteComponents[1], remoteComponents[2], remoteComponents[3]);
		glColor4f(remoteComponents[0], remoteComponents[1], remoteComponents[2], remoteComponents[3]);
		usingRemoteColor = YES;
	}// else {
		//NSLog(@"already usingRemoteColor!");
	//}
	
	if (!usingRemotePointSize)
		usingRemotePointSize = YES;
	
	CGRect rect = CGRectFromString(strRect);
	CGPoint start, end;
	start = CGPointMake(rect.origin.x, rect.origin.y);
	end = CGPointMake(rect.size.width, rect.size.height);
	[drawingView renderLineFromPoint:start toPoint:end];
}

// Dangerous!

- (void) setRemoteColor:(id)useless
{
	NSLog(@"%s %f %f %f %f", _cmd, remoteComponents[0], remoteComponents[1], remoteComponents[2], remoteComponents[3]);
	glColor4f(remoteComponents[0], remoteComponents[1], remoteComponents[2], remoteComponents[3]);
}

/*
- (void) setRemotePointSize:(id)useless
{
	pointSize = remotePointSize;
}
*/
 
- (void) renderMyColorLineFromPoint:(CGPoint)previousLocation toPoint:(CGPoint)location
{
	//NSLog(@"%s", _cmd);
	// why do we need the lock?! we (MainThread) do ALL the drawing!
	/*
	while (![colorLock tryLock]) {
		// pump RunLoop so we do all of inStreamThread's drawing!
		// but does this mess up my sending?
		NSLog(@"tryLock failed, pumping RunLoop");
		int i;
		for(i = 0; i < 100 && CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, YES) == kCFRunLoopRunHandledSource; i++) {
			NSLog(@"renderMyColorLineFromPoint: RunLoop %d", i);
		}
	}
	 */
	// we have the lock now
	if (usingRemoteColor) {
		glColor4f(components[0], components[1], components[2], components[3]);
		usingRemoteColor = NO;
	}
	
	if (usingRemotePointSize)
		usingRemotePointSize = NO;
	
	[drawingView renderLineFromPoint:previousLocation toPoint:location];
	//[colorLock unlock];
}

- (void) presentTools {
	if ([self pickerIsHidden]) {
		
		//NSLog(@"reloadData");
		//[[[_picker bvc] tableView] reloadData];

		[self showPicker];
	} else {
		//NSLog(@"hiding tools");
		[self hidePicker];

	}
}

- (void) hideTools {
	if (![self pickerIsHidden])
		[self hidePicker];
}

- (void) doErase:(id)useless {
	[erasingSound play];
	[drawingView erase];
}

- (void) erase:(id)sender {
	if ([_outStreams count] >= 1) {
		// Assumes there is only 1 other user!
		//   is - (id) anyObject faster?
		NSString* serverName = [namesForStreams objectForKey:[[_outStreams objectAtIndex:0] description]];
		
		eraseWaitAlertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Asking “%@” to Start Over", serverName] message:@"Please wait for their reply..." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
		
		// Create the activity indicator and add it to the alert
		UIActivityIndicatorView* activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		// -22 y if name is 6 chars or less
		activityView.frame = CGRectMake(244.0f, ([serverName length] <= 6) ? 46.0f : 68.0f, kProgressIndicatorSize, kProgressIndicatorSize); //30.0f, 68.0f, 225.0f, 13.0f); //139.0f-18.0f, 80.0f, 37.0f, 37.0f);
		[eraseWaitAlertView addSubview:activityView];
		[activityView startAnimating];
		
		[eraseWaitAlertView show];
		//[eraseWaitAlertView release];
		
		// Send an erase request (e)
		[self send:@"e}}"];
	} else {
		
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Are you sure you want to Start Over?" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Start Over", nil];
		[alertView show];
		[alertView release];
		
	}
}

- (void) changePointSize:(id)sender {
	UISlider* slider = sender;
	//glPointSize([slider value]);
	_pointSize = [slider value];
	// send to others
	[self sendMyPointSize];
}

- (CGFloat) pointSize {
	return usingRemotePointSize ? remotePointSize : _pointSize;
}

// Assumes stream is an _inStream
// Executes on inStreamThread
- (BOOL) disconnectFromPeerWithStream:(NSStream*)stream
{
	NSLog(@"%s", _cmd);
	
	NSArray* allStreams;
	NSUInteger index;
	
	if (stream == nil) {
		allStreams = [namesForStreams allKeys];
		
		// allStreams count must be >= 0
		
		if ([allStreams count] == 0) {
			NSLog(@"Warning: no streams to disconnect from");
		}
		
		// Assume we're connected to only 1 peer
		// TODO: disconnect from the correct peer only (when selected from list)
		index = 0;
		
		@try {
			stream = [_inStreams objectAtIndex:0];
		}
		
		@catch (NSException *e) {
			NSLog(@"Warning: error selecting _inStream 0 (NSRangeException)");
		}
		
	} else {
		//NSLog(@"[namesForStreams count] == %d", [namesForStreams count]);
		NSString* name = [namesForStreams objectForKey:[stream description]];
		allStreams = [namesForStreams allKeysForObject:name];
		//NSLog(@"[allStreams count] == %d", [allStreams count]);
		
		// Close streams
		// stream is my _inStream
		
		index = [_inStreams indexOfObject:stream];
		if (index == NSNotFound) {
			// already disconnected
			return NO;
		}
	}
	
	
	if ([_picker bvc].currentResolve) {
		NSLog(@"[_picker bvc].currentResolve.name == %@", [_picker bvc].currentResolve.name);
	} else {
		NSLog(@"[_picker bvc].currentResolve == nil");
	}
	if ([_picker bvc].nextService) {
		NSLog(@"[_picker bvc].nextService.name == %@", [_picker bvc].nextService.name);
	} else {
		NSLog(@"[_picker bvc].nextService == nil");
	}
	
	// setting currentResolve moved to bottom
	
	// do we need to reload here?
	//[[[_picker bvc] tableView] reloadData];
	
	/*
	 NSString* strStream;
	 // Print streams
	 for (strStream in allStreams) {
	 NSLog(@"stream:%@", strStream);
	 }
	 */
	
	NSOutputStream* _outStream;
	
	@try {
		// this may throw NSRangeException if stream was removed concurrently
		_outStream = [_outStreams objectAtIndex:index];
		
		NSString* _outStreamDescription = [NSString stringWithString:[_outStream description]];
		
		// Close stream
		[_outStream close];
		[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		//[_outStream release];
		//_outStream = nil;
		
		// Remove stream from NSMutableDictionary
		[namesForStreams removeObjectForKey:_outStreamDescription];
		
		// Remove stream?
		NSLog(@"removeObject:%@", _outStream);
		[_outStreams removeObject:_outStream];
		NSLog(@"disconnectFromPeerWithStream: Removed _outStream");
	}
	
	@catch (NSException *e) {
		NSLog(@"Warning: error removing stream (NSRangeException)");
	}
	
	// use @finally if an object may need to be released
	
	NSString* _inStreamDescription = [NSString stringWithString:[stream description]];
	
	// Close stream
	[stream close];
	[stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	//[_inStream release];
	//_inStream = nil;
	
	// Remove stream from NSMutableDictionary
	[namesForStreams removeObjectForKey:_inStreamDescription];
	
	// Remove stream?
	NSLog(@"removeObject:%@", stream);
	[_inStreams removeObject:stream];
	NSLog(@"Removed stream");
	
	NSLog(@"[_outStreams count] == %d", [_outStreams count]);
	for (_outStream in _outStreams) {
		NSLog(@"_outStream:%@", _outStream);
	}
	
	NSInputStream* _inStream;
	NSLog(@"[_inStreams count] == %d", [_inStreams count]);
	for (_inStream in _inStreams) {
		NSLog(@"_inStream:%@", _inStream);
	}
	
	// Added this so acceptReject.name indicates that there's an ongoing incoming connection
	NSLog(@"disconnectFromPeerWithStream: [_acceptReject setName:nil];");
	[_acceptReject setName:nil];
	
	if ([_server isStopped]) {
		/*** Start Advertising Again ***/
		NSLog(@"Start Advertising Again");
		
		// We should do this only if we are stopped!
		
		assert(_server != nil);
		
		NSError* error;
		if(_server == nil || ![_server start:&error]) {
			NSLog(@"Failed creating server: %@", error);
			[self _showAlert:@"Failed creating server"];
			return YES;
		}
		
		//Start advertising to clients, passing nil for the name to tell Bonjour to pick use default name
		if(![_server enableBonjourWithDomain:@"local" applicationProtocol:[TCPServer bonjourTypeFromIdentifier:kGameIdentifier] name:nil]) {
			[self _showAlert:@"Failed advertising server"];
			//return;
		}
		
		//NSLog(@"success");
	}
	
	assert([_inStreams count] >= 0 && [_outStreams count] >= 0);
	
	if ([_inStreams count] == 0 && [_outStreams count] == 0) {
		
		/* // Shouldn't do this because it's already taken care of...
		 // For the conflict situation
		 if ([_picker bvc].nextService) {
		 [_picker bvc].currentResolve = [_picker bvc].nextService;
		 // set [[_picker bvc] _nextService] to nil?
		 // release it?
		 [_picker bvc].nextService = nil;
		 } else {
		 */
		[_picker bvc].currentResolve = nil;
		//}
		// should we do this on MainThread?
		[[_picker bvc] setConnectedName:nil];
		((UILabel*)[_picker viewWithTag:kWaitingTag]).text = @"Waiting for others to join whiteboard:";
		((UILabel*)[_picker viewWithTag:kOrJoinTag]).text = @"Or, join a different whiteboard:";
		
	}
	
	return YES;
}


- (CGColorRef) myColor
{
	CGFloat oldOpacity = components[2];
	components[2] = 1.0f;
	CGColorRef newColor = CGColorCreate(CGColorSpaceCreateDeviceRGB(), components);
	components[2] = oldOpacity;
	return newColor;
	//return CGColorCreateGenericRGB(components[0], components[1], components[2], components[3]);
}


@end

@implementation AppController (NSStreamDelegate)


- (void) stream:(NSStream*)stream handleEvent:(NSStreamEvent)eventCode
{
	//NSLog(@"%s", _cmd);
	//UIAlertView* alertView;
	switch(eventCode) {
		// Executes on both server and clients
		case NSStreamEventOpenCompleted:
		{
			NSLog(@"NSStreamEventOpenCompleted");
			//[self destroyPicker];
			//[self hidePicker];
			
			// Keep server running so I can always accept new connections
			//[_server release];
			//_server = nil;
			//[_server stop];

			BOOL setInReady = NO;
			
			NSInputStream* _inStream;
			for(_inStream in _inStreams) {
				if (stream == _inStream) {
					NSLog(@"set _inReady = YES");
					_inReady = YES;
					setInReady = YES;
					break;
				}
			}

			if(setInReady == NO) {
				_outReady = YES;
			}
			/*
			NSOutputStream* _outStream;
			for(_outStream in _outStreams) {
				if (stream == _outStream) {
					NSLog(@"set _outReady = YES");
					_outReady = YES;
					break;
				}
			}
			*/
			
			NSLog(@"check _inReady && _outReady");
			if (_inReady && _outReady) {
				NSLog(@"(_inReady && _outReady) == YES");
				
				//NSString* serverName = [namesForStreams objectForKey:[stream description]];
				// if I'm the client, I need to initializeWithPeers
				if (!amServer/*serverName != nil*/) {
					/*
					alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Successfully connected to %@", serverName] message:@"Waiting for response from server" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
					[alertView show];
					[alertView release];
					 */
					// wait for point size or rejection
					initializedWithPeers = NO;
				} // else I'm the server, so wait for them to tell us their name
			} else {
				NSLog(@"(_inReady && _outReady) == NO");
			}
			break;
		}
		case NSStreamEventHasBytesAvailable:
		{
			int i;


			//NSLog(@"NSStreamEventHasBytesAvailable");
			NSInputStream* _inStream;
			for(_inStream in _inStreams) {
				if (stream == _inStream) {
					//NSLog(@"stream == _inStream");
					
					uint8_t buff[1024];
					bzero(buff, sizeof(buff));
					
					NSInteger readLength;
					NSString* message = @"";
					
					//CGRect cgRect;
					
					// TODO: handle incomplete streams
					
					for(i = 0; i < 100 && [_inStream hasBytesAvailable]; i++) {
					//while([_inStream hasBytesAvailable]) {
						readLength = [_inStream read:buff maxLength:sizeof(buff) - 1];
						buff[readLength] = '\0';
						
						message = [message stringByAppendingString:[NSString stringWithUTF8String:(const char *)buff]];
					}
					NSLog(@"%d %@", i, message);

					/*
					for(i = 0; i < 10 && CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, YES) == kCFRunLoopRunHandledSource; i++) {
						NSLog(@"RunLoop %d", i);
					}
					*/
					NSArray* points = [message componentsSeparatedByString:@"}}"];
					for(message in points) {
						// Watch out for blank "messages"!
						
						// handle remote color changes
						//NSLog(@"starting for loop, receivingRemoteColor = %d", receivingRemoteColor);
						if ([message isEqualToString:@"c"]) {
							// since a color is also 4 CGFloat's, we'll again store it in a CGRect
							NSLog(@"receivingRemoteColor = YES");
							receivingRemoteColor = YES;
						} else if (receivingRemoteColor && ![message isEqualToString:@""]) {
							NSLog(@"setting remoteComponents");
							CGRect rect = CGRectFromString([message stringByAppendingString:@"}}"]);
							remoteComponents[0] = rect.origin.x;
							remoteComponents[1] = rect.origin.y;
							remoteComponents[2] = rect.size.width;
							remoteComponents[3] = rect.size.height;
							receivingRemoteColor = NO;
							//usingRemoteColor = NO; // Very important! So we set the color next time we need it
							if (usingRemoteColor) {
								[self performSelectorOnMainThread:@selector(setRemoteColor:)
													   withObject:nil
													waitUntilDone:YES];
							}
							// I don't think we have shared data between threads?!
							//[colorLock lock];
							/*
							[self performSelectorOnMainThread:@selector(setRemoteColor:)
												   withObject:nil
												waitUntilDone:YES];
							*/
							//usingRemoteColor = YES;
							//[colorLock unlock];
							
						} else if ([message isEqualToString:@"s"]) {
							receivingRemotePointSize = YES;
						} else if (receivingRemotePointSize && ![message isEqualToString:@""]) {
							receivingRemotePointSize = NO; // Don't forget this!
							if ([message isEqualToString:@"r"]) {
								// rejection message
								NSLog(@"rejected");

								if (!initializedWithPeers) {
									initializedWithPeers = YES;
									
									if ([NSThread isMainThread]) {
										NSLog(@"%s on MainThread", _cmd);
									} else {
										NSLog(@"%s NOT on MainThread", _cmd);
									}
									
									// Aren't I already executing on inStreamThread?
									// Optimize later
									//[[_picker bvc] stopActivityIndicator];
									[[_picker bvc] performSelector:@selector(stopActivityIndicator:) onThread:inStreamThread withObject:nil waitUntilDone:YES];
									
									NSString* serverName = [namesForStreams objectForKey:[stream description]];

									UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"“%@” has rejected your request", serverName]
																		   message:@"If you wish, you may try your request again." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
									[alertView show];
									[alertView release];
									
									[self disconnectFromPeerWithStream:stream];
								}
								
							} else {
								remotePointSize = [message floatValue];
								
								if (!initializedWithPeers) {
									initializedWithPeers = YES;
									
									// is this right?
									if (amServer && pendingJoinRequest && [[[_picker bvc] ownName] compare:message] == NSOrderedAscending) {
										NSLog(@"Warning: server attempting to initialize!");
									} else {
									
										/** This executes on the client **/
										
										[_server stop];
										
										//[[_picker bvc] stopActivityIndicator];
										[[_picker bvc] performSelector:@selector(stopActivityIndicator:) onThread:inStreamThread withObject:nil waitUntilDone:YES];
										
										NSString* serverName = [namesForStreams objectForKey:[stream description]];
										
										// Executing on inStreamThread
										
										if ([NSThread isMainThread]) {
											NSLog(@"%s on MainThread", _cmd);
										} else {
											NSLog(@"%s NOT on MainThread", _cmd);
										}
										
										[[_picker bvc] setConnectedName:serverName];
										((UILabel*)[_picker viewWithTag:kWaitingTag]).text = @"Your whiteboard's name is:";
										((UILabel*)[_picker viewWithTag:kOrJoinTag]).text = @"Whiteboards on this network:";
										//[[[_picker bvc] tableView] reloadData];

										UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"“%@” has accepted your request", serverName] message:@"You are now drawing together!" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
										[alertView show];
										[alertView release];
										
										// Successfully connected, so drop any connection that's not this one
										// Assumes only 1 peer
										// Handles conflict case
										if ([_inStreams count] >= 2) {
											NSLog(@"client: dropping 'extra' connection");
											NSInputStream* _inStream;
											for(_inStream in _inStreams) {
												if (stream != _inStream) {
													NSLog(@"going to disconnect from _inStream: %@", _inStream);
													[self performSelector:@selector(disconnectFromPeerWithStream:) onThread:inStreamThread withObject:_inStream waitUntilDone:YES];													break;
												}
											}
										}

										[self sendMyColor];
										[self sendMyPointSize];
										//[self presentTools]; // actually hide tools
										[self hideTools];
										
									}
									
								}
							}
							
						} else if ([message isEqualToString:@"n"]) {
							receivingRemoteName = YES;
						} else if (receivingRemoteName && ![message isEqualToString:@""]) {
							receivingRemoteName = NO;
							
							if (!amServer && !pendingJoinRequest && !([[[_picker bvc] ownName] compare:message] == NSOrderedAscending)) {
								// pendingJoinRequest == YES also indicates that I'm the server!
								NSLog(@"Warning: client trying to process initialization info");
								
								// Maybe this means I should actually be the server!
								// I should be the server if [[[_picker bvc] ownName] compare:message] == NSOrderedAscending
								
							} else {
							
								/** Executes on server **/
								NSLog(@"Executing server code");
								
								// Name doesn't exist yet, or name does exist but I'm supposed to be the server
								// Everyone: don't send name unless you're supposed to!
								if ([namesForStreams objectForKey:[stream description]] == nil || ([[[_picker bvc] ownName] compare:[namesForStreams objectForKey:[stream description]]] == NSOrderedAscending)) {
									[namesForStreams setObject:message forKey:[stream description]];
									
									// associate name with _outStream, too
									NSUInteger index = [_inStreams indexOfObject:stream];
									[namesForStreams setObject:message forKey:[[_outStreams objectAtIndex:index] description]];
									
									// If more than one client tries to join simultaneously, reject them
									// Either a dialog is already showing, or the server isn't running (anymore), or I'm trying to resolve another peer
									if (acceptRejectAlertView || [_server isStopped]/* || [[_picker bvc] currentResolve]*/) {
										NSLog(@"Reject only this peer (silently)");
										
										// message is name!
										[self performSelector:@selector(rejectSilentlyWithName:) onThread:inStreamThread withObject:[message copy] waitUntilDone:YES];
										//[self acceptPendingRequest:kRejectSilently withName:[message copy]];
									} else if ([[[_picker bvc] currentResolve].name isEqualToString:[message copy]]) {
										
										// Is it the case that only 1 device has this occur?
										
										#if TARGET_CPU_ARM
										NSLog(@"Device");
										#else
										NSLog(@"Simulator");
										#endif
										
										// I'm trying to connect to a peer who's trying to connect to me
										
										// NSOrderedAscending if the receiver precedes aString
										// NSOrderedDescending if the receiver follows aString
										if ([[[_picker bvc] ownName] compare:message] == NSOrderedAscending) {
											NSLog(@"Conflict resolution: I'll be the server");
											amServer = YES;
											
											// Cancel my request (silently?), accept theirs
											//[disconnectFromPeerWithStream:nil];
											// How do I know my connection's streams?
											// It's the stream that isn't this one (stream)
											NSInputStream* _inStream;
											for(_inStream in _inStreams) {
												if (stream != _inStream) {
													NSLog(@"going to disconnect from _inStream: %@", _inStream);
													[self performSelector:@selector(disconnectFromPeerWithStream:) onThread:inStreamThread withObject:_inStream waitUntilDone:YES];													break;
												}
											}
											
											// Optimize later
											
											if (_acceptReject == nil)
												_acceptReject = [[AcceptReject alloc] init];
											[_acceptReject setName:message];
											acceptRejectAlertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"“%@” would like to join your whiteboard", message]
																							   message:nil
																							  delegate:_acceptReject cancelButtonTitle:@"Don't Allow"
																					 otherButtonTitles:@"OK", nil];
											[self acceptPendingRequest:YES withName:message];
											
											// TODO: Deselect row?
											[[_picker bvc] performSelector:@selector(stopActivityIndicator:) onThread:inStreamThread withObject:nil waitUntilDone:YES];
										
										} else {
											NSLog(@"Conflict resolution: I'll be the client");
											amServer = NO;
											
											/** Remember that this code is executing on the "server" **/
											
											// Reject their request, keep my request going
											
											// Don't need to reject? They'll cancel?
											// But this might be asynchronous?
											
											// This stream hit a conflict: they requested me when I was requesting them
											// But the server needs to realize there's a conflict...
											
											//[self disconnectFromPeerWithStream:stream];
											// Fixes an Exception where the array got mutated while being iterated
											[self performSelector:@selector(disconnectFromPeerWithStream:) onThread:inStreamThread withObject:stream waitUntilDone:YES];
											NSLog(@"doing nothing");
										}
										 
										
									} else {
									
										// Normal procedure: no conflict detected (yet!)
										
										if (_acceptReject == nil)
											_acceptReject = [[AcceptReject alloc] init];
										[_acceptReject setName:message];
										acceptRejectAlertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"“%@” would like to join your whiteboard", message]
																							message:nil
																						   delegate:_acceptReject cancelButtonTitle:@"Don't Allow"
																				  otherButtonTitles:@"OK", nil];
										[acceptRejectAlertView show];
										//[alertView release];
										//NSLog(@"alertView released");
											
									}
								} else {
									NSLog(@"Name for this stream %@ already exists", stream);
								}
								
							} // if (amServer)
							
						} else if ([message isEqualToString:@"e"]) {
							// erase request
							NSString* serverName = [namesForStreams objectForKey:[stream description]];
							
							eraseWaitAlertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"“%@” would like to Start Over", serverName] message:@"Do you want to Start Over?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
							[eraseWaitAlertView show];
							//[eraseWaitAlertView release];
							
							NSLog(@"showed alertView for erase request");
						} else if ([message isEqualToString:@"a"]) {
							// Erase accept reply (a)
							
							// Erase
							[self performSelectorOnMainThread:@selector(doErase:)
												   withObject:nil
												waitUntilDone:YES];
							
							// Close alertView (don't need to notify, it'll be obvious)
							if (eraseWaitAlertView) {
								[eraseWaitAlertView dismissWithClickedButtonIndex:0 animated:YES];
								[eraseWaitAlertView release];
								eraseWaitAlertView = nil;
							}
							
						} else if ([message isEqualToString:@"j"]) {
							// Erase reject reply (j)
							
							// Close alertView
							if (eraseWaitAlertView) {
								[eraseWaitAlertView dismissWithClickedButtonIndex:0 animated:YES];
								[eraseWaitAlertView release];
								eraseWaitAlertView = nil;
							}
							
							// Notify rejected
							UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Your request to Start Over was declined"
																				message:@"" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
							[alertView show];
							[alertView release];
							
						} else if ([message isEqualToString:@"L"]) {
							NSLog(@"Cancel request (L)");
							
							// Close alertView
							if (eraseWaitAlertView) {
								[eraseWaitAlertView dismissWithClickedButtonIndex:0 animated:YES];
								[eraseWaitAlertView release];
								eraseWaitAlertView = nil;
							}
							
							// Don't process blank messages!
						} else if (![message isEqualToString:@""]) {
							/*
							if ([NSThread isMainThread]) {
								NSLog(@"Warning! MainThread is executing %s", _cmd);
							}
							 */
							//NSLog(@"%s attempting [colorLock lock]", _cmd);
							//[colorLock lock];
							
							/*
							if (!usingRemoteColor) {
								NSLog(@"setRemoteColor: %f %f %f %f", remoteComponents[0], remoteComponents[1], remoteComponents[2], remoteComponents[3]);
								// This makes the main thread do something -- which it can't, because it's waiting for colorLock!
								////////////////////
								[self performSelectorOnMainThread:@selector(setRemoteColor:)
													   withObject:nil
													waitUntilDone:YES];
								////////////////////
								usingRemoteColor = YES;
								// do this on inStreamThread
								// OpenGL won't work with threads :(
								glColor4f(remoteComponents[0], remoteComponents[1], remoteComponents[2], remoteComponents[3]);
							} else {
								NSLog(@"already usingRemoteColor!");
							}
							*/
						
							// NO puts incoming drawings at higher priority
							//NSLog(@"%s attempting renderLineWithRect:", _cmd);
							// make the MainThread not block when lock is used, because we need MainThread to do all the drawing!
							[self performSelectorOnMainThread:@selector(renderRemoteColorLineWithRect:)
												   withObject:[message stringByAppendingString:@"}}"]
												waitUntilDone:YES];
							//[colorLock unlock];
							//NSLog(@"%s renderRemoteColorLineWithRect: success", _cmd);
						}
						//NSLog(@"done handling message");
					}
					//NSLog(@"for loop done");
					
					
					/*
					if ([stream streamStatus] != NSStreamStatusAtEnd) {
						NSLog(@"[stream streamStatus] != NSStreamStatusAtEnd");
					}
					*/
					
					/*
					uint8_t b;
					unsigned int len = 0;
					len = [_inStream read:&b maxLength:sizeof(uint8_t)];
					if(!len) {
						if ([stream streamStatus] != NSStreamStatusAtEnd)
							[self _showAlert:@"Failed reading data from peer"];
					} else {
						//We received a remote tap update, forward it to the appropriate view
						if(b & 0x80)
							[(TapView*)[_window viewWithTag:b & 0x7f] touchDown:YES];
						else
							[(TapView*)[_window viewWithTag:b] touchUp:YES];
					}
					*/
					break;
				}
			}
			break;
		}
		case NSStreamEventEndEncountered:
		{
			NSString* serverName = [[namesForStreams objectForKey:[stream description]] retain]; // very important to retain here!
			NSLog(@"serverName == %@", serverName);
			
			NSLog(@"NSStreamEventEndEncountered");
			// disappears here!
			if ([self disconnectFromPeerWithStream:stream]) {
				// rejected case covered because rejection message always gets sent?
				
				// We've successfully disconnected, so set acceptReject.name to nil
				// This is used by BrowserViewController bvc
				[_acceptReject setName:nil];
				
				// if acceptReject alertView is showing, dismiss it
				NSLog(@"about to check acceptRejectAlertView"); /******/
				if (acceptRejectAlertView != nil) {
					NSLog(@"acceptRejectAlertView != nil");
					//[[_picker bvc] stopActivityIndicator];
					
					//NSLog(@"it's YES");
					[acceptRejectAlertView dismissWithClickedButtonIndex:2 animated:YES];
					
					[acceptRejectAlertView release];
					acceptRejectAlertView = nil;
				}

				//NSLog(@"about to show disconnect msg, serverName == %@", serverName);
				
				// kind of a hack? sometimes it's (null) [conflict, or simultaneous, case]
				if (serverName) {
					UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"“%@” has disconnected", serverName] message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
					[alertView show];
					[alertView release];
					//NSLog(@"showed disconnect msg");
					
					
					// Do this even if we didn't need to disconnect?
					
					// Give the device we disconnected from some time to reappear (if it is going to)
					// If it does reappear, then we don't remove it
					// But if it then disappears again, make sure we do!
					[NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(removeServiceWithTimer:) userInfo:[serverName copy] repeats:NO];
				}
			}
			
			//NSLog(@"done disconnecting");
			
			// Moved to disconnectFromPeerWithStream:
			//[[_picker bvc] setConnectedName:nil];
			//[[[_picker bvc] tableView] reloadData];
			//NSLog(@"scheduling timer");
			

			
			[serverName release];
			// do I need to remove the streams from my arrays? YES
			// TODO: move below alertView so user gets feedback first?
			// TODO: make sure this is actually a mirror image of what I did to prepare the stream
			/*
			NSInputStream* _inStream;
			NSOutputStream* _outStream;
			NSUInteger index;
			for(_inStream in _inStreams) {
				if (stream == _inStream) {
					// don't think it matters whether I use stream or _inStream...
					
					// TODO: make sure indices of in and out will actually always be the same
					// TODO: indexOfObjectIdenticalTo:? try it someday... should work?
					index = [_inStreams indexOfObjectIdenticalTo:_inStream];
					
					
					[_inStream close];
					[_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
					[_inStream release];
					_inStream = nil;
					
					//[_inStreams removeObjectAtIndex:index];
					[_inStreams removeObject:_inStream];
					
					_outStream = [_outStreams objectAtIndex:index];
					
					[_outStream close];
					[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
					[_outStream release];
					_outStream = nil;
					
					//[_outStreams removeObjectAtIndex:index];
					[_outStreams removeObject:_outStream];
				}
			}
			*/
			// TODO: There are no more targets in my run loop, so when another client connects, will I need to kick off the run loop again?
			
			/*
			NSArray*				array = [_window subviews];
			TapView*				view;
			UIAlertView*			alertView;
			
			NSLog(@"%s", _cmd);
			
			//Notify all tap views
			for(view in array)
				[view touchUp:YES];
			*/
			
			// TODO: remove from NSMutableDictionary (namesForStreams)
			break;
		}
		case NSStreamEventNone:
		{
			NSLog(@"NSStreamEventNone");
			break;
		}
		case NSStreamEventHasSpaceAvailable:
		{
			/** This is an event that occurs for NSOutputStreams! **/
			
			// Assumes 1 peer
			if (needToSendName) {
				needToSendName = NO;
				[self sendMyNameToOutStream:(NSOutputStream*)stream]; // could save a little bandwidth by doing this only if I'm the client
				// TODO: what if name changes -- can it?
			}
			
			//NSLog(@"NSStreamEventHasSpaceAvailable");
			/*
			if (!initializedWithPeers) {
				[self sendMyName]; // could save a little bandwidth by doing this only if I'm the client
				// TODO: what if name changes -- can it?
				
				[self sendMyColor];
				[self sendMyPointSize];
				[self presentTools];
				initializedWithPeers = YES;
			}
			 */
			break;
		}
		case NSStreamEventErrorOccurred:
		{
			NSLog(@"NSStreamEventErrorOccurred");
			break;
		}
		default:
		{
			NSLog(@"unrecognized eventCode:%u", eventCode); // Unsigned 32-bit integer (unsigned int)
			break;
		}
	}
}


// Execute on inStreamThread
- (void)rejectSilentlyWithName:(NSString*)name {
	[self acceptPendingRequest:kRejectSilently withName:name];
}


// Execute on MainThread
- (void)removeServiceWithTimer:(NSTimer*)timer {
	if ([NSThread isMainThread]) {
		NSLog(@"%s on MainThread", _cmd);
	} else {
		NSLog(@"%s NOT on MainThread", _cmd);
	}
	
	[[_picker bvc] performSelectorOnMainThread:@selector(removeServiceWithName:)
						   withObject:[timer userInfo]
						waitUntilDone:YES];
}

@end

@implementation AppController (TCPServerDelegate)

// Called after disconnect because devices re-enable Bonjour after disconnecting!
- (void) serverDidEnableBonjour:(TCPServer*)server withName:(NSString*)string
{
	//NSLog(@"%s", _cmd);
	[self presentPicker:string];
}

// Executes on the server (the device whose name gets tapped - the "host")
- (void)didAcceptConnectionForServer:(TCPServer*)server inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr
{
	//NSLog(@"%s", _cmd);
	
	// This is problematic
	
	if ([NSThread isMainThread]) {
		NSLog(@"%s on MainThread", _cmd);
	} else {
		NSLog(@"%s NOT on MainThread", _cmd);
	}

	// Stream already exists or a different server has connected to us
	if ([_inStreams count] > 0 || [_outStreams count] > 0 || server != _server) {
		// Reject immediately

		// The streams haven't even been added yet
		
		// This is a REALLY silent rejection
		//return;
		
		/*
		[self performSelector:@selector(openStream:) onThread:inStreamThread withObject:ostr waitUntilDone:YES];
		
		[self performSelector:@selector(rejectAndCloseOutStream:) onThread:inStreamThread withObject:ostr waitUntilDone:YES];
		
		return;
		 */
		
		NSLog(@"Stream already exists or a different server has connected to us");
		
		//return;
		//[self _showAlert:@"New client joined"];
		/*
		UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"New User Connected!" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
		[alertView show];
		[alertView release];
		 */
	}

	// Test Case: I make a request; then someone tries to request to join me. They should get rejected
	//amServer = YES;
	

	
	// Keep server running
	//[_server release];
	//_server = nil;
	//[_server stop];
	
	// Add istr and ostr to their respective NSMutableArrays
	
	//_inStream = istr;
	//[_inStream retain];
	NSLog(@"[_inStreams addObject:%@];", istr);
	[_inStreams addObject:istr];
	//_outStream = ostr;
	//[_outStream retain];
	NSLog(@"[_outStreams addObject:%@];", ostr);
	[_outStreams addObject:ostr];
	
	[self openInStream:istr withOutStream:ostr];
	//[self performSelectorInBackground:@selector(openStream:) withObject:istr];
	//[self performSelectorInBackground:@selector(openStream:) withObject:ostr];
	
	//[self sendMyColor];
	//[self presentTools];
	// trying to move this to where we say Game Started!
	//initializedWithPeers = NO;
	pendingJoinRequest = YES;
}

// From GLPaint
// Change the brush color
- (void)changeBrushColor:(id)sender
{
 	//CGFloat					components[3];
	
	//Play sound
 	[selectSound play];
	
	//NSLog(@"[sender selectedSegmentIndex]=%d", [sender selectedSegmentIndex]);
	//Set the new brush color
	if ([sender selectedSegmentIndex] == 0) {
		components[0] = components[1] = components[2] = 0.0f; // Black
	} else if ([sender selectedSegmentIndex] == kPaletteSize + 1) {
		components[0] = components[1] = components[2] = 1.0f; // White
	} else {
		HSL2RGB((CGFloat)([sender selectedSegmentIndex] - 1) / (CGFloat)kPaletteSize, kSaturation, kLuminosity, &components[0], &components[1], &components[2]);
	}
	
	if (!usingRemoteColor)
		glColor4f(components[0], components[1], components[2], kBrushOpacity); // must do this!
	//NSLog(@"glColor4f(%f, %f, %f, %f)", components[0], components[1], components[2], kBrushOpacity);
	// Don't need to do this because we'll check before doing our strokes!
	/*
	[colorLock lock];
 	glColor4f(components[0], components[1], components[2], kBrushOpacity);
	usingRemoteColor = NO;
	[colorLock unlock];
	*/
	
	[_picker redrawPreview];
	
	[self sendMyColor];
	//[self presentTools];
}


/*
#if TARGET_CPU_ARM
// Called when the accelerometer detects motion; toggles Picker display if the motion is over a threshold.
- (void) accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration
{
	//NSLog(@"%s", _cmd);
	
	UIAccelerationValue				length,
	x,
	y,
	z;
	
	//Use a basic high-pass filter to remove the influence of the gravity
	myAccelerometer[0] = acceleration.x * kFilteringFactor + myAccelerometer[0] * (1.0 - kFilteringFactor);
	myAccelerometer[1] = acceleration.y * kFilteringFactor + myAccelerometer[1] * (1.0 - kFilteringFactor);
	myAccelerometer[2] = acceleration.z * kFilteringFactor + myAccelerometer[2] * (1.0 - kFilteringFactor);
	// Compute values for the three axes of the acceleromater
	x = acceleration.x - myAccelerometer[0];
	y = acceleration.y - myAccelerometer[0];
	z = acceleration.z - myAccelerometer[0];
	
	//Compute the intensity of the current acceleration 
	length = sqrt(x * x + y * y + z * z);
	// If above a given threshold, play the erase sounds and erase the drawing view
	if((length >= kEraseAccelerationThreshold) && (CFAbsoluteTimeGetCurrent() > lastTime + kMinEraseInterval)) {
		[self presentTools];
		lastTime = CFAbsoluteTimeGetCurrent();
	}
}
#endif
 */
@end
