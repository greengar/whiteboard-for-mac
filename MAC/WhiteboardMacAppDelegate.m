//
//  WhiteboardMacAppDelegate.m
//  WhiteboardMac
//
//  Created by Silvercast on 11/4/10.
//  Copyright 2010-2011 Greengar Studios. All rights reserved.
//

#import "WhiteboardMacAppDelegate.h"
#import "WhiteboardMacAppDelegate+NSStreamDelegate.h"
#import "BrushPickerPanel.h"
#import "Picker.h"
#import "NSImage+Transform.h"

BOOL USE_HEX_STRING_IMAGE_DATA = YES;

#define kGameIdentifier			@"whiteboard"
#define kMinPointSize			1.0
#define kMaxPointSize			32.0
#define kBannerHeight			25
#define kDefaultOpacityValue	0.75

#if LITE
	// this is the width a single ad, but the ad container actually shows up to 3-4 ads
	#define kAdWidth  320
	#define kAdHeight 50
	#define kAdZoneID 1255873
	#define kDefaultRefreshInterval 30
#else
	#define kAdWidth  0
	#define kAdHeight 0
#endif


@implementation WhiteboardMacAppDelegate

@synthesize window;
@synthesize drawingView;
#if LITE
	@synthesize adContainerView1;
	//@synthesize adContainerView2;
	//@synthesize adContainerView3;
#endif
@synthesize viewMode;
@synthesize brushPanel;
@synthesize customColorPickerWindow;
@synthesize customAlertTableDialogWindow;
@synthesize usingRemotePointSize;
@synthesize usingRemoteColor;
@synthesize picker = _picker;
@synthesize pointSize = _pointSize;
@synthesize ownName;
@synthesize isCustomColorPickerOn;

@synthesize imageHexString;

@synthesize connection = _connection;
//KONG: moving local connection 
@synthesize remoteDevice;


+ (void)initialize
{
	//[[BrushPickerPanel class] poseAsClass:[NSColorPanel class]];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	
	[window setAcceptsMouseMovedEvents: YES];
	[window setDelegate:self];
	if ([window acceptsMouseMovedEvents]) {DLog(@"window now acceptsMouseMovedEvents");}

	NSRect screenRect = [[NSScreen mainScreen] frame];
	NSToolbar *toolbar;
    NSRect windowFrame;
	
    toolbar = [window toolbar];
	
    if(toolbar && [toolbar isVisible])
    {
        windowFrame = window.frame;
        toolbarHeight = NSHeight(windowFrame) - NSHeight([[window contentView] frame]);
		DLog(@"toolbar height %f", toolbarHeight);
    }
	
	windowFrame.size.width = MIN(screenRect.size.width, 1024 + kPickerHeight);
	windowFrame.size.height = MIN(screenRect.size.height, 768 + toolbarHeight + kBannerHeight + kAdHeight);
	windowFrame.origin.x = screenRect.size.width/2 - windowFrame.size.width/2;
	windowFrame.origin.y = screenRect.size.height/2 - windowFrame.size.height/2 + 20;
	
	[[self window] setFrame:windowFrame display:YES animate:NO];
	
	windowFrame = window.frame;
	
	//CGRect contentRect = NSMakeRect(0, 0, 1024 + kAdHeight, 768 + kPickerHeight + kBannerHeight);
	NSRect contentRect = NSMakeRect(0, 0, windowFrame.size.width, windowFrame.size.height - toolbarHeight);
	contentView = [[NSView alloc] initWithFrame:contentRect];

	drawingView = [[MainPaintingView alloc] initWithFrame:NSMakeRect(0, kAdHeight, contentRect.size.width - kPickerHeight, contentRect.size.height - kBannerHeight - kAdHeight)];
	
#if LITE
	adContainerView1 = [[BSAAdContainerView alloc] initWithFrame:NSMakeRect(0, 0, windowFrame.size.width - kPickerHeight, kAdHeight)];
//	adContainerView2 = [[BSAAdContainerView alloc] initWithFrame:NSMakeRect((contentRect.size.width - kPickerHeight - kAdWidth) / 2, 0, kAdWidth, kAdHeight)];
//	adContainerView3 = [[BSAAdContainerView alloc] initWithFrame:NSMakeRect(contentRect.size.width - kAdWidth - kPickerHeight, 0, kAdWidth, kAdHeight)];
	
	// Without this, the frame height would need to be at least 52 instead of 50
	adContainerView1.bordered = NO;
//	adContainerView2.bordered = NO;
//	adContainerView3.bordered = NO;
	
	adContainerView1.zoneIdentifier = [NSNumber numberWithInt:kAdZoneID];
//	adContainerView2.zoneIdentifier = [NSNumber numberWithInt:kAdZoneID];
//	adContainerView3.zoneIdentifier = [NSNumber numberWithInt:kAdZoneID];
	
	[adContainerView1 setDelegate:self];
//	[adContainerView2 setDelegate:self];
//	[adContainerView3 setDelegate:self];
	
	//KONG: there has crash when refreshing I cannot debug more with this crash
	[[BSAAdController sharedController] loadAdsWithKey:@"a2ab64b1c0c7dad55e83bddd72841c1b"]; // Sidebar of Mac App
	
//	// start a timer to refresh ads every |refreshInterval| seconds
//	#define kRefreshIntervalKey @"GSRefreshIntervalKey"
//	NSTimeInterval refreshInterval = [[NSUserDefaults standardUserDefaults] doubleForKey:kRefreshIntervalKey]; // NSTimeInterval is double
//	if (refreshInterval < 0.1) {
//		refreshInterval = kDefaultRefreshInterval; // default 30 seconds
//	}
//	DLog(@"refreshInterval = %lf", refreshInterval);
//	refreshTimer = [[NSTimer scheduledTimerWithTimeInterval:refreshInterval target:self selector:@selector(refreshAds) userInfo:nil repeats:YES] retain]; // release timer on app terminate
#endif
	
	self.picker = [[Picker alloc] initWithFrame:NSMakeRect(contentRect.size.width - kPickerHeight, -(kPickerWidth + kBannerHeight - contentRect.size.height), kPickerHeight, contentRect.size.height - kBannerHeight + (kPickerWidth + kBannerHeight - contentRect.size.height))];
	[self.picker setHorizontal:FALSE];
	
	bannerView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, contentRect.size.height - kBannerHeight, contentRect.size.width, kBannerHeight)];
	[bannerView setImage:[NSImage imageNamed:@"Gray-background2.gif"]];
	[bannerView setImageScaling:NSImageScaleAxesIndependently];
	
	customColorPickerBackground = [[NSImageView alloc] initWithFrame:NSMakeRect(contentRect.size.width - kPickerHeight, 0, kPickerHeight, contentRect.size.height)];
	[customColorPickerBackground setImage:[NSImage imageNamed:@"Gray-background2.gif"]];
	[customColorPickerBackground setImageScaling:NSImageScaleAxesIndependently];
	
	connectedDeviceName = [[NSText alloc] initWithFrame:NSMakeRect(0, -7, contentRect.size.width, kBannerHeight)];
	[connectedDeviceName setAlignment:NSCenterTextAlignment];
	[connectedDeviceName setVerticallyResizable:YES];
	[connectedDeviceName setTextColor:[NSColor whiteColor]];
	[connectedDeviceName setString:@"Your Whiteboard"];
	[connectedDeviceName setEditable:NO];
	[connectedDeviceName setSelectable:NO];
	[connectedDeviceName setBackgroundColor:[NSColor clearColor]];
	[bannerView addSubview:connectedDeviceName];
	
