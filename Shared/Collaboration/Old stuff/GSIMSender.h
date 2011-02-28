//
//  GSIMSender.h
//  iPhoneXMPP
//
//  Created by Cong Vo on 12/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GSIMSender;

@protocol GSIMSenderDelegate <NSObject>

- (void)IMSender:(GSIMSender *)sender triggerToSendMessage:(NSString *)message;

@end



@interface GSIMSender : NSObject {

	NSMutableArray *_messageQueuer;
	
	id _networkDelegate;
}

@property (nonatomic, retain) NSMutableArray *messageQueuer;
@property (nonatomic, assign) id networkDelegate;

- (id)initWithNetworkDelegate:(id <GSIMSenderDelegate>)delegate;

- (void)startToSendMessage;

- (void)sendMessage:(NSString *)message;

+ (NSArray *)commandStringsFromString:(NSString *)commandsString;

@end
