//
//  SphereNetNetworkController.m
//  iPhoneXMPP
//
//  Created by Cong Vo on 12/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GSInternetXMPPConnection.h"
//#import "iPhoneXMPPAppDelegate.h"
#import "AppController.h"

@interface GSInternetXMPPConnection()

- (XMPPStream *)xmppStream;

@end



@implementation GSInternetXMPPConnection
@synthesize toJID = _toJID, IMSender = _IMSender;

- (id)initWithFriend:(XMPPJID *)toJID delegate:(id <SphereNetNetworkControllerDelegate>)delegate {
	if((self = [self init])) {
		// assign the delegate 
		_toJID = [toJID retain];
		_delegate = delegate;
		
		// TODO: put in a starting session method.
		[[self xmppStream] addDelegate:self];
		_IMSender = [[GSIMSender alloc] initWithNetworkDelegate:self];
		[_IMSender startToSendMessage];
	}
	return self;
}

- (void) dealloc {
	[[self xmppStream] removeDelegate:self];
	[_toJID release];
	[_IMSender release];
	[super dealloc];
}


#pragma mark Packet message

+ (NSArray *)sphereCommandFromMessage:(XMPPMessage *)message {
	NSString *bodyString = [[[message elementsForName:@"body"] objectAtIndex:0] stringValue];
	
	NSArray *sphereCommand = [bodyString componentsSeparatedByString:SphereNetDomainDelimiter];
	if ([[sphereCommand objectAtIndex:0] isEqualToString:SphereNetDomain]) {
		return [GSIMSender commandStringsFromString:[sphereCommand objectAtIndex:1]];
	}
	return nil;
}

+ (NSArray *)commandParamsFromSphereCommand:(NSString *)command {
	return [command componentsSeparatedByString:SphereNetCommandDelimiter];
}

+ (BOOL)isCommand:(NSArray *)commandComponents kindOfSphereCommand:(SphereNetCommand)sphereCommand {
	if (commandComponents == nil) {
		return NO;
	}
	
	return ([[commandComponents objectAtIndex:0] intValue] == sphereCommand);
}

#pragma mark Network Stream
- (id)appDelegate {
	return (AppController*)[[UIApplication sharedApplication] delegate];
}

- (XMPPStream *)xmppStream {
	return [[self appDelegate] xmppStream];
}


#pragma mark Network methods

- (void)sendMessageWithBody:(NSString *)bodyString {
	// send update via XMPP
	// send hello message
	NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
	
	// header
	XMPPJID *myJID = [[self xmppStream] myJID];
	NSString *fromString = [NSString stringWithFormat:@"%@@%@/%@", [myJID user], [myJID domain], [myJID resource]];
	NSString *toString = [NSString stringWithFormat:@"%@@%@/%@", [_toJID user], [_toJID domain], [_toJID resource]];	
	
	[message addAttributeWithName:@"from" stringValue:fromString];
	[message addAttributeWithName:@"to" stringValue:toString];
		
	// body
	
	NSXMLElement *bodyElement = [[[NSXMLElement alloc] initWithName:@"body" 
														stringValue:bodyString] autorelease];	
	
	[message addChild:bodyElement];
	[[self xmppStream] sendElement:message];
}

- (void)sendSphereMessageWithBody:(NSString *)bodyString {
	[self sendMessageWithBody:[NSString stringWithFormat:@"%@%@%@", 
							   SphereNetDomain,
							   SphereNetDomainDelimiter,
							   bodyString]];
}

- (NSString *)sphereNetBodyWithCommand:(SphereNetCommand)command params:(NSString *)params {
	return [NSString stringWithFormat:@"%d%@%@", 
			command, 
			SphereNetCommandDelimiter,
			params];
}

- (NSString *)sphereParamStringFromPositiveFloats:(double)firstFloat,... { // -1.0, at the end
	NSMutableString *paramsString = [NSMutableString string];
    va_list args;
    va_start(args, firstFloat);
    for (double arg = firstFloat; arg >= 0; arg = va_arg(args, double)) {
        [paramsString appendString:[NSString stringWithFormat:@"%g%@", arg, SphereNetCommandDelimiter]];
    }
    va_end(args);
    
	return [NSString stringWithString:paramsString];
}