#if LITE
	[contentView addSubview:adContainerView1];
//	[contentView addSubview:adContainerView2];
//	[contentView addSubview:adContainerView3];
#endif
	
	[contentView addSubview:drawingView];
	[contentView addSubview:customColorPickerBackground];
	[contentView addSubview:self.picker];
	[contentView addSubview:bannerView];
	[window setContentView:contentView];
	[window makeFirstResponder: contentView];

	

	
	int count = [viewModePopUpButton numberOfItems];
	for(int i = 0; i < count; i++) {
		NSMenuItem * item = [viewModePopUpButton itemAtIndex:i];
		[item setEnabled:FALSE];
	}
	
	[viewModePopUpButton setAutoenablesItems:NO];
	
	_pointSize = kDefaultPointSize;
	usingRemoteColor = NO;
	receivingRemoteColor = NO;
	usingRemotePointSize = NO;
	
	//NSColor * c = [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1];
	//[c getComponents:components];
	
//	[[NSColor blueColor] getComponents:components];
//	[OPAQUE_HEXCOLOR(0x0000FF) getComponents:components];
//	[OPAQUE_HEXCOLOR(0x00FFFF) getComponents:components];
	
//	components[3] = kDefaultOpacityValue;
	
	[drawingView setColor:components];
	[[Picker sharedPicker] setSelectedTab:2];
	
	_toolMode = normalMode;
	
	
	isBrushSelectorHorizontal = FALSE;
	[NSApp setDelegate:self];
	
	//KONG: collaboration
	_connection = [[GSConnectionController alloc] init];
	[_connection didFinishLaunching];	

	// force the drawing to draw something
	// this is a quick fix for the issue of incorrect rendering caused when we pan before drawing anything
	[drawingView renderLineFromPoint:NSZeroPoint toPoint:NSZeroPoint];
	
	// Create namesForStreams NSDictionary
//	namesForStreams = [[NSMutableDictionary dictionaryWithCapacity:2] retain];
//	
//	//[self create];
//	inStreamThread = [[NSThread alloc] initWithTarget:self
//											 selector:@selector(create:)
//											   object:nil];
//	[inStreamThread start];	
}

//#if LITE
//- (void)refreshAds {
//	DLog();
//	[adContainerView1 refresh];
//}
//#endif

- (void)windowDidResize:(NSNotification *)notification {
	NSRect windowFrame = window.frame;
	toolbarHeight = NSHeight(windowFrame) - NSHeight([[window contentView] frame]);
	NSRect contentRect = NSMakeRect(0, 0, windowFrame.size.width, windowFrame.size.height - toolbarHeight);

	[contentView setFrame:contentRect];
	
	if (isBrushSelectorHorizontal == FALSE) {
		
#if LITE
		// ad width changes with the window width
		[adContainerView1 setFrame:NSMakeRect(0, 0, windowFrame.size.width - kPickerHeight, kAdHeight)]; // kAdWidth
//		[adContainerView2 setFrame:NSMakeRect((contentRect.size.width - kPickerHeight - kAdWidth) / 2, 0, kAdWidth, kAdHeight)];
//		[adContainerView3 setFrame:NSMakeRect(contentRect.size.width - kAdWidth - kPickerHeight, 0, kAdWidth, kAdHeight)];
#endif
		
		[customColorPickerBackground setFrame:NSMakeRect(contentRect.size.width - kPickerHeight, 0, kPickerHeight, contentRect.size.height - kBannerHeight)];
		[self.picker setFrame:NSMakeRect(contentRect.size.width - kPickerHeight, -(kPickerWidth + kBannerHeight - contentRect.size.height), kPickerHeight, contentRect.size.height - kBannerHeight + (kPickerWidth + kBannerHeight- contentRect.size.height))];
		[self.picker setHorizontal:FALSE];
		[connectedDeviceName setFrame:NSMakeRect(0, -7, contentRect.size.width, kBannerHeight)];
		[bannerView setFrame:NSMakeRect(0, contentRect.size.height - kBannerHeight, contentRect.size.width, kBannerHeight)];
		[drawingView setFrame:NSMakeRect(0, kAdHeight, contentRect.size.width - kPickerHeight,contentRect.size.height - kBannerHeight -kAdHeight)];
		
	} else {
		
#if LITE
		// ad width changes with the window width
		[adContainerView1 setFrame:NSMakeRect(0, 0, windowFrame.size.width, kAdHeight)]; // kAdWidth
//		[adContainerView2 setFrame:NSMakeRect((contentRect.size.width - kAdWidth) / 2, 0, kAdWidth, kAdHeight)];
//		[adContainerView3 setFrame:NSMakeRect(contentRect.size.width - kAdWidth, 0, kAdWidth, kAdHeight)];
#endif
		
		[customColorPickerBackground setFrame:NSMakeRect(0, kAdHeight, contentRect.size.width, kPickerHeight)];
		[self.picker setFrame:NSMakeRect(0, kAdHeight, contentRect.size.width, kPickerHeight)];
		[self.picker setHorizontal:TRUE];
		[connectedDeviceName setFrame:NSMakeRect(0, -7, contentRect.size.width, kBannerHeight)];
		[bannerView setFrame:NSMakeRect(0, contentRect.size.height - kBannerHeight, contentRect.size.width, kBannerHeight)];
		[drawingView setFrame:NSMakeRect(0, kPickerHeight + kAdHeight, contentRect.size.width ,contentRect.size.height - kBannerHeight - kPickerHeight - kAdHeight)];
		
	}

}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *) theApplication {
	return YES;
}


