//
//  GSConnectionStream.h
//  Whiteboard
//
//  Created by Cong Vo on 12/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#if TARGET_OS_IPHONE
	#import <UIKit/UIKit.h>
#else
	#import <Cocoa/Cocoa.h>
#endif

@class GSWhiteboard;

typedef enum GSConnectionType {
	GSConnectionTypeNone = 0,
	GSConnectionTypeLocal,
	GSConnectionTypeInternet
} GSConnectionType;

@protocol GSConnection <NSObject>

- (GSConnectionType)type;

- (void)startToConnect;
- (void)stopConnecting;
- (void)startToBroadcast;
- (void)stopBroadcasting;


- (NSString *)myName;

//KONG: Each connection has it own way to solve this conflicting situation
- (void)solveConflictWhenReceiveConnectionRequest:(GSWhiteboard *)requester;

@optional
- (BOOL)isConnected;

@end


@interface GSConnection : NSObject {
	
}

+ (BOOL)isNSStream:(id)stream;
#if INTERNET_INCLUDING
+ (BOOL)isInternetStream:(id)stream;
#endif
+ (GSConnectionType)connectionTypeForSource:(id)source;
@end

