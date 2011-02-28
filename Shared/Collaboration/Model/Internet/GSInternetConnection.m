//
//  GSInternetConnection.m
//  Whiteboard
//
//  Created by Elliot Lee on 4/4/10.
//  Copyright 2010 GreenGar Studios <www.greengar.com>. All rights reserved.
//

#import "GSInternetConnection.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "JSON.h"
#import "GSWhiteboard.h"
//#import "NSString+GSURL.h"
#import "AppController.h"
#import "GSLocalConnection.h"
//#import "GSLocalConnection+NSStreamDelegate.h"
#import "ASIFormDataRequest.h"
#import "GSConnectionController.h"
#import "GSWhiteboardUser.h"

#import "XMPP.h"
#import "XMPPRosterCoreDataStorage.h"
#import "GSViewHelper.h"
#import "GSUserHelper.h"

#define kWb ([UIDevice currentDevice].uniqueIdentifier)
#define kGetMessageDelay				0.50f					//2.0f	// second
#define kGetMessageAfterFailureDelay	(kGetMessageDelay/2.0f) //1.0f	// seconds

@interface GSInternetConnection ()
@property (nonatomic, retain) NSMutableDictionary *interactingPeers;
@end

@implementation GSInternetConnection

//@synthesize name, sendingBuffer = _sendingBuffer, sendingDestinationWb = _sendingDestinationWb, 
@synthesize connectedWhiteboard, delegate;
// XMPP
@synthesize xmppStream = _xmppStream, xmppRoster = _xmppRoster, xmppRosterStorage = _xmppRosterStorage;
@synthesize username = _username, xmppPassword = password;

@synthesize buffer = _buffer;
@synthesize interactingPeers = _interactingPeers;
@synthesize isLogedInGreengar = _isLogedInGreengar;
@synthesize isOnline = _isOnline;

const NSString *kServerURL = @"http://whiteboardonline.appspot.com/api/";

- (id)init {
	if ((self = [super init])) {		
		[self initiateXMPP];
		_buffer = [[NSMutableString alloc] init];
		_interactingPeers = [[NSMutableDictionary alloc] init];
	}
	return self;
}

//- (BOOL)isOnline {
//    DLog(@"online: %d", [_xmppRoster.myUser isOnline]);
//    return [_xmppRoster.myUser isOnline];
//}

- (void)dealloc {
	[_buffer release];
	[[self xmppStream] removeDelegate:self];
	[super dealloc];
}

- (NSString *)username {
	return [GSWhiteboardUser displayNameFromXMPPUser:_xmppStream.myJID.user];
}


// call this method whenever you have new connection
//- (void)setConnectedWhiteboard:(GSInternetWhiteboard *)wb {
//	if (connectedWhiteboard) {
//		[connectedWhiteboard release];
//	}
//	connectedWhiteboard = [wb retain];	
//}

- (GSInternetWhiteboard *)peerWithJIDString:(NSString *)jidString {
	
	// get peer with origin jid
	GSInternetWhiteboard *peer = [_interactingPeers objectForKey:jidString];
	if (peer) {
		return peer;
	}
	
	XMPPJID *jid = [XMPPJID jidWithString:jidString];
	if (jid == nil 
		|| jid.user == nil // iq from server
		|| [jid.user isEqualToString:_xmppStream.myJID.user] // my from my jid when I retreive my list
		) {
		return nil;
	}
	// get peer with bare jid string
	peer = [_interactingPeers objectForKey:[jid bare]]; 
	
	if (peer) {
		return peer;
	}
	
	// create new peer
	peer = [[[GSInternetWhiteboard alloc] initWithJID:jid] autorelease];
	
	[_interactingPeers setObject:peer forKey:jidString];
	[_interactingPeers setObject:peer forKey:[jid bare]];
	return peer;
}

- (void)removeCacheOfPeer:(GSInternetWhiteboard *)peer {
	NSArray *allKeys = [_interactingPeers allKeysForObject:peer];
	[_interactingPeers removeObjectsForKeys:allKeys];
}


- (BOOL)isConnected {
	return [_xmppStream isConnected];
}

- (BOOL)isInAuthenticatingProcess {
	DLog();
	return (_shouldLoginAfterConnected || _isAuthenticating);
}

- (NSString *)getElement:(NSString *)data fromMessage:(XMPPMessage *)message {
	NSArray *bodyElements = [message elementsForName:data];
	if (bodyElements == nil || [bodyElements count] == 0) {
		return nil;
	}
	return [[bodyElements objectAtIndex:0] stringValue];
}