- (BOOL)windowShouldClose:(NSWindow *)sender
{
	if (sender == customColorPickerWindow) {
		return YES;
	}
	NSString *msg = @"Are you sure to quit Whiteboard without saving ?";
	SEL sel_ok = @selector(acceptedSheet:returnCode:contextInfo:);
	SEL sel_not_ok = @selector(rejectedSheet:returnCode:contextInfo:);
	
	NSBeginAlertSheet(
					  @"Quit Whiteboard",	// NSString *title,								sheet title				
					  @"OK",								// NSString *defaultButton,				default button label			
					  @"Cancel",						// NSString *alternateButton,			alternate button label		
					  nil,				// NSString *otherButton,					other button label				
					  sender,								// NSWindow *docWindow,						document window				
					  self,									// id modalDelegate,							(id) modal delegate				
					  sel_ok,								// SEL didEndSelector,						OK selector and arguments			
					  sel_not_ok,						// SEL didDismissSelector,				NOT_OK selector and arguments			
					  sender,								// void *contextInfo,							context info				
					  msg,									// NSString *msg,									confirm message				
					  nil);									// 																params for message string				
	
	return NO;
}


- (void)rejectedSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	// NSLog(@"NSAlert returnCode = %d",returnCode);
	
	if (returnCode == NSAlertAlternateReturn)	// Similar to NSCancelButton
	{
		//NSLog(@"NSAlertAlternateReturn returnCode = %d",returnCode);
	}
	else if (returnCode == NSAlertOtherReturn)
	{
		//NSLog(@"NSAlertOtherReturn returnCode = %d",returnCode);
		// DO NOT SAVE THE DOCUMENT, JUST CLOSE THE WINDOW AND QUIT
		[(NSWindow *)contextInfo close];
		[NSApp stop:nil];
	}
	else
	{		
		//NSLog(@"NSAlertErrorReturn returnCode = %d",returnCode);
	}
}

- (void)acceptedSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	//NSLog(@"NSAlert returnCode = %d",returnCode);
	
	if (returnCode == NSAlertDefaultReturn)
	{

		[(NSWindow *)contextInfo close];
		[NSApp stop:nil];
	}
}

- (void)setOwnName:(NSString *)name {
	ownName = name;
	[connectedDeviceName setString:[NSString stringWithFormat:@"Your Whiteboard: %@", name]];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	[_connection willTerminate];
	
//#if LITE
//	[refreshTimer invalidate], [refreshTimer release], refreshTimer = nil;
//#endif
}

- (void)send:(NSString *)message {
	[_connection send:message];
}

- (CGFloat) pointSize {
	return usingRemotePointSize ? remotePointSize : _pointSize;
}


//
// This method must be called on the main thread.
//
- (void)setRemoteColor {
	usingRemotePointSize = YES;
	//remoteComponents[3] = powf(1.0 - (1.0 - remoteTrueOpacity), kBrushPixelStep / 3.0);
	//DLog(@"myOpacity:%f remoteOpacity:%f", components[3], remoteComponents[3]);
	
	if (protocolVersion == 1) {
		// This looks really close, but needs a little boost
		// This decreases the opacity, so that Lite strokes aren't too opaque
		//   due to the new brush pixel step
		remoteComponents[3] = powf(1.0 - (1.0 - remoteTrueOpacity), 3.0 / kBrushPixelStep);
		if (remotePointSize <= 24) {
			CGFloat boost = ((1.0 - remoteTrueOpacity) / 10.0);
			remoteComponents[3] += boost;
			DLog(@"boost:%f", boost);
		}
	} else {
		remoteComponents[3] = remoteTrueOpacity;
	}

	[drawingView setColor:remoteComponents];
	
	usingRemoteColor = YES;
}


- (void)renderRemoteColorLineWithRect:(NSString *)rectString {
	//
	// CGRectFromString() returns CGRectZero if the data is invalid.
	//
	
	// rectString is in format {{0,0},{90,90}} so NSRectFromString doesn't work
	
	NSString * str = [rectString stringByReplacingOccurrencesOfString:@" " withString:@""];
	str = [str stringByReplacingOccurrencesOfString:@"{{" withString:@""];
	str = [str stringByReplacingOccurrencesOfString:@"}}" withString:@""];
	str = [str stringByReplacingOccurrencesOfString:@"},{" withString:@"#"];
	str = [str stringByReplacingOccurrencesOfString:@"," withString:@"#"];
	//DLog(@"%@ %@", rectString, str);
	
	NSArray * arr = [str componentsSeparatedByString:@"#"];
	
	if ([arr count] != 4) {
		//DLog(@"WARNING: Invalid message received:%@", str);
		return;
	}
	
	NSRect rect = NSMakeRect([[arr objectAtIndex:0] doubleValue], 
							 [[arr objectAtIndex:1] doubleValue], 
							 [[arr objectAtIndex:2] doubleValue], 
							 [[arr objectAtIndex:3] doubleValue]); 
	
	if (NSEqualRects(rect, NSZeroRect)) {
		//DLog(@"WARNING: Invalid message received:%@", rectString);
		
		// 2010-03-24 19:12:40.380 Whiteboard[4972:207] -[AppController renderRemoteColorLineWithRect:] [Line 1704] WARNING: Invalid message received: 126}}
		// [Line 1704] WARNING: Invalid message received:{{33,}}
		// 2010-03-24 19:16:16.027 Whiteboard[4972:207] -[AppController renderRemoteColorLineWithRect:] [Line 1704] WARNING: Invalid message received: 410}, {24, 411}}
		
		return;
	}
	
	//
	// CGRect is valid, so render the line
	//
	
	// Fix color on connection
	[self setRemoteColor];
	
	NSPoint start = NSMakePoint(rect.origin.x,   rect.origin.y);
	NSPoint	end   = NSMakePoint(rect.size.width, rect.size.height);

	//
	// For iPad<->iPhone compatibility
	//
	
	if (remoteDevice != iPadDevice) {
		start = [self convertPoint:start fromSize:NSMakeSize(320, 480) toSize:NSMakeSize(768, 1024) scaleBy:2.0f];
		end   = [self convertPoint:end   fromSize:NSMakeSize(320, 480) toSize:NSMakeSize(768, 1024) scaleBy:2.0f];
	}
		
	[drawingView renderLineFromPoint:start toPoint:end];
}

