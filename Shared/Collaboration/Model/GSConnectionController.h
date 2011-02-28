//
//  GSConnectionController.h
//  Whiteboard
//
//  Created by Cong Vo on 12/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>

#import "GSWhiteboard.h"
#import "GSAlert.h"

#if INTERNET_INCLUDING
	#import "XMPP.h"
	@class GSInternetConnection;
#endif

#if !TARGET_OS_IPHONE
	#define IS_IPAD 0
#endif

//@class AcceptReject;
@class GSConnectViewController;
@class CMAlertTableDialog;
@class GSLocalConnection;


@class GSConnectionAlertManager;

extern BOOL USE_HEX_STRING_IMAGE_DATA; // currently always YES


// The Bonjour application protocol, which must:
// 1) be no longer than 14 characters
// 2) contain only lower-case letters, digits, and hyphens
// 3) begin and end with lower-case letter or digit
// It should also be descriptive and human-readable
// See the following for more information:
// http://developer.apple.com/networking/bonjour/faq.html
#define kGameIdentifier		@"whiteboard"

#define SUPPORT_CONNECTION_IN_BACKGROUND 0



typedef enum ConnectionStatus {
	ConnectionStatusNotYetConnected,
	ConnectionStatusInConnecting,
	ConnectionStatusConnected
} ConnectionStatus;


@interface GSConnectionController : NSObject {
	
	@public
	
	GSLocalConnection *_localConnection;
#if INTERNET_INCLUDING	
	GSInternetConnection  *_internetConnection;	
#endif	
	
#if TARGET_OS_IPHONE	
	GSConnectViewController *_connectionView;
#else
	CMAlertTableDialog *_connectionView;
#endif	
	
	BOOL amServer;
	BOOL _isConnectingConflict;
	
	
	/*
	 - What new in protocol 2?
	 - Transfer image
	 - Change distance of 2 nearby circle in a line from 2 -> 1. If affects the opacity
	 - 
	 
	 */
	int protocolVersion;
	
	
//	NSMutableArray *_inStreams;
//	NSMutableArray *_outStreams;
	
//	NSMutableDictionary *namesForStreams;
	

	// image
	NSString *_imageHexString;	
	
	BOOL sendingRemoteImage;
	BOOL receivingRemoteImage;
//	BOOL peerReadyToReceive;
	
	// SHERWIN:
	// Message Type: Image Hex Data
	// These are image transfer variables
	int imageDataSize;
	
	// view
	
	
//	AcceptReject* _acceptReject; // used to ask user when receive a connection request
	
//	UIAlertView* acceptRejectAlertView;

	BOOL initializedWithPeers; // to make sure we just need to call initializeWithPeer method once
	
	
	// step 3 - moving all into connection controller
	// Message Type: Point Size (s) //
	BOOL receivingRemotePointSize;
//	CGFloat remotePointSize;
	BOOL receivingRemoteColor;

	
	// Message Type: Name (n) //
	BOOL receivingRemoteName;
	
	
	
	
	BOOL receivingSpray;
	BOOL receivingText;
	BOOL receivingTextFont;
	BOOL receivingTextSize;
	BOOL receivingTextPosition;
	
	
	GSWhiteboard *_connectedWhiteboard;
	
//	GSWhiteboard *_pendingWhiteboard; 
	
	
	GSWhiteboard *_waitedWhiteboard; // peer that i sent connected request, and am waiting for response
	GSWhiteboard *_requestingWhiteboard; // peer that sent me a connection request
	
	ConnectionStatus _status;
	
	
	GSWhiteboard *_nextWhiteboard;
		
	GSConnectionAlertManager *_alertManager;
	
//	NSThread *_connectionThread;
	
#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
	//KONG: Multitasking 
	UIBackgroundTaskIdentifier _backgroundTask;
#endif
	
}

@property (nonatomic, assign) ConnectionStatus status;

