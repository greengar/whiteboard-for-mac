//
//  AppController+TCPServerDelegate.m
//  Whiteboard
//
//  Created by Elliot Lee on 6/29/09.
//  Copyright 2010-2011 Greengar Studios. All rights reserved.
//

#import "WhiteboardMacAppDelegate+TCPServerDelegate.h"
//#import "Picker.h"


@implementation WhiteboardMacAppDelegate (TCPServerDelegate)

// Called after disconnect because devices re-enable Bonjour after disconnecting!
- (void)serverDidEnableBonjour:(TCPServer*)server withName:(NSString*)string {
	[self performSelectorOnMainThread:@selector(setServerName:) withObject:[string retain] waitUntilDone:YES];
//	[self setServerName:[string retain]];
}

- (void)setServerName:(NSString *)string {
	[string autorelease];
//	if (self.picker) {
//		self.picker.ownName = string;
//	} else {
//		DLog(@"!self.picker");
//		[self performSelector:@selector(setServerName:) withObject:[string retain] afterDelay:0];
//	}
	
	self.ownName = [string retain];
//	[self performSelector:@selector(setServerName:) withObject:[string retain] afterDelay:0];
}

// Executes on the server (the device whose name gets tapped - the "host")
- (void)didAcceptConnectionForServer:(TCPServer*)server inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr {
	//
	//  o [_inStreams count] and [_outStreams count] tell us how many connections are currently established
	//  o _server tells us which server we're connected to.
	//  o We should check these values if we're going to support more than 2 peers
	//
	
	// Add istr and ostr to their respective NSMutableArrays
	[_inStreams addObject:istr];
	[_outStreams addObject:ostr];
	
	// Open the streams
	[self openInStream:istr withOutStream:ostr];
	
	// Set the flag that indicates there is a pending join request
	pendingJoinRequest = YES;
}


@end
