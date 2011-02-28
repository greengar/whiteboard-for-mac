//
//  AppController+NSStreamDelegate.m
//  Whiteboard
//
//  Created by Elliot Lee on 6/26/09.
//  Copyright 2009 GreenGar Studios <http://www.greengar.com/>. All rights reserved.
//

#import "AppController+NSStreamDelegate.h"
#import "Picker.h"
#import "GSInternetConnection.h"
#import "GSWhiteboard.h"
#import "MainPaintingView.h"
//#import "errno.h"

//#if IS_WHITEBOARD_HD
#	import "FlurryAPI.h"
//#else
//#	import "Beacon.h"
//#endif

extern BOOL USE_HEX_STRING_IMAGE_DATA; // currently always YES

@implementation AppController (NSStreamDelegate)


- (void)initializeWithPeersIfNecessaryMessage:(NSString *)message stream:(NSStream *)stream {
	DLog();
	if (!initializedWithPeers) {
		initializedWithPeers = YES;
		
		if (amServer && pendingJoinRequest && [[[_picker bvc] ownName] compare:message] == NSOrderedAscending) {
			ALog(@"WARNING: Server is attempting to initialize a client connection");
		} else {
			
			DLog();
			
			//
			//  Client Code
			//
			//  This code executes on the client device.
			//
			
			[_server stop]; // Stop the existing server (which advertises to clients)
			
			// Stop the activity indicator
			// Generally, this code is already running on the networking thread (inStreamThread), but we do this just in case:
			[[_picker bvc] performSelector:@selector(stopActivityIndicator:) onThread:inStreamThread withObject:nil waitUntilDone:YES];
			
			NSString *serverName;
			if (stream) {
				serverName = [namesForStreams objectForKey:[stream description]];
			} else {
				serverName = [self.picker.internetConnection.connectedWhiteboard name];
				DLog(@"Internet peer's name: %@", serverName);
			}
			
			//[[_picker bvc] setConnectedName:serverName];
			[_picker setConnectedName:serverName];
			
			// Set labels in the Lite version's UI
			//((UILabel*)[_picker viewWithTag:kWaitingTag]).text = @"Your whiteboard's name is:";
			//((UILabel*)[_picker viewWithTag:kOrJoinTag]).text = @"Whiteboards on this network:";
			
			// No need to refresh the tableView
			//[[[_picker bvc] tableView] reloadData];
			
			// Tell the user on the client device that their request was accepted
			if (!amServer) {
				UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"“%@” has accepted your request", serverName] message:@"You are now drawing together!" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
				[alertView show];
				[alertView release];
			}
			
			//
			// Now we're successfully connected.
			//
			// Currently, Whiteboard only supports 1 connection, so if we have more than 1 connection,
			// we disconnect from the other one.
			//
			const int kMaxConnections = 1;
			if ([_inStreams count] > kMaxConnections) {
				DLog(@"CLIENT: Dropping extra connection");
				for(NSInputStream *_inStream in _inStreams) {
					if (stream != _inStream) {
						DLog(@"CLIENT: Disconnecting from _inStream: %@", _inStream);
						[self performSelector:@selector(disconnectFromPeerWithStream:) onThread:inStreamThread withObject:_inStream waitUntilDone:YES];
						//break; // 20100324: Drop all extra connections
					}
				}
			}
			
			// For Whiteboard Pro, make sure the client AND server both send this message
			// This is the "protocol version" (protocolVersion)
			// It defaults to 1, but becomes 2 when this message is received:
			[self send:@"2}}"];
			
			//
			// If I'm an iPad, tell my peer.
			//
			if (IS_IPAD) {
				[self send:[NSString stringWithFormat:@"%@}}", kiPadMessage]];
			}
			
			[self sendMyColor];
			[self sendMyPointSize];
			
//#if IS_WHITEBOARD_HD
			// time session
			// [FlurryAPI logEvent:@"EVENT_NAME" withParameters:YOUR_NSDictionary timed:YES];
			// Use this version of logEvent to start timed event with event parameters.
			// [FlurryAPI endTimedEvent:@"EVENT_NAME" withParameters:nil];
			[FlurryAPI logEvent:@"connected" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:runCount], @"runCount", nil] timed:YES];
//#else
//			[[Beacon shared] startSubBeaconWithName:@"connected" timeSession:YES]; // Pinch Media Analytics
//#endif
			//[self presentTools];
			//[self hideToolsWithDialog:NO]; // hide the drawing tools
			
			[[NSNotificationCenter defaultCenter] postNotificationName:@"kConnectedNotification" object:nil];
			
			
		}
	}
}

- (void)setRemotePointSize:(float)size {
	if (remoteDevice != iPadDevice && IS_IPAD) { //[[UIScreen mainScreen] bounds].size.width == 768
		size = size * 2.0f;
		DLog(@"%f", size);
	} else {
		DLog(@"%f", size);
	}
	
	remotePointSize = size;
	
	if (usingRemoteColor) {
		//
		// We may already be OnMainThread, but it doesn't hurt to make sure.
		//
		[self performSelectorOnMainThread:@selector(setRemoteColor) withObject:nil waitUntilDone:YES];
	}
}

