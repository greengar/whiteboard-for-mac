//
//  GSUserHelper.h
//  Whiteboard
//
//  Created by Cong Vo on 2/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *const kXMPPCachedUsername = @"xmpp-user";
static NSString *const kXMPPCachedPassword = @"xmpp-password";
static NSString *const kXMPPCachedDomain = @"xmpp-domain";

static NSString *const kGreengarCachedUsername = @"greengar-username";
static NSString *const kGreengarCachedUserID = @"greengar-user-id";
static NSString *const kGreengarCachedPassword = @"greengar-password";

@interface GSUserHelper : NSObject {

}

+ (NSString *)XMPPPasswordForUsername:(NSString *)username;

+ (NSString *)greengarUsernameFromXMPPUsername:(NSString *)xmppUser;

+ (void)cacheUsername:(NSString *)username password:(NSString *)password userID:(NSString *)userID;

@end