/*
- (void)setPendingRequesterFromSource:(id)source {

	
	NSLog(@"%s %@", _cmd, source);
	
	if ([source isKindOfClass:[XMPPJID class]]) {
		XMPPJID *pendingJID = (XMPPJID *)source;
		pendingWhiteboard = [[GSInternetWhiteboard alloc] initWithName:
							 [GSWhiteboardUser displayNameFromJID:pendingJID]];
//		pendingWhiteboard.name = [pendingJID user];
		pendingWhiteboard.wb = [pendingJID bare];
		pendingWhiteboard.jid = pendingJID;
	}
}

- (void)setConnectedWithPendingWhiteboard {
	if (pendingWhiteboard) {
		connectedWhiteboard = pendingWhiteboard;
		pendingWhiteboard = nil;
	} else {
		[self.delegate friendAcceptedConnectionRequest];
	}

}
*/

- (void)sendSubscribePresenceType:(NSString *)type toWBUsername:(NSString *)username {
	// <presence id="5OKE2-100" to="athanhcong@chatmask.com" type="subscribe" from="testbbbb@chatmask.com"/>
	//	XMPPPresence *presence = [[XMPPPresence alloc] initWithType:@"subscribe" to:<#(XMPPJID *)to#>
	
	NSXMLElement *presence = [NSXMLElement elementWithName:@"presence"];
	
	XMPPJID *myJID = [[self xmppStream] myJID];
	//	XMPPJID *toJID = self.connectedWhiteboard.jid;
	
	
	NSString *fromString = [NSString stringWithFormat:@"%@@%@", [myJID user], [myJID domain]];
//	NSString *toString = [NSString stringWithFormat:@"%@@chatmask.com", username];	
	NSString *toString = username;
	//	[presence addAttributeWithName:@"id" stringValue:@"5OKE2-99"];
	[presence addAttributeWithName:@"from" stringValue:fromString];
	[presence addAttributeWithName:@"to" stringValue:toString];
	[presence addAttributeWithName:@"type" stringValue:type];
	
	[[self xmppStream] sendElement:[XMPPPresence presenceFromElement:presence]];
	
	//KONG: test
	
	id <XMPPUser> user = [_xmppRosterStorage userForJID:[XMPPJID jidWithString:toString]];
	
	DLog(@"sent to user: %@", user);
	
}

- (void)sendSubscribePresenceToJIDString:(NSString *)username {
	[self sendSubscribePresenceType:@"subscribe" toWBUsername:username];
}

- (void)sendSubscribedPresenceToJIDString:(NSString *)username {
	[self sendSubscribePresenceType:@"subscribed" toWBUsername:username];
	
}

- (void)sendUnsubscribedPresenceToJIDString:(NSString *)username {
	[self sendSubscribePresenceType:@"unsubscribed" toWBUsername:username];
	
}


#pragma mark GSOutputStream 

- (BOOL)hasSpaceAvailable {
	return YES;
}

//- (BOOL)sendMessage:(NSString *)message {
//	if (connectedWhiteboard) {
//		[self sendMessage:message toWb:connectedWhiteboard.wb];		
//		return YES;
//	}
//	return NO;
//}


#pragma mark XMPP
- (void)initiateConnection {
	// with a peer
}


- (void)startToConnect {	
	NSString *loginUsername = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPCachedUsername];
	NSString *loginPassword = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPCachedPassword];	
	
	NSString *xmppDomain = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPCachedDomain];	
	
	
	//	NSString *loginUsername = @"kong";
	//	NSString *loginPassword = @"kkkkong";	
	
	if (loginUsername == nil || loginPassword == nil || xmppDomain == nil) {
		return;
		// alert view
		//		UIAlertVie	w *alert = [[[UIAlertView alloc] initWithTitle:@"Login" message:@"Please set username & passwork in Settings. Thanks" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
		//		[alert show];		
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticatingNotification object:nil];
		
	[_xmppStream setHostName:xmppDomain];
	[_xmppStream setHostPort:5222];

	[_xmppStream setMyJID:[XMPPJID jidWithString:
						   [NSString stringWithFormat:@"%@@%@", loginUsername, xmppDomain]
										resource:@"wb-ip"]];
	password = loginPassword;
	//	[xmppStream setMyJID:[XMPPJID jidWithString:@"kong@greengar.com"]];
	//	password = @"";


	// Uncomment me when the proper information has been entered above.
	NSError *error = nil;
	if ([_xmppStream connect:&error] == NO) {
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Login" message:[NSString stringWithFormat:@"Connection error:\n%@", error]
														delegate:self 
											   cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
		[alert show];
		NSLog(@"Error connecting: %@", error);
	} else {
		_shouldLoginAfterConnected = YES;
	}

	DLog();
}