- (void)acceptStartOverRequest {
	//[erasingSound play];
	//[drawingView erase];
	[drawingView erase];
	
	// Send erase accept reply (a)
	[self send:@"a}}"];
}
- (void)doErase {
	[drawingView erase];
}

- (NSPoint)convertPoint:(NSPoint)p fromSize:(NSSize)f toSize:(NSSize)t scaleBy:(CGFloat)s {

	float m = 1.0f / s; // s = 0.5 -> m = 2
	float marginX = (f.width  - (t.width  * m)) / 2.0f; // divide by 2 to make
	float marginY = (f.height - (t.height * m)) / 2.0f; // the margin equal on both sides
	
	return NSMakePoint(round(((p.x - marginX) / (t.width * m)) * t.width), round(((p.y - marginY) / (t.height * m)) * t.height));
	
}

- (void)displayAlertConnectedDevice:(NSString*)message {
//	NSRunAlertPanel([NSString stringWithFormat:@"Connected to %@", message], 
//				@"You are now able to view drawing on connected device",
//				@"OK", nil, nil);
	[self setConnectedDeviceName:message];
	
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:[NSString stringWithFormat:@"Connected to “%@”", message]];
	[alert setInformativeText:@"You are now drawing together!"];
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert setIcon:[NSImage imageNamed:kAlertIcon]];
	
	[alert runModal];
	[alert release];
	
	
	
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {

}

#define kNetworkOnImage  @"Gnome-Network-Wireless.icns"
#define kNetworkOffImage @"Gnome-Network-Wireless-Off-64.png"

-(IBAction)networking:(id)sender {
	
	if (customAlertTableDialogWindow == nil) {
		
//		customAlertTableDialogWindow = [[CMAlertTableDialog alloc] init];
		
		

		NSNib *nib = [[NSNib alloc] initWithNibNamed:@"AlertTableDialog" bundle:nil];
		
		BOOL success = [nib instantiateNibWithOwner:self topLevelObjects:nil];
		[nib release];
		
		if (success != YES)
		{
			// should present error
			return;
		}
		
		//KONG: start networking when starting
		[customAlertTableDialogWindow.networkingButton setTitle:networkingDisableString];
		
		[_connection setConnectionView:customAlertTableDialogWindow];
	}
	
    [customAlertTableDialogWindow orderOut:nil];	
	
	[NSApp beginSheet:customAlertTableDialogWindow
	   modalForWindow:window 
		modalDelegate:self 
	   didEndSelector:@selector(didEndConnectSheet:returnCode:contextInfo:)
		  contextInfo:NULL];
	
}

- (void)networkingEnableDidChange:(BOOL)isEnabled {
	
	if (isEnabled) {
		[networkToolbarItem setImage:[NSImage imageNamed:kNetworkOnImage]];
	} else {
		[networkToolbarItem setImage:[NSImage imageNamed:kNetworkOffImage]];
	}

	/*
	 * Change behavior of Networking
	 * Now show the list of devices
	 if (![_server isStopped]) {
	 DLog(@"closing networking");
	 [self disconnectFromPeerWithStream:nil];
	 
	 // stop broadcasting on Bonjour
	 BOOL stopped = [_server stop];
	 DLog(@"stopped = %d", stopped);
	 
	 if (stopped) {
	 
	 }
	 
	 } else {
	 
	 DLog(@"starting networking");
	 
	 
	 inStreamThread = [[NSThread alloc] initWithTarget:self
	 selector:@selector(create:)
	 object:nil];
	 [inStreamThread start];
	 
	 }*/
}

- (void)didEndConnectSheet:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo {	
	DLog(@"End Connect");
	[customAlertTableDialogWindow orderOut:self];
	return;
}



-(IBAction)save:(id)sender {
	DLog(@"saved");
	NSSavePanel *spanel = [NSSavePanel savePanel];
	NSString *path = @"~/Documents";
	[spanel setDirectory:[path stringByExpandingTildeInPath]];
	[spanel setPrompt:NSLocalizedString(@"Save",nil)];
	[spanel setRequiredFileType:@"jpeg"];
	[spanel beginSheetForDirectory:path
                              file:nil
					modalForWindow:window
					 modalDelegate:self
					didEndSelector:@selector(didEndSaveSheet:returnCode:conextInfo:)
					   contextInfo:NULL];
}

-(void)didEndSaveSheet:(NSSavePanel *)savePanel
			returnCode:(int)returnCode conextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton){
		NSImage * img = [drawingView glToNSImage];
		
		NSData *imageData = [img TIFFRepresentation];
		NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
		NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
		imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
		
		//DLog([[savePanel URL] path]);
		
		[imageData writeToFile:[[savePanel URL] path] atomically:NO]; 
		
		[img release];
	}else{
        DLog(@"Cancel");
	}
}

- (IBAction)cancelConnection:(id)sender {
	[NSApp endSheet:customAlertTableDialogWindow returnCode:NSCancelButton];
}

-(IBAction)open:(id)sender {
	DLog(@"opened");
	NSOpenPanel *spanel = [NSOpenPanel openPanel];
	NSString *path = @"~/Documents";
	[spanel setDirectory:[path stringByExpandingTildeInPath]];
	[spanel setPrompt:NSLocalizedString(@"Open",nil)];
	//[spanel setRequiredFileType:@"jpeg"];
	NSArray * fileTypes = [NSArray arrayWithObjects:@"jpeg", @"jpg", @"png", nil];
	[spanel setCanChooseDirectories:NO];
	[spanel setAllowedFileTypes:fileTypes];
	int i = [spanel runModalForTypes:fileTypes];

//	[spanel beginSheetForDirectory:NSHomeDirectory()
//                              file:nil
//					modalForWindow:window
//					 modalDelegate:self
//					didEndSelector:@selector(didEndOpenSheet:returnCode:conextInfo:)
//					   contextInfo:NULL];
	
	if(i == NSOKButton){
		[self openFile:[spanel filename]];
	}
}

