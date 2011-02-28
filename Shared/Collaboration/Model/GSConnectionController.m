//
//  GSConnectionController.m
//  Whiteboard
//
//  Created by Cong Vo on 12/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GSConnectionController.h"
#import "GSLocalConnection.h"

#import APP_DELEGATE




#import "Picker.h"

#import "GSConnection.h"
#import "GSWhiteboard.h"
#import "GSLocalWhiteboard.h"
#import "GSLocalWhiteboard+NSStreamDelegate.h"
#import "GSLocalConnection+TCPServerDelegate.h"
#import "GSWhiteboard.h"
#import "GSWhiteboardUser.h"
#import "GSViewHelper.h"

#import "GSLocalConnection.h"
#import "GSConnectionAlertManager.h"

#if INTERNET_INCLUDING
	#import "XMPP.h"
	#import "GSInternetConnection.h"

#endif

#if TARGET_OS_IPHONE
	#import "FlurryAPI.h"
	#import "GSConnectViewController.h"
    #import "GSConnectViewController.h"
#endif

@implementation GSConnectionController	
@synthesize localConnection = _localConnection;


@synthesize imageHexString = _imageHexString;
@synthesize receivingRemoteImage, sendingRemoteImage;

@synthesize receivingRemotePointSize;
@synthesize receivingRemoteColor;
@synthesize receivingRemoteName;



#if INTERNET_INCLUDING
@synthesize internetConnection = _internetConnection;
#endif
@synthesize connectionView = _connectionView;
@synthesize connectedWhiteboard = _connectedWhiteboard, waitedWhiteboard = _waitedWhiteboard, requestingWhiteboard = _requestingWhiteboard, nextWhiteboard = _nextWhiteboard;
@synthesize protocolVersion;
//@synthesize acceptReject = _acceptReject;
@synthesize status = _status;

@synthesize amServer;


/////////// new refactor

#pragma mark Handle Application State & Event

- (BOOL)isSourceFromLocalConection:(id)source {
	return [source isKindOfClass:[NSStream class]];
}

////////////////////////////////////////////////////////////
#pragma mark NotYetConnected

- (NSString *)statusDescription:(ConnectionStatus)status {
	switch (status) {
		case ConnectionStatusNotYetConnected:
			return @"ConnectionStatusNotYetConnected";
			break;
		case ConnectionStatusConnected:
			return  @"ConnectionStatusConnected";
			break;
		case ConnectionStatusInConnecting:
			return @"ConnectionStatusInConnecting";
			break;			
		default:
			break;
	}
	return nil;
}

#define StatusLog
//#define StatusLog DLog(@"\nSTATUS: %@ - waited: [%@] - requesting: [%@] - connected: [%@] - isConflict: %d - amServer: %d", [self statusDescription:_status], _waitedWhiteboard, _requestingWhiteboard, _connectedWhiteboard, _isConnectingConflict, amServer);

#define WarningLog DLog(@"WARNING: UNEXPECTED SITUATION. SHOULD NOT GO HERE ------------------------------------------------!"); StatusLog
#define GetUnexpectedSituation  WarningLog //[self resetToStartingStatus];


- (void)resetToStartingStatus {
//	WarningLog
	self.connectedWhiteboard = nil;
	self.waitedWhiteboard = nil;
	self.requestingWhiteboard = nil;
	_status = ConnectionStatusNotYetConnected;
	
	AppDelegate.remoteDevice = iPhoneDevice;
#if TARGET_OS_IPHONE
	[AppDelegate.picker setConnectedName:nil];
	
	[AppDelegate displayProgressView:NO];
	#if INTERNET_INCLUDING			
		[_internetConnection setConnectedWhiteboard:nil];
	#endif	
#else
	[AppDelegate clearConnectedDeviceName];
#endif	

}

// [1.2]
- (void)userSelectedFriendInNotYetConnected:(GSWhiteboard *)selectedWhiteboard {
	StatusLog

	self.waitedWhiteboard = selectedWhiteboard;
	
	[AppDelegate.connection initateSessionWithWhiteBoard:selectedWhiteboard];
	self.status = ConnectionStatusInConnecting;
	
}

// [1.3]
- (void)receivedConnectionRequestInNotYetConnected:(id <GSWhiteboard>)requester
										 showAlert:(BOOL)willShow /* this attribute for code reused with [3.4] */ { 
	StatusLog
	/*
	 ***** Save requestingWhiteboard
	 ***** Action: Alert user
	 ***** Changing to connecting status			 
	 */
	
	//KONG: update status 	
	self.requestingWhiteboard = requester;
	self.status = ConnectionStatusInConnecting;
	
	
	
	DLog(@"Server's Normal procedure: no conflict detected (yet!)");
	
	// Assume whiteboard protocol version 1 until we hear otherwise
	DLog(@"protocolVersion = 1");
	protocolVersion = 1;
	
	AppDelegate.remoteDevice = iPhoneDevice; // assume remoteDevice is an iPhone until we hear otherwise

	NSString *alertTitle =[NSString stringWithFormat:@"“%@” would like to join your whiteboard", _requestingWhiteboard.name];
	GSConnectionAlert * requestingAlert = [GSConnectionAlert alertWithDelegate:self
																		 title:alertTitle message:nil
																 defaultButton:@"OK"
																   otherButton:@"Don't Allow"];	
	
	requestingAlert.tag = AlertTagCollaborationConnectionRequest;
	requestingAlert.action = AlertActionAskForConnect;
	requestingAlert.affectedPeer = _requestingWhiteboard;
		
	if (willShow) {
		[_alertManager showAlertView:requestingAlert];
	}
	
}

////////////////////////////////////////////////////////////
#pragma mark Connecting

- (void)showAlertTitle:(NSString *)title message:(NSString *)message button:(NSString *)cancelTitle
				action:(AlertAction)action peer:(GSWhiteboard *)whiteboard{
	
	GSConnectionAlert *alertView = [GSConnectionAlert alertWithDelegate:self
																  title:title message:message
														  defaultButton:cancelTitle
															otherButton:nil];	
	alertView.action = action;
	alertView.affectedPeer = whiteboard;
	[_alertManager showAlertView:alertView];	
}

- (void) showRequestAcceptedAlert {
	if (_connectedWhiteboard == nil) {
		return;
	}
	
	[self showAlertTitle:[NSString stringWithFormat:@"“%@” has accepted your request", _connectedWhiteboard.name]
				 message:@"You are now drawing together!"
				  button:@"Continue"
				  action:AlertActionAccepted
					peer:_connectedWhiteboard];
}

- (void)receivedAcceptedMessageInConnectingWaitingFrom:(id)source { // [2.1]
	StatusLog
	// this method can be call more than once
	if (initializedWithPeers) {
		DLog(@"already initialized with peer");
		return;
	}
	
	initializedWithPeers = YES;

	//KONG: update status 
	self.connectedWhiteboard = _waitedWhiteboard;
	self.waitedWhiteboard  = nil;
	//KONG: Update status
	self.status = ConnectionStatusConnected;
	
	// Set labels in the Lite version's UI
	//((UILabel*)[_picker viewWithTag:kWaitingTag]).text = @"Your whiteboard's name is:";
	//((UILabel*)[_picker viewWithTag:kOrJoinTag]).text = @"Whiteboards on this network:";
	
	// No need to refresh the tableView
	//[[[_picker bvc] tableView] reloadData];
	
	// Tell the user on the client device that their request was accepted
	if (amServer ==  NO) {
		[self showRequestAcceptedAlert];

	}	
	
	
	// For Whiteboard Pro, make sure the client AND server both send this message
	// This is the "protocol version" (protocolVersion)
	// It defaults to 1, but becomes 2 when this message is received:
	[self send:@"2}}"];
	
	//
	// If I'm an iPad, tell my peer.
	//

#if TARGET_OS_IPHONE
	if (IS_IPAD) {
		[self send:[NSString stringWithFormat:@"%@}}", kiPadMessage]];
	}
#else
	[self send:[NSString stringWithFormat:@"%@}}", kiPadMessage]];
#endif	
	
	//KONG: UI stuff 
	[AppDelegate sendMyColor];
	[AppDelegate sendMyPointSize];	
	
	//#if IS_WHITEBOARD_HD
	// time session
	// [FlurryAPI logEvent:@"EVENT_NAME" withParameters:YOUR_NSDictionary timed:YES];
	// Use this version of logEvent to start timed event with event parameters.
	// [FlurryAPI endTimedEvent:@"EVENT_NAME" withParameters:nil];
#if TARGET_OS_IPHONE	
	[FlurryAPI logEvent:@"connected" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:AppDelegate.runCount], @"runCount", nil] timed:YES];
