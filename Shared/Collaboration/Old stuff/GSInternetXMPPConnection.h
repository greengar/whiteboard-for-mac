//
//  SphereNetNetworkController.h
//  iPhoneXMPP
//
//  Created by Cong Vo on 12/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "SphereNetSphere.h"
#import "XMPP.h"
#import "GSIMSender.h"

static NSString * const SphereNetDomain = @"sphere";

static NSString * const SphereNetDomainDelimiter = @"#%#";

static NSString * const SphereNetCommandDelimiter = @"#";
//static NSString * const SphereCommandConnect = @"connect";
//static NSString * const SphereCommandAccepted = @"accepted";
//static NSString * const SphereCommandDenied = @"denied";
//static NSString * const SphereCommandUpdatingPosition = @"position";

typedef enum {
	SphereNetCommandNil = 0,
	SphereNetCommandConnect,
	SphereNetCommandAccept,
	SphereNetCommandDeny,
	SphereNetCommandMoveToPosition,
	SphereNetCommandDisconnect,
} SphereNetCommand;

@class GSInternetXMPPConnection;

@protocol SphereNetNetworkControllerDelegate

typedef struct {
	float r, g, b;
	CGPoint position; 
} SphereNetSphereUpdate;

//- (void)networkController:(SphereNetNetworkController *)controller 
//		 didReceiveUpdate:(SphereNetSphereUpdate)update 
//			  fromAddress:(NSData *)address;

- (void)networkController:(GSInternetXMPPConnection *)controller 
		 didReceiveUpdate:(SphereNetSphereUpdate)update;

@end

@interface GSInternetXMPPConnection : NSObject <GSIMSenderDelegate> {
	id <SphereNetNetworkControllerDelegate> _delegate; 
	
	SphereNetSphereUpdate _lastSentUpdate;
	
	XMPPJID *_toJID;
	
	GSIMSender *_IMSender;
}

@property (nonatomic, retain) XMPPJID *toJID;
@property (nonatomic, retain) GSIMSender *IMSender;

- (id)initWithFriend:(XMPPJID *)toJID 
			delegate:(id <SphereNetNetworkControllerDelegate>)delegate;
//- (void)localSphereDidMove:(SphereNetSphere *)sphere;



+ (void)sendConnectMessageToRemoteJID:(XMPPJID *)remoteJID;
+ (void)sendDenyMessageToRequesterJID:(XMPPJID *)requesterJID;
+ (void)sendAcceptMessageToRequesterJID:(XMPPJID *)requesterJID;
+ (void)sendDisconnectMessageToRequesterJID:(XMPPJID *)requesterJID;

+ (NSString *)usernameFromSphereCommandRequest:(NSArray *)requestComponents;
+ (NSArray *)sphereCommandFromMessage:(XMPPMessage *)message;
+ (NSArray *)commandParamsFromSphereCommand:(NSString *)command;
+ (BOOL)isCommand:(NSArray *)commandComponents kindOfSphereCommand:(SphereNetCommand)sphereCommand;


+ (NSString *)mergeAllString:(NSArray *)strings usingDelimiter:(NSString *)delimiter;
@end