- (CGImageRef)paddingImage:(CGImageRef)image toWidth:(int)width toHeight:(int)height {
	
	CGColorSpaceRef colorSpace = CGImageGetColorSpace(image);
	CGContextRef bmContext = CGBitmapContextCreate(NULL,
												   width,
												   height,
												   8,
												   width * 4,
												   colorSpace,
												   kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast );
	
	CGFloat whiteColor[4] = {255, 255, 255, 255};

	CGContextSetFillColor(bmContext, whiteColor);
	CGContextFillRect(bmContext, CGRectMake(0, 0, width, height));
	int imageW = CGImageGetWidth(image);
	int imageH = CGImageGetHeight(image);
	
	CGContextDrawImage(bmContext, CGRectMake(width/2 - imageW/2, height/2 - imageH/2, imageW, imageH), image);

	CGImageRef paddedImageRef = CGBitmapContextCreateImage(bmContext);
	CGContextRelease(bmContext);
	
	return paddedImageRef;
}

-(void)openFile:(NSString*)filePath
{
//	if (returnCode == NSOKButton){
		
		NSData *myData = [NSData dataWithContentsOfFile:filePath];  
		
		if (myData) {  
			
			NSImage * img = [[NSImage alloc] initWithData:myData];
			if (img) {
				//DLog(@"%@", [[openPanel URL] path]);
			
				[myData retain];
				
				CFDataRef imgData = (CFDataRef)myData;
				
				CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData (imgData);
				CGImageRef image2 = CGImageCreateWithJPEGDataProvider(imgDataProvider, NULL, true, kCGRenderingIntentDefault);
				
				// check if it's a JPG file if doesn't work check if it's a PNG file
				// otherwise pop up an alert view to user
				
				if (!image2) {
					// check if the input is a PNG file
					image2 = CGImageCreateWithPNGDataProvider(imgDataProvider, NULL, true, kCGRenderingIntentDefault);
				} 
				
				// unsupported file
				if (!image2) {
					NSAlert *alert = [[NSAlert alloc] init];
					[alert addButtonWithTitle:@"OK"];
					[alert setMessageText:@"Unsupported File Type"];
					[alert setInformativeText:@"Only JPEG files are supported."];
					[alert setAlertStyle:NSInformationalAlertStyle];
					[alert setIcon:[NSImage imageNamed:kAlertIcon]];
					
					[alert runModal];
					[alert release];
					return;
				}

				if ((CGImageGetWidth(image2) > kDocumentWidth) || (CGImageGetHeight(image2) > kDocumentHeight)) {
					NSAlert *alert = [[NSAlert alloc] init];
					[alert addButtonWithTitle:@"OK"];
					[alert setMessageText:@"Unsupported Image size"];
					[alert setInformativeText:@"Image is too large. Whiteboard only support images with maximum 1024x768 size. Please try a smaller one."];
					[alert setAlertStyle:NSInformationalAlertStyle];
					[alert setIcon:[NSImage imageNamed:kAlertIcon]];
					
					[alert runModal];
					[alert release];
					return;
				}
				
				CGImageRef image;
				
				if ((CGImageGetWidth(image2) < kDocumentWidth) || (CGImageGetHeight(image2) < kDocumentHeight)) {
					
					image = [self paddingImage:image2 toWidth:kDocumentWidth toHeight:kDocumentHeight];
					
				} else {
					
					image = image2;
					
				}


				if ([drawingView loadImage:image]) {
					if ([_connection isConnected]) {
						[self transferDrawing:nil];
					} else {
						[drawingView drawObject];
						[drawingView pushScreenToUndoStack];
					}

					
				} else {
					NSAlert *alert = [[NSAlert alloc] init];
					[alert addButtonWithTitle:@"OK"];
					[alert setMessageText:@"Unsupported File Type"];
					[alert setInformativeText:@"Only JPEG files are supported."];
					[alert setAlertStyle:NSInformationalAlertStyle];
					[alert setIcon:[NSImage imageNamed:kAlertIcon]];
					
					[alert runModal];
					[alert release];
					
					
				}
				
				
				
			}
			// do something useful  
		}  
//	}else{
//        DLog(@"Cancel");
//	}
}



-(IBAction)transferDrawing:(id)sender {
	if([_connection isConnected]) {
		
		//if ([drawingView loadImage:image]) {
			
		NSImage * img = [drawingView glToNSImage];
		NSImage * img2 = [NSImage rotateIndividualImage: img clockwise: NO];
		NSData *imageData = [img2 TIFFRepresentation];
		NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
		NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
		imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
		
		DLog(@"Image Data Bytes: %d", [imageData length]);
		
		//Get a hex representation in String for the data (Remove unnecessary values, such as spaces and < >)
		NSString *imageHexString2 = [[imageData description] stringByReplacingOccurrencesOfString:@" " withString:@""];
		imageHexString2 = [imageHexString2 substringWithRange:NSMakeRange(1, [imageHexString2 length]-2)];
		
		//Make sure it doesn't get autoreleased until we're finished with it
		[imageHexString2 retain];
		
		//SHERWIN: UNCOMMENT the following to show the hex string
		//DLog(@"Image Hex Data: %@", imageHexString);
		DLog(@"Image Hex String Length: %d", [imageHexString2 length]);
		
		[_connection initiateImageTransfer:imageHexString2];
		//[appController sendImageHexData:imageHexString];
		
		[imageHexString2 release];
		
	} 		
}

-(IBAction)undo:(id)sender {
	[drawingView undoStroke];
}

-(IBAction)redo:(id)sender {
	[drawingView redoStroke];
}

// this method follows Apple's recommended pattern (see Apple documentation)
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
	BOOL enable = YES; // default state, applies to most items
	if (theItem == undoToolbarItem) {
		if ([drawingView.undoImageArray count] <= 1) {
			enable = NO;
		}
	} else if (theItem == redoToolbarItem) {
		if ([drawingView.redoImageArray count] <= 0) {
			enable = NO;
		}
	}
	return enable;
}

-(IBAction)startOver:(id)sender {
	if ([_connection isConnected]) {
		[_connection initiateStartOver];
	} else {
		[self startOverAlert];		
	}
}

