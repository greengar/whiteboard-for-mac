//
//  GSLocalConnection+TCPServerDelegate.m
//  Whiteboard
//
//  Created by Cong Vo on 1/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GSLocalConnection+TCPServerDelegate.h"

#import "Picker.h"
#import APP_DELEGATE
#import "GSConnectionController.h"
#import "GSLocalWhiteboard.h"

@implementation GSLocalConnection(TCPServerDelegate)
// Called after disconnect because devices re-enable Bonjour after disconnecting!
- (void)serverDidEnableBonjour:(TCPServer*)server withName:(NSString*)string {
	[self performSelectorOnMainThread:@selector(setServerName:) withObject:[string retain] waitUntilDone:YES];
	//	[self setServerName:[string retain]];
}

- (void)setServerName:(NSString *)string {
	[string autorelease];
	// TODO: KONG: refactor these ownName, my name
	[self.bvc setOwnName:string];
	self.myName = string;
#if TARGET_OS_IPHONE	
	if (AppDelegate.picker) {
		
		// TODO: check for appropriate method for internet
		AppDelegate.picker.ownName = string;
	} else {
		ALog(@"!self.picker");
		[self performSelector:@selector(setServerName:) withObject:[string retain] afterDelay:0];
	}
	
#else
	AppDelegate.ownName = [string retain];
#endif	
}

// Executes on the server (the device whose name gets tapped - the "host")
- (void)didAcceptConnectionForServer:(TCPServer*)server inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr {
	DLog(@"inputStream: %@ outputStream: %@", istr, ostr);
	
	GSLocalWhiteboard *newPeer = [[[GSLocalWhiteboard alloc] initWithInStream:istr
																   outStream:ostr] autorelease];
	
	if (_serverConnectedPeers == nil) {
		self.serverConnectedPeers = [NSMutableArray array];
	}
	[_serverConnectedPeers addObject:newPeer];
	
	//
	//  o [_inStreams count] and [_outStreams count] tell us how many connections are currently established
	//  o _server tells us which server we're connected to.
	//  o We should check these values if we're going to support more than 2 peers
	//
/*	
	// Add istr and ostr to their respective NSMutableArrays
	[_inStreams addObject:istr];
	DLog(@"instreams added: %@", istr);
	[_outStreams addObject:ostr];
	
	// Open the streams
	[self openInStream:istr withOutStream:ostr];
	
	// Set the flag that indicates there is a pending join request
	pendingJoinRequest = YES;
 
 */
}


@end