- (void)stopConnecting {
	DLog();
	[self goOffline];
	[_xmppStream disconnect];
}

- (void)startToBroadcast {
//	[self goOnline];
	DLog();
}

- (void)stopBroadcasting {
//	[self goOffline];
	DLog();	
}

- (void)initiateXMPP {
	
	self.xmppStream = [[[XMPPStream alloc] init] autorelease];
	self.xmppRosterStorage = [[[XMPPRosterCoreDataStorage alloc] init] autorelease];
	self.xmppRoster = [[[XMPPRoster alloc] initWithStream:_xmppStream rosterStorage:_xmppRosterStorage] autorelease];
	
	[_xmppStream addDelegate:self];
	[_xmppRoster addDelegate:self];
	
//	// TODO: check
//	[xmppStream addDelegate:_internetConnection];
	
	[_xmppRoster setAutoRoster:YES];
	
	// Replace me with the proper domain and port.
	// The example below is setup for a typical google talk account.
	//	[xmppStream setHostName:@"talk.google.com"];
	//	[xmppStream setHostPort:5222];
	//	[xmppStream setHostName:@"Thuy-Truongs-MacBook-Air-2.local"];
	
	// public XMPP service: 
	
	
	// You may need to alter these settings depending on the server you're connecting to
	allowSelfSignedCertificates = NO;
	allowSSLHostNameMismatch = NO;

}

#pragma mark app state

//- (void)willTerminate {
//	[self stopConnecting];
//}



- (void)goOnline
{
	NSXMLElement *presence = [NSXMLElement elementWithName:@"presence"];
	
	[[self xmppStream] sendElement:presence];
    _isOnline = YES;
}