- (void)startOverAlert {
	GSAlert *startOverAlert = [GSAlert alertWithDelegate:self
												   title:@"Start Over"
												 message:@"Are you sure you want to Start Over ?" 
										   defaultButton:@"OK"
											 otherButton:@"Cancel"];
	startOverAlert.tag = AlertTagStartOverWithoutConnection;
	[startOverAlert registerToReceiveNotificationForSelector:@selector(dismiss)];
	[startOverAlert show];
}

- (void)alertView:(GSAlert *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	
}

- (void)alertView:(GSAlert*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	BOOL answer = NO;
	if (buttonIndex == 1) {
		answer = YES;
	} else if (buttonIndex > 1) {
		return;
	}
	if (answer == YES) {
		switch (alertView.tag) {
			case AlertTagStartOverWithoutConnection:
				[drawingView erase];
				[self send:@"e}}"];
				break;
			default:
				break;
		}
	}
}


- (void) toolbarWillAddItem:(NSNotification *)notification 
{
    NSToolbarItem *addedItem = [[notification userInfo] objectForKey: @"item"];
    if([[addedItem itemIdentifier] isEqual: NSToolbarShowColorsItemIdentifier]) {                
		[addedItem setToolTip:@"Change Text Color"];
		[addedItem setTarget:self];
		[addedItem setAction:@selector(showColorPicker)];
    }
} 

- (void)setConnectedDeviceName:(NSString*)name {

	[bannerView setImage:[NSImage imageNamed:@"Orange-background.jpg"]];
	[connectedDeviceName setString:[NSString stringWithFormat:@"Connected to “%@”", name]];
	//[connectedDeviceName setTextColor:[NSColor orangeColor]];

}

- (void)clearConnectedDeviceName {
	
	[connectedDeviceName setString:[NSString stringWithFormat:@"Your Whiteboard: %@", self.ownName]];
	[bannerView setImage:[NSImage imageNamed:@"Gray-background2.gif"]];
	//[connectedDeviceName setTextColor:[NSColor orangeColor]];

}

- (void)showColorPicker:(NSColor*)chosenColor
{
	
	if (!customColorPicker) {
		customColorPicker = [[CMColorPicker alloc] initWithFrame:NSMakeRect(0, 0, 300, 338)];
		//[customColorPicker setSelectedColor:chosenColor animated:YES];
		//[customColorPicker setBrushSize:pointSize];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorPickerValueChanged:) name:@"kMyColorPickerValueChangedNotification" object:nil];
	}
	
	if (!customColorPickerWindow) {
	
		[customColorPicker setSelectedColor:chosenColor animated:YES];
//		[customColorPicker setBrushSize:self.pointSize];
		
		customColorPickerWindow = [[NSWindow alloc] init];
		[customColorPickerWindow setFrameTopLeftPoint: NSMakePoint( [self window].frame.origin.x + [self window].frame.size.width, 768 - 300)];
		[customColorPickerWindow setDelegate:self];
		[customColorPickerWindow setStyleMask:NSTitledWindowMask|NSClosableWindowMask];
		[customColorPickerWindow setContentSize:customColorPicker.frame.size];
		[customColorPickerWindow setContentView:customColorPicker];
		[customColorPickerWindow setAcceptsMouseMovedEvents: YES];
		[customColorPickerWindow setReleasedWhenClosed:NO];
		[window addChildWindow:customColorPickerWindow ordered:NSWindowAbove];
		
		[window orderFrontRegardless];
		
		isCustomColorPickerOn = YES;
	} else {
		[customColorPicker setSelectedColor:chosenColor animated:YES];
//		[customColorPicker setOpacity:self.pointSize];
//		[customColorPicker setBrushSize:self.pointSize];
	}

}

- (void)windowWillClose:(NSNotification *)notification
{
	if ([notification object] == customColorPickerWindow) {		
		[window removeChildWindow:customColorPickerWindow];
		[customColorPickerWindow orderOut:self];
		[customColorPickerWindow release];
		customColorPickerWindow = nil;
		isCustomColorPickerOn = NO;
	}
}

- (void) colorPickerValueChanged:(id)notification
{	
	NSColor *pickedColor = customColorPicker.selectedColor;
	[self.picker pickedColor:pickedColor];
	//CGFloat components[4];
	
	//KONG: update component color
	[pickedColor getComponents:components];
//	DLog(@"_____________________ %f", [customColorPicker.opacitySlider doubleValue]);

	[self.picker pickedOpacity:[customColorPicker.opacitySlider doubleValue]];
	
	//KONG: update component opacity
	//This fixed a bug relating to changing the brush width makes change to brush opacity
	//This is just a temporary fix, because I think the color and opacity should always go together for consistent
	//Currently in GSTab, we store color and opacity in separate space, it make inconsistent, sometime update color without opacity
	components[3] = [customColorPicker.opacitySlider doubleValue];
	
	_pointSize = [customColorPicker.brushSizeSlider floatValue];
	[self.picker pickedBrushSize:_pointSize];
	[self sendMyPointSize];
	usingRemotePointSize = NO;

	[drawingView setColor:components];
	usingRemoteColor = NO;
	[self sendMyColor];
	
}


- (IBAction)showWheelModelColorPanel:(id)sender
{
	[[NSColorPanel sharedColorPanel] setMode:NSWheelModeColorPanel];
}

- (IBAction)showRGBModelColorPanel:(id)sender
{
	[[NSColorPanel sharedColorPanel] setMode:NSRGBModeColorPanel];
}


- (void)localBrushSizeChanged:(id)sender
{
	DLog(@"%f", [sender doubleValue]);
	_pointSize = [sender doubleValue];
	[self sendMyPointSize];
	usingRemotePointSize = NO;
}

- (void)localOpacityValueChanged:(id)sender
{
	DLog(@"%f", [sender doubleValue]);
	//_pointSize = [sender doubleValue];
	//[self sendMyPointSize];
	//usingRemotePointSize = NO;
}
- (void)changeColor:(id)sender
{
	NSColor *pickedColor = [sender color];
	//CGFloat components[4];
	[pickedColor getComponents:components];

	DLog(@"%f %f %f %f", components[0], components[1], components[2], components[3]);
	
	[drawingView setColor:components];
	usingRemoteColor = NO;
	[self sendMyColor];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
	return [NSArray arrayWithObjects: 
			 NSToolbarShowColorsItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier, 
			NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, nil];
}

