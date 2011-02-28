//
//  NSStream+WbMessage.h
//  Whiteboard
//
//  Created by Cong Vo on 12/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
//#import <Foundation/NSStream.h>
//#import "NSStream.h"

//@interface NSInputStream (WbMessage) {
//
//}

@interface NSOutputStream (WbMessage)

- (BOOL)sendMessage:(NSString *)message;

@end
