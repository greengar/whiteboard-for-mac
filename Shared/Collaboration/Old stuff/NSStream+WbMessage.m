//
//  NSStream+WbMessage.m
//  Whiteboard
//
//  Created by Cong Vo on 12/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSStream+WbMessage.h"


@implementation NSOutputStream (WbMessage)

- (BOOL)sendMessage:(NSString *)message {
	
	const char *buff = [message UTF8String];
	NSUInteger buffLen = strlen(buff);
	NSInteger writtenLength = 0;
//	if (_outStream) {
		if ([self hasSpaceAvailable]) {
			writtenLength = [self write:(const uint8_t *)buff maxLength:strlen(buff)];
			if (writtenLength != buffLen) {
				DLog(@"Failed sending data to peer, writtenLength = %d, buffLen = %d", writtenLength, buffLen);
				buff += writtenLength;
				buffLen -= writtenLength;
				while (buffLen > 0 && writtenLength != -1) {
					writtenLength = [self write:(const uint8_t *)buff maxLength:strlen(buff)];
					DLog(@"successfully wrote %d bytes", writtenLength);
					buff += writtenLength;
					buffLen -= writtenLength;
				}
			} else {
				//DLog(@"write successful");
			}
		} else {
			DLog(@"Warning: send:toOutStream: ![_outStream hasSpaceAvailable]");
			
			/*
			// Use the stream synchronously
			// https://devforums.apple.com/message/2902#2902
			// turn around and try to write the remaining data.  If buffer space hasn't become available, this will block.
			while (buffLen > 0 && writtenLength != -1) {
				writtenLength = [self write:(const uint8_t *)buff maxLength:strlen(buff)];
				DLog(@"successfully wrote %d bytes", writtenLength);
				buff += writtenLength;
				buffLen -= writtenLength;
			}
			 */
			
		}
		if (writtenLength == -1) {
			// This occurs if we try to do stuff at the point when we say Game Started!
//			[NSException raise:@"send:toOutStream: WriteFailure" format:@"writtenLength = %d, [_outStreams count] = %d, _outStream = %@", writtenLength, [_outStreams count], _outStream];
//			[NSException raise:@"send:toOutStream: WriteFailure" format:@"writtenLength = %d, _outStream = %@", writtenLength, self];
			return NO;
		}
//	} else {
//		DLog(@"Warning: !_outStream");
//	}
	return YES;
	
}
@end