//
// Send start and end points to connected peer
//   NO TRANSFORMATIONS CAN TAKE PLACE HERE.
//   Other methods which use this function assume that the points pass through unchanged.
//   (e.g. -sendMyColorForPoint)
//
- (void)sendLineFromPoint:(NSPoint)start toPoint:(NSPoint)end {
	if (remoteDevice != iPadDevice) { //[[UIScreen mainScreen] bounds].size.width == 768
		//
		// Perform transformation
		//  1024 -> 480 * 2 = 960 ( 64 extra pixels) [32 each side, top/bottom]
		//   768 -> 320 * 2 = 640 (128 extra pixels) [64 each side, left/right]
		//
		// X
		//  64     -> 0
		//  64+960 -> 480
		//
		//		DLog(@"start = %@, end = %@", NSStringFromCGPoint(start), NSStringFromCGPoint(end));
		//		CGPoint cStart = [self convertPoint:start fromSize:CGSizeMake(1024, 768) toSize:CGSizeMake(320, 480) scaleBy:0.5f];
		//		CGPoint cEnd   = [self convertPoint:end   fromSize:CGSizeMake(1024, 768) toSize:CGSizeMake(320, 480) scaleBy:0.5f];
		
		// width first, THEN height
		start = [self convertPoint:start fromSize:NSMakeSize(768, 1024) toSize:NSMakeSize(320, 480) scaleBy:0.5f];
		end   = [self convertPoint:end   fromSize:NSMakeSize(768, 1024) toSize:NSMakeSize(320, 480) scaleBy:0.5f];
		
//		start = [self convertPoint:start fromSize:CGSizeMake(1024, 768) toSize:CGSizeMake(480, 320) scaleBy:0.5f];
//		end   = [self convertPoint:end   fromSize:CGSizeMake(1024, 768) toSize:CGSizeMake(480, 320) scaleBy:0.5f];
		
	}
	
	// TASKS X send 1/2 point size
	//       X double received point size
	//       X transform received lines
	//         send opacity calculated for 1/2 point size
	//         modify received opacity for double point size
	//         make iPad's max point size double that of iPhone's (OPTIONAL)
	//         make connection bar wider on iPad (100%)
	//         do something about the Open button
	//         make it work in landscape (rotated)
	
	//
	// Credit: go2_ on irc.freenode.net
	//
	//CGRect cgRect = CGRectMake(start.x, start.y, end.x, end.y);
	NSString * nsRectString = [NSString stringWithFormat:@"{{%f,%f},{%f,%f}}", start.x, start.y, end.x, end.y];
	
	//[self send:NSStringFromRect(cgRect)];
	[self send:nsRectString];
	//}
}

- (void)sendBeginStroke {
	[self send:@"b}}"];
}

- (void)sendEndStroke {
	[self send:@"w}}"];
}

- (void)sendUndoRequest {
	[self send:@"u}}"];
}

- (void)sendRedoRequest {
	[self send:@"r}}"];
}

// For Preview
- (CGColorRef)myColor
{
	//CGFloat oldOpacity = components[3];
	//components[3] = 1.0f;
	
	CGFloat previewComponents[4];
	previewComponents[0] = components[0];
	previewComponents[1] = components[1];
	previewComponents[2] = components[2];
	//float c = components[3] + 1.0;
	//previewComponents[3] = c * (3.0 - 3.0 * c + c * c);
	//previewComponents[3] = components[3];
	
	previewComponents[3] = 1.0;//effectiveOpacity; //1.0 - powf(1.0 - components[3], (self.picker.previewArea.widthRadius * 2.0 / kBrushPixelStep)); // - 1.0
	
	//DLog(@"previewComponents[3]:%f", previewComponents[3]);
	
	CGColorRef newColor = CGColorCreate(CGColorSpaceCreateDeviceRGB(), previewComponents);
	//components[3] = oldOpacity;
	
	//DLog(@"myColor RGBA = %f %f %f %f", previewComponents[0], previewComponents[1], previewComponents[2], previewComponents[3]);
	
	return newColor;
	//return CGColorCreateGenericRGB(components[0], components[1], components[2], components[3]);
}

// This is used by the Color Spectrum (Color Picker)
- (void)setCGColor:(CGColorRef)color {
	const CGFloat *c = CGColorGetComponents(color);
	components[0] = c[0];
	components[1] = c[1];
	components[2] = c[2];
	// Notice the Color Picker tells us nothing about alpha (opacity)
	
	//	DLog(@"%s RGBA = %f %f %f %f", _cmd, components[0], components[1], components[2], components[3]);
	
	// Set the color in OpenGL
	[self setMyColor];
	
	// We won't send our color to our peer until the user hides the tools
	//[self.picker redrawPreview];
}

// This is used by the Color Spectrum (Color Picker)
- (void)setWhiteCGColor {
	components[0] = 1.0;
	components[1] = 1.0;
	components[2] = 1.0;
	components[3] = 1.0;

	// Set the color in OpenGL
	[self setMyColor];
	
	// We won't send our color to our peer until the user hides the tools
	//[self.picker redrawPreview];
}

- (void)setMyColor {
	[self setMyColorSend:YES];
}

- (void)setMyColorSend:(BOOL)send {
	//DLog(@"Setting active color to my color:%f, %f, %f, %f", components[0], components[1], components[2], components[3]);
	//glColor4f(components[0], components[1], components[2], components[3]);
	
	//if (usingRemotePointSize || usingRemoteColor) { // performance optimization
		[drawingView setColor:components];
		usingRemoteColor = NO;
	//}
	
	if (send) {
		// Send my color to my peer (includes opacity)
		// Future optimization: only do this when my color has changed
		[self sendMyColor];
	}
}

- (void)sendMyPointSize {
	[self send:[NSString stringWithFormat:@"s}}%f}}", [self pointSizeToSend]]];
}


- (CGFloat)pointSizeToSend {
	//CGFloat pointSizeToSend = _pointSize;
	if (remoteDevice != iPadDevice) { //[[UIScreen mainScreen] bounds].size.width == 768
		//pointSizeToSend = 0.5f * pointSizeToSend;
		return 0.5f * _pointSize;
	}
	return _pointSize;
	//return 1.0;
}

