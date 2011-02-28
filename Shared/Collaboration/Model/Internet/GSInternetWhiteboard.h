//
//  GSInternetWhiteboard.h
//  Whiteboard
//
//  Created by Cong Vo on 1/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPP.h"
#import "GSWhiteboard.h"

@interface GSInternetWhiteboard : GSWhiteboard {
	
	// XMPP
	XMPPJID *_jid;
	// buffer
	BOOL _isWaitingAcknowlegment;
	NSMutableString *_buffer;
}

@property (nonatomic, retain) XMPPJID *jid;
@property (nonatomic, retain) NSMutableString *buffer;
- (id)initWithJID:(XMPPJID *)jid;
- (BOOL)receivedIQ:(XMPPIQ *)iq;
- (void)receivedMessage:(NSString *)message;

- (void)sendAnEmptyAcknowledgement;
- (void)sendBuffer;

- (void)resetStateForNewConnection;

@end

