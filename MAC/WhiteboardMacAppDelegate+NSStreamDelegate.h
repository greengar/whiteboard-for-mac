//
//  AppController+NSStreamDelegate.h
//  Whiteboard
//
//  Created by Elliot Lee on 6/26/09.
//  Copyright 2010-2011 Greengar Studios. All rights reserved.
//

#import "WhiteboardMacAppDelegate.h"


@interface WhiteboardMacAppDelegate (NSStreamDelegate)

- (void)sendMyColor;

- (void)streamEventHasSpaceAvailable:(id)stream;
- (void)receivedMessages:(NSArray *)messages;
- (void)processMessage:(NSString *)message source:(id)source;
@end
