//
//  GSInternetWhiteboard.m
//  Whiteboard
//
//  Created by Cong Vo on 1/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GSInternetWhiteboard.h"
#import "GSWhiteboard.h"
#import "GSWhiteboardUser.h"
#import "GSInternetConnection.h"
#import "AppController.h"
#import "GSConnectionController.h"

@interface GSInternetWhiteboard()
- (void)sendMessageInstantly:(NSString *)body;

@end


@implementation GSInternetWhiteboard
@synthesize jid = _jid;
@synthesize buffer = _buffer;

static GSInternetConnection *connection = nil;
static XMPPStream *stream = nil;
- (id)initWithName:(NSString *)name {
	if ((self = [super initWithName:name])) {
		_type = GSConnectionTypeInternet;
		//		_connection = (id <GSConnection>)UIAppDelegate.connection.internetConnection;
		
		// other setting 
		_buffer = [[NSMutableString string] retain];
		_isWaitingAcknowlegment = NO;
		
		if (connection == nil) {
			connection = UIAppDelegate.connection.internetConnection;
		}
		if (stream == nil) {
			stream = connection.xmppStream;
		}
		
	}
	return self;
}

- (id)initWithJID:(XMPPJID *)jid {
	if ((self = [self initWithName:[GSWhiteboardUser displayNameFromJID:jid]])) {
		_jid = [[XMPPJID jidWithUser:jid.user domain:jid.domain resource:@"wb-ip"] retain];
	}
	return self;
}

- (id <GSConnection>)connection {
	return connection;
}

- (GSConnectionType)connectionType {
	return GSConnectionTypeInternet;
}

- (id)source {
	return _jid;
}


- (void) dealloc {
	[_jid release];
	[super dealloc];
}


- (NSString *)description {
	return [NSString stringWithFormat:@"%@; xmppJID: %@", [super description], [_jid bare]];
}

- (void)initiateConnection {
    // send an initiate iq
//	NSString *fromString = [stream.myJID bare];	
//	XMPPIQ *ack = [XMPPIQ iqWithType:@"init" to:_jid elementID:nil];
//	[stream sendElement:ack];
}

- (void)sendDisconnectMessage {
    [self sendMessageInstantly:@"disconnect}}"];
}

- (void)disconnect {
	[self resetStateForNewConnection];
	[connection removeCacheOfPeer:self];
	//KONG: no action for internet connection 
}

#pragma mark Streamming

- (BOOL)receivedIQ:(XMPPIQ *)iq {
	_isWaitingAcknowlegment = NO;
	[self sendBuffer];
	return YES;
}

- (void)receivedMessage:(NSString *)message {
	[self sendAnEmptyAcknowledgement];
	[UIAppDelegate.connection processMessage:message source:self];
}

- (void)send:(NSString *)message {
	//	[connection sendToConnectedWhiteboard:message];
	
	[_buffer appendString:message];		
	
	if (_isWaitingAcknowlegment == NO) {
		[self sendBuffer];
	}
//	NSLog(@"buffer msg: %@", message);
}

#pragma mark XMPP


//- (XMPPStream *)stream {
//	if (stream == nil) {
//		stream = connection.xmppStream;
//	}
//	return stream;
//}

- (void)sendMessageInstantly:(NSString *)body {
	NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
	
	// header
	//XMPPJID *myJID = [[self xmppStream] myJID];
	//	XMPPJID *toJID = self.connectedWhiteboard.jid;
	//	NSString *fromString = [NSString stringWithFormat:@"%@@%@/%@", [myJID user], [myJID domain], [myJID resource]];
//	NSString *fromString = [stream.myJID full];
	//	NSString *toString = [NSString stringWithFormat:@"%@@%@/%@", [toJID user], [toJID domain], [toJID resource]];	
	NSString *toString = [_jid full];
	
	
//	[message addAttributeWithName:@"from" stringValue:fromString];
	[message addAttributeWithName:@"to" stringValue:toString];
	
	// body
	
	NSXMLElement *bodyElement = [[[NSXMLElement alloc] initWithName:@"body" 
														stringValue:body] autorelease];	
	
	[message addChild:bodyElement];
	[stream sendElement:message];	
}

- (void)sendBuffer {
    DLog();
	
	if ([_buffer length] == 0) {
		return;
	}
	[self sendMessageInstantly:_buffer];
	
	// reset buffer
	_isWaitingAcknowlegment = YES;
	self.buffer = [NSMutableString string];
}

- (void)sendAnEmptyAcknowledgement {
	// send an emply iq
//	NSString *fromString = [stream.myJID bare];	
//	XMPPIQ *ack = [XMPPIQ iqWithType:@"result" to:_jid elementID:@"112233"];
//	[ack addAttributeWithName:@"from" stringValue:fromString];
    
	XMPPIQ *ack = [XMPPIQ iqWithType:@"result" to:_jid elementID:nil];
//	[ack addAttributeWithName:@"from" stringValue:fromString];
	
	[stream sendElement:ack];
	DLog();
}