// for server AND client
- (void)streamEventOpenCompleted:(id)stream {
	DLog();
	
	BOOL setInReady = NO;
	if (stream && [stream isKindOfClass:[NSStream class]]) {
		// These lines are commented because we want to keep the server running
		// which allows us to continue accepting new connections:
		//[_server release];
		//_server = nil;
		//[_server stop];
		
		NSInputStream* _inStream;
		for(_inStream in _inStreams) {
			if (stream == _inStream) {
				DLog(@"set _inReady = YES");
				_inReady = YES;
				setInReady = YES;
				break;
			}
		}
		
		if(setInReady == NO) {
			_outReady = YES;
		}
		/*
		 NSOutputStream* _outStream;
		 for(_outStream in _outStreams) {
		 if (stream == _outStream) {
		 DLog(@"set _outReady = YES");
		 _outReady = YES;
		 break;
		 }
		 }
		 */
	}
	
	DLog(@"check _inReady && _outReady");
	if (!stream || [stream isKindOfClass:[NSString class]] || (_inReady && _outReady)) {
		//NSString* serverName = [namesForStreams objectForKey:[stream description]];
		// when serverName is set, I'm actually the client
		// when serverName is nil, I'm actually the server
		//DLog(@"(_inReady && _outReady) == YES, amServer:%d serverName:%@", amServer, serverName);
		
		// if I'm the client, I need to initializeWithPeers
		DLog();
		if (!amServer/* && serverName != nil*/) {
			/*
			 alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Successfully connected to %@", serverName] message:@"Waiting for response from server" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
			 [alertView show];
			 [alertView release];
			 */
			// wait for point size or rejection
			initializedWithPeers = NO;
		} // else I'm the server, so wait for them to tell us their name
	} else {
		DLog(@"(_inReady && _outReady) == NO");
	}
}

- (void)streamEventHasSpaceAvailable:(id)stream {
	/**
	 * This assumes 1 peer.
	 * The Client sends its name to the Server, but not the other way around!
	 */
	if (needToSendName) {
		needToSendName = NO;
		
		if ([stream isKindOfClass:[GSWhiteboard class]]) { // || !stream || [stream isKindOfClass:[NSString class]]
			DLog(@"creating Internet connection (client)");
			GSWhiteboard *w = stream;
			self.picker.internetConnection.connectedWhiteboard = w;
			[self streamEventOpenCompleted:w.wb]; // act like a local connection
		}
		
		// Send my name to this output stream
		// (Maybe we could save a little bandwidth by doing this only if I'm the client)
		[self send:[NSString stringWithFormat:@"n}}%@}}", self.picker.ownName] toOutStream:(id)stream];
		
		//
		// Note: we should handle here what happens when my name changes.
		//       That is: listen for the Bonjour event.
		//       Bonjour might change our name when there's a conflict on the network.
		//
	}
	
	// Send any buffered data,
	// but watch out for an infinite loop:
	if ([writeBuffer length] > 0) {
		[self send:writeBuffer];
		writeBuffer = @"";
		DLog(@"done writing buffer");
	}
}