#endif	
	//#else
	//			[[Beacon shared] startSubBeaconWithName:@"connected" timeSession:YES]; // Pinch Media Analytics
	//#endif
	//[self presentTools];
	//[self hideToolsWithDialog:NO]; // hide the drawing tools		
}

//KONG: currently, assume that sender for this methos only is _waitedWhiteboard
- (void)receivedRejectedMessageInConnectingFromWaitedWhiteboardShowAlert:(BOOL)willAlert { // [2.2]
	StatusLog
	
	//
	
	// This method can be called more than once
	if (initializedWithPeers) return;
	initializedWithPeers = YES;
	
	if ([NSThread isMainThread]) {
		DLog(@"on MainThread");
	} else {
		DLog(@"NOT on MainThread");
	}
    
	NSString *alertTitle = [NSString stringWithFormat:@"“%@” has rejected your request", _waitedWhiteboard.name];
	GSConnectionAlert *alertView = [GSConnectionAlert alertWithDelegate:self
																  title:alertTitle 
																message:@"If you wish, you may try your request again."
														  defaultButton:@"Continue"
															otherButton:nil];	
	alertView.action = AlertActionRejected;
	alertView.affectedPeer = _waitedWhiteboard;
	
	if (willAlert) {
		[_alertManager showAlertView:alertView];		
	}

	[_waitedWhiteboard disconnect];
	//KONG: update status 
	self.waitedWhiteboard = nil;
	self.status = ConnectionStatusNotYetConnected;

}

//- (void)userSelectedFriendInConnectingWaiting:(GSWhiteboard *)selectedWhiteboard { // [2.3]
//KONG: reused this method: - (void)showDisconnectQuestion:currentWhiteboard selectedWhiteboard:selectedWhiteboard

- (void)userDecidedToDisconnect { // [2.4.1], [3.7]
	StatusLog

	GSWhiteboard *disconnectWhiteboard = nil;
	
	if (_status == ConnectionStatusInConnecting && _waitedWhiteboard != nil) {
		disconnectWhiteboard = _waitedWhiteboard;
	} else if (_status == ConnectionStatusConnected) {
		disconnectWhiteboard = _connectedWhiteboard;
	} else {
		return;
	}
	
	[disconnectWhiteboard sendDisconnectMessage];
	[disconnectWhiteboard disconnect];
	
	if (_status == ConnectionStatusConnected) {
#if TARGET_OS_IPHONE		
		[FlurryAPI endTimedEvent:@"connected" withParameters:nil];		
#endif		
	}
	
	//KONG: update status 
	amServer = NO;
	self.requestingWhiteboard = nil; //KONG: just for sure
	self.connectedWhiteboard = nil;
	self.waitedWhiteboard = nil;
	self.status = ConnectionStatusNotYetConnected;
}

- (void)userAcceptedConnectionRequestInConnectingRequesting { // [2.9]
	StatusLog
	
	// acceptPendingRequest:withName: on MainThread
	if ([NSThread isMainThread]) {
		DLog(@"on MainThread");
	} else {
		DLog(@"NOT on MainThread");
	}
	//KONG: update status
	self.connectedWhiteboard = _requestingWhiteboard;
	self.requestingWhiteboard = nil;
	amServer = YES;
	// updated status to reset the state before send any initializing message
	self.status = ConnectionStatusConnected;
    [self.connectedWhiteboard resetStateForNewConnection];

	
	// For Whiteboard Pro, make sure the client AND server both send this message (protocolVersion)
	[_connectedWhiteboard send:@"2}}"];		
	//
	// If I'm an iPad, tell my peer.
	//
#if TARGET_OS_IPHONE
	if (IS_IPAD) {
		[self send:[NSString stringWithFormat:@"%@}}", kiPadMessage]];
	}
#else
	[self send:[NSString stringWithFormat:@"%@}}", kiPadMessage]];
#endif	
	
	DLog(@"server sending pointSize"); // too early, send again when iPad message is received	
	[AppDelegate sendMyColor];
	[AppDelegate sendMyPointSize];
	
	//#if IS_WHITEBOARD_HDreceivingRemoteName
#if TARGET_OS_IPHONE	
	[FlurryAPI logEvent:@"connected" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:AppDelegate.runCount], @"runCount", nil] timed:YES];
#endif	
	//#else
	//		[[Beacon shared] startSubBeaconWithName:@"connected" timeSession:YES];
	//#endif
	
	//  Remember: this is server code, running on the server.
	
//	[[NSNotificationCenter defaultCenter] postNotificationName:@"kConnectedNotification" object:nil];		
}

- (void)userRejectedConnectionRequestInConnectingRequesting { // [2.10]
	[_requestingWhiteboard send:@"s}}r}}"];
	[_requestingWhiteboard disconnect];	
	
	// set status
	amServer = NO;
	self.requestingWhiteboard = nil;
	self.status = ConnectionStatusNotYetConnected;
}

- (void)receivedConnectionRequestInConnecting:(GSWhiteboard *)requester {
	StatusLog
	[self rejectedSilentlyConnectionRequest:requester];
}

- (void)receivedNetworkUnavailableSignal:(GSConnectionType)networkType {
	if (networkType == GSConnectionTypeInternet) {
		DLog(@"GSConnectionTypeInternet");
		
	} else if (networkType == GSConnectionTypeLocal) {
		DLog(@"GSConnectionTypeLocal");
	}
	
	
	if (_status == ConnectionStatusConnected && _connectedWhiteboard.type == networkType) {
		self.connectedWhiteboard = nil;
		self.status = ConnectionStatusNotYetConnected;
	} else if (_status == ConnectionStatusInConnecting 
			   && (_waitedWhiteboard.type == networkType
				   || _requestingWhiteboard.type == networkType)) {
				   self.waitedWhiteboard = nil;
				   self.requestingWhiteboard = nil;
				   self.status = ConnectionStatusNotYetConnected;
			   }
	
	[_connectionView networkUnavailable:networkType];
}

////////////////////////////////////////////////////////////
#pragma mark Connected


// TODO: KONG - check for source of connection
//- (void)userRejectedConnectionRequest {
//	// TODO: refactor this
//	if (_requestingWhiteboard.type == GSConnectionTypeInternet) {
//		[_internetConnection send:@"s}}r}}" toWhiteboard:_requestingWhiteboard];
//		
//		
//		// Added this so acceptReject.name indicates that there's an ongoing incoming connection
//		DLog(@"[_acceptReject setName:nil];");
////		[_acceptReject setName:nil];
//		return;
//	} else {
//		[_localConnection sendRejectMessageAndCloseAllStreamsFrom:_requestingWhiteboard.name];
//	}
//	
//	self.requestingWhiteboard = nil;		
//	
//	// Added this so acceptReject.name indicates that there's an ongoing incoming connection
//	DLog(@"[_acceptReject setName:nil];");
////	[_acceptReject setName:nil];	
//}

- (void)rejectedSilentlyConnectionRequest:(GSWhiteboard *)requester {
	StatusLog
	//KONG: choose a more meaningful message, when you are busy 
	[requester send:@"s}}r}}"];
	[requester disconnect];
}


- (void)showDisconnectQuestion:(GSWhiteboard *)currentWhiteboard selectedWhiteboard:(GSWhiteboard *)selectedWhiteboard {
	
	NSString* message = @"";
	// choose same field -> disconnect
	if ([currentWhiteboard.name isEqual:selectedWhiteboard.name]) {
		//message = @"";
	} else {
		_nextWhiteboard = [selectedWhiteboard retain];
		message = [NSString stringWithFormat:@"You will then connect to “%@”", _nextWhiteboard.name];
	}
	
	// Show disconnect confirmation
	
	NSString *alertTitle = [NSString stringWithFormat:@"Do you want to disconnect from “%@”?", currentWhiteboard.name];
	GSConnectionAlert *alertView = [GSConnectionAlert alertWithDelegate:self
																  title:alertTitle 
																message:message
														  defaultButton:@"Yes"
															otherButton:@"No"];
	alertView.tag = AlertTagCollaborationDisconnect; // [dC]
	alertView.action = AlertActionDisconnected;
	alertView.affectedPeer = currentWhiteboard;
	
	if (_nextWhiteboard) {
		alertView.secondAction = AlertActionAskForConnect;
		alertView.secondAffectedPeer = _nextWhiteboard;
	}
	
	[_alertManager showAlertView:alertView];
//	[alertView show];
}

