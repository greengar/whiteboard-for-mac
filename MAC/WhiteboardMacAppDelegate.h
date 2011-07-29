//
//  WhiteboardMacAppDelegate.h
//  WhiteboardMac
//
//  Created by Silvercast on 11/4/10.
//  Copyright 2010-2011 Greengar Studios. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MainPaintingView.h"
#import "TCPServer.h"
#import "Wrapper.h"
#import "BrushPickerPanel.h"
#import "CMColorPicker.h"
#import "CMAlertTableDialog.h"
#import "GSConnectionController.h"
#import "GSAlert.h"
#import "MAAttachedWindow.h"

#if LITE
	#import "Framework/Classes/BSAAdFramework.h"
#endif

#define kiPadMessage      @"i"
#define kBrushPixelStep	  1.0
#define kDefaultPointSize 9.0
#define kAlertIcon        @"Whiteboard.icns"

#define NSAppDelegate     ((WhiteboardMacAppDelegate *)[NSApplication sharedApplication].delegate)
#define AppDelegate			((WhiteboardMacAppDelegate *)[NSApplication sharedApplication].delegate)

typedef enum {
	kNormalMsg   = 0,
	kOpacityMsg
} MsgType;

typedef enum {
	iPhoneDevice = 0,
	iPodTouchDevice,
	iPadDevice
} GSDevice;

typedef enum {
	normalMode = 0,
	panMode,
	zoomInMode,
    zoomOutMode
} ToolType;

@class Picker;

@interface WhiteboardMacAppDelegate : NSObject <NSApplicationDelegate, TCPServerDelegate, NSStreamDelegate, NSToolbarDelegate, NSWindowDelegate
#if LITE
, BSAAdContainerViewDelegate
#endif
> {
    NSWindow *			window;
	
#if LITE
	//BuySellAds
	BSAAdContainerView *adContainerView1;
#endif
	
	
	IBOutlet NSToolbarItem  * undoToolbarItem;
	IBOutlet NSToolbarItem  * redoToolbarItem;
    IBOutlet NSToolbarItem  * panToolbarItem;
    IBOutlet NSToolbarItem  * zoomInToolbarItem;
    IBOutlet NSToolbarItem  * zoomOutToolbarItem;
	IBOutlet NSToolbarItem  * networkToolbarItem;
	IBOutlet CMAlertTableDialog * customAlertTableDialogWindow;
    IBOutlet NSMenuItem     * fullscreenMenuItem;
    
    
	NSText                  * connectedDeviceName;
	NSImageView             * bannerView;
	NSImageView             * customColorPickerBackground;
	NSString                * ownName;
	
	Picker                  * _picker;
	CMColorPicker           * customColorPicker;
	MAAttachedWindow        * customColorPickerWindow;
    MAAttachedWindow        * pickerWindow;
    MAAttachedWindow        * bannerWindow;
	
	MainPaintingView        * drawingView;
	ToolType                _toolMode;
	
	CGFloat                 _pointSize; // always MY pointSize
	
	// Message Type: Point Size (s) //
	BOOL                    receivingRemotePointSize;
	CGFloat                 remotePointSize;
	BOOL                    usingRemotePointSize;
	BOOL                    needToSendName;
	BOOL                    pendingJoinRequest;
	BOOL                    sendingRemoteImage;
	BOOL                    receivingRemoteColor;
	CGFloat                 components[4];
	BOOL                    receivingRemoteName;

	int                     imageDataSize;
	BOOL                    receivingRemoteImage;
	BOOL                    peerReadyToReceive;
	NSString                * imageHexString;
	
	NSString                * writeBuffer;
	int                     protocolVersion;
	GSDevice                remoteDevice;

	float                   toolbarHeight;
	
	NSWindow                * brushPanel;
	NSAlert                 * imageSendTransferAlert;
	NSView                  * contentView;
	BOOL                    isBrushSelectorHorizontal;
	BOOL                    isCustomColorPickerOn;
	
	GSConnectionController *_connection;
@public	
	CGFloat                 remoteComponents[4];
	CGFloat                 remoteTrueOpacity;
	BOOL                    usingRemoteColor;	
	
}

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic,retain) NSWindow *brushPanel;
@property (nonatomic, readonly) MainPaintingView *drawingView;
#if LITE
@property (nonatomic, retain) BSAAdContainerView *adContainerView1;
#endif
@property (nonatomic) CGFloat pointSize;
@property (nonatomic, readwrite) BOOL usingRemotePointSize;
@property (nonatomic, readwrite) BOOL usingRemoteColor;
@property (assign              ) Picker *picker; // nonatomic?
@property (nonatomic, retain) NSWindow *customColorPickerWindow;
@property (nonatomic, retain) CMAlertTableDialog *customAlertTableDialogWindow;
@property (nonatomic) BOOL isCustomColorPickerOn;
@property (nonatomic, copy)		NSString				*ownName;
@property (nonatomic, retain) NSString *imageHexString;
@property (nonatomic, retain) GSConnectionController *connection;