- (void) changeAndSendOpacity {
	[self.picker opacityChanged];
	
	if (!usingRemoteColor) {
		// NOTE: This is very important.
		// BUG: Doesn't update opacity on external screen.
		//glColor4f(components[0], components[1], components[2], components[3]);
		
		[self.drawingView setColor:components]; // BUG FIX
	}
	
	// Send to others
	[self sendMyColor];
}


- (void)changePointSize:(CGFloat)ps {
	//DLog(@"%f", ps);
	
	_pointSize = ps;
//	[self.picker setTabPointSize:_pointSize];
	[self sendMyPointSize]; // Send to others
	
	//
	//  Update opacity, which depends on pointSize.
	//  This also calls [picker opacityChanged];
	//
	[self changeAndSendOpacity];
}

- (ToolType) getMode {
	return _toolMode;
}

- (void) setMode:(ToolType)mode {
	_toolMode = mode;
}

- (void) changePointSize {
	[self changePointSize:[[CMColorPicker sharedColorSelector].brushSizeSlider floatValue]];
	
	//UISlider* slider = self.picker.pointSizeSlider;
	//glPointSize([slider value]);
}

// Modified by Hector Zhao starts
// Fix opacity range of Whiteboard MAC
- (void) setTrueColorAndOpacity:(CGFloat [])newComponents {
//	DLog(@"opacity: %f", newComponents[3]);
//	if (newComponents[3] > 0.8) {
//		DLog(@"KONG: error here");
//	}
	components[0] = newComponents[0];
	components[1] = newComponents[1];
	components[2] = newComponents[2];
	components[3] = newComponents[3];
}

- (CGFloat) getRedValue {
	return components[0];
}

- (CGFloat) getGreenValue {
	return components[1];
}

- (CGFloat) getBlueValue {
	return components[2];
}

- (CGFloat) getAlphaValue {
	return components[3];
}

- (CGFloat) getPointSize {
	return _pointSize;
}

// Fix Fullscreen image on connection iPhone to iMac
- (GSDevice) getRemoteDevice {
	return remoteDevice;
}
// Modified by Hector Zhao ends

-(IBAction)flipVertical:(id)sender {
	[drawingView rotate180Degree];
}

-(IBAction)brushSelectorReposition:(id)sender {
	if (isBrushSelectorHorizontal) {
		
		isBrushSelectorHorizontal = !isBrushSelectorHorizontal;

		DLog(@"change to vertical brush selector");
		
		[[self window] setFrame:NSMakeRect([self window].frame.origin.x, 
										   [self window].frame.origin.y + kPickerHeight, 
										   [self window].frame.size.width + kPickerHeight, 
										   [self window].frame.size.height -kPickerHeight) 
						display:YES animate:NO];
		
		// - (void)windowDidResize:(NSNotification *)notification will handle sub view repositioning
		
	} else {
		
		isBrushSelectorHorizontal = !isBrushSelectorHorizontal;

		DLog(@"change to horizontal brush selector");
		[[self window] setFrame:NSMakeRect([self window].frame.origin.x, 
										   [self window].frame.origin.y - kPickerHeight,
										   [self window].frame.size.width - kPickerHeight, 
										   [self window].frame.size.height + kPickerHeight) 
						display:YES animate:NO];
		
		// - (void)windowDidResize:(NSNotification *)notification will handle sub view repositioning
		
	}

}

#if LITE
- (BOOL)adContainerView:(BSAAdContainerView*)adContainerView shouldHandleClickOfAd:(BSAAd *)ad {
	return YES;
}
#endif

- (void)sendMyColorForPoint {
	// ForPoint means the opacity modification has already been considered
	
	//	CGPoint first2components = CGPointMake(components[0], components[1]);
	//	CGPoint second2components = CGPointMake(components[2], components[3]);
	
	// "c" means color
	[self send:@"c}}"];
	
	// Send the components as a CGRect
	//	[self sendLineFromPoint:first2components toPoint:second2components];
	CGRect cgRect = CGRectMake(components[0], components[1], components[2], components[3]);
	[self send:NSStringFromRect(NSRectFromCGRect(cgRect))];
}

- (void)sendMyColor {
	//DLog();
	
	//
	// iPad<->iPhone opacity conversion is taken care of in -pointSizeToSend
	//
	
	//CGFloat modifiedDiameter = [self pointSizeToSend] * 2.0f;
	
	if (protocolVersion == 1) {
		
		[self sendMyColorForPoint];
		
	} else {
		
		CGFloat temp[4];
		temp[0] = [NSAppDelegate getRedValue];
		temp[1] = [NSAppDelegate getGreenValue];
		temp[2] = [NSAppDelegate getBlueValue];
		temp[3] = [NSAppDelegate getAlphaValue];
		
		CGFloat opacity = temp[3];
		
		temp[3] = 1.0 - powf(1.0 - temp[3], 1.0 / (2.0 * [NSAppDelegate getPointSize]));
		
		[NSAppDelegate setTrueColorAndOpacity:temp];
		
		[self sendMyColorForPoint];
		
		temp[3] = opacity;
		[NSAppDelegate setTrueColorAndOpacity:temp];
	}
}

- (void)setRemotePointSize:(float)size {
	if (remoteDevice != iPadDevice) { //[[UIScreen mainScreen] bounds].size.width == 768
		size = size * 2.0f;
		DLog(@"%f", size);
	} else {
		DLog(@"%f", size);
	}
	
	remotePointSize = size;
	//DLog(@"remotePointSize %f", size);
	if (usingRemoteColor) {
		//
		// We may already be OnMainThread, but it doesn't hurt to make sure.
		//
		[self performSelectorOnMainThread:@selector(setRemoteColor) withObject:nil waitUntilDone:YES];
	}
}

- (void)receiveBeginStroke {
	[drawingView receiveBeginStroke];
}

- (void)receiveEndStroke {
	[drawingView receiveEndStroke];
}

-(void) receiveRedoRequest {
	[drawingView receiveRedoRequest];
}

- (void)receiveUndoRequest {
	[drawingView receiveUndoRequest];
}

- (void)displayProgressView:(BOOL)display {
	DLog();
}
- (void)updateProgressView:(float)progress {
	DLog();
}

@end
