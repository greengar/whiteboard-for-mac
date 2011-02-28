//
//  AppController+NSStreamDelegate.h
//  Whiteboard
//
//  Created by Elliot Lee on 6/26/09.
//  Copyright 2009 GreenGar Studios <http://www.greengar.com/>. All rights reserved.
//

#import "GSLocalWhiteboard.h"



@interface GSLocalWhiteboard (NSStreamDelegate)
- (void)streamEventHasSpaceAvailable:(id)stream;

#pragma mark TODO: check if we should expose this

- (void)streamEventOpenCompleted:(id)stream;
- (void)stream:(NSStream *)stream handleError:(NSError *)error;
- (void)receivedMessage:(NSString *)message;
- (void)storeMessage:(NSString *)message;
@end