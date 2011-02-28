//
//  GSLocalConnection.h
//  Whiteboard
//
//  Created by Cong Vo on 1/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BrowserViewController.h"
#import "TCPServer.h"
#import "GSConnection.h"

@class GSConnectionController;
@class GSLocalWhiteboard;

#define RUN_IN_STREAM_THREAD \
if ([NSThread isMainThread]) { [self performInStreamThreadSelector:_cmd withObject:nil wait:NO]; return; }


@interface GSLocalConnection : NSObject <GSConnection, TCPServerDelegate>{
	TCPServer *_server;
	NSThread *_streamThread;
	
	BrowserViewController *_bvc;
	
	NSMutableArray *_serverConnectedPeers;
	
	NSString *_myName;
}


@property (nonatomic, retain) BrowserViewController *bvc;
@property (nonatomic, retain) NSThread *streamThread;
@property (nonatomic, retain) TCPServer *server;
@property (nonatomic, retain) NSMutableArray *serverConnectedPeers;
@property (nonatomic, retain) NSString *myName;

- (void)showNetworkError:(NSString*)title;

// this is only for test, should be removed
//@property (nonatomic, assign) BOOL peerReadyToReceive;
- (GSLocalWhiteboard *)peerForInstream:(NSStream *)stream;
- (void)performInStreamThreadSelector:(SEL)selector withObject:(id)object wait:(BOOL)willWait;
@end