- (void)goOffline {
	NSXMLElement *presence = [NSXMLElement elementWithName:@"presence"];
	[presence addAttributeWithName:@"type" stringValue:@"unavailable"];
	
	[[self xmppStream] sendElement:presence];
    _isOnline = NO;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
	NSLog(@"---------- xmppStream:willSecureWithSettings: ----------");
	
	if (allowSelfSignedCertificates)
	{
		[settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
	}
	
	if (allowSSLHostNameMismatch)
	{
		[settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
	}
	else
	{
		// Google does things incorrectly (does not conform to RFC).
		// Because so many people ask questions about this (assume xmpp framework is broken),
		// I've explicitly added code that shows how other xmpp clients "do the right thing"
		// when connecting to a google server (gmail, or google apps for domains).
		
		NSString *expectedCertName = nil;
		
		NSString *serverDomain = _xmppStream.hostName;
		NSString *virtualDomain = [_xmppStream.myJID domain];
		
		if ([serverDomain isEqualToString:@"talk.google.com"])
		{
			if ([virtualDomain isEqualToString:@"gmail.com"])
			{
				expectedCertName = virtualDomain;
			}
			else
			{
				expectedCertName = serverDomain;
			}
		}
		else
		{
			expectedCertName = serverDomain;
		}
		
		[settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
	}
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
	NSLog(@"---------- xmppStreamDidSecure: ----------");
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
	DLog(@"---------- xmppStreamDidConnect: ----------");
	
	isOpen = YES;
	if (_shouldLoginAfterConnected) {
		NSError *error = nil;
		if (password) {
			if ([[self xmppStream] authenticateWithPassword:password error:&error] == NO) {
				NSLog(@"Error authenticating: %@", error);
			} else {
				_isAuthenticating = YES;
			}

		}
		_shouldLoginAfterConnected = NO;
	}
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	NSLog(@"---------- xmppStreamDidAuthenticate: ----------");
	
	[self goOnline];
	_isAuthenticating = NO;
    
    _isLogedInGreengar = YES;
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
	NSLog(@"---------- xmppStream:didNotAuthenticate: ----------");
	_isAuthenticating = NO;
}

//- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
//{
//	NSLog(@"---------- xmppStream:didReceiveIQ: ----------");
//	
//	return NO;
//}

//- (void)receiveUnavailableFriendJID:(XMPPJID *)friendJID {
//
//	
////	if (UIAppDelegate.connection.connectedWhiteboard != nil &&
////		UIAppDelegate.connection.connectedWhiteboard.type == GSConnectionTypeInternet) {
////		NSString *connectedUser = UIAppDelegate.connection.connectedWhiteboard.name;
////		if ([[friendJID user] isEqualToString:connectedUser]) {
////			[self receiveDisconnectMessageFrom:friendJID];
////		}
////	}
//}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence {
//	NSLog(@"---------- xmppStream:didReceivePresence: ----------");
	
	NSString *presenceType = [presence attributeStringValueForName:@"type"];
	if ([presenceType isEqualToString:@"subscribe"]) {
		NSString *from = [presence attributeStringValueForName:@"from"];		
		[self.delegate internetConnection:self didReceiveSubscribeFrom:from];
		
	} else if ([presenceType isEqualToString:@"subscribed"]) {
		// 
		NSLog(@"subscribe request from: %@", [presence attributeStringValueForName:@"from"]);
		
		NSString *from = [presence attributeStringValueForName:@"from"];
		[self.delegate internetConnection:self didReceiveSubscribedFrom:from];
	} else if ([presenceType isEqualToString:@"unsubscribed"]) {
		// 
		NSString *from = [presence attributeStringValueForName:@"from"];
		[self.delegate internetConnection:self didReceiveUnsubscribedFrom:from];
	}
	// available
	else if ([presenceType isEqualToString:@"unavailable"]) {
		NSString *requesterJIDString = [presence attributeStringValueForName:@"from"];
		
		GSInternetWhiteboard *requester = [self peerWithJIDString:requesterJIDString];
		[UIAppDelegate.connection receivedPeerUnavailableSignalFrom:requester];		
	}
	
}


- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error {
	NSLog(@"---------- xmppStream:didReceiveError: ----------\nERROR: %@", error);
	
	/*
	<stream:error><conflict xmlns='urn:ietf:params:xml:ns:xmpp-streams'/><text xml:lang='' xmlns='urn:ietf:params:xml:ns:xmpp-streams'>Replaced by new connection</text></stream:error></stream:stream>
	 */
	
	if ([error isKindOfClass:[DDXMLElement class]]) {
		NSXMLElement *conflictElement = [(DDXMLElement *)error elementForName:@"conflict"];
		
		if (conflictElement != nil) {
			[GSViewHelper showAlertViewTitle:@"Connection lost" 
									 message:@"This account is logged in by another device." 
								cancelButton:@"OK"];		
		}		
	}

}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender
{
	NSLog(@"---------- xmppStreamDidDisconnect: ----------");
	
	if (!isOpen)
	{
		NSLog(@"Unable to connect to server. Check xmppStream.hostName");
	} else {
		
	}
	_shouldLoginAfterConnected = NO;
    _isLogedInGreengar = NO;
	_isOnline = NO;
	// if I accidentially disconnected, refresh the connection status
	[UIAppDelegate.connection receivedNetworkUnavailableSignal:GSConnectionTypeInternet];
}

- (void)xmppStream:(XMPPStream *)sender didSendIQ:(XMPPIQ *)iq {
	DLog(@"%@", iq);
}

- (BOOL)isConnectedWhiteboardFromSource:(XMPPJID *)jid {
	// check for connected, and acknowledgement from connected WB
	GSWhiteboard *connectedWB = UIAppDelegate.connection.connectedWhiteboard;
	
	if (connectedWB != nil
		&& connectedWB.type == GSConnectionTypeInternet
		&& [[[(GSInternetWhiteboard *) connectedWB jid] bare] isEqualToString:[jid bare]]) {
		return YES;
	}
	return NO;
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
	NSLog(@"---------- xmppStream:didReceiveIQ: ----------");
	
	// recreate an XMPPJID for requester
	NSString *requesterJIDString = [iq attributeStringValueForName:@"from"];
	
	if (requesterJIDString == nil) {
		return YES;
	}
	
	GSInternetWhiteboard *peer = [self peerWithJIDString:requesterJIDString];
		
	[peer receivedIQ:iq];	
	
	// always return yes
	return YES;
	//	if (sendingData) {
	//		if ([[iq type] isEqualToString:@"set"]) {
	//			NSXMLElement *child = [iq childElement];
	//			if ([[child name] isEqualToString:@"close"]) {
	//				NSLog(@"received data: %@", [sendingData objectForKey:@"data"]);
	//				// remove sending data
	//				[sendingData release];
	//				sendingData = nil;
	//				return YES;
	//			}
	//		}
	//	}

	
	/*
	 SEND: <presence from="ap.g.g.s@openjabber.org" to="kong.g.g.s@binaryfreedom.info" type="subscribe"/>
	 RECV: <iq from='ap.g.g.s@openjabber.org/wb-ip' to='ap.g.g.s@openjabber.org/wb-ip' id='push' type='set'><query xmlns='jabber:iq:roster'><item ask='subscribe' subscription='none' jid='kong.g.g.s@binaryfreedom.info'/></query></iq>
	 2011-01-11 08:30:37.182 Whiteboard[2944:207] ---------- xmppStream:didReceiveIQ: ----------
	 2011-01-11 08:30:37.183 Whiteboard[2944:207] SEND: <iq type="error" to="ap.g.g.s@openjabber.org/wb-ip" id="push"><query xmlns="jabber:iq:roster"><item ask="subscribe" subscription="none" jid="kong.g.g.s@binaryfreedom.info"/></query><error type="cancel" code="501"><feature-not-implemented xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/></error></iq>
	 2011-01-11 08:30:37.183 Whiteboard[2944:207] -[GSInternetConnection xmppStream:didSendIQ:] [Line 479] <iq type="error" to="ap.g.g.s@openjabber.org/wb-ip" id="push"><query xmlns="jabber:iq:roster"><item ask="subscribe" subscription="none" jid="kong.g.g.s@binaryfreedom.info"></item></query><error type="cancel" code="501"><feature-not-implemented xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"></feature-not-implemented></error></iq>
	 2011-01-11 08:30:37.450 Whiteboard[2944:207] RECV: <iq from='ap.g.g.s@openjabber.org/wb-ip' to='ap.g.g.s@openjabber.org/wb-ip' type='error' id='push'><query xmlns='jabber:iq:roster'><item ask='subscribe' subscription='none' jid='kong.g.g.s@binaryfreedom.info'/></query><error type='cancel' code='501'><feature-not-implemented xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/></error></iq>
	 2011-01-11 08:30:37.454 Whiteboard[2944:207] ---------- xmppStream:didReceiveIQ: ----------
	 */
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {
	
	// eliminate offline message
	//KONG: I removed this for testing, I should enable this again 

	if ([message elementForName:@"x"] != nil && [[message elementForName:@"x"] elementForName:@"offline"] != nil) {
		DLog (@"Receive offline message: %@", [[message elementForName:@"x"] elementForName:@"offline"]);		
		return;
	}

	NSString *wbMessage = [self getElement:@"body" fromMessage:message];
	if (wbMessage == nil) {
		wbMessage = [self getElement:@"data" fromMessage:message];
	}

	if (wbMessage == nil && [wbMessage length] == 0) {
		return;
	}
	
	// recreate an XMPPJID for requester
	NSString *requesterJIDString = [message attributeStringValueForName:@"from"];
	GSInternetWhiteboard *requester = [self peerWithJIDString:requesterJIDString];
	[requester receivedMessage:wbMessage];
}


//- (void)xmppRoster:(XMPPRoster *)sender didReceiveBuddyRequest:(XMPPPresence *)presence {
//	NSString *from = [presence attributeStringValueForName:@"from"];
//	[self.delegate internetConnection:self didReceiveSubscribeFrom:from];
//}

#pragma mark Connection

- (GSConnectionType)type {
	return GSConnectionTypeInternet;
}


- (void)sendLargeDataByChunks:(NSString*)message identifier:(NSString*)sendID {
	
}

- (void)solveConflictWhenReceiveConnectionRequest:(GSWhiteboard *)sender {
	UIAppDelegate.connection.requestingWhiteboard = UIAppDelegate.connection.waitedWhiteboard;
	UIAppDelegate.connection.waitedWhiteboard = nil;
	[UIAppDelegate.connection userAcceptedConnectionRequestInConnectingRequesting];
	
	//KONG: This alert view make user think they received accepted message from friend 
	[UIAppDelegate.connection showRequestAcceptedAlert];
}

- (NSString *)myName {
	if ([_xmppStream isConnected] == NO) {
		return nil;
	}
	return [GSWhiteboardUser displayNameFromJID:_xmppStream.myJID];
}

@end
