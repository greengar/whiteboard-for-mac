//
//  GSWhiteboardUser.h
//  Whiteboard
//
//  Created by Cong Vo on 12/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class XMPPJID;

@interface GSWhiteboardUser : NSObject {
	
	
}

+ (NSString *)displayNameFromJIDString:(NSString *)jidString;
+ (NSString *)displayNameFromXMPPUser:(NSString *)xmppUser;
+ (NSString *)displayNameFromJID:(XMPPJID *)jid;
@end
