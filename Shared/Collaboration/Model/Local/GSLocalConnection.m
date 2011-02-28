//
//  GSLocalConnection.m
//  Whiteboard
//
//  Created by Cong Vo on 1/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GSLocalConnection.h"
#import "GSLocalWhiteboard.h"
#import APP_DELEGATE
#import "GSConnectionController.h"
#import "GSLocalConnection+TCPServerDelegate.h"
#import "GSLocalWhiteboard+NSStreamDelegate.h"

@interface GSLocalConnection()

@end

@implementation GSLocalConnection
@synthesize server = _server;
@synthesize bvc = _bvc;
@synthesize streamThread = _streamThread;

@synthesize serverConnectedPeers = _serverConnectedPeers;
@synthesize myName = _myName;

#pragma mark Utilities

- (void)showNetworkError:(NSString*)title {
	GSAlert *alertView = [GSAlert alertWithDelegate:nil
											  title:title
											message:@"Check your networking configuration."
									  defaultButton:@"OK"
										otherButton:nil];
	[alertView show];
}



- (GSConnectionType)type {
	return GSConnectionTypeLocal;
}

#pragma mark Broadcasting/Multitasking

- (void)startToConnect {
	//[self create];
	self.streamThread = [[[NSThread alloc] initWithTarget:self
											 selector:@selector(createStreamThread)
											   object:nil] autorelease];	
	[_streamThread start];
	
	

}
// This executes inStreamThread
- (void)createStreamThread {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// check for current status
	// Destroy any existing server
	self.server = [TCPServer new];
	[_server setDelegate:self];
	
	
	NSError* error;
	if(_server == nil || ![_server start:&error]) {
		DLog(@"Failed creating server: %@", error);
		[self showNetworkError:@"Failed creating server"];
		return;
	}

	[_bvc startToBrowsing];
#if !TARGET_OS_IPHONE	
	[self startToBroadcast];
#endif	
	// Kick off the RunLoop
	[[NSRunLoop currentRunLoop] run];
	
	DLog(@"inStreamThread pool release");
	[pool release];
}


- (void)performInStreamThreadSelector:(SEL)selector withObject:(id)object wait:(BOOL)willWait {
	[self performSelector:selector onThread:_streamThread
			   withObject:object waitUntilDone:willWait];
}


- (void)startToBroadcast {
	RUN_IN_STREAM_THREAD
	
//	if ([_server isStopped] == NO) {
//		return;
//	}
	
	
	//Start advertising to clients, passing nil for the name to tell Bonjour to pick use default name
	if(![_server enableBonjourWithDomain:@"local" applicationProtocol:[TCPServer bonjourTypeFromIdentifier:kGameIdentifier] name:nil]) {
		[self showNetworkError:@"Failed advertising server"];
		return;
	}
	
	DLog();
	// Check if we already broadcast
	
	// Advertise a new whiteboard and discover other available whiteboards
	/*
	 Make sure to let the user know what name is being used for Bonjour advertisement.
	 This way, other players can browse for and connect to this game.
	 Note that this may be called while the alert is already being displayed, as
	 Bonjour may detect a name conflict and rename dynamically.
	 Note that it is also called after disconnect, because devices then begin advertising again.
	 */	
}

- (void)stopBroadcasting {
	RUN_IN_STREAM_THREAD
	// stop broadcasting on Bonjour		
	[_server disableBonjour];
//	[_server stop];
//	self.server = nil;
	DLog();
}

- (void)stopConnecting {
	[self stopBroadcasting];
	
	[_bvc stopBrowsing];
	[_server stop];	
	self.server = nil;
	
	
	[_streamThread cancel];
	self.streamThread = nil;
	DLog();	
}

#pragma mark sending message

- (void)send:(NSString *)message toWhiteboard:(GSWhiteboard *)whiteboard {
	if (whiteboard.type == GSConnectionTypeLocal) {
		[(GSLocalWhiteboard *) whiteboard send:message];
	}
}

// using buffer
- (void)sendToConnectedWhiteboard:(NSString *)message {
	[self send:message toWhiteboard:AppDelegate.connection.connectedWhiteboard];
}

- (void)solveConflictWhenReceiveConnectionRequest:(GSWhiteboard *)requester {
	//KONG: connecting and conflict in A
		
	// I'm trying to connect to a peer who's trying to connect to me
	
	
	//KONG: Am I already resolved and sent my request?
	// If NO: so I should not resolve it. I cancel my request.
	GSLocalWhiteboard *myWaitedWhiteboard = (GSLocalWhiteboard *)AppDelegate.connection.waitedWhiteboard;
	
	DLog(@"conflict check: isResolved: %d, didSendConnectionRequest: %d", 
		 myWaitedWhiteboard.isResolved, myWaitedWhiteboard.didSendConnectionRequest);
	
	if (myWaitedWhiteboard.isResolved == NO 
		|| myWaitedWhiteboard.didSendConnectionRequest == NO) {
		DLog(@"Conflict solved: I haven't sent request yet. I canceled it");
		[myWaitedWhiteboard disconnect];
		AppDelegate.connection.waitedWhiteboard = nil;
		[AppDelegate.connection receivedConnectionRequestInNotYetConnected:requester showAlert:YES];
		return;
	}
	
	//KONG: based on order of name to solve conflict
	// this has downside when names are the same
	
	// NSOrderedAscending if the receiver precedes aString
	// NSOrderedDescending if the receiver follows aString
	
	//KONG: connecting and conflict in B
	// follow the assumption above, A's name < B's name, and this code run in B
	// B should be the server
	if ([[_bvc ownName] compare:requester.name] == NSOrderedAscending) {
		DLog(@"Conflict resolution: I'll be the server");
/*
		********* [GOTO] receive Connection Reject from B (not display alert)
		********* [GOTO] receive connection request from friend
		********* [GOTO] user Accepted connection request
*/
		[AppDelegate.connection receivedRejectedMessageInConnectingFromWaitedWhiteboardShowAlert:NO];
		[AppDelegate.connection receivedConnectionRequestInNotYetConnected:requester showAlert:NO];
		[AppDelegate.connection userAcceptedConnectionRequestInConnectingRequesting];
		[AppDelegate.connection showRequestAcceptedAlert];
	}
	else {	
		DLog(@"Conflict resolution: I'll be the client");
		[AppDelegate.connection receivedConnectionRequestInConnecting:requester];
	}
}

#pragma mark Stream
- (BrowserViewController *)bvc {
	if (_bvc == nil) {
		_bvc = [[BrowserViewController alloc] init];
		[_bvc startToBrowsing];
	}	
	return _bvc;
}

- (GSLocalWhiteboard *)peerForInstream:(NSStream *)stream {
	GSLocalWhiteboard *returnWB = nil;
	for (GSLocalWhiteboard *peer in _serverConnectedPeers) {
		if (peer.inStream == stream) {
			returnWB = peer;
			//break;
		}
	}
	[returnWB retain];
	[_serverConnectedPeers removeObject:returnWB];
	return [returnWB autorelease];
}

@end
