//
//  GSInternetConnection.h
//  Whiteboard
//
//  Created by Elliot Lee on 4/4/10.
//  Copyright 2010 GreenGar Studios <www.greengar.com>. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GSConnection.h"
#import "GSWhiteboard.h"
#import "GSInternetWhiteboard.h"

@class ASIHTTPRequest, GSWhiteboard, SBJSON;
@class GSInternetConnection;

@class XMPPStream;
@class XMPPRoster;
@class XMPPRosterCoreDataStorage;

static NSString *const kAuthenticatingNotification = @"kAuthenticatingNotification";



@protocol GSInternetConnectionDelegate <NSObject>
@optional
//- (void)findCompleteDictionary:(NSDictionary *)dictionary;

- (void)internetConnection:(GSInternetConnection *)iconn 
didReceiveSubscribedFrom:(NSString *)JIDString;

- (void)internetConnection:(GSInternetConnection *)iconn 
  didReceiveUnsubscribedFrom:(NSString *)friendJID;

- (void)internetConnection:(GSInternetConnection *)iconn 
   didReceiveSubscribeFrom:(NSString *)JIDString;

@end

@interface GSInternetConnection : NSObject <GSConnection> {
	id<GSInternetConnectionDelegate> delegate;
	
//	NSMutableDictionary *sendingData;
	NSMutableDictionary *_interactingPeers;
	
	// XMPP
	XMPPStream *_xmppStream;
	XMPPRoster *_xmppRoster;
	XMPPRosterCoreDataStorage *_xmppRosterStorage;	
	
	NSString *password;
	
	BOOL allowSelfSignedCertificates;
	BOOL allowSSLHostNameMismatch;
	
	BOOL isOpen;
	// end XMPP
	
	NSString *_username;
	
	// perform tasks for other view, object
	
	BOOL _shouldLoginAfterConnected;
	BOOL _isAuthenticating;
    
    BOOL _isLogedInGreengar;
    
    BOOL _isOnline;
}

@property (nonatomic, retain) GSInternetWhiteboard *connectedWhiteboard;
@property (nonatomic, assign) id<GSInternetConnectionDelegate> delegate;
@property (nonatomic, retain) NSMutableString *buffer;
// XMPP
@property (nonatomic, retain) XMPPStream *xmppStream;
@property (nonatomic, retain) XMPPRoster *xmppRoster;
@property (nonatomic, retain) XMPPRosterCoreDataStorage *xmppRosterStorage;
@property (nonatomic, copy) NSString *username, *xmppPassword;

@property (nonatomic, assign) BOOL isLogedInGreengar, isOnline;


- (BOOL)isConnected;
- (BOOL)isInAuthenticatingProcess;

- (void)sendSubscribePresenceToJIDString:(NSString *)username;
- (void)sendSubscribedPresenceToJIDString:(NSString *)username;
- (void)sendUnsubscribedPresenceToJIDString:(NSString *)username;
- (void)sendSubscribePresenceType:(NSString *)type toWBUsername:(NSString *)username;

#pragma mark refactor

- (void)initiateXMPP;
- (void)goOnline;
- (void)goOffline;

- (GSInternetWhiteboard *)peerWithJIDString:(NSString *)jidString;
- (void)removeCacheOfPeer:(GSInternetWhiteboard *)peer;
@end