- (void)showColorPicker:(NSColor*)chosenColor;
- (void)updateCustomColorPickerLocation;
- (void)closeCustomColorPickerLocation;
- (void)adjustPickerWindowHorizontal:(BOOL)horizontal;
- (void)adjustBannerWindowHorizontal:(BOOL)horizontal;
// Toolbar button
-(IBAction)networking:(id)sender;
-(IBAction)save:(id)sender;
-(IBAction)open:(id)sender;
-(void)openFile:(NSString*)filePath;
-(IBAction)transferDrawing:(id)sender;
-(IBAction)undo:(id)sender;
-(IBAction)redo:(id)sender;
-(IBAction)startOver:(id)sender;
-(IBAction)pan:(id)sender;
-(IBAction)zoomIn:(id)sender;
-(IBAction)zoomOut:(id)sender;
-(IBAction)flipVertical:(id)sender;
-(IBAction)brushSelectorReposition:(id)sender;
-(IBAction)toggleFullscreenDrawing:(id)sender;
-(IBAction)cancelConnection:(id)sender;

- (void)send:(NSString*)message;
- (NSPoint)convertPoint:(NSPoint)p fromSize:(NSSize)f toSize:(NSSize)t scaleBy:(CGFloat)s;

- (void)sendBeginStroke;
- (void)sendEndStroke;
- (void)sendUndoRequest;
- (void)sendRedoRequest;
- (void)sendLineFromPoint:(NSPoint)start toPoint:(NSPoint)end;
- (void)sendMyPointSize;

- (void) changePointSize;
- (void)changePointSize:(CGFloat)ps;

- (void)startOverAlert;
- (ToolType)getMode;
- (void)setMode:(ToolType) mode;

// Fix opacity range of Whiteboard MAC
- (void)setTrueColorAndOpacity:(CGFloat [])newComponent;
- (CGFloat) getRedValue;
- (CGFloat) getGreenValue;
- (CGFloat) getBlueValue;
- (CGFloat) getAlphaValue;
- (CGFloat) getPointSize;

// Fix Fullscreen image on connection iPhone to iMac
- (GSDevice) getRemoteDevice;

- (CGFloat)pointSizeToSend;
- (CGColorRef)myColor;
- (void)setCGColor:(CGColorRef)color;
- (void)setWhiteCGColor;
- (void)setMyColor;
- (void)setMyColorSend:(BOOL)send;


// Connection Bar
- (void)setConnectedDeviceName:(NSString*)name;
- (void)clearConnectedDeviceName;


	//KONG: refactoring 
//@property (nonatomic, assign) int runCount;
@property (nonatomic, assign) GSDevice remoteDevice;

- (void)sendMyColorForPoint;
- (void)sendMyColor;
- (void)sendMyPointSize;

- (void)setRemotePointSize:(float)size;
- (void)receiveBeginStroke;
- (void)receiveEndStroke;
- (void)receiveRedoRequest;
- (void)receiveUndoRequest;
- (void)acceptStartOverRequest;

- (void)displayProgressView:(BOOL)display;
- (void)updateProgressView:(float)progress;
- (void)networkingEnableDidChange:(BOOL)isEnabled;

@end