//KONG: currently, this is called when you are connected and receive another connection request 
- (void)showConnectionRequestQuestionFor:(id <GSWhiteboard>)requester currentWhiteboard:(GSWhiteboard *)currentWB {
	StatusLog
	
	NSString *message = nil;
	//KONG: check if request come from connected friend or not
	// If YES: this request is unexpected, but we still process it
	if ([self isWhiteboard:currentWB usingSource:requester.source] == NO) {
		message = [NSString stringWithFormat:@"Do you want to disconnect with “%@”?", currentWB.name];
//		self.nextWhiteboard = [self whiteboard:name source:source];
		self.nextWhiteboard = requester;
	}

	NSString *alertTitle = [NSString stringWithFormat:@"“%@” would like to join your whiteboard", requester.name];
	GSConnectionAlert *requestingAlert = [GSConnectionAlert alertWithDelegate:self
																  title:alertTitle 
																message:message
														  defaultButton:@"OK"
															otherButton:@"Don't Allow"];
	
	requestingAlert.tag = AlertTagCollaborationConnectionRequest;
	requestingAlert.action = AlertActionAskForConnect;
	requestingAlert.affectedPeer = _nextWhiteboard;
	
	if (_nextWhiteboard) {  //KONG: message != nil means you want to disconnect to other
		// TODO: KONG - Add disconnected peer 

		requestingAlert.action = AlertActionDisconnected;
		requestingAlert.affectedPeer = currentWB;
		
		
		requestingAlert.secondAction = AlertActionAskForConnect;
		requestingAlert.secondAffectedPeer = _nextWhiteboard;
	}
	
	[_alertManager showAlertView:requestingAlert];		
}

- (void)resetIsConnectingConflictState {
	_isConnectingConflict = NO;
}

- (void)solveConnectingConflictRequestFrom:(GSWhiteboard *)sender {
	StatusLog
	

	self.requestingWhiteboard = sender;	

	//KONG: if connection request from local source -> solve conflict
	// from internet connection -> just accept
	
	[sender.connection solveConflictWhenReceiveConnectionRequest:sender];
	
}

static NSString * const kDisconnectReasonDisconnect = @"has disconnected";
static NSString * const kDisconnectReasonCancel = @"canceled request";
static NSString * const kDisconnectReasonUnavailable = @"is unavailable";

- (void)showDisconnectedAlertFor:(GSWhiteboard *)whiteboard reason:(NSString *)reason {
	[self showAlertTitle:[NSString stringWithFormat:@"“%@” %@", [whiteboard name], reason]
				 message:nil
				  button:@"Continue"
				  action:AlertActionDisconnected
					peer:whiteboard];	
}

- (BOOL)receivedDisconnectedMessageFrom:(GSWhiteboard *)currentWhiteboard reason:(NSString *)reason {
	StatusLog
	/*
	 Show user request canceled message
	 Close connection
	 Set NotYetConnected status
	 */
	[self showDisconnectedAlertFor:currentWhiteboard reason:reason];

	[currentWhiteboard disconnect];
	
	//KONG: update status 
	amServer = NO;
	self.connectedWhiteboard = nil;
	self.waitedWhiteboard = nil;
	self.requestingWhiteboard = nil;
	self.nextWhiteboard = nil;
	self.status = ConnectionStatusNotYetConnected;
	
	return YES;
}

- (void)initiateConnection {
	DLog(@"amServer = NO;");
	amServer = NO;
	
	// initiateConnection on MainThread
	//	if ([NSThread isMainThread]) {
	//		DLog(@"%s on MainThread", _cmd);
	//	} else {
	//		DLog(@"%s NOT on MainThread", _cmd);
	//	}
	
	// need to send color and present tools, but it's not safe to do so here
	initializedWithPeers = NO;
	
//	_localConnection->needToSendName = YES;
	// wait until we get acceptance or rejection
}



///////////////////
#pragma mark collaboration based on events

- (void)userSelectedWhiteboard:(GSWhiteboard *)selectedWhiteboard {
	StatusLog
	
	//KONG: we can reset the conflict status in an event that can cause a Connection Request conflict 
	_isConnectingConflict = NO;	
	
	if (_status == ConnectionStatusInConnecting && _waitedWhiteboard != nil) { // [2.3]
		[self showDisconnectQuestion:_waitedWhiteboard selectedWhiteboard:selectedWhiteboard];
		return;
	} 
	
	if (_status == ConnectionStatusConnected && _connectedWhiteboard != nil) { // [3.4]
		[self showDisconnectQuestion:_connectedWhiteboard selectedWhiteboard:selectedWhiteboard];
		return;
	}

	if (_status == ConnectionStatusNotYetConnected && _connectedWhiteboard == nil) { // [1.2]
		[self userSelectedFriendInNotYetConnected:selectedWhiteboard];
		return;
	}
	
	GetUnexpectedSituation
	//KONG: get the unexpected situation when received a user's command.
	// we should reset the Connection status here
	[self resetToStartingStatus];
}

- (void)receivedConnectionRequestFrom:(GSWhiteboard *)sender name:(NSString *)name{
	StatusLog
	/*
	 - Check for the connection type
	 - Handle in each case
	 */

	//KONG: we can reset the conflict status in an event that can cause a Connection Request conflict 
	_isConnectingConflict = NO;

	sender.name = name;
	DLog(@"received Connection Request from: %@", sender.name);	
	if (_status == ConnectionStatusNotYetConnected && _connectedWhiteboard == nil) {
		[self receivedConnectionRequestInNotYetConnected:sender showAlert:YES];
		return;
	}
	
	if (_status == ConnectionStatusInConnecting && _waitedWhiteboard!= nil  // already request a peer, and waiting for his reply
		&& _waitedWhiteboard.type == sender.type // requesting peer come from the same connection type, and same peer name
		&& [_waitedWhiteboard.name isEqualToString:sender.name]) { // [2.7] - conflict
		_isConnectingConflict = YES;
		[self solveConnectingConflictRequestFrom:sender];
		return;
	}	
	
	if (_status == ConnectionStatusInConnecting && (_waitedWhiteboard != nil || _requestingWhiteboard != nil)) { // [2.11] - reject silently
		//KONG: check for _waitedWhiteboard OR _requestingWhiteboard 
		[self receivedConnectionRequestInConnecting:sender];
		//[self rejectedSilentlyConnectionRequest:name source:source];
		return;
	}

	if (_status == ConnectionStatusConnected && _connectedWhiteboard != nil) { //[3.3]
		[self showConnectionRequestQuestionFor:sender currentWhiteboard:_connectedWhiteboard];
		return;
	}
	GetUnexpectedSituation
}

- (void)receivedAcceptedMessageFrom:(id)source  { // [2.1]
	if (_status == ConnectionStatusInConnecting && _waitedWhiteboard != nil) { //[2.1]
		[self receivedAcceptedMessageInConnectingWaitingFrom:source];
		return;
	}
	//KONG: Other case 
	//KONG: received in Connected Status, from the _connectedWhiteboard is OK
}

- (void)receivedRejectedMessageFrom:(GSWhiteboard *)sender {
	// TODO: KONG - check for appropriate source 
	if (_status == ConnectionStatusInConnecting && 
		[self isWhiteboard:sender identicalWith:_waitedWhiteboard]) {
		[self receivedRejectedMessageInConnectingFromWaitedWhiteboardShowAlert:YES];
		return;
	}
	GetUnexpectedSituation
}

- (BOOL)receivedDisconnectedMessageFrom:(GSWhiteboard *)sender {
//	DLog(@"source: %@", source);	
	StatusLog

	if (_status == ConnectionStatusInConnecting && _isConnectingConflict) { // [2.7]
		// << do nothing >>
		//KONG: I just put this here to cover all the cases 
		DLog(@" - in Conflict mode: stream %@", sender);
		return NO;
	}
	
	if (_status == ConnectionStatusInConnecting && [self isWhiteboard:sender identicalWith:_requestingWhiteboard]) { // [2.8]		
		return [self receivedDisconnectedMessageFrom:_requestingWhiteboard reason:kDisconnectReasonCancel];

	}
	if (_status == ConnectionStatusInConnecting && [self isWhiteboard:sender identicalWith:_waitedWhiteboard]) { // [2.2]
		return [self receivedDisconnectedMessageFrom:_waitedWhiteboard reason:kDisconnectReasonDisconnect];
	}
	
	if (_status == ConnectionStatusConnected && _connectedWhiteboard!= nil && 
		[self isWhiteboard:sender identicalWith:_nextWhiteboard]) { // []
		// TODO: check for name
		[self showDisconnectedAlertFor:_nextWhiteboard reason:kDisconnectReasonCancel];
		return YES;
	}
	
	if (_status == ConnectionStatusConnected && 
		[self isWhiteboard:sender identicalWith:_connectedWhiteboard]) { //[3.2.2]
		// TODO: check for name
		if ([self receivedDisconnectedMessageFrom:_connectedWhiteboard reason:kDisconnectReasonDisconnect]) {
#if TARGET_OS_IPHONE			
			[FlurryAPI endTimedEvent:@"connected" withParameters:nil];
#endif			
			return YES;
		};
	}
//	GetUnexpectedSituation
	return NO;
}

