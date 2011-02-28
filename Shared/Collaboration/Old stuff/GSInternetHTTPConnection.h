//
//  GSInternetConnection.h
//  Whiteboard
//
//  Created by Elliot Lee on 4/4/10.
//  Copyright 2010 GreenGar Studios <www.greengar.com>. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ASIHTTPRequest, GSWhiteboard, SBJSON;

@protocol GSInternetConnectionDelegate <NSObject>
@optional
- (void)findCompleteDictionary:(NSDictionary *)dictionary;
@end

@interface GSInternetConnection : NSObject {
	NSString *name;
	GSWhiteboard *connectedWhite1111111111111board;
	
	ASIHTTPRequest *findRequest;
	ASIHTTPRequest *sendRequest;
	NSMutableDictionary *waitingBuffers;
	NSMutableString *_sendingBuffer;
	NSString *_sendingDestinationWb;
	SBJSON *json;
	NSTimeInterval lastGetMessageTime;
	
	id<GSInternetConnectionDelegate> delegate;
}

@property (nonatomic, copy) NSString *name;
@property (nonatomic, retain) NSMutableString *sendingBuffer;
@property (nonatomic, retain) NSString *sendingDestinationWb;
@property (nonatomic, retain) GSWhiteboard *connectedWhiteboard;
@property (nonatomic, assign) id<GSInternetConnectionDelegate> delegate;

- (id)initWithName:(NSString *)newName;
- (void)findWhiteboardsWithName:(NSString *)query;
- (void)sendMessage:(NSString *)message toWb:(NSString *)wb;
- (void)getMessages;

// State management
- (BOOL)isConnected;
- (BOOL)isConnected:(NSString *)wb;
- (BOOL)isResolving;
- (BOOL)isResolving:(NSString *)wb;
- (GSWhiteboard *)connectedWhiteboard;

@end