- (void)receivedMessages:(NSArray *)messages {
	//DLog(@"%s%@", _cmd, messages);
	// combine messages together
	NSMutableString *combinedMessage = nil;
	NSString *sender = nil;
	for (NSObject *message in messages) {
		NSString *messageString;
		if ([message isKindOfClass:[NSArray class]]) {
			NSArray *messageArray = (NSArray *)message;
			if (!sender) {
				sender = [messageArray objectAtIndex:0];
			} else {
				if (![sender isEqualToString:[messageArray objectAtIndex:0]]) {
					// process previous combinedMessage and create a new one
					[self processMessage:combinedMessage source:sender];
					combinedMessage = nil;
					sender = [messageArray objectAtIndex:0];
				}
			}
			messageString = [messageArray objectAtIndex:1];
		} else if ([message isKindOfClass:[NSString class]]) {
			messageString = (NSString *)message;
		} else if ([message isKindOfClass:[NSDictionary class]]) {
			messageString = [(NSDictionary *)message objectForKey:@"message"];
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
	
	[self processMessage:combinedMessage source:sender];
}

- (void)receiveRemoteName:(NSString *)message wb:(NSString *)wb {
	// If more than one client tries to join simultaneously, reject them
	// Either a dialog is already showing, or the server isn't running (anymore), or I'm trying to resolve another peer
	if (acceptRejectAlertView || [self.picker.internetConnection connectedWhiteboard]) {
		DLog(@"Reject only this peer (silently)");
		
		// message is name!
		// TODO: implement rejectSilentlyWithName: for Internet //blah
		[self performSelector:@selector(rejectSilentlyWithName:) onThread:inStreamThread withObject:[message copy] waitUntilDone:YES];
		//[self acceptPendingRequest:kRejectSilently withName:[message copy]];
	} else if ([self.picker.internetConnection isResolving:wb]) {
		
		// Is it the case that only 1 device has this occur?
		
#if TARGET_CPU_ARM
		DLog(@"Device");
#else
		DLog(@"Simulator");
#endif
		
		// I'm trying to connect to a peer who's trying to connect to me
		
		// NSOrderedAscending if the receiver precedes aString
		// NSOrderedDescending if the receiver follows aString
		if ([[[_picker bvc] ownName] compare:message] == NSOrderedAscending) {
			DLog(@"Conflict resolution: I'll be the server");
			amServer = YES;
			
			// replace my connection with theirs
			
			// Assume whiteboard protocol version 1 until we hear otherwise
			DLog(@"protocolVersion = 1");
			protocolVersion = 1;
			
			remoteDevice = iPhoneDevice; // assume remoteDevice is an iPhone until we hear otherwise
			
			/*
			 Optimize later
			 */
			if (_acceptReject == nil)
				_acceptReject = [[AcceptReject alloc] init];
			[_acceptReject setName:message];
			acceptRejectAlertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"“%@” would like to join your whiteboard", message]
															   message:nil
															  delegate:_acceptReject cancelButtonTitle:@"Don't Allow"
													 otherButtonTitles:@"OK", nil];
			
			// Remember that this code is running on the Server.
			// pendingJoinRequest should be YES already, but since we're not supporting more than 2 peers,
			// it may be NO. So let's make sure:
			pendingJoinRequest = YES;
			
			[self acceptPendingRequest:YES withName:message];
			
			//
			// Note: at this point, we may want to deselect the row in the tableView with this name
			//
			
			[[_picker bvc] performSelector:@selector(stopActivityIndicator:) onThread:inStreamThread withObject:nil waitUntilDone:YES];
			
		} else {
			DLog(@"Conflict resolution: I'll be the client");
			amServer = NO;
			
			// reject their request, keep my request going
			
			DLog(@"sending color and pointSize");
			[self sendMyColor];
			[self sendMyPointSize];
			
			// wasn't giving checkmark and
			// was't deselecting when I tapped to disconnect
			// then said No!
			
			// at this point, the resolve is done!
			// hope this is right!
			[_picker bvc].currentResolve = nil;
			// and message is name!
			//[[_picker bvc] setConnectedName:message];
			
			[_picker setConnectedName:message];
			
		}
		
		
	} else {
		
		// TODO: check that we're not connected to anyone else yet
		
		DLog(@"creating Internet connection (server)");
		GSWhiteboard *w = [GSWhiteboard whiteboardWithType:@"Internet" name:message];
		w.wb = wb;
		self.picker.internetConnection.connectedWhiteboard = w;
		[self streamEventOpenCompleted:w.wb]; // act like a local connection
		
		pendingJoinRequest = YES; // Set the flag that indicates there is a pending join request
		
		// Assume whiteboard protocol version 1 until we hear otherwise
		DLog(@"protocolVersion = 1");
		protocolVersion = 1;
		
		remoteDevice = iPhoneDevice; // assume remoteDevice is an iPhone until we hear otherwise
		
		if (_acceptReject == nil)
			_acceptReject = [[AcceptReject alloc] init];
		[_acceptReject setName:message];
		acceptRejectAlertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"“%@” would like to join your whiteboard", message]
														   message:nil
														  delegate:_acceptReject cancelButtonTitle:@"Don't Allow"
												 otherButtonTitles:@"OK", nil];
		[acceptRejectAlertView show];
		//[alertView release];
		//DLog(@"alertView released");
		
	}
}