@property (nonatomic, readonly) GSLocalConnection *localConnection;
@property (nonatomic, retain) GSWhiteboard *connectedWhiteboard, *waitedWhiteboard, *requestingWhiteboard, *nextWhiteboard;

@property int protocolVersion;


@property (nonatomic, retain) NSString *imageHexString;
@property (nonatomic, assign) BOOL receivingRemoteImage, sendingRemoteImage;


@property (nonatomic, readwrite) BOOL receivingRemoteColor;
@property (nonatomic, readwrite) BOOL receivingRemotePointSize;
@property (nonatomic, readwrite) BOOL receivingRemoteName;


#if TARGET_OS_IPHONE	
@property (nonatomic, retain) GSConnectViewController *connectionView;
#else
@property (nonatomic, retain) NSWindow *connectionView;
#endif


#if INTERNET_INCLUDING
@property (nonatomic, retain) GSInternetConnection *internetConnection;
#endif

//@property (nonatomic, retain) NSThread *_connectionThread;

- (id)init;
- (BOOL)isConnected;
// start tcp server & xmpp
- (void)startToConnect;
- (void)stopConnecting;

//- (void)enterForeground;
//- (void)enterBackground;


- (void)initateSessionWithWhiteBoard:(id <GSWhiteboard>)wb;




- (void)send:(NSString *)message;
- (void)processMessage:(NSString *)message source:(id)source;
- (void)receivedMessages:(NSArray *)messages;


- (void)initiateImageTransfer:(NSString*)imageHex;
- (void)stopImageTransfer;

//- (void) acceptPendingRequest:(NSUInteger)response withName:(NSString*)name;


#pragma mark Refactor stuff
- (void) sendImageHexData:(NSString*)imageData;

- (BOOL)peerSupportsImageTransfer;

//@property (nonatomic, retain) AcceptReject* acceptReject;
@property (nonatomic, assign) BOOL amServer;


//- (void)receivedConnectionRequestFrom:(id <GSWhiteboard>)whiteboard;
//- (void)userAcceptedConnectionRequest;

// NotYetConnected
- (void)receivedConnectionRequestInNotYetConnected:(id <GSWhiteboard>)requester
										 showAlert:(BOOL)willShow;
// Connecting
- (void)receivedRejectedMessageInConnectingFromWaitedWhiteboardShowAlert:(BOOL)willAlert; // [2.2]
- (void)receivedConnectionRequestInConnecting:(GSWhiteboard *)requester;
// Connected


- (void)receivedAcceptedMessageFrom:(GSWhiteboard *)sender;
- (void)initiateConnection;
- (void)userSelectedWhiteboard:(GSWhiteboard *)selectedWhiteboard;
- (BOOL)receivedPeerUnavailableSignalFrom:(GSWhiteboard *)sender;
- (BOOL)receivedDisconnectedMessageFrom:(GSWhiteboard *)sender;
- (void)receivedAcceptedMessageInConnectingWaitingFrom:(GSWhiteboard *)sender;

- (GSWhiteboard *)whiteboard:(NSString *)name source:(id)source;
- (BOOL)isWhiteboard:(GSWhiteboard *)whiteboard usingSource:(id)source;
- (void)userAcceptedConnectionRequestInConnectingRequesting;
- (void)rejectedSilentlyConnectionRequest:(GSWhiteboard *)requester;
- (void) showRequestAcceptedAlert;
- (void)receivedNetworkUnavailableSignal:(GSConnectionType)networkType;
- (BOOL)isWhiteboard:(GSWhiteboard *)sender identicalWith:(GSWhiteboard *)current;
- (void)finishSendingImageHexData;

- (void)didFinishLaunching;
- (void)willTerminate;
#if TARGET_OS_IPHONE
	//KONG: multitasking
- (void)willResignActive;
- (void)didEnterBackground;
- (void)willEnterForeground;
- (void)didBecomeActive;


// Greengar ID
- (NSString *)greengarUsername;
- (NSString *)greengarPassword;
#endif

- (void)initiateStartOver;
@end
