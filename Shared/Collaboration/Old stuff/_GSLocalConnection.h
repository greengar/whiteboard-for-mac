//
//  GSLocalConnection.h
//  Whiteboard
//
//  Created by Cong Vo on 12/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BrowserViewController.h"
#import "TCPServer.h"
#import "AcceptReject.h"
#import "GSConnection.h"

@class GSConnectionController;
@class GSLocalWhiteboard;

@interface GSLocalConnection : NSObject <GSConnection, BrowserViewControllerDelegate, TCPServerDelegate, NSStreamDelegate> {

	@public
	
	TCPServer*			_server;
	NSMutableArray*		_inStreams;
	NSMutableArray*		_outStreams;
	BOOL				_inReady;
	BOOL				_outReady;
//	BOOL				initializedWithPeers;

	BOOL				needToSendName;  // make sure to send name (in stream-available method) once
	BOOL				pendingJoinRequest;
	NSThread*			inStreamThread;

	NSMutableDictionary *namesForStreams;
	
//	AcceptReject* _acceptReject;	
//	UIAlertView* acceptRejectAlertView;
	
	
	

	
// image	
//	BOOL sendingRemoteImage;
//	BOOL receivingRemoteImage;
	

	BOOL peerReadyToReceive; 	// check if I can start to send to friend
	
	
//write
	NSString* writeBuffer;

//remote
	
	
	//view
	BrowserViewController *_bvc;
//	id<BrowserViewControllerDelegate> bvcDelegate;
	
	BOOL _didSendConnectionRequest;
	
}

//@property (nonatomic, retain) NSMutableArray* outStreams;
//@property (nonatomic, assign) BOOL receivingRemoteImage, sendingRemoteImage;
//@property (nonatomic, retain) NSMutableDictionary *namesForStreams;

#pragma mark TODO: BrowserViewController & connectionController
//@property (nonatomic, assign) id<BrowserViewControllerDelegate> bvcDelegate;
@property (nonatomic, retain) BrowserViewController *bvc;

@property (nonatomic, retain) NSMutableArray *outStreams, *inStreams;
@property (nonatomic, retain) NSMutableDictionary *namesForStreams;
@property (nonatomic, readonly) NSThread*			inStreamThread;


@property (nonatomic, assign) BOOL peerReadyToReceive;
@property (nonatomic, assign) BOOL didSendConnectionRequest;


- (void)closeConnection;

- (void)enterBackground;
- (void)enterForeground;


//- (NSUInteger)streamCount;
//- (NSUInteger)outStreamCount;




- (void)send:(NSString*)message;
- (void)send:(NSString *)message toOutStream:(id)destination;
- (void)sendLargeDataByChunks:(NSString*)message identifier:(NSString*)sendID;

//- (NSString *)getServerName;

//- (void) acceptPendingRequest:(NSUInteger)response withName:(NSString*)name;
- (void) openInStream:(NSInputStream*)_inStream withOutStream:(NSOutputStream*)_outStream;

#pragma mark Refactoring stuff
- (void)showNetworkError:(NSString*)title;


//- (void)sendRejectMessageAndCloseAllStreamsFrom:(NSString *)name;
- (BOOL)disconnectFromPeerWithStream:(NSStream *)stream;
- (void)initializeWithPeersIfNecessaryWithSource:(id)source;
- (NSUInteger)streamCount;
- (NSUInteger)outStreamCount;
- (void)receivedDisconnectedMessageFrom:(id)stream;
- (NSOutputStream *)outStreamWithInStream:(NSInputStream *)inStream;
- (void)restartServer;
- (BOOL)sendMessage:(NSString *)message toPeerWithInStream:(id)stream;
- (void)removeAllStreamsExceptStreamsInWhiteboard:(GSLocalWhiteboard *)whiteboard;
- (void)sendRejectMessageToPeerWithInStream:(id)stream;
@end