- (BOOL)receivedPeerUnavailableSignalFrom:(GSWhiteboard *)sender {
	return [self receivedDisconnectedMessageFrom:sender];
	
	/*
	
	DLog(@"source: %@", source);
	if (_status == ConnectionStatusInConnecting && [self isWhiteboard:_requestingWhiteboard usingSource:source]) { // [2.8]
		// TODO: dismiss requesting alert
		
		
//		return [self receivedDisconnectedMessageInConnectedAlertingFromSource:source whiteboard:_requestingWhiteboard reason:kDisconnectReasonUnavailable];
		return [self receivedDisconnectedMessageFromSource:source whiteboard:_requestingWhiteboard reason:kDisconnectReasonUnavailable];

	}
	if (_status == ConnectionStatusInConnecting && _waitedWhiteboard != nil) {
		return [self receivedDisconnectedMessageFromSource:source whiteboard:_waitedWhiteboard reason:kDisconnectReasonUnavailable];
	}
	if (_status == ConnectionStatusInConnecting && _isConnectingConflict) {
		// << do nothing >>
		//KONG: I just put this here to cover all the cases 
		DLog(@" - in Conflict mode: stream %@", source);
		return NO;
	}
	if (_status == ConnectionStatusConnected && _nextWhiteboard != nil) { // [3.2.2]
		// TODO: check for name
		return [self receivedDisconnectedMessageInConnectedAlertingFromSource:source 
															whiteboard:_nextWhiteboard reason:kDisconnectReasonCancel];
	}

	if (_status == ConnectionStatusConnected && _connectedWhiteboard != nil ) {
		// check if we did handle this situation
		if ([self receivedDisconnectedMessageFromSource:source whiteboard:_connectedWhiteboard reason:kDisconnectReasonUnavailable]){
			return YES;
		}
		
		return NO;
	}	
	
	if (_status == ConnectionStatusConnected && _connectedWhiteboard != nil) {
		if ([self receivedDisconnectedMessageFromSource:source whiteboard:_connectedWhiteboard reason:kDisconnectReasonUnavailable]){
			[FlurryAPI endTimedEvent:@"connected" withParameters:nil];
			return YES;
		}

		return NO;
	}
	return NO;
	*/
}

#pragma mark Alert View and Methods to handle User answer

- (void)userAnswer:(BOOL)yesOrNo forFriendRequestAlertView:(GSAlert *)alertView {
	
//	_localConnection->pendingJoinRequest = NO;
	if (_status == ConnectionStatusInConnecting && _requestingWhiteboard != nil) { // [2.8]
		if (yesOrNo == YES) { // [2.9]
			[self userAcceptedConnectionRequestInConnectingRequesting];
		} else { // [2.10]
			[self userRejectedConnectionRequestInConnectingRequesting];
		}
		return;
	}
	
	if (_status == ConnectionStatusConnected) {
		if (yesOrNo == YES) { // [3.4]
			[self userDecidedToDisconnect];
			if (_nextWhiteboard) {
				[self receivedConnectionRequestInNotYetConnected:_nextWhiteboard
													   showAlert:NO];
				self.nextWhiteboard = nil;
				[self userAnswer:YES forFriendRequestAlertView:alertView];
			}
			
		} else { 
			if (_nextWhiteboard) { // [3.5]
				[_nextWhiteboard send:@"s}}r}}"];
				[_nextWhiteboard disconnect];
				self.nextWhiteboard = nil;				
			}
		}
		return;
	}
	
}

- (void)userAnswer:(BOOL)yesOrNo forDisconnectAlertView:(GSAlert *)alertView {
//	GSWhiteboard *currentWhiteboard = nil;


	if (yesOrNo == YES) { // [2.4] && [3.7]
		[self userDecidedToDisconnect];
		StatusLog
		if (_nextWhiteboard) {
			[self userSelectedFriendInNotYetConnected:_nextWhiteboard];
			self.nextWhiteboard = nil;
		}
	} else { 
		// [2.10]
		// <<do nothing>>
	}
}

- (void)alertView:(GSAlert *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if ([alertView isKindOfClass:[GSConnectionAlert class]]) {
		DLog();		
		[_alertManager alertView:alertView didDismissWithButtonIndex:buttonIndex];
	}

}

- (void)alertView:(GSAlert*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	DLog(@"alert tag: %uld clicked buttonIndex: %d", alertView.tag, buttonIndex);
	
	
	BOOL answer = NO;
	if (buttonIndex == 1) {
		answer = YES;
	} else if (buttonIndex > 1) {
		DLog (@"dismiss Alert View");
		return; // dismiss alertView intensionally
	}
	
	switch (alertView.tag) {
		case AlertTagCollaborationConnectionRequest: // [RE] Connection REquest
			[self userAnswer:answer forFriendRequestAlertView:alertView];
			break;
		case AlertTagCollaborationDisconnect: // [dC] disConnect
			[self userAnswer:answer forDisconnectAlertView:alertView];
			break;
			
			
//KONG: Image 			
		case AlertTagImageSend:
			if(answer == NO){
				//This is the sender's image transfer alert view
				//Sender Cancelled image transfer
				//			[self send:@"Z}}"];
				receivingRemoteImage = NO;
				[self send:@"Z}}"];
			}
			else {
				//This is the sender's image transfer alert view
				//This alert has been finished!
			}
			break;
		case AlertTagReceiveImage:
			if(answer == NO){
				//This is the receiver's image transfer alert view
				//Receiver pressed NO to reject image transfer
				receivingRemoteImage = NO;
				[self send:@"X}}"];
			}
			else {
				//This is the receiver's image transfer alert view
				//Receiver pressed YES to accept image transfer		
				receivingRemoteImage = YES;				
				[AppDelegate displayProgressView:YES]; //Show progress view
				[self send:@"Y}}"];
			}
			break;
			
//KONG: Start Over
		case AlertTagStartOverSend:
			// Cancel request (L)
			[self send:@"L}}"];			
			break;
		case AlertTagStartOverReceive:
			if (answer == YES) {
				// Yes
				[AppDelegate acceptStartOverRequest];
			} else {
				// No
				// Send erase reject reply (j)
				[self send:@"j}}"];
			}
			break;
			
		default:
			break;
	}
	
}

///////////
- (id)init {
	if ((self = [super init])) {
		_localConnection = [[GSLocalConnection alloc] init];	
#if INTERNET_INCLUDING
		_internetConnection = [[GSInternetConnection alloc] init];
		_connectionView = [[GSConnectViewController alloc] initWithInternetConnection:_internetConnection
																		 localBrowser:_localConnection.bvc];
#else
		
#endif				


		_alertManager = [[GSConnectionAlertManager alloc] init];
	}
	return self;
}

- (void) dealloc {
	[super dealloc];
}


- (void)startToConnect {
	initializedWithPeers = YES; // No peers yet
	
#ifndef LITE
	//SHERWIN: Setting my uninitalized variables
	sendingRemoteImage = NO;
	receivingRemoteImage = NO;
//	peerReadyToReceive = NO;
#endif	

	receivingRemoteColor = NO;	
	receivingRemotePointSize = NO;
	receivingRemoteName = NO;
	receivingText = NO;
	receivingTextFont = NO;
	receivingTextSize = NO;
	receivingTextPosition = NO;

	[_localConnection startToConnect];
#if INTERNET_SUPPORTING	
	[_internetConnection startToConnect];
#endif	
}

- (void)stopConnecting {
	[self userDecidedToDisconnect];
	
	[_localConnection stopConnecting];
#if INTERNET_SUPPORTING	
	[_internetConnection stopConnecting];
#endif
	DLog(@"whiteboard count: %d", [GSWhiteboard whiteboardCount]);
	
}