//KONG: another implementation of Acknowledgment 
/*
- (void)sendBufferWithAcknowledgePrefix:(BOOL)withAck {
	//	NSString *message = @"";
	
	//	if (withAck) {
	//		message = @"A}}";
	//	}
	
	if ([_buffer length] == 0) {
		if (withAck) {
			[self sendAnEmptyAcknowledgement];			
		}
		return;
	}
	
	//	message = [NSString stringWithFormat:@"%@%@", message, _buffer];
	
	// When we send more message, we should wait for reply
	_isWaitingAcknowlegment = YES;
	
	[self sendBuffer];
	// set timer to reset _isWaitingAcknowlegment	
}
 */

#pragma mark send large DATA


/*
static NSString *const messageEndSendingData = @"endSendingData";
- (void)sendCloseSendingDataForSID:(NSString *)sid {
	//	<iq from="alice@wonderland.lit/rabbithole" id="fr61g835"
	//	to="sister@realworld.lit/home"
	//	type="set"> <close xmlns="http://jabber.org/protocol/ibb" sid="dv917fb4"/>
	//	</iq>
	[self sendMessageInstantly:messageEndSendingData];
}
*/
- (void)sendBlockData:(NSString *)block seq:(NSUInteger)seq sid:(NSString *)sid{
	NSLog(@"%s %@", _cmd, block);
	
	//
	//	<message from="alice@wonderland.lit/rabbithole" to="sister@realworld.lit/home"
	//	id="ck39fg47"> <data xmlns="http://jabber.org/protocol/ibb"
	//	sid="dv917fb4"
	//	seq="0"> qANQR1DBwU4DX7jmYZnncmUQB/9KuKBddzQH+tZ1ZywKK0yHKnq57kWq+RFtQdCJ WpdWpR0uQsuJe7+vh3NWn59/gTc5MDlX8dS9p0ovStmNcyLhxVgmqS8ZKhsblVeu IpQ0JgavABqibJolc3BKrVtVV1igKiX/N7Pi8RtY1K18toaMDhdEfhBRzO/XB0+P AQhYlRjNacGcslkhXqNjK5Va4tuOAPy2n1Q8UUrHbUd0g+xJ9Bm0G0LZXyvCWyKH kuNEHFQiLuCY6Iv0myq6iX6tjuHehZlFSh80b5BVV9tNLwNR5Eqz1klxMhoghJOA
	//	</data> </message>
	
	
	NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
	
	// header
	NSString *fromString = [stream.myJID full];
	NSString *toString = [_jid full];	
	
	[message addAttributeWithName:@"from" stringValue:fromString];
	[message addAttributeWithName:@"to" stringValue:toString];
	
	// body
	
	NSXMLElement *dataElement = [[[NSXMLElement alloc] initWithName:@"data" 
														stringValue:block] autorelease];	
	
	[dataElement addAttributeWithName:@"xmlns" stringValue:@"http://jabber.org/protocol/ibb"];
	[dataElement addAttributeWithName:@"sid" stringValue:sid]; 
	[dataElement addAttributeWithName:@"seq" stringValue:[NSString stringWithFormat:@"%d", seq]];
	
	[message addChild:dataElement];
	[stream sendElement:message];
	
	
	//	<message from="kong@chatmask.com/wb" to="greengar@chatmask.com/wb"><data xmlns="http://jabber.org/protocol/ibb" sid="wb-sid1234" seq="14">ee45625a4ef730abc91b211d41fe95bd570ab05569d9c65a9f4b85a928cb91bd57f5</data></message>
}



- (void)sendLargeDataByChunks:(NSString *)message {
	// the message is already in hex
	
	// chop up into block
	// block length: 4096byte per block - 
	NSUInteger dataBlockLength = 4000;
	NSUInteger numberOfBlocks = [message length]/dataBlockLength;
	
	//	NSMutableArray *messageBlocks = [NSMutableArray array];
	NSLog(@"sending image: with hex length: %d", [message length]);
	
	NSString *sid = @"wb-sid1234";
	
	NSString *sendingBlock =  nil;
	for (NSUInteger i = 0, seq=0; seq< numberOfBlocks; i = i + dataBlockLength, seq++) { 
		sendingBlock = [message substringWithRange:NSMakeRange(i, dataBlockLength)];
		
		// send each block
		[self sendBlockData:sendingBlock seq:seq sid:sid];
	}
	NSUInteger remainString = [message length] - numberOfBlocks*dataBlockLength;
	if (remainString > 0) {
		sendingBlock = [message substringWithRange:NSMakeRange(numberOfBlocks*dataBlockLength, remainString)];
		[self sendBlockData:sendingBlock seq:numberOfBlocks sid:sid];
	}
	// send end of transfer	
	
	[UIAppDelegate.connection finishSendingImageHexData];
}

- (void)processStoredMessages {
	DLog();
}

- (void)resetStateForNewConnection {
    _isWaitingAcknowlegment = NO;
    self.buffer = [NSMutableString string];
}

@end