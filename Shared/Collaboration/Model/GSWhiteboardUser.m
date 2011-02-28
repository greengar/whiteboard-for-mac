//
//  GSWhiteboardUser.m
//  Whiteboard
//
//  Created by Cong Vo on 12/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GSWhiteboardUser.h"

#import "XMPP.h"


const int xmppSuffixLength = 6; //.g.g.s
static NSString *const xmppSuffix = @".g.g.s";
@implementation GSWhiteboardUser

+ (NSString *)displayNameFromXMPPUser:(NSString *)xmppUser {
	if (xmppUser == nil || [xmppUser isKindOfClass:[NSString class]] == NO) {
		return nil;
	}
	
	if ([xmppUser rangeOfString:xmppSuffix].location == NSNotFound) {
		return xmppUser;
	}
	
	return [xmppUser substringToIndex:xmppUser.length - xmppSuffixLength];
}

+ (NSString *)displayNameFromJIDString:(NSString *)jidString {
	// user@domain.com
	XMPPJID *jid = [XMPPJID jidWithString:jidString];
	
	return [self displayNameFromXMPPUser:[jid user]];
}

+ (NSString *)displayNameFromJID:(XMPPJID *)jid {
	// user@domain.com	
	return [self displayNameFromXMPPUser:[jid user]];
}

@end