- (void)startToBroadcast {
	[_localConnection startToBroadcast];
#if INTERNET_SUPPORTING
	[_internetConnection startToBroadcast];
#endif

}

- (void)stopBroadcasting {
	[_localConnection stopBroadcasting];
#if INTERNET_SUPPORTING	
	[_internetConnection stopBroadcasting];	
#endif	
}

#pragma mark sending

- (void)send:(NSString *)message {
	if (_connectedWhiteboard == nil) {
		return;
	}

//	NSLog(@"WHITEBOARD's SENDING: %@", message);
	
//	[_connectedWhiteboard.connection sendToConnectedWhiteboard:message];
	[_connectedWhiteboard send:message];
}

#pragma mark sending image

- (void)initiateImageTransfer:(NSString*)imageHex {
	//Save the image data
	self.imageHexString = imageHex;
	
	if(!imageHex) return;
	
	DLog(@"App Delegate: Requesting image transfer with peer!");
	
	//1. First send header to notify start of image transfer, and the number of bytes to expect
	[self send: [NSString stringWithFormat:@"<I--N:%d}}", [imageHex length]] ];
	
	// Show the transfer wait
	
	GSAlert *imageSendTransferAlert = [GSAlert alertWithDelegate:self
												  title:
							  [NSString stringWithFormat:@"Asking “%@” to Accept Image", _connectedWhiteboard.name]
												message:@"Please wait for their reply..."
										  defaultButton:@"Cancel"
											otherButton:nil];
#if TARGET_OS_IPHONE	
	[imageSendTransferAlert addSpinnerForName:_connectedWhiteboard.name];
#endif	
	imageSendTransferAlert.tag = AlertTagImageSend;
	[imageSendTransferAlert registerToReceiveNotificationForSelector:@selector(dismiss)];
	[imageSendTransferAlert registerToReceiveNotificationForSelector:@selector(changeMessage:)];
	[imageSendTransferAlert show];
}

- (void)stopImageTransfer {

	[GSAlert postNotificationToAlertTag:AlertTagImageSend
							   selector:@selector(dismiss) 
								 object:nil];	
	self.imageHexString = nil;
	
	[GSViewHelper showAlertViewTitle:@"Image Transfer Rejected!"
							 message:[NSString stringWithFormat:@"“%@” has rejected your request!", _connectedWhiteboard.name]
						cancelButton:@"OK"];
}

- (void)sendImageHexData:(NSString*)imageData {
	[GSAlert postNotificationToAlertTag:AlertTagImageSend
							   selector:@selector(changeMessage:) 
								 object:@"Accepted! Sending image..."];
	
	sendingRemoteImage = YES;
	DLog(@"App Delegate: Sending image hex data to peer: %d", [imageData length]);
	
	
	[_connectedWhiteboard sendLargeDataByChunks:imageData];
	//[self send:[NSString stringWithFormat:@"<I--}}%@}}--/I>}}", imageData]];
}

- (void)finishSendingImageHexData {
	DLog(@"App Delegate: Finished sending image hex data to peer!");
	sendingRemoteImage = NO;
	[GSAlert postNotificationToAlertTag:AlertTagImageSend 
							   selector:@selector(dismiss) 
								 object:nil];		
	
	self.imageHexString = nil;
	
	[AppDelegate.drawingView performSelectorOnMainThread:@selector(renderImage) withObject:nil waitUntilDone:NO];
	//[drawingView renderImage];	
}

- (void)receivedImageTransferRequest:(GSWhiteboard *)sender {

}

#pragma mark Process Message

