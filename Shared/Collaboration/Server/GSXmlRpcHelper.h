//
//  GSXmlRpcHelper.h
//  Whiteboard
//
//  Created by Cong Vo on 12/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMLRPCRequest.h"


@interface GSXmlRpcHelper : NSObject {
	XMLRPCRequest *_request;
	id _delegate;
	SEL _callback;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) SEL callback;

+ (void)performRequest:(XMLRPCRequest *)request delegate:(id)delegate callback:(SEL)callback;
+ (void)performRequestWithMethod:(NSString *)method args:(NSArray *)args
						delegate:(id)delegate callback:(SEL)callback;

+ (void)performAuthRequestWithMethod:(NSString *)method args:(NSArray *)args
							delegate:(id)delegate callback:(SEL)callback;

+ (void)retrieveXmppServicesListWithDelegate:(id)delegate callback:(SEL)callback;

@end