- (void)receiveRemoteName:(NSString *)message source:(id)source {
	NSStream *stream = nil;
	NSString *wb = nil;
	if ([source isKindOfClass:[NSStream class]]) {
		stream = source;
	} else if ([source isKindOfClass:[NSString class]]) {
		wb = source;
	}
	
	if (wb) {
		// receive from Internet
		
		[self receiveRemoteName:message wb:(NSString *)wb];
		
	} else if (stream) {
		if (!amServer && !pendingJoinRequest && !([[[_picker bvc] ownName] compare:message] == NSOrderedAscending)) {
			// pendingJoinRequest == YES also indicates that I'm the server!
			DLog(@"Warning: client trying to process initialization info");
			
			// Maybe this means I should actually be the server!
			// I should be the server if [[[_picker bvc] ownName] compare:message] == NSOrderedAscending
			
		} else {
			
			/** Executes on server **/
			DLog(@"Executing server code");
			
			// Name doesn't exist yet, or name does exist but I'm supposed to be the server
			// Everyone: don't send name unless you're supposed to!
			if ([namesForStreams objectForKey:[stream description]] == nil || ([[[_picker bvc] ownName] compare:[namesForStreams objectForKey:[stream description]]] == NSOrderedAscending)) {
				[namesForStreams setObject:message forKey:[stream description]];
				
				// associate name with _outStream, too
				NSUInteger index = [_inStreams indexOfObject:stream];
				[namesForStreams setObject:message forKey:[[_outStreams objectAtIndex:index] description]];
				
				// If more than one client tries to join simultaneously, reject them
				// Either a dialog is already showing, or the server isn't running (anymore), or I'm trying to resolve another peer
				if (acceptRejectAlertView || [_server isStopped]/* || [[_picker bvc] currentResolve]*/) {
					DLog(@"Reject only this peer (silently)");
					
					// message is name!
					[self performSelector:@selector(rejectSilentlyWithName:) onThread:inStreamThread withObject:[message copy] waitUntilDone:YES];
					//[self acceptPendingRequest:kRejectSilently withName:[message copy]];
				} else if ([[[_picker bvc] currentResolve].name isEqualToString:[[message copy] autorelease]]) { // BUGFIX: autorelease fixes memory leak
					
					// Is it the case that only 1 device has this occur?
					
	#if TARGET_CPU_ARM
					DLog(@"Device");
	#else
					DLog(@"Simulator");
	#endif
					
					// I'm trying to connect to a peer who's trying to connect to me
					
					// NSOrderedAscending if the receiver precedes aString
					// NSOrderedDescending if the receiver follows aString
					if ([[[_picker bvc] ownName] compare:message] == NSOrderedAscending) {
						DLog(@"Conflict resolution: I'll be the server");
						amServer = YES;
						
						// Cancel my request (silently?), accept theirs
						//[disconnectFromPeerWithStream:nil];
						// How do I know my connection's streams?
						// It's the stream that isn't this one (stream)
						NSInputStream* _inStream;
						for(_inStream in _inStreams) {
							if (stream != _inStream) {
								DLog(@"going to disconnect from _inStream: %@", _inStream);
								[self performSelector:@selector(disconnectFromPeerWithStream:) onThread:inStreamThread withObject:_inStream waitUntilDone:YES];										
								break;
							}
						}
						
						// Assume whiteboard protocol version 1 until we hear otherwise
						DLog(@"protocolVersion = 1");
						protocolVersion = 1;
						
						remoteDevice = iPhoneDevice; // assume remoteDevice is an iPhone until we hear otherwise
						
						/*
						 Optimize later
						 */
						if (_acceptReject == nil)
							_acceptReject = [[AcceptReject alloc] init];
						[_acceptReject setName:message];
						acceptRejectAlertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"“%@” would like to join your whiteboard", message]
																		   message:nil
																		  delegate:_acceptReject cancelButtonTitle:@"Don't Allow"
																 otherButtonTitles:@"OK", nil];
						
						// Remember that this code is running on the Server.
						// pendingJoinRequest should be YES already, but since we're not supporting more than 2 peers,
						// it may be NO. So let's make sure:
						pendingJoinRequest = YES;
						
						[self acceptPendingRequest:YES withName:message];
						
						//
						// Note: at this point, we may want to deselect the row in the tableView with this name
						//
						
						[[_picker bvc] performSelector:@selector(stopActivityIndicator:) onThread:inStreamThread withObject:nil waitUntilDone:YES];
						
					} else {
						DLog(@"Conflict resolution: I'll be the client");
						amServer = NO;
						
						/** Remember that this code is executing on the "server" **/
						
						// Reject their request, keep my request going
						
						// Don't need to reject? They'll cancel?
						// But this might be asynchronous?
						
						// This stream hit a conflict: they requested me when I was requesting them
						// But the server needs to realize there's a conflict...
						
						//[self disconnectFromPeerWithStream:stream];
						// Fixes an Exception where the array got mutated while being iterated
						[self performSelector:@selector(disconnectFromPeerWithStream:) onThread:inStreamThread withObject:stream waitUntilDone:YES];
						
						DLog(@"sending color and pointSize");
						[self sendMyColor];
						[self sendMyPointSize];
						
						// wasn't giving checkmark and
						// was't deselecting when I tapped to disconnect
						// then said No!
						
						// at this point, the resolve is done!
						// hope this is right!
						[_picker bvc].currentResolve = nil;
						// and message is name!
						//[[_picker bvc] setConnectedName:message];
						
						[_picker setConnectedName:message];
						
					}
					
					
				} else {
					
					DLog(@"Server's Normal procedure: no conflict detected (yet!)");
					
					// Assume whiteboard protocol version 1 until we hear otherwise
					DLog(@"protocolVersion = 1");
					protocolVersion = 1;
					
					remoteDevice = iPhoneDevice; // assume remoteDevice is an iPhone until we hear otherwise
					
					if (_acceptReject == nil)
						_acceptReject = [[AcceptReject alloc] init];
					[_acceptReject setName:message];
					acceptRejectAlertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"“%@” would like to join your whiteboard", message]
																	   message:nil
																	  delegate:_acceptReject cancelButtonTitle:@"Don't Allow"
															 otherButtonTitles:@"OK", nil];
					[acceptRejectAlertView show];
					//[alertView release];
					//DLog(@"alertView released");
					
				}
			} else {
				DLog(@"Name for this stream %@ already exists", stream);
			}
			
		} // if (amServer)
	} else {
		ALog(@"WARNING: unrecognized source = %@", source);
	}
}

- (void)receiveBeginStroke
{
	[drawingView receiveBeginStroke];
}

- (void)receiveEndStroke
{
	[drawingView receiveEndStroke];
}

- (void)receiveUndoRequest
{
	[drawingView receiveUndoRequest];
}

-(void) receiveRedoRequest
{
	[drawingView receiveRedoRequest];
}