- (void)processMessage:(NSString *)message source:(GSWhiteboard *)sender {
	// TODO: KONG - seperate which message is only processed when in connected status 
	
//	NSLog(@"processing Message: %@", message);
//	NSStream *stream = nil;
//	NSString *wb = nil;
//	if ([source isKindOfClass:[NSStream class]]) {
//		stream = source;
//	}
//	else if ([source isKindOfClass:[NSString class]]) {
//		wb = source;
//	}
	
	//DLog(@"message = %@", message);
	
	
	
	NSArray* points = [message componentsSeparatedByString:@"}}"];
	for(message in points) {
		// Watch out for blank "messages"!
		
		// handle remote color changes
		//DLog(@"starting for loop, receivingRemoteColor = %d", receivingRemoteColor);
		
		//SHERWIN: Handle receiving images first
		if(USE_HEX_STRING_IMAGE_DATA) {
		
			static NSMutableString *imageHexData = nil;
			static int imageByteSize = 0;
			
			if(!receivingRemoteImage){ //Not in receiving image state
				if([message hasPrefix:@"<I--N:"]){ 
					//Sender requesting image transfer
					//[self receivedImageTransferRequest:sender];
					
					if (sender != _connectedWhiteboard) {
						continue;
					}
					DLog(@"Received request for remote image transfer! (hex string format)");
					
					//Initialize the necessary variables for image transfer
					[imageHexData release];
					imageHexData = [[NSMutableString alloc] init];
					imageByteSize = [[message substringFromIndex:6] intValue];
					DLog(@"Remote image size expected is %d", imageByteSize);
					
					GSAlert *imageReceiveTransferAlert = [GSAlert alertWithDelegate:self
																			  title:
														  [NSString stringWithFormat:@"“%@” would like to open an image", _connectedWhiteboard.name] 
																			message:@"This will transfer the image\nto your whiteboard."
																	  defaultButton:@"OK"
																		otherButton:@"Don't Allow"];
					
					imageReceiveTransferAlert.tag = AlertTagReceiveImage;
					
					[imageReceiveTransferAlert registerToReceiveNotificationForSelector:@selector(dismiss)];					
					
					[imageReceiveTransferAlert show];
					continue;
				}
				else if([message isEqualToString:@"disconnect"]){
					//[_internetConnection receiveDisconnectMessageFrom:source];
					[self receivedDisconnectedMessageFrom:sender];
				} 
				else if([message isEqualToString:@"Z"]){ // Z}}
					//if (receivingRemoteImage == NO) continue;
					
					[GSAlert postNotificationToAlertTag:AlertTagReceiveImage
											   selector:@selector(dismiss) 
												 object:nil];	
										
					//Sender cancelled image transfer request
					receivingRemoteImage = NO;
					
					[imageHexData release];
					imageHexData = nil;
					imageByteSize = 0;
					
					continue;
				}
				else if([message isEqualToString:@"X"]){ // X}}
					//Receiver rejected image transfer request
					[self stopImageTransfer];
					
					continue;
				}
				else if([message isEqualToString:@"Y"]){ // Y}}
					//Receiver accepted image transfer request, so send image
					[self sendImageHexData:_imageHexString];
					
					continue;
				}
			}
			else { //IN Receiving image state
				if([message length]){
					
					if([message rangeOfString:@"Z"].location == NSNotFound) {
						//Z has not been found
						
						//THE FOLLOWING METHOD will only get the set amount of bytes for the image									
						// Then ignores the rest
						if([message length] > imageByteSize - [imageHexData length]){
							message = [message substringToIndex:imageByteSize-[imageHexData length]];
						}
						
						//DLog(@"Append image data! (%d to %d of %d)", [message length], [imageHexData length], imageByteSize);
						[imageHexData appendString:message];						
						
						//Update the progress view
						[AppDelegate updateProgressView:(float)[imageHexData length]/imageByteSize];
						
						//Check whether image transfer is finished
						if([imageHexData length] >= imageByteSize){
							receivingRemoteImage = NO;
							DLog(@"Finished receive for remote image!");
							
							[AppDelegate displayProgressView:NO];
							
//							BOOL imageOkay = [AppDelegate.drawingView loadRemoteImageWithHexString:imageHexData];
							[AppDelegate.drawingView performSelectorOnMainThread:@selector(loadRemoteImageWithHexString:) withObject:imageHexData waitUntilDone:YES];
//							if(!imageOkay){
//								UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Image Loading Failed!" message:@"Please try again!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//								[alert show];
//								[alert release];
//							}

							[imageHexData release];
							imageHexData = nil;
							imageByteSize = 0;
						}						
					}
					else {
						//Z has been found
						//Sender cancelled the image transfer, while image transfer was in progress!
						receivingRemoteImage = NO;
						
						[imageHexData release];
						imageHexData = nil;
						imageByteSize = 0;
					}
					
				}
			}
			
			/*
			 if(!receivingRemoteImage && [message hasPrefix:@"<I--"]){
			 if(!imageHexData){
			 DLog(@"Received request for remote image transfer! (hex string format)");
			 receivingRemoteImage = YES;
			 imageHexData = [[NSMutableString alloc] init];
			 
			 if([message hasPrefix:@"<I--N:"]) { 
			 imageByteSize = [[message substringFromIndex:6] intValue];
			 DLog(@"Remote image size expected is %d", imageByteSize);
			 
			 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Receiving Image!" message:[NSString stringWithFormat:@"Receiving image from peer! (Byte: %d", imageByteSize] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			 [alert show];
			 [alert release];
			 }
			 else imageByteSize = -1;
			 }
			 else {
			 //DLog(@"Appending image hex data");
			 
			 [imageHexData appendString:[message substringFromIndex:4]];
			 }
			 continue;
			 }
			 else if([message isEqualToString:@"--/I>"]){
			 
			 receivingRemoteImage = NO;
			 DLog(@"Finished receive for remote image!");
			 
			 if(imageHexData) {
			 if(imageByteSize == -1 || [imageHexData length] == imageByteSize) { 
			 [drawingView loadRemoteImageWithHexString:imageHexData];
			 }
			 else {
			 DLog(@"Incorrect number of bytes received for image! (%d received)", [imageHexData length]);
			 
			 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Image Receive Failed!" message:[NSString stringWithFormat:@"Image transferred from peer is incomplete! (%d received)", [imageHexData length]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			 [alert show];
			 [alert release];
			 }
			 
			 [imageHexData release];
			 imageHexData = nil;
			 imageByteSize = 0;
			 }
			 
			 continue;
			 }
			 */
			
		} 
		else {
			if( !receivingRemoteImage && [message isEqualToString:@"<I--"] ){
				DLog(@"Began receiving remote image byte data!");
				receivingRemoteImage = YES;
				
				continue;
			}
			else if( receivingRemoteImage && ![message isEqualToString:@""] ){
				//static int imageDataSize = 0;
				
				imageDataSize = [message intValue];
				DLog(@"Remote image size is: %d", imageDataSize);
				
				//Send acknowledgement, to set peerReadyToReceive
				[self send:@"K}}"];
								
				continue;
			}
			else if ([message isEqualToString:@"K"]){
//				if (_connectedWhiteboard.type = GSConnectionTypeLocal) {
//					_localConnection.peerReadyToReceive = YES;
//				}
				// TODO: KONG - do we still use "K" 
				
				continue;
			}
		}
		
		
		
		//NON IMAGE TRANSFER CODES HERE:
		//USED so far: c,s,r,n,e,a,j,L,t
		//             b,w,u for begin stroke, end stroke, undo respectively
		//			   t for text
		//			   P for spray
		
		//const NSString *kiPadMessage = @"i";
		//#define kiPadMessage @"i" // moved to header
		
		if (receivingRemoteImage) {
			continue;
		} else if ([message isEqualToString:@"c"]) { // c}}
			// since a color is also 4 CGFloat's, we'll again store it in a CGRect
			DLog(@"receivingRemoteColor = YES");
			receivingRemoteColor = YES;
		} else if (receivingRemoteColor && ![message isEqualToString:@""]) {
#if TARGET_OS_IPHONE			
			CGRect rect = CGRectFromString([message stringByAppendingString:@"}}"]);
#else
			NSRect rect = NSRectFromString([message stringByAppendingString:@"}}"]);		
#endif			
			AppDelegate->remoteComponents[0] = rect.origin.x;
			AppDelegate->remoteComponents[1] = rect.origin.y;
			AppDelegate->remoteComponents[2] = rect.size.width;
			//remoteComponents[3] = rect.size.height;
			//remoteComponents[3] = 1.0 - powf(1.0 - rect.size.height, 1.0 / ((2.0 / kBrushPixelStep) * widthDiameter));
			
			//if (protocolVersion == 1) {
			AppDelegate->remoteTrueOpacity = rect.size.height;
			//} else {
			// Fixed a bug where I was setting this to remoteTrueOpacity :(
			//	remoteComponents[3] = rect.size.height;
			//}
			
			receivingRemoteColor = NO;
			//usingRemoteColor = NO; // Very important! So we set the color next time we need it
			if (AppDelegate->usingRemoteColor) {
				[AppDelegate performSelectorOnMainThread:@selector(setRemoteColor) withObject:nil waitUntilDone:YES];
			}
		} else if ([message isEqualToString:@"s"]) { // s}}
			receivingRemotePointSize = YES;
		} else if (receivingRemotePointSize && ![message isEqualToString:@""]) {
			receivingRemotePointSize = NO; // Don't forget this!
			if ([message isEqualToString:@"r"]) {  // r}}
				// rejection message
//				DLog(@"rejected");
				
				[self receivedRejectedMessageFrom:sender];
				
			} else {
				[AppDelegate setRemotePointSize:[message floatValue]];
				// TODO: KONG - Check initialize here 
//				[self initializeWithPeersIfNecessaryMessage:name source:source];
				
				//KONG: this is for support old device I think. 
				//KONG: NOT sure if I should call below methods, don't know what assumption we made here?
//				[self receivedAcceptedMessageInConnectingWaitingFrom:sender];
			}
		
	} else if ([message isEqualToString:@"n"]) {// n}}
			
			receivingRemoteName = YES;
			
		} else if (receivingRemoteName && ![message isEqualToString:@""]) {
			
			receivingRemoteName = NO;
			[self receivedConnectionRequestFrom:sender name:message];
			
		} else if ([message isEqualToString:@"e"]) {// e}}
			// erase request
#if TARGET_OS_IPHONE			
			if ([AppDelegate.picker shouldConfirmStartOver] == NO) {
					// Remember we're in a different thread here, and UI updates only work in the main thread
					[AppDelegate performSelectorOnMainThread:@selector(acceptStartOverRequest) withObject:nil waitUntilDone:YES];
					continue;
			}
#endif			

			//				NSString *message = @"";
			//if (drawingView.autoSave && drawingView.hasUnsavedChanges) {
			//				if (drawingView.hasUnsavedChanges) {
			//					message = @"Your current drawing will be\nauto-saved to your Photos.\n\n";
			//				}
//			message = [message stringByAppendingString:@"Do you want to Start Over?"];
			
			//KONG: run in receiver 
			GSAlert *eraseWaitAlertView = [GSAlert alertWithDelegate:self
																   title:
											   [NSString stringWithFormat:@"“%@” would like to Start Over", _connectedWhiteboard.name]
																 message:nil
														   defaultButton:@"Yes"
															 otherButton:@"No"];
			eraseWaitAlertView.tag = AlertTagStartOverReceive;
			[eraseWaitAlertView registerToReceiveNotificationForSelector:@selector(dismiss)];
			[eraseWaitAlertView show];
			
			DLog(@"showed alertView for erase request");				
		
		} else if ([message isEqualToString:@"a"]) {// a}}
			//KONG: run in sender 
			// Erase accept reply (a)
			
			// Erase
			[AppDelegate performSelectorOnMainThread:@selector(doErase)
											withObject:nil
										 waitUntilDone:YES];
			
			// Close alertView (don't need to notify, it'll be obvious)
			[GSAlert postNotificationToAlertTag:AlertTagStartOverSend
									   selector:@selector(dismiss) object:nil];
			// Erase
			[AppDelegate performSelectorOnMainThread:@selector(doErase)
								   withObject:nil
								waitUntilDone:YES];			
		} else if ([message isEqualToString:@"j"]) {
			//KONG: run in sender 
			// Erase reject reply (j)
			// Close alertView
//			if (AppDelegate->eraseWaitAlertView) {
//				[AppDelegate->eraseWaitAlertView dismissWithClickedButtonIndex:0 animated:YES];
//				[AppDelegate->eraseWaitAlertView release];
//				AppDelegate->eraseWaitAlertView = nil;
//			}
			[GSAlert postNotificationToAlertTag:AlertTagStartOverSend
									   selector:@selector(dismiss) object:nil];

			GSAlert *eraseRejectedAlertView = [GSAlert alertWithDelegate:self
															   title:@"Your request to Start Over was declined"
															 message:nil
													   defaultButton:@"OK"
														 otherButton:nil];
			[eraseRejectedAlertView show];
			// Notify rejected
			
		} else if ([message isEqualToString:@"L"]) {// L}}
			//KONG: run in receiver 
			DLog(@"Cancel request (L)");
			[GSAlert postNotificationToAlertTag:AlertTagStartOverReceive
									   selector:@selector(dismiss) object:nil];
		} else if ([message isEqualToString:@"2"]) {
			// Peer supports whiteboard protocol version 2
			DLog(@"protocolVersion = 2");
			protocolVersion = 2;
			
			[self receivedAcceptedMessageFrom:sender];
//			[self initializeWithPeersIfNecessaryMessage:name source:source];
			
			[AppDelegate sendMyColor];
			[AppDelegate sendMyPointSize];
			
		} else if ([message isEqualToString:kiPadMessage]) {
			DLog(@"remoteDevice = iPadDevice");
			AppDelegate.remoteDevice = iPadDevice;
			[AppDelegate sendMyColor];		// these change for iPad-iPad connections
			[AppDelegate sendMyPointSize];	//
			
			/*
			 Don't process blank messages!
			 */
		} else if ([message isEqualToString:@"b"]) { // b}}
			[AppDelegate receiveBeginStroke];
			
		} else if ([message isEqualToString:@"w"]) {
			[AppDelegate receiveEndStroke];
			
		} else if ([message isEqualToString:@"r"]) {
			//[AppDelegate receiveRedoRequest];
			[AppDelegate.drawingView performSelectorOnMainThread:@selector(receiveRedoRequest) withObject:nil waitUntilDone:YES];
			
		} else if ([message isEqualToString:@"u"]) { 
			//[AppDelegate receiveUndoRequest];
			[AppDelegate.drawingView performSelectorOnMainThread:@selector(receiveUndoRequest) withObject:nil waitUntilDone:YES];
			/*
			 // undo request
			 
			 if ([self.picker shouldConfirmUndo]) {
			 NSString* serverName = [namesForStreams objectForKey:[stream description]];
			 
			 NSString *message = @"";
			 //				if (drawingView.autoSave && drawingView.hasUnsavedChanges) {
			 //					message = @"Your current drawing will be\nauto-saved to your Photos.\n\n";
			 //				}
			 message = [message stringByAppendingString:@"Do you want to undo?"];
			 undoWaitAlertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"“%@” would like to undo", serverName] message:message delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
			 [undoWaitAlertView show];
			 //[eraseWaitAlertView release];
			 
			 DLog(@"showed alertView for erase request");
			 } else {
			 // Remember we're in a different thread here, and UI updates only work in the main thread
			 [self performSelectorOnMainThread:@selector(acceptUndoRequest) withObject:nil waitUntilDone:YES];
			 }
			 */
#if TARGET_OS_IPHONE			
		} else if ([message isEqualToString:@"t"]) { // t}}
			
			//[self send:[NSString stringWithFormat:@"t}}%@}}%@}}%f}}%f}}%f}}", text, textFontName, textFontSize, textPoint.x, textPoint.y]];
			receivingText = YES;
		} else if (receivingText && ![message isEqualToString:@""]) {
			//DLog(@"gettting remote text %@", message);
			AppDelegate->remoteText = [NSString stringWithString:message];
			receivingText = NO;
			receivingTextFont = YES;
			
			//[self performSelectorOnMainThread:@selector(setRemoteColor) withObject:nil waitUntilDone:YES];
			
		} else if (receivingTextFont && ![message isEqualToString:@""]) {
			//DLog(@"gettting remote font name %@", message);
			AppDelegate->remoteFontName = [NSString stringWithString:message];
			receivingTextFont = NO;
			receivingTextSize = YES;
			
			
		} else if (receivingTextSize && ![message isEqualToString:@""]) {
			//DLog(@"gettting remote text size %@", message);
			AppDelegate->remoteTextSize = [message floatValue];
			receivingTextSize = NO;
			receivingTextPosition = YES;
			
		} else if (receivingTextPosition && ![message isEqualToString:@""]) {
			//DLog(@"gettting remote text position %@", message);
			AppDelegate->remoteTextPoint = CGPointFromString(message);
			receivingTextPosition = NO;
			
			[AppDelegate performSelectorOnMainThread:@selector(renderRemoteText) withObject:nil waitUntilDone:YES];
			
		} else if ([message isEqualToString:@"p"]) {
			
			receivingSpray = YES;
			
		} else if (receivingSpray && ![message isEqualToString:@""]) {
			
			receivingSpray = NO;
			
			[AppDelegate performSelectorOnMainThread:@selector(renderRemoteColorSprayWithRect:)
											withObject:[message stringByAppendingString:@"}}"]
										 waitUntilDone:YES];

#endif			
		} else if (![message isEqualToString:@""]) {
			//DLog(@"gettting remote line %@", message);
			/*
			 This is probably an incoming line to draw.
			 waitUntilDone so that we don't slow down the UI with too many requests.
			 Note that the withObject: parameter MUST be an object (CGRect won't work).
			 */
			[AppDelegate performSelectorOnMainThread:@selector(renderRemoteColorLineWithRect:)
											withObject:[message stringByAppendingString:@"}}"]
										 waitUntilDone:YES];
		}
		//DLog(@"done handling message");
	}
}



