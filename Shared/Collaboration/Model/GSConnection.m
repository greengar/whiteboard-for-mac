//
//  GSStream.m
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

#import "GSConnection.h"

#if INTERNET_INCLUDING
	#import "GSInternetConnection.h"
#endif

@implementation GSConnection

+ (BOOL)isNSStream:(id)stream {
	return [stream isKindOfClass:[NSStream class]];
}

#if INTERNET_INCLUDING
+ (BOOL)isInternetStream:(id)stream {
	return [stream isKindOfClass:[GSInternetConnection class]];	
}
#endif

+ (GSConnectionType)connectionTypeForSource:(id)source {
	
	if (source == nil) {
		return GSConnectionTypeNone;
	}
	if ([self isNSStream:source]) {
		return GSConnectionTypeLocal;
	}
	
#if INTERNET_INCLUDING	
	if ([source isKindOfClass:[XMPPJID class]]) {
		return GSConnectionTypeInternet;
	}
	if ([self isInternetStream:source]) {
		return GSConnectionTypeInternet;
	}
#endif
	
	return GSConnectionTypeNone;
}

@end

