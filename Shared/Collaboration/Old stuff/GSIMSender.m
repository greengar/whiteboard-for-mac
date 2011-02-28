//
//  GSIMSender.m
//  iPhoneXMPP
//
//  Created by Cong Vo on 12/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GSIMSender.h"
#import "GSInternetXMPPConnection.h"

const float sendingInterval = 1.0f;

NSString * const GSIMSenderMessageDelimiter = @";";

@implementation GSIMSender
@synthesize messageQueuer = _messageQueuer, networkDelegate = _networkDelegate;

- (id)initWithNetworkDelegate:(id <GSIMSenderDelegate>)delegate {
	if ((self = [super init])) {
		_networkDelegate = delegate;	
		_messageQueuer = [[NSMutableArray alloc] init];
	}
	return self;
}


- (void)dealloc {
	[_messageQueuer release];
	[super dealloc];
}




- (NSString *)mergeAllMessagesInQueue {
	return [GSInternetXMPPConnection mergeAllString:self.messageQueuer
									   usingDelimiter:GSIMSenderMessageDelimiter];
}

- (void)startToSendMessage {
	// trigger timer sending message
	if ([self.messageQueuer count] > 0) {
		// get all message
		NSString *mergedMessage = [self mergeAllMessagesInQueue];
		
		// remove all message in queue
		[self.messageQueuer removeAllObjects];
		
		// tell network sender to do network sending job
		if ([mergedMessage length] > 0) {
			[self.networkDelegate IMSender:self triggerToSendMessage:mergedMessage];			
		}
	}
		 
	// timer
	[self performSelector:@selector(startToSendMessage) withObject:nil afterDelay:sendingInterval];
}

- (void)stopSendingMessage {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startSendingMessage) object:nil];
}

- (void)sendMessage:(NSString *)message {	
	// add to queue
	[_messageQueuer addObject:message];
	
}


+ (NSArray *)commandStringsFromString:(NSString *)commandsString {
	return [commandsString componentsSeparatedByString:GSIMSenderMessageDelimiter];
}

@end
