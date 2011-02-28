//
//  AppController+NSStreamDelegate.m
//  Whiteboard
//
//  Created by Elliot Lee on 6/26/09.
//  Copyright 2010-2011 Greengar Studios. All rights reserved.
//

#import "WhiteboardMacAppDelegate+NSStreamDelegate.h"
#import "GSWhiteboard.h"
#import "MainPaintingView.h"
//#import "errno.h"

//extern BOOL USE_HEX_STRING_IMAGE_DATA; // currently always YES

@implementation WhiteboardMacAppDelegate (NSStreamDelegate)


- (void)initializeWithPeersIfNecessaryMessage:(NSString *)message stream:(NSStream *)stream {
	//DLog();
//	[self send:@"2}}"];
//	
//	//
//	// If I'm an iPad, tell my peer.
//	//
//
//	[self send:[NSString stringWithFormat:@"%@}}", kiPadMessage]];
//	
//	[self sendMyColor];
//	[self sendMyPointSize];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"kConnectedNotification" object:nil];
}

- (void)streamEventHasSpaceAvailable:(id)stream {
	/**
	 * This assumes 1 peer.
	 * The Client sends its name to the Server, but not the other way around!
	 */
	if (needToSendName) {
		needToSendName = NO;
		
		// Send my name to this output stream
		// (Maybe we could save a little bandwidth by doing this only if I'm the client)
		[self send:[NSString stringWithFormat:@"n}}%@}}", @"Mac"] toOutStream:(id)stream];
		
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
			DLog(@"unknown message type");
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


// for server AND client
- (void)streamEventOpenCompleted:(id)stream {
	//DLog();
	
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
				//DLog(@"set _inReady = YES");
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
	
	//DLog(@"check _inReady && _outReady");
	if (!stream || [stream isKindOfClass:[NSString class]] || (_inReady && _outReady)) {
		//NSString* serverName = [namesForStreams objectForKey:[stream description]];
		// when serverName is set, I'm actually the client
		// when serverName is nil, I'm actually the server
		//DLog(@"(_inReady && _outReady) == YES, amServer:%d serverName:%@", amServer, serverName);
		
		// if I'm the client, I need to initializeWithPeers
		//DLog();
	} else {
		//DLog(@"(_inReady && _outReady) == NO");
	}
}

- (void)sendMyColorForPoint {
	// ForPoint means the opacity modification has already been considered
	
	//	CGPoint first2components = CGPointMake(components[0], components[1]);
	//	CGPoint second2components = CGPointMake(components[2], components[3]);
	
	// "c" means color
	[self send:@"c}}"];
	
	// Send the components as a CGRect
	//	[self sendLineFromPoint:first2components toPoint:second2components];
	CGRect cgRect = CGRectMake(components[0], components[1], components[2], components[3]);
	[self send:NSStringFromRect(NSRectFromCGRect(cgRect))];
}

- (void)sendMyColor {
	//DLog();
	
	//
	// iPad<->iPhone opacity conversion is taken care of in -pointSizeToSend
	//
	
	//CGFloat modifiedDiameter = [self pointSizeToSend] * 2.0f;
	
	if (protocolVersion == 1) {

		[self sendMyColorForPoint];
		
	} else {

		CGFloat temp[4];
		temp[0] = [NSAppDelegate getRedValue];
		temp[1] = [NSAppDelegate getGreenValue];
		temp[2] = [NSAppDelegate getBlueValue];
		temp[3] = [NSAppDelegate getAlphaValue];
		
		CGFloat opacity = temp[3];
		
		temp[3] = 1.0 - powf(1.0 - temp[3], 1.0 / (2.0 * [NSAppDelegate getPointSize]));
		
		[NSAppDelegate setTrueColorAndOpacity:temp];
		
		[self sendMyColorForPoint];
		
		temp[3] = opacity;
		[NSAppDelegate setTrueColorAndOpacity:temp];
	}
}

- (void)setRemotePointSize:(float)size {
	if (remoteDevice != iPadDevice) { //[[UIScreen mainScreen] bounds].size.width == 768
		size = size * 2.0f;
		DLog(@"%f", size);
	} else {
		DLog(@"%f", size);
	}
	
	remotePointSize = size;
	//DLog(@"remotePointSize %f", size);
	if (usingRemoteColor) {
		//
		// We may already be OnMainThread, but it doesn't hurt to make sure.
		//
		[self performSelectorOnMainThread:@selector(setRemoteColor) withObject:nil waitUntilDone:YES];
	}
}


/** Executes on the server **/
// Accept (OK) or reject (Don't Allow) an incoming join request
- (void) acceptPendingRequest:(NSUInteger)response withName:(NSString*)name
{

	pendingJoinRequest = NO;
	//amServer = YES; // moved from didAcceptConnection...
	
	if (response == YES) {
		
		[_server stop];
		

		// For Whiteboard Pro, make sure the client AND server both send this message (protocolVersion)
		[self send:@"2}}"];
		

		[self send:[NSString stringWithFormat:@"%@}}", kiPadMessage]];
		//DLog(@"server sending pointSize"); // too early, send again when iPad message is received
		[self sendMyColor];
		[self sendMyPointSize];
		
		//  Remember: this is server code, running on the server.
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"kConnectedNotification" object:nil];
		
		
	} else {
		// Response is No
		DLog(@"[namesForStreams count] == %d", [namesForStreams count]);
		
		NSArray* allStreams = [namesForStreams allKeysForObject:name];
		
		DLog(@"[allStreams count] == %d", [allStreams count]);
		
		NSString* strStream;
		// Print streams
		for (strStream in allStreams) {
			DLog(@"stream:%@", strStream);
		}
		
		/** Watch out! This is duplicated code from NSStreamEventEndEncountered! **/
		
		// Close streams
		NSInputStream* _inStream;
		NSOutputStream* _outStream;
		for (_outStream in _outStreams) {
			NSString* _outStreamDescription = [NSString stringWithString:[_outStream description]];
			if (_outStream && [allStreams containsObject:_outStreamDescription]) {

				if (![_outStream hasSpaceAvailable]) {
					DLog(@"Warning: acceptPendingRequest: ![_outStream hasSpaceAvailable]");
				}

				// Send a rejection message only to this _outStream
				[self send:@"s}}r}}" toOutStream:_outStream];
				
				// Close stream
				[_outStream close];
				[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
				//[_outStream release];
				//_outStream = nil;
				
				// Remove stream from NSMutableDictionary
				[namesForStreams removeObjectForKey:_outStreamDescription];
				
				// Remove stream?
				DLog(@"removeObject:%@", _outStream);
				[_outStreams removeObject:_outStream];
				
				DLog(@"acceptPendingRequest: Removed _outStream");
			}
		}
		
		DLog(@"looking for _inStream");
		for (_inStream in _inStreams) {
			NSString* _inStreamDescription = [NSString stringWithString:[_inStream description]];
			if (_inStream && [allStreams containsObject:_inStreamDescription]) {
				
				// Close stream
				[_inStream close];
				[_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
				//[_inStream release];
				//_inStream = nil;
				
				// Remove stream from NSMutableDictionary
				[namesForStreams removeObjectForKey:_inStreamDescription];
				
				// Remove stream?
				DLog(@"removeObject:%@", _inStream);
				[_inStreams removeObject:_inStream];
				
				DLog(@"Removed _inStream");
			}
		}
		
		// Added this so acceptReject.name indicates that there's an ongoing incoming connection
		DLog(@"[_acceptReject setName:nil];");
		//[_acceptReject setName:nil];
		
		DLog(@"[_outStreams count] == %d", [_outStreams count]);
		for (_outStream in _outStreams) {
			DLog(@"_outStream:%@", _outStream);
		}
		
		DLog(@"[_inStreams count] == %d", [_inStreams count]);
		for (_inStream in _inStreams) {
			DLog(@"_inStream:%@", _inStream);
		}
	}
}


- (void)receiveRemoteName:(NSString *)message wb:(NSString *)wb {
		 
	// TODO: check that we're not connected to anyone else yet
	
	DLog(@"creating Internet connection (server)");
	GSWhiteboard *w = [GSWhiteboard whiteboardWithType:@"Internet" name:message];
	w.wb = wb;
	//self.picker.internetConnection.connectedWhiteboard = w;
	[self streamEventOpenCompleted:w.wb]; // act like a local connection
	
	pendingJoinRequest = YES; // Set the flag that indicates there is a pending join request
	
	// Assume whiteboard protocol version 1 until we hear otherwise
	DLog(@"protocolVersion = 1");
	protocolVersion = 1;
	
	remoteDevice = iPhoneDevice; // assume remoteDevice is an iPhone until we hear otherwise
	
	[self performSelectorOnMainThread:@selector(displayAlertConnectedDevice:) withObject:message waitUntilDone:YES];
	
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
	
		// Name doesn't exist yet, or name does exist but I'm supposed to be the server
		// Everyone: don't send name unless you're supposed to!
		//if ([namesForStreams objectForKey:[stream description]] == nil || ([[[_picker bvc] ownName] compare:[namesForStreams objectForKey:[stream description]]] == NSOrderedAscending)) {
		{	[namesForStreams setObject:message forKey:[stream description]];
			
			// associate name with _outStream, too
			NSUInteger index = [_inStreams indexOfObject:stream];
			[namesForStreams setObject:message forKey:[[_outStreams objectAtIndex:index] description]];
			

			protocolVersion = 1;
			
			remoteDevice = iPhoneDevice; // assume remoteDevice is an iPhone until we hear otherwise
			
			// Remember that this code is running on the Server.
			// pendingJoinRequest should be YES already, but since we're not supporting more than 2 peers,
			// it may be NO. So let's make sure:
			pendingJoinRequest = YES;
			
			[self acceptPendingRequest:YES withName:message];
			[self performSelectorOnMainThread:@selector(displayAlertConnectedDevice:) withObject:message waitUntilDone:YES];
		}			
		//DLog(@"here");
	}
	
}


- (void)processMessage:(NSString *)message source:(id)source {
	NSStream *stream = nil;
//	NSString *wb = nil;
	if ([source isKindOfClass:[NSStream class]]) {
		stream = source;
	}

	
	//DLog(@"message = %@", message);
	
	NSArray* points = [message componentsSeparatedByString:@"}}"];
	for(message in points) {
		// Watch out for blank "messages"!
		
		// handle remote color changes
		//DLog(@"starting for loop, receivingRemoteColor = %d", receivingRemoteColor);
		
		
		if(TRUE){
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
					
					// say 'Yes' by default
					receivingRemoteImage = YES;
					[self send:@"Y}}"];
					
					continue;
				}
				else if([message isEqualToString:@"Z"]){
//					[imageReceiveTransferAlert dismissWithClickedButtonIndex:61 animated:YES];
//					[imageReceiveTransferAlert release];
					
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
						//[self updateProgressView:(float)[imageHexData length]/imageByteSize];
						
						//Check whether image transfer is finished
						if([imageHexData length] == imageByteSize){
							receivingRemoteImage = NO;
							DLog(@"Finished receive for remote image!");
							
							//[self displayProgressView:NO];
							
							[drawingView performSelectorOnMainThread:@selector(loadRemoteImageWithHexString:) withObject:imageHexData waitUntilDone:YES];
							
							/*if(!imageOkay){
//								UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Image Loading Failed!" message:@"Please try again!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//								[alert show];
//								[alert release];
								DLog(@"image loading failed");
							}*/
							
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
				
				
				
				
				continue;
			}
			else if ([message isEqualToString:@"K"]){
				
				peerReadyToReceive = YES;
				
				continue;
			}
		}
		
		
		
		//NON IMAGE TRANSFER CODES HERE:
		//USED so far: c,s,r,n,e,a,j,L, 
		//             b,w,u for begin stroke, end stroke, undo respectively
		
		//const NSString *kiPadMessage = @"i";
		//#define kiPadMessage @"i" // moved to header
		
		if (receivingRemoteImage) {
			continue;
		} else if ([message isEqualToString:@"c"]) {
			// since a color is also 4 CGFloat's, we'll again store it in a CGRect
			//DLog(@"receivingRemoteColor = YES");
			receivingRemoteColor = YES;
		} else if (receivingRemoteColor && ![message isEqualToString:@""]) {
			//DLog(@"setting remoteComponents");
			NSRect rect = NSRectFromString([message stringByAppendingString:@"}}"]);
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
			[self performSelectorOnMainThread:@selector(acceptStartOverRequest) withObject:nil waitUntilDone:YES];
			
		} else if ([message isEqualToString:@"a"]) {
			// Erase accept reply (a)
			
			// Erase
			[self performSelectorOnMainThread:@selector(doErase)
								   withObject:nil
								waitUntilDone:YES];
			
		} else if ([message isEqualToString:@"j"]) {
			// Erase reject reply (j)
			
			
		} else if ([message isEqualToString:@"L"]) {
			DLog(@"Cancel request (L)");
			
			
		} else if ([message isEqualToString:@"2"]) {
			// Peer supports whiteboard protocol version 2
			//DLog(@"protocolVersion = 2");
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
			
			[drawingView receiveBeginStroke];
			
		} else if ([message isEqualToString:@"w"]) {
			
			[drawingView receiveEndStroke];
			
		} else if ([message isEqualToString:@"r"]) {
			
			[drawingView performSelectorOnMainThread:@selector(receiveRedoRequest) withObject:nil waitUntilDone:YES];
			
		} else if ([message isEqualToString:@"u"]) { 
			
			[drawingView performSelectorOnMainThread:@selector(receiveUndoRequest) withObject:nil waitUntilDone:YES];

		} else if (![message isEqualToString:@""]) {
			
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
			int i;
			
			
			//DLog(@"NSStreamEventHasBytesAvailable");
			NSInputStream* _inStream;
			for(_inStream in _inStreams) {
				if (stream == _inStream) {
					//DLog(@"stream == _inStream");
					
					
					//Retrieve remote image data
					imageDataSize = 0;
					static NSMutableData *imgData = nil;
					//if(receivingRemoteImage && imageDataSize && !USE_HEX_STRING_IMAGE_DATA){
					if(receivingRemoteImage && imageDataSize){
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
								
								// FIXME: code from iOS version. actually this rarely gets called.
								// we have to fix this anyway.
								
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
			//DLog(@"serverName == %@", serverName);
			
			//DLog(@"NSStreamEventEndEncountered");
			// disappears here!
			[self disconnectFromPeerWithStream:stream];
			

			
			//
			// At this point, we're done disconnecting.
			// -disconnectFromPeerWithStream: does the work of:
			//     o Resetting connectedName
			//     o Reloading the tableView
			//
			
			[self performSelectorOnMainThread:@selector(showDisconnectedAlert:) withObject:[[serverName copy] autorelease] waitUntilDone:YES];
			[NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(removeServiceWithTimer:) userInfo:[[serverName copy] autorelease] repeats:NO]; // BUGFIX: autorelease fixes memory leak
			
			[serverName release];
			
			//
			// Note: we may need to do more cleanup here,
			//       like removing leftover objects from arrays, etc.
			//
			
			break;
		}
		case NSStreamEventNone:
		{
			//DLog(@"NSStreamEventNone");
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
			
						
			[stream close];
			[stream release];
			
			break;
		}
		default:
		{
			DLog(@"unrecognized eventCode:%u", eventCode); // Unsigned 32-bit integer (unsigned int)
			break;
		}
	}
}


- (void)showDisconnectedAlert:(NSString *)serverName {
//	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"“%@” has disconnected", serverName] message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
//	[alertView show];
//	[alertView release];
	
	[NSAppDelegate clearConnectedDeviceName];
	
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:[NSString stringWithFormat:@"“%@” has disconnected", serverName]];
	//[alert setInformativeText:@"You are now able to view drawing on connected device"];
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert setIcon:[NSImage imageNamed:kAlertIcon]];
	
	[alert runModal];
	[alert release];
	
	
}

- (void)removeServiceWithTimer:(NSTimer*)timer {
	if ([NSThread isMainThread]) {
		DLog(@"%s on MainThread", _cmd);
	} else {
		DLog(@"%s NOT on MainThread", _cmd);
	}

}

@end
