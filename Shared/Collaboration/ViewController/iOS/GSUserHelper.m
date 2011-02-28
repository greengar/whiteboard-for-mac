//
//  GSXMPPHelper.m
//  Whiteboard
//
//  Created by Cong Vo on 2/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GSUserHelper.h"
#import "NSString+MD5.h"

@implementation GSUserHelper

static NSString *kXMPPPasswordSecret = @"%S1mpl3@Fun&Us3ful^";

+ (NSString *)XMPPPasswordForUsername:(NSString *)username {
    if (username == nil) {
        return nil;
    }
    NSString *usernameWithSecret = [NSString stringWithFormat:@"%@&%@", username, kXMPPPasswordSecret];
    NSString *md5 = [usernameWithSecret md5sum];
    DLog(@"md5: %@", md5);
    return [md5 substringToIndex:10];
}

static int xmppSuffixLength = 6; //.g.g.s
static NSString *const xmppSuffix = @".g.g.s";

+ (NSString *)greengarUsernameFromXMPPUsername:(NSString *)xmppUser {
	if (xmppUser == nil || [xmppUser isKindOfClass:[NSString class]] == NO) {
		return nil;
	}
	
	if ([xmppUser rangeOfString:xmppSuffix].location == NSNotFound) {
		return xmppUser;
	}
	
	return [xmppUser substringToIndex:xmppUser.length - xmppSuffixLength];
}

+ (void)cacheUsername:(NSString *)username password:(NSString *)password userID:(NSString *)userID {
    DLog("username: %@ password: %@ userid: %@", username, password, [userID description]);
    [NSDEF setObject:username forKey:kGreengarCachedUsername];
    [NSDEF setObject:password forKey:kGreengarCachedPassword];

    [NSDEF setObject:[userID description] forKey:kGreengarCachedUserID];
}


@end
