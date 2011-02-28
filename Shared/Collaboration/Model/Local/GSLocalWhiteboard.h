//
//  GSLocalWhiteboard.h
//  Whiteboard
//
//  Created by Cong Vo on 1/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GSWhiteboard.h"

@interface GSLocalWhiteboard : GSWhiteboard <NSStreamDelegate, NSNetServiceDelegate> {
	// use when service is already resolved
	NSInputStream *_inStream;
	NSOutputStream *_outStream;
	
	// use when service has not resolved yet
	NSNetService *_service;
	
//	BOOL				_inReady;
//	BOOL				_outReady;
	
	BOOL				needToSendName;  // make sure to send name (in stream-available method) once
	
//	BOOL peerReadyToReceive; 	// check if I can start to send to friend
	
	NSString* _writeBuffer;
	
	//KONG: use for store message when in background
	NSMutableString *_readBuffer;
}

@property (nonatomic, retain) NSInputStream *inStream;
@property (nonatomic, retain) NSOutputStream *outStream;

@property (nonatomic, retain) NSNetService *service;
@property (nonatomic, readonly) BOOL isResolved;
@property (nonatomic, readonly) BOOL didSendConnectionRequest;

@property (nonatomic, retain) NSString *writeBuffer;
@property (nonatomic, retain) NSString *readBuffer;

- (id)initWithNetService:(NSNetService *)service name:(NSString *)name;
- (id)initWithInStream:(NSInputStream *)inStream outStream:(NSOutputStream *)outStream;

// standard whiteboard methods

- (void)initiateConnection;
- (void)disconnect;

- (void)send:(NSString *)message;
- (void)performInStreamThreadSelector:(SEL)selector withObject:(id)object wait:(BOOL)willWait;
@end