- (void)internetInitializeWithPeersIfNecessaryMessage:(NSString *)name source:(id)source {
	
//	serverName = [(XMPPJID *) source user];
//	self.connectedWhiteboard = [[[GSInternetWhiteboard alloc] initWithName:serverName] autorelease];
//	[(GSInternetWhiteboard *) _connectedWhiteboard setJid:source];


}

- (void)receivedMessages:(NSArray *)messages {
	//DLog(@"%s%@", _cmd, messages);
	// combine messages together
	NSMutableString *combinedMessage = nil;
	NSString *sender = nil;
	for (NSObject *name in messages) {
		NSString *messageString;
		if ([name isKindOfClass:[NSArray class]]) {
			NSArray *messageArray = (NSArray *)name;
			if (!sender) {
				sender = [messageArray objectAtIndex:0];
			} else {
				if (![sender isEqualToString:[messageArray objectAtIndex:0]]) {
					// process previous combinedMessage and create a new one
					[AppDelegate.connection processMessage:combinedMessage source:sender];
					combinedMessage = nil;
					sender = [messageArray objectAtIndex:0];
				}
			}
			messageString = [messageArray objectAtIndex:1];
		} else if ([name isKindOfClass:[NSString class]]) {
			messageString = (NSString *)name;
		} else if ([name isKindOfClass:[NSDictionary class]]) {
			messageString = [(NSDictionary *)name objectForKey:@"message"];
		} else {
			ALog(@"unknown message type");
			messageString = nil;
		}
		if (messageString) {
			if (combinedMessage) {
				[combinedMessage appendString:messageString]; // TODO: make sure the array is ordered
			} else {
				combinedMessage = [[NSMutableString alloc] initWithString:messageString];
			}
		}
	}
	
	[AppDelegate.connection processMessage:combinedMessage source:sender];
}

/*
- (UIViewController *)connectViewController {
	
	if (!_internetConnection) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Not Yet Ready" message:@"Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
		return nil;
	}
	
	//	ConnectViewController *controller = [[ConnectViewController alloc] initWithNibName:@"ConnectView" bundle:nil];
	//	GSConnectViewController *controller = [[GSConnectViewController alloc] initWithInternetConnection:internetConnection];
	if (_connectionView == nil) {
		_connectionView = [[GSConnectViewController alloc] initWithInternetConnection:_internetConnection
																						 localBrowser:_localConnection.bvc];		
	}
	return _connectionView;
}
*/
- (void)initateSessionWithWhiteBoard:(GSWhiteboard *)waitedWhiteboard {
	amServer = NO;
	// need to send color and present tools, but it's not safe to do so here
	initializedWithPeers = NO;
	
	[waitedWhiteboard initiateConnection];
	NSString *requestString = [NSString stringWithFormat:@"n}}%@}}", waitedWhiteboard.connection.myName];
	[waitedWhiteboard send:requestString];

}

- (void)setConnectedWhiteboard:(GSWhiteboard *)whiteboard {

	if (_connectedWhiteboard) [_connectedWhiteboard release];
	_connectedWhiteboard = [whiteboard retain];
	
}

#pragma mark New refactor
- (BOOL)peerSupportsImageTransfer {
	return (protocolVersion == 2);
}


//- (ConnectionStatus)status {
//	if (_connectedWhiteboard) {
//		return ConnectionStatusConnected;
//	}
//	
//	return ConnectionStatusNotYetConnected;
//}

- (BOOL)isConnected {
	return (_status == ConnectionStatusConnected && _connectedWhiteboard != nil);
}