- (void)processMessage:(NSString *)message source:(id)source {
	NSStream *stream = nil;
//	NSString *wb = nil;
	if ([source isKindOfClass:[NSStream class]]) {
		stream = source;
	}
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
		
		if(USE_HEX_STRING_IMAGE_DATA){
			static NSMutableString *imageHexData = nil;
			static int imageByteSize = 0;
			
			if(!receivingRemoteImage){ //Not in receiving image state
				if([message hasPrefix:@"<I--N:"]){ 
					//Sender requesting image transfer
					DLog(@"Received request for remote image transfer! (hex string format)");
					
					//Initialize the necessary variables for image transfer
					[imageHexData release];
					imageHexData = [[NSMutableString alloc] init];
					imageByteSize = [[message substringFromIndex:6] intValue];
					DLog(@"Remote image size expected is %d", imageByteSize);
					
					//Show alert for image transfer
					imageReceiveTransferAlert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"“%@” would like to open an image", [self getServerName]] message:@"This will transfer the image\nto your whiteboard." delegate:self cancelButtonTitle:@"Don't Allow" otherButtonTitles:@"OK", nil];
					imageReceiveTransferAlert.tag = 61;
					[imageReceiveTransferAlert show];
					//[imageTransferAlert release];
					
					//Wait for user's input on alert to set the receivingRemoteImage boolean!
					
					continue;
				}
				else if([message isEqualToString:@"Z"]){
					[imageReceiveTransferAlert dismissWithClickedButtonIndex:61 animated:YES];
					[imageReceiveTransferAlert release];
					
					//Sender cancelled image transfer request
					receivingRemoteImage = NO;
					
					[imageHexData release];
					imageHexData = nil;
					imageByteSize = 0;
					
					continue;
				}
				else if([message isEqualToString:@"X"]){
					//Receiver rejected image transfer request
					[self stopImageTransfer];
					
					continue;
				}
				else if([message isEqualToString:@"Y"]){
					//Receiver accepted image transfer request, so send image
					[self sendImageHexData:self.imageHexString];
					
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
						[self updateProgressView:(float)[imageHexData length]/imageByteSize];
						
						//Check whether image transfer is finished
						if([imageHexData length] == imageByteSize){
							receivingRemoteImage = NO;
							DLog(@"Finished receive for remote image!");
							
							[self displayProgressView:NO];
							
							BOOL imageOkay = [drawingView loadRemoteImageWithHexString:imageHexData];
							
							if(!imageOkay){
								UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Image Loading Failed!" message:@"Please try again!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
								[alert show];
								[alert release];
							}
							
							
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
				
				//usleep(1000); //Quick fix... not reliable
				
				/*
				 //if there's no bytes available in stream and the last read length is not 0
				 while(![_inStream hasBytesAvailable] && !readLength);
				 DLog(@"Retrieving remote image!");
				 
				 Byte *buffer = malloc(imageDataSize);
				 if(!buffer) {
				 DLog(@"Buffer allocatino error in Receiving Remote Image!");
				 
				 }
				 else {
				 NSInteger len = 0;
				 
				 if(readLength){
				 memcpy(buffer, buff, readLength);
				 len = [_inStream read:buffer+readLength maxLength:imageDataSize-readLength];
				 }
				 else {
				 len  = [_inStream read:buffer maxLength:imageDataSize];
				 }
				 
				 if(len){
				 NSData *imageData = [NSData dataWithBytes:buffer length:imageDataSize];
				 DLog(@"Finished receive for remote image!");
				 
				 [drawingView loadRemoteImageWithByteData:imageData];
				 }
				 free(buffer);
				 }
				 
				 imageDataSize = 0;
				 receivingRemoteImage = NO;
				 */
				
				
				/*
				 static NSMutableString *imageByteData = nil;
				 
				 if( [message isEqualToString:@"--/I>"] ){
				 receivingRemoteImage = NO;
				 
				 if(imageByteData) {
				 
				 const char *bytes = [imageByteData UTF8String];
				 NSData *imageData = [NSData dataWithBytes:bytes length:strlen(bytes)];
				 if(!bytes && !imageData) DLog(@"IMAGE BYTE DATA CONVERSION ERROR!");
				 
				 [drawingView loadRemoteImageWithByteData:imageData];
				 
				 [imageByteData release];
				 imageByteData = nil;
				 
				 DLog(@"Finished receive for remote image!");
				 }
				 }
				 else {
				 if(!imageByteData){
				 imageByteData = [[NSMutableString alloc] init];
				 }
				 
				 [imageByteData appendString:message];
				 
				 }
				 
				 */
				
				continue;
			}
			else if ([message isEqualToString:@"K"]){
				
				peerReadyToReceive = YES;
				
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
		} else if ([message isEqualToString:@"c"]) {
			// since a color is also 4 CGFloat's, we'll again store it in a CGRect
			DLog(@"receivingRemoteColor = YES");
			receivingRemoteColor = YES;
		} else if (receivingRemoteColor && ![message isEqualToString:@""]) {
			DLog(@"setting remoteComponents");
			CGRect rect = CGRectFromString([message stringByAppendingString:@"}}"]);
			remoteComponents[0] = rect.origin.x;
			remoteComponents[1] = rect.origin.y;
			remoteComponents[2] = rect.size.width;
			//remoteComponents[3] = rect.size.height;
			//remoteComponents[3] = 1.0 - powf(1.0 - rect.size.height, 1.0 / ((2.0 / kBrushPixelStep) * widthDiameter));
			
			//if (protocolVersion == 1) {
			remoteTrueOpacity = rect.size.height;
			//} else {
			// Fixed a bug where I was setting this to remoteTrueOpacity :(
			//	remoteComponents[3] = rect.size.height;
			//}
			
			receivingRemoteColor = NO;
			//usingRemoteColor = NO; // Very important! So we set the color next time we need it
			if (usingRemoteColor) {
				[self performSelectorOnMainThread:@selector(setRemoteColor) withObject:nil waitUntilDone:YES];
			}
			
		} else if ([message isEqualToString:@"s"]) {
			receivingRemotePointSize = YES;
		} else if (receivingRemotePointSize && ![message isEqualToString:@""]) {
			receivingRemotePointSize = NO; // Don't forget this!
			if ([message isEqualToString:@"r"]) {
				// rejection message
				DLog(@"rejected");
				
				if (!initializedWithPeers) {
					initializedWithPeers = YES;
					
					if ([NSThread isMainThread]) {
						DLog(@"%s on MainThread", _cmd);
					} else {
						DLog(@"%s NOT on MainThread", _cmd);
					}
					
					// Aren't I already executing on inStreamThread?
					// Optimize later
					//[[_picker bvc] stopActivityIndicator];
					[[_picker bvc] performSelector:@selector(stopActivityIndicator:) onThread:inStreamThread withObject:nil waitUntilDone:YES];
					
					NSString* serverName = [namesForStreams objectForKey:[stream description]];
					
					UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"“%@” has rejected your request", serverName]
																		message:@"If you wish, you may try your request again." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
					[alertView show];
					[alertView release];
					
					[self disconnectFromPeerWithStream:stream];
				}
				
			} else {
				[self setRemotePointSize:[message floatValue]];
				[self initializeWithPeersIfNecessaryMessage:message stream:stream];
			}
			
		} else if ([message isEqualToString:@"n"]) {
			
			receivingRemoteName = YES;
			
		} else if (receivingRemoteName && ![message isEqualToString:@""]) {
			
			receivingRemoteName = NO;
			[self receiveRemoteName:message source:source];
			
		} else if ([message isEqualToString:@"e"]) {
			// erase request
			
			if ([self.picker shouldConfirmStartOver]) {
				NSString* serverName = [namesForStreams objectForKey:[stream description]];
				
//				NSString *message = @"";
				//if (drawingView.autoSave && drawingView.hasUnsavedChanges) {
//				if (drawingView.hasUnsavedChanges) {
//					message = @"Your current drawing will be\nauto-saved to your Photos.\n\n";
//				}
				message = [message stringByAppendingString:@"Do you want to Start Over?"];
				eraseWaitAlertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"“%@” would like to Start Over", serverName] message:@"" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
				[eraseWaitAlertView show];
				//[eraseWaitAlertView release];
				
				DLog(@"showed alertView for erase request");
			} else {
				// Remember we're in a different thread here, and UI updates only work in the main thread
				[self performSelectorOnMainThread:@selector(acceptStartOverRequest) withObject:nil waitUntilDone:YES];
			}
		} else if ([message isEqualToString:@"a"]) {
			// Erase accept reply (a)
			
			// Erase
			[self performSelectorOnMainThread:@selector(doErase)
								   withObject:nil
								waitUntilDone:YES];
			
			// Close alertView (don't need to notify, it'll be obvious)
			if (eraseWaitAlertView) {
				[eraseWaitAlertView dismissWithClickedButtonIndex:0 animated:YES];
				[eraseWaitAlertView release];
				eraseWaitAlertView = nil;
			}
			
		} else if ([message isEqualToString:@"j"]) {
			// Erase reject reply (j)
			
			// Close alertView
			if (eraseWaitAlertView) {
				[eraseWaitAlertView dismissWithClickedButtonIndex:0 animated:YES];
				[eraseWaitAlertView release];
				eraseWaitAlertView = nil;
			}
			
			// Notify rejected
			UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Your request to Start Over was declined"
																message:@"" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alertView show];
			[alertView release];
			
		} else if ([message isEqualToString:@"L"]) {
			DLog(@"Cancel request (L)");
			
			// Close alertView
			if (eraseWaitAlertView) {
				[eraseWaitAlertView dismissWithClickedButtonIndex:0 animated:YES];
				[eraseWaitAlertView release];
				eraseWaitAlertView = nil;
			}
		} else if ([message isEqualToString:@"2"]) {
			// Peer supports whiteboard protocol version 2
			DLog(@"protocolVersion = 2");
			protocolVersion = 2;
			
			[self initializeWithPeersIfNecessaryMessage:message stream:stream];
			
			[self sendMyColor];
			[self sendMyPointSize];
		} else if ([message isEqualToString:kiPadMessage]) {
			DLog(@"remoteDevice = iPadDevice");
			remoteDevice = iPadDevice;
			[self sendMyColor];		// these change for iPad-iPad connections
			[self sendMyPointSize];	//
			
			/*
			 Don't process blank messages!
			 */
		} else if ([message isEqualToString:@"b"]) {
			[self receiveBeginStroke];
			
		} else if ([message isEqualToString:@"w"]) {
			[self receiveEndStroke];
			
		} else if ([message isEqualToString:@"r"]) {
			[self receiveRedoRequest];
			
		} else if ([message isEqualToString:@"u"]) { 
			[self receiveUndoRequest];
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
		} else if ([message isEqualToString:@"t"]) {
			
			//[self send:[NSString stringWithFormat:@"t}}%@}}%@}}%f}}%f}}%f}}", text, textFontName, textFontSize, textPoint.x, textPoint.y]];
			receivingText = YES;
		} else if (receivingText && ![message isEqualToString:@""]) {
			//DLog(@"gettting remote text %@", message);
			remoteText = [NSString stringWithString:message];
			receivingText = NO;
			receivingTextFont = YES;
			
			//[self performSelectorOnMainThread:@selector(setRemoteColor) withObject:nil waitUntilDone:YES];
			
		} else if (receivingTextFont && ![message isEqualToString:@""]) {
			//DLog(@"gettting remote font name %@", message);
			remoteFontName = [NSString stringWithString:message];
			receivingTextFont = NO;
			receivingTextSize = YES;
			
		
		} else if (receivingTextSize && ![message isEqualToString:@""]) {
			//DLog(@"gettting remote text size %@", message);
			remoteTextSize = [message floatValue];
			receivingTextSize = NO;
			receivingTextPosition = YES;
		
		} else if (receivingTextPosition && ![message isEqualToString:@""]) {
			//DLog(@"gettting remote text position %@", message);
			remoteTextPoint = CGPointFromString(message);
			receivingTextPosition = NO;
			
			[self performSelectorOnMainThread:@selector(renderRemoteText) withObject:nil waitUntilDone:YES];
			
		} else if ([message isEqualToString:@"p"]) {
			
			receivingSpray = YES;
			
		} else if (receivingSpray && ![message isEqualToString:@""]) {
			
			receivingSpray = NO;
			
			[self performSelectorOnMainThread:@selector(renderRemoteColorSprayWithRect:)
								   withObject:[message stringByAppendingString:@"}}"]
								waitUntilDone:YES];
			
		} else if (![message isEqualToString:@""]) {
			//DLog(@"gettting remote line %@", message);
			/*
			 This is probably an incoming line to draw.
			 waitUntilDone so that we don't slow down the UI with too many requests.
			 Note that the withObject: parameter MUST be an object (CGRect won't work).
			 */
			[self performSelectorOnMainThread:@selector(renderRemoteColorLineWithRect:)
								   withObject:[message stringByAppendingString:@"}}"]
								waitUntilDone:YES];
		}
		//DLog(@"done handling message");
	}
}