- (void)sendUpdates {

	NSString *paramsString = [self sphereParamStringFromPositiveFloats:
							 _lastSentUpdate.position.x, 
							 _lastSentUpdate.position.y,
							 _lastSentUpdate.r,
							 _lastSentUpdate.g,
							 _lastSentUpdate.b,
							 -1.0];
	
//	[self sendSphereMessageWithBody:[self sphereNetBodyWithCommand:SphereNetCommandMoveToPosition
//															params:paramsString]];
	[self.IMSender sendMessage:[self sphereNetBodyWithCommand:SphereNetCommandMoveToPosition
													   params:paramsString]];
}
 
+ (void)sendCommand:(SphereNetCommand)command toRequesterJID:(XMPPJID *)requesterJID {
	GSInternetXMPPConnection *netController = [[[GSInternetXMPPConnection alloc] initWithFriend:requesterJID
																						   delegate:nil] autorelease];
	
	NSString *denyParams = [NSString stringWithFormat:@"%@",
							[[[netController xmppStream] myJID] user]];
	[netController sendSphereMessageWithBody:[netController sphereNetBodyWithCommand:command
																			  params:denyParams]];
}


+ (void)sendConnectMessageToRemoteJID:(XMPPJID *)remoteJID {
	[self sendCommand:SphereNetCommandConnect toRequesterJID:remoteJID];
}

+ (void)sendDenyMessageToRequesterJID:(XMPPJID *)requesterJID {
	[self sendCommand:SphereNetCommandDeny toRequesterJID:requesterJID];
}

+ (void)sendAcceptMessageToRequesterJID:(XMPPJID *)requesterJID {
	[self sendCommand:SphereNetCommandAccept toRequesterJID:requesterJID];
}

+ (void)sendDisconnectMessageToRequesterJID:(XMPPJID *)requesterJID {
	[self sendCommand:SphereNetCommandDisconnect toRequesterJID:requesterJID];
}

//- (void)sendRequestToJID:(XMPPJID *)toJID {
//	NSString *requestString = [NSString stringWithFormat:@"%@:%@", 
//							   SphereCommandConnect,
//							   [[[self xmppStream] myJID] user]];
//	[self sendMessageWithBody:requestString];	
//}


+ (NSString *)usernameFromSphereCommandRequest:(NSArray *)requestComponents {
	// TODO: component
	NSLog(@"request Array: %@", requestComponents);
	
	if ([self isCommand:requestComponents kindOfSphereCommand:SphereNetCommandConnect]) {
		return [requestComponents objectAtIndex:1];
	}
	return nil;
}

//- (void)localSphereDidMove:(SphereNetSphere *)sphere {
//	_lastSentUpdate.r = [sphere r]; 
//	_lastSentUpdate.g = [sphere g]; 
//	_lastSentUpdate.b = [sphere b]; 
//	_lastSentUpdate.position = [sphere position];
//	[self sendUpdates];	
//}

#pragma mark XMPPStream Delegate

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
//	NSLog(@"SphereNetNetworkController: didReceiveMessage.");
	
	NSArray *commands = [GSInternetXMPPConnection sphereCommandFromMessage:message];
	
	for (NSString *command in commands) {
		NSArray *requestParam = [GSInternetXMPPConnection commandParamsFromSphereCommand:command];
		NSLog(@"message Array: %@", requestParam);
		if ([GSInternetXMPPConnection isCommand:requestParam
							  kindOfSphereCommand:SphereNetCommandMoveToPosition]) {
			SphereNetSphereUpdate newPosition;
			newPosition.position.x = [[requestParam objectAtIndex:1] floatValue];
			newPosition.position.y = [[requestParam objectAtIndex:2] floatValue];
			newPosition.r = [[requestParam objectAtIndex:3] floatValue];
			newPosition.g = [[requestParam objectAtIndex:4] floatValue];
			newPosition.b = [[requestParam objectAtIndex:5] floatValue];
			
			
			[_delegate networkController:self
						didReceiveUpdate:newPosition];
		}
		
	}
}


- (void)IMSender:(GSIMSender *)sender triggerToSendMessage:(NSString *)message {
	[self sendSphereMessageWithBody:message];
}

#pragma mark Utilities
+ (NSString *)mergeAllString:(NSArray *)strings usingDelimiter:(NSString *)delimiter {
	NSMutableString *mergedString = [NSMutableString string];
	NSUInteger count = [strings count];
	
	if (count == 0) {
		return mergedString;
	}
	
	[mergedString appendString:[strings objectAtIndex:0]];
	NSUInteger index = 1;
	while (index < count) {
		[mergedString appendFormat:@"%@%@", delimiter, [strings objectAtIndex:index]];
		index ++;
	}
	return [NSString stringWithString:mergedString];
}
@end