- (void)setStatus:(ConnectionStatus)status {
	NSLog(@"Changed from: %@ to: %@", [self statusDescription:_status], [self statusDescription:status]);
	_status = status;	
	[_connectionView connectionControllerDidChangeStatus];
	
	// UI
	if (_status == ConnectionStatusConnected || _status == ConnectionStatusNotYetConnected) {
		
		if (_connectedWhiteboard) {
			if (_connectedWhiteboard.type == GSConnectionTypeInternet) {
#if INTERNET_INCLUDING				
				[_internetConnection setConnectedWhiteboard:(GSInternetWhiteboard *) _connectedWhiteboard];
#endif
			} else if ((_connectedWhiteboard.type == GSConnectionTypeLocal)) {
//				[_localConnection removeAllStreamsExceptStreamsInWhiteboard:(GSLocalWhiteboard *)_connectedWhiteboard];
//				[_localConnection.bvc setConnectedName:_connectedWhiteboard.name];
			}
			
			// Notification for dismiss picker
			[[NSNotificationCenter defaultCenter] postNotificationName:@"kConnectedNotification" object:nil];			
#if !TARGET_OS_IPHONE
			[AppDelegate setConnectedDeviceName:_connectedWhiteboard.name];
			[AppDelegate cancelConnection:nil];
#endif			
			
			
		} else { // not yet connected
			
			[self resetToStartingStatus];
		}

#if TARGET_OS_IPHONE		
		[AppDelegate.picker setConnectedName:_connectedWhiteboard.name];
#endif		
	}

	StatusLog	
}

- (GSWhiteboard *)whiteboard:(NSString *)name source:(id)source {
	GSWhiteboard *returnWhiteboard = nil;
	if ([source isKindOfClass:[NSStream class]]) {
/*		
		returnWhiteboard = [[[GSLocalWhiteboard alloc] initWithName:name] autorelease];
		[(GSLocalWhiteboard *) returnWhiteboard setInStream:source];
		[(GSLocalWhiteboard *) returnWhiteboard setOutStream:[_localConnection outStreamWithInStream:source]];
 
 */
		returnWhiteboard = [_localConnection peerForInstream:source];
		returnWhiteboard.name = name;
#if INTERNET_INCLUDING		
	} else if ([source isKindOfClass:[XMPPJID class]]) { // internetconnection
		returnWhiteboard = [[[GSInternetWhiteboard alloc] initWithName:
							 [GSWhiteboardUser displayNameFromJID:source]] autorelease];
		[(GSInternetWhiteboard *) returnWhiteboard setJid:source];
#endif		
	}
	
	return returnWhiteboard;
}
- (BOOL)isWhiteboard:(GSWhiteboard *)whiteboard usingSource:(id)source {
	if (whiteboard == nil) {
		return NO;
	}
	
	if (whiteboard.type == GSConnectionTypeLocal && [source isKindOfClass:[NSStream class]]) {
		return ([(GSLocalWhiteboard *)whiteboard inStream] == source);
	}
#if INTERNET_INCLUDING	
	if (whiteboard.type == GSConnectionTypeInternet && [source isKindOfClass:[XMPPJID class]]) {
		return ([[(XMPPJID *)[(GSInternetWhiteboard *)whiteboard jid] user] isEqualToString:[(XMPPJID *)source user]]);
	}
#endif	
	return NO;
}


- (BOOL)isWhiteboard:(GSWhiteboard *)sender identicalWith:(GSWhiteboard *)current {
	if (current == nil) {
		return NO;
	}
	
	if (sender == nil) {
		return NO;
	}
	
	if (sender == current) {
		return YES;
	}
	
	return [self isWhiteboard:sender usingSource:[current source]];
}


#pragma mark Multitasking

		
- (void)didFinishLaunching {
	
	//	if ([AppDelegate supportsMultitasking] == NO) {
	//		
	//		return;
	//	}
	
	[self startToConnect];
	//	[self startToBroadcast];
}	
- (void)willTerminate {
	[self stopConnecting];
}
		
#if TARGET_OS_IPHONE

- (void)prepareRemainTimeNotification {
	//KONG: ref: http://developer.apple.com/library/ios/#documentation/iphone/conceptual/iphoneosprogrammingguide/BackgroundExecution/BackgroundExecution.html#//apple_ref/doc/uid/TP40007072-CH5-SW4 
	
	UIApplication *app = [UIApplication sharedApplication];
    NSArray *oldNotifications = [app scheduledLocalNotifications];
	
    // Clear out the old notification before scheduling a new one.
    if ([oldNotifications count] > 0)
        [app cancelAllLocalNotifications];
	
	//KONG: find out how many time we have in background
	NSTimeInterval remainTime = [UIApplication sharedApplication].backgroundTimeRemaining;
	
	remainTime = fmin(remainTime, 590.); // in case: backgroundTimeRemaining is not updated
	DLog(@"remain time: %f", remainTime);	
	
    // Create a new notification	
    UILocalNotification* alarm = [[[UILocalNotification alloc] init] autorelease];
	
    if (alarm) {
		alarm.fireDate = [NSDate dateWithTimeIntervalSinceNow:remainTime - 60]; // 1 min before
        alarm.timeZone = [NSTimeZone defaultTimeZone];
        alarm.repeatInterval = 0;
		
        alarm.soundName = UILocalNotificationDefaultSoundName;
        alarm.alertBody = @"You will be disconnected in less than a minute due to inactivity";
        alarm.alertAction = @"Open";
		[app scheduleLocalNotification:alarm];
    }
}

- (BOOL)shouldStayInBackground {
#if !SUPPORT_CONNECTION_IN_BACKGROUND
	return NO;
#endif
	
	return ([AppDelegate supportsMultitasking] 
			&& [self isConnected]);
}



- (void)didBecomeActive {
	DLog();
	
	[self startToBroadcast];

	//KONG: multitasking
	//KONG: restore stored message which is received when I'm in background	
//	if ([AppDelegate supportsMultitasking] && [self isConnected]) {
//	if ([self shouldStayInBackground]) {
//	}
	if ([self isConnected]) {
		[_connectedWhiteboard processStoredMessages];
	}
}


- (void)willResignActive {
	DLog();
	
	[self stopBroadcasting];
}


- (void)didEnterBackground {
	//KONG: iOS4 
	DLog();
	
//	if ([AppDelegate supportsMultitasking] == NO) {
	if ([self shouldStayInBackground] == NO) {	
		[self stopConnecting];
		return;
	}
		
#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
	//KONG: start task completion
	UIApplication*    app = [UIApplication sharedApplication];
    _backgroundTask = [app beginBackgroundTaskWithExpirationHandler:^{
		[self stopConnecting];
        [app endBackgroundTask:_backgroundTask];
        _backgroundTask = UIBackgroundTaskInvalid;
    }];	
	
	//KONG: prepare local notification
	if ([NSDEF boolForKey:@"multitasking_alert_preference"]) {
		[self prepareRemainTimeNotification];
	}
	
#endif	
	
//    // Start the long-running task and return immediately.
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        // Do the work associated with the task.
//		DLog(@"Do the work associated with the task.");
//		
//        [app endBackgroundTask:_backgroundTask];
//        _backgroundTask = UIBackgroundTaskInvalid;		
//    });
}

- (void)willEnterForeground {	
	//KONG: iOS4	
//	if ([AppDelegate supportsMultitasking] == NO) {
	if ([self shouldStayInBackground] == NO) {	
		[self startToConnect];
		return;
	}
	DLog();
}


#endif


#if INTERNET_INCLUDING
// Greengar ID
- (NSString *)greengarUsername {
	return [_internetConnection username];
}

- (NSString *)greengarPassword {
	return [_internetConnection xmppPassword];	
}
#endif

- (void)initiateStartOver {
	
	GSAlert *startOverSendAlert = [GSAlert alertWithDelegate:self
														   title:
									   [NSString stringWithFormat:@"Asking “%@” to Start Over", _connectedWhiteboard.name]
														 message:@"Please wait for their reply..." 
												   defaultButton:@"Cancel"
													 otherButton:nil];
#if TARGET_OS_IPHONE	
	[startOverSendAlert addSpinnerForName:_connectedWhiteboard.name];
#endif	
	startOverSendAlert.tag = AlertTagStartOverSend;
	[startOverSendAlert registerToReceiveNotificationForSelector:@selector(dismiss)];
	[startOverSendAlert show];
	
	// Send an erase request (e)
	[self send:@"e}}"];
}
@end