// All incoming stream events go through here
- (void)stream:(NSStream*)stream handleEvent:(NSStreamEvent)eventCode {
	switch(eventCode) {
		// Executes on both the Server and the Client
		case NSStreamEventOpenCompleted:
		{
			[self streamEventOpenCompleted:stream];
			break;
		}
		case NSStreamEventHasBytesAvailable:
		{
			
			if ([[UIApplication sharedApplication] respondsToSelector:@selector(applicationState)]) {
				if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
					// don't read bytes if the app is not active (may be inactive or background)
					return;
				}
			}
			
			int i;
			
			
			//DLog(@"NSStreamEventHasBytesAvailable");
			NSInputStream* _inStream;
			for(_inStream in _inStreams) {
				if (stream == _inStream) {
					//DLog(@"stream == _inStream");
					
					
					//Retrieve remote image data
					imageDataSize = 0;
					static NSMutableData *imgData = nil;
					if(receivingRemoteImage && imageDataSize && !USE_HEX_STRING_IMAGE_DATA){
						DLog(@"Retrieving remote image!");
						Byte *buffer = malloc(imageDataSize);
						if(!buffer) {
							DLog(@"Buffer allocation error in Receiving Remote Image!");
							
						}
						else {
							if(!imgData){
								imgData = [[NSMutableData alloc] initWithCapacity:10000];
							}
							
							NSInteger len = [_inStream read:buffer maxLength:imageDataSize];
							[imgData appendBytes:buffer length:len];
							
							if(len == imageDataSize){
								
								DLog(@"Finished receive for remote image! (Bytes: %d", [imgData length]);
								
								[drawingView loadRemoteImageWithByteData:imgData];
								
								imageDataSize = 0;
								receivingRemoteImage = NO;
							}
							else {
								imageDataSize -= len;
								DLog(@"Image retrieval left: %d (%d retrieved)", imageDataSize, len);
							}
							free(buffer);
						}
						
						break;
					}
					
					
					uint8_t buff[1024];
					bzero(buff, sizeof(buff));
					
					NSInteger readLength;
					NSString* message = @"";
					NSString *temp = nil;
					
					//
					// Note: We don't explicitly handle incomplete streams here
					//
					
					for(i = 0; i < 1000 && [_inStream hasBytesAvailable]; i++) {
						readLength = [_inStream read:buff maxLength:sizeof(buff) - 1];
						buff[readLength] = '\0';
						
						// Not all chars can be converted to UTF8 Strings
						temp = [NSString stringWithUTF8String:(const char *)buff];
						if (temp) {
							message = [message stringByAppendingString:temp];
//							readLength = 0; // Value stored to 'readLength' is never read
						} else {
							DLog(@"Non UTF8 String Received!");
							break;
						}
					}
					
					[self processMessage:message source:stream];
					
					//DLog(@"for loop done");
					
					
					/*
					 if ([stream streamStatus] != NSStreamStatusAtEnd) {
					 DLog(@"[stream streamStatus] != NSStreamStatusAtEnd");
					 }
					 */
					
					/*
					 uint8_t b;
					 unsigned int len = 0;
					 len = [_inStream read:&b maxLength:sizeof(uint8_t)];
					 if(!len) {
					 if ([stream streamStatus] != NSStreamStatusAtEnd)
					 [self showNetworkError:@"Failed reading data from peer"];
					 } else {
					 //We received a remote tap update, forward it to the appropriate view
					 if(b & 0x80)
					 [(TapView*)[_window viewWithTag:b & 0x7f] touchDown:YES];
					 else
					 [(TapView*)[_window viewWithTag:b] touchUp:YES];
					 }
					 */
					break;
				}
			}
			break;
		}
		case NSStreamEventEndEncountered:
		{
			NSString* serverName = [[namesForStreams objectForKey:[stream description]] retain]; // very important to retain here!
			DLog(@"serverName == %@", serverName);
			
			DLog(@"NSStreamEventEndEncountered");
			// disappears here!
			if ([self disconnectFromPeerWithStream:stream]) {
				// rejected case covered because rejection message always gets sent?
				
				// We've successfully disconnected, so set acceptReject.name to nil
				// This is used by BrowserViewController bvc
				[_acceptReject setName:nil];
				
				// if acceptReject alertView is showing, dismiss it
				DLog(@"about to check acceptRejectAlertView"); /******/
				if (acceptRejectAlertView != nil) {
					DLog(@"acceptRejectAlertView != nil");
					//[[_picker bvc] stopActivityIndicator];
					
					//DLog(@"it's YES");
					[acceptRejectAlertView dismissWithClickedButtonIndex:2 animated:YES];
					
					[acceptRejectAlertView release];
					acceptRejectAlertView = nil;
				}
				
				DLog(@"about to show disconnect msg, serverName == %@", serverName);
				
				// kind of a hack? sometimes it's (null) [conflict, or simultaneous, case]
				if (serverName) {
					[self performSelectorOnMainThread:@selector(showDisconnectedAlert:) withObject:[[serverName copy] autorelease] waitUntilDone:YES];
					DLog(@"showed disconnect msg");
					
					
					// Do this even if we didn't need to disconnect?
					
					// Give the device we disconnected from some time to reappear (if it is going to)
					// If it does reappear, then we don't remove it
					// But if it then disappears again, make sure we do!
					[NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(removeServiceWithTimer:) userInfo:[[serverName copy] autorelease] repeats:NO]; // BUGFIX: autorelease fixes memory leak
				}
			}
			
			//
			// At this point, we're done disconnecting.
			// -disconnectFromPeerWithStream: does the work of:
			//     o Resetting connectedName
			//     o Reloading the tableView
			//
			
			[serverName release];
			
			//
			// Note: we may need to do more cleanup here,
			//       like removing leftover objects from arrays, etc.
			//
			
			DLog();
			
			break;
		}
		case NSStreamEventNone:
		{
			DLog(@"NSStreamEventNone");
			break;
		}
		case NSStreamEventHasSpaceAvailable: // This event occurs only for NSOutputStreams.
		{
			[self streamEventHasSpaceAvailable:stream];
			
			break;
		}
		case NSStreamEventErrorOccurred:
		{
			DLog(@"NSStreamEventErrorOccurred");
			
			//
			// A better user experience would be to show only 1 error alert.
			// Currently, this alert can appear multiple times.
			//
			
			NSError *theError = [stream streamError];
			
			if (!errorAlert) {
				NSString *title = nil, *message = nil;
				NSInteger code = [theError code];
				NSString *domain = [theError domain];
				DLog(@"error domain = %@", domain);
				
				if (code == 32) {
					title = @"Peer Disconnected";
					message = [NSString stringWithFormat:@"Error %i: %@", code, [theError localizedDescription]];
					
					// disconnect and clean up
					[self disconnectFromPeerWithStream:nil];
					
				} else if ([domain isEqualToString:NSPOSIXErrorDomain] && code == EAFNOSUPPORT /*47*/) {
					// Error 47: ... Address family not supported by protocol family
					title = @"Connection Error";
					message = @"Make sure Whiteboard is still running on the other device.";
				}
//				else if (code == 49) {
//					title = @"Unexpected Networking Event";
//					message = @"The connection was probably established just fine.";
//				}
				else if (code == 57) {
					// Error 57 / NSPOSIXErrorDomain / Operation could not be completed. Socket is not connected
					// errno.h
					title = @"Network Error";
					message = @"";
					if (drawingView.hasUnsavedChanges) {
						// Save drawing
						//[drawingView captureToSavedPhotoAlbum];
						[drawingView captureToWhiteboardTempFile];
						message = @"Your drawing will be restored when you restart. ";
					}
					message = [message stringByAppendingString:@"Please restart Whiteboard\nand try again."];
				} else if (code == ETIMEDOUT /*60*/) {
					// Error 60 / NSPOSIXErrorDomain / The operation couldn't be completed. Operation timed out
					title = @"Network Error";
					message = @"The other device disconnected.";
					// socket has been dropped (by the server / other device) and is no longer there
					
					// TODO: try to reconnect for 5-10 sec. depending on what the error is
					
					// TODO: clean up connection
				} else if (code == 61) {
					title = @"Peer Unavailable";
				} else {
					title = @"Error reading/writing stream";
					message = [NSString stringWithFormat:@"Error %i: %@", code, [theError localizedDescription]];
				}
				errorAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[errorAlert show];
				//[alert release];
				
				NSString *analyticsMessage = [NSString stringWithFormat:@"Error%i", code];
				ANALYTICS_LOG(analyticsMessage);
			}
			
			[stream close];
			[stream release], stream = nil;
			
			break;
		}
		default:
		{
			DLog(@"unrecognized eventCode:%u", eventCode); // Unsigned 32-bit integer (unsigned int)
			break;
		}
	}
}

// Execute on MainThread
- (void)showDisconnectedAlert:(NSString *)serverName {
	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"“%@” has disconnected", serverName] message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
	[alertView show];
	[alertView release];
}

// Execute on inStreamThread
- (void)rejectSilentlyWithName:(NSString*)name {
	[self acceptPendingRequest:kRejectSilently withName:name];
}


// Execute on MainThread
- (void)removeServiceWithTimer:(NSTimer*)timer {
	if ([NSThread isMainThread]) {
		DLog(@"%s on MainThread", _cmd);
	} else {
		DLog(@"%s NOT on MainThread", _cmd);
	}
	
	[[_picker bvc] performSelectorOnMainThread:@selector(removeServiceWithName:)
									withObject:[timer userInfo]
								 waitUntilDone:YES];
}

@end
