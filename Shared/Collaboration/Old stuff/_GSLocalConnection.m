//
//  GSLocalConnection.m
//  Whiteboard
//
//  Created by Cong Vo on 12/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GSLocalConnection.h"
#import "GSInternetConnection.h"
#import "AppController.h"
#import "Picker.h"
#import "FlurryAPI.h"
#import "GSWhiteboard.h"
#import "BrowserViewController.h"
#import "GSConnectionController.h"
//#import "GSStream.h"

@interface GSLocalConnection ()

- (void)send:(NSString *)message;
- (void)showNetworkError:(NSString*)title;
- (void)rejectedSilentlyConnectionRequest:(NSString *)name source:(id)source;
- (void)sendInStreamThreadMessage:(NSString *)message toOutStream:(id)stream;

@end


@implementation GSLocalConnection	
//@synthesize outStreams = _outStreams;


@synthesize bvc = _bvc, peerReadyToReceive;
@synthesize outStreams = _outStreams, inStreams = _inStreams;
@synthesize namesForStreams, inStreamThread;
@synthesize didSendConnectionRequest = _didSendConnectionRequest;

- (BrowserViewController *)bvc {
	if (_bvc == nil) {
		//DLog(@"bvc alloc"); // occurs the first time Connect is tapped
		_bvc = [[BrowserViewController alloc] initWithDelegate:self];
		[_bvc searchForServicesOfType:[TCPServer bonjourTypeFromIdentifier:kGameIdentifier] inDomain:@"local"];
//		_bvc.delegate = self.bvcDelegate;
//		_bvc.delegate = self;		
		//[self.bvc.view setFrame:CGRectMake(0, runningY, self.bounds.size.width, kTableHeight)];
		//self.bvc.view.tag = kBvcTag;
		//[self addSubview:self.bvc.view];
	}	
	return _bvc;
}

// This executes inStreamThread
- (void) create:(id)useless {
	NSLogMark;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	//DLog(@"inStreamThread started");
	
	// Destroy any existing server
	[_server release];
	_server = nil;
	
	// Create a new game
	//_server = [[TCPServer new] retain]; // added retain here
	_server = [TCPServer new];
	[_server setDelegate:self];
	
//	// Create the _inStreams and _outStreams NSMutableArrays
//	_inStreams = [[NSMutableArray arrayWithCapacity:1] retain];
//	_outStreams = [[NSMutableArray arrayWithCapacity:1] retain];
	
	/*
	 NSInputStream* _inStream;
	 for(_inStream in _inStreams) {
	 [_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	 [_inStream release];
	 _inStream = nil;
	 }
	 */
	_inReady = NO;
	
	/*
	 NSOutputStream* _outStream;
	 for(_outStream in _outStreams) {
	 [_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	 [_outStream release];
	 _outStream = nil;
	 }
	 */
	_outReady = NO;
	
	NSError* error;
	if(_server == nil || ![_server start:&error]) {
		DLog(@"Failed creating server: %@", error);
		[self showNetworkError:@"Failed creating server"];
		return;
	}
	
	//Start advertising to clients, passing nil for the name to tell Bonjour to pick use default name
	if(![_server enableBonjourWithDomain:@"local" applicationProtocol:[TCPServer bonjourTypeFromIdentifier:kGameIdentifier] name:nil]) {
		[self showNetworkError:@"Failed advertising server"];
		return;
	}
	//DLog(@"inStreamThread success");
	
	//	[[UIApplication sharedApplication] setupScreenMirroringWithFramesPerSecond:3];
	
	
	// Kick off the RunLoop
	[[NSRunLoop currentRunLoop] run];
	
	DLog(@"inStreamThread pool release");
	[pool release];
}


- (void)startToBroadcast {
	NSLogMark;
	
	// Create namesForStreams NSDictionary
	namesForStreams = [[NSMutableDictionary dictionaryWithCapacity:2] retain];
	
	// Create the _inStreams and _outStreams NSMutableArrays
	_inStreams = [[NSMutableArray arrayWithCapacity:1] retain];
	_outStreams = [[NSMutableArray arrayWithCapacity:1] retain];
	
	
	//[self create];
	inStreamThread = [[NSThread alloc] initWithTarget:self
											 selector:@selector(create:)
											   object:nil];
	[inStreamThread start];
	
	
	// Advertise a new whiteboard and discover other available whiteboards
	
	/*
	 Make sure to let the user know what name is being used for Bonjour advertisement.
	 This way, other players can browse for and connect to this game.
	 Note that this may be called while the alert is already being displayed, as
	 Bonjour may detect a name conflict and rename dynamically.
	 Note that it is also called after disconnect, because devices then begin advertising again.
	 */
	
	// Connection
	
	pendingJoinRequest = NO;
//	initializedWithPeers = YES; // No peers yet
	needToSendName = NO;
	
	writeBuffer = @"";

#ifndef LITE
	//SHERWIN: Setting my uninitalized variables
	peerReadyToReceive = NO;
#endif	
	
	
	_bvc.delegate = self;
}

- (void)closeConnection {
	
}

- (void)showNetworkError:(NSString*)title {
	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:@"Check your networking configuration." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}


- (void)enterBackground {
	// Disconnect from all peers
	// TODO: re-connect when the app returns to the foreground
//	[self disconnectFromPeerWithStream:nil];
	
	// stop broadcasting on Bonjour
	//BOOL stopped = [_server stop];
	//DLog(@"stopped = %d", stopped);
	[_server stop];
}

//- (NSUInteger)streamCount {
//	return ([_inStreams count] + [_outStreams count]);
//}
//
//- (NSUInteger)outStreamCount {
//	return [_outStreams count];
//}

- (void)dealloc {
	// clean things, low level stuff latter, high level stuff (view) first - kong

	
	
	// Cleanup any running resolve and free memory
	if (_bvc) {
		//[self.bvc stop];
		[_bvc release];
		_bvc = nil;
	}

	[_server release]; // this release was already here

	// close stream
	NSInputStream* _inStream;
	for(_inStream in _inStreams) {
		[_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		//[_inStream release];
		DLog(@"instreams removed: %@", _inStream);
		[_inStreams removeObject:_inStream];
		
	}
	
	NSOutputStream* _outStream;
	for(_outStream in _outStreams) {
		[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		//[_outStream release];
		[_outStreams removeObject:_outStream];
	}
	
	[_inStreams release];
	[_outStreams release];
	
	[super dealloc];
}

- (NSUInteger)streamCount {
	return ([_inStreams count] + [_outStreams count]);
}

- (NSUInteger)outStreamCount {
	return [_outStreams count];
}




- (void) sendImageData:(NSData*)imageData {
	
	if(![imageData length]) return;
	
	// TODO: check number of stream
	if(![_outStreams count]) return;
	
	DLog(@"Sending Image Header!");
	NSString *header = [NSString stringWithFormat:@"<I--}}%d}}", [imageData length]]; 
	[self send: header];

	//Set up the sending state variables
	UIAppDelegate.connection.sendingRemoteImage = YES;
	while(!peerReadyToReceive);
	peerReadyToReceive = NO; //Reset the image setting boolean
	DLog(@"Begin Image Transfer!");
	
	
	//NSString *ender = @"--/I>}}";
	//DLog(@"Send Size - Header: %d, Data: %d, Ender: %d", [header length], [imageData length], [ender length]);
	/*
	DLog(@"Send Data Length - Byte: %d, Tags: %d", [imageData length], [header length]+[ender length]);
	
	NSUInteger buffLen = [imageData length] + [header length] + [ender length];
	char *buff = malloc(buffLen + 1);
	
	memcpy(buff,	[header UTF8String],	[header length]);
	memcpy(buff + [header length],	[imageData bytes],	[imageData length]);
	memcpy(buff + [header length] + [imageData length], [ender UTF8String], [ender length]);
	buff[buffLen] = '\0';
	*/
	 
	//DLog(@"TEST IMAGE BYTES: %s", buff);
	//return;
	
	//const Byte *buff = [imageData bytes];
	
	const Byte *buff = [imageData bytes];
	NSUInteger buffLen = [imageData length];
	NSInteger writtenLength = 0;
	NSOutputStream* _outStream;
	
	// TODO: stop using deprecated method
	NSString *message = [NSClassFromString(@"NSString") stringWithCString:[imageData bytes] length:buffLen];
	if ([writeBuffer length] > 0 && ![writeBuffer isEqualToString:message]) {
		[self send:writeBuffer];
		writeBuffer = @"";
		//DLog(@"back to %s%@", _cmd, message); // Conversion specifies type 'char *' but the argument has type 'SEL'
	}
	
	// TODO: seperate into 2 methods
	for(_outStream in _outStreams) {
		if (_outStream) {
			if ([_outStream hasSpaceAvailable]) {
				//DLog(@"send:%@", message);
				writtenLength = [_outStream write:buff maxLength:buffLen];
				if (writtenLength != buffLen) {
					DLog(@"Failed sending data to peer, writtenLength = %d, buffLen = %d", writtenLength, buffLen);
					
					buff += writtenLength;
					buffLen -= writtenLength;
					while (buffLen > 0 && writtenLength != -1) {
						writtenLength = [_outStream write:buff maxLength:buffLen];
						DLog(@"Successfully wrote %d bytes", writtenLength);
						buff += writtenLength;
						buffLen -= writtenLength;
					}
					
				} else {
					DLog(@"Write successful! (Bytes written: %d)", writtenLength);
				}
			} else {
				DLog(@"Warning: send: ![_outStream hasSpaceAvailable]");
				
				// Use the stream synchronously
				// https://devforums.apple.com/message/2902#2902
				// turn around and try to write the remaining data.  If buffer space hasn't become available, this will block.
				
				
				/*
				 while (buffLen > 0 && writtenLength != -1) {
				 writtenLength = [_outStream write:(const uint8_t *)buff maxLength:strlen(buff)];
				 DLog(@"successfully wrote %d bytes", writtenLength);
				 buff += writtenLength;
				 buffLen -= writtenLength;
				 }
				 */
				
				
				// Put into a write buffer
				writeBuffer = [writeBuffer stringByAppendingString:message];
				
				
			}
			if (writtenLength == -1) {
				DLog(@"writtenLength == -1");
				// This occurs if we try to do stuff at the point when we say Game Started!
				//[NSException raise:@"send: WriteFailure" format:@"writtenLength = %d, [_outStreams count] = %d, _outStream = %@", writtenLength, [_outStreams count], _outStream];
				
				// Put into a write buffer
				writeBuffer = [writeBuffer stringByAppendingString:message];
				
			}
		} else {
			DLog(@"Warning: !_outStream");
		}
	}
	
	if ([writeBuffer isEqualToString:message]) {
		writeBuffer = @"";
	}
	
	//[self send:ender];
	UIAppDelegate.connection.sendingRemoteImage = NO;
}


- (void)sendLargeDataByChunks:(NSString*)message identifier:(NSString*)sendID {
	
	if(![message length]) return; //Don't send message with no data
	
	// check for internet connection
//	GSWhiteboard *connectedWhiteboard = [self.internetConnection connectedWhiteboard];
	GSWhiteboard *connectedWhiteboard = [UIAppDelegate.connection.internetConnection connectedWhiteboard];	
	if (connectedWhiteboard) {
		[UIAppDelegate.connection.internetConnection sendLargeDataByChunks:message];
		return;
	} 
	
	
	// TODO: check
	if(![_outStreams count]) return; //Don't try to send if there's no streams!
	
	if ([writeBuffer length] > 0 && ![writeBuffer isEqualToString:message]) {
		[self send:writeBuffer];
		writeBuffer = @"";
		//DLog(@"back to %s%@", _cmd, message);
	}	
	
	// Loop variables
	int byteRange = 50;//500; //How many bytes to send at once
 	int idx = 0;
	BOOL lastLoop = NO;
	
	// Temporary variables
	NSRange range; 
	NSString *tempStr = nil;
	
	// Network sending variables
	const char *buff = nil;
	NSUInteger buffLen = 0;
	NSInteger writtenLength = 0;
	NSOutputStream *_outStream;
	
	
	//	NSString *header = @"";
	//	NSString *ender  = @"";
	if(sendID){
		//		header = [NSString stringWithFormat:@"<%@--", sendID];
		//		ender =  [NSString stringWithFormat:@"--/%@>}}", sendID];
		
		//DLog(@"Header Bytes: %d, Ender Bytes: %d", [header length], [ender length]);
		
		//1. First send header to notify start of image transfer, and the number of bytes to expect
		//[self send: [NSString stringWithFormat:@"<I--N:%d}}", [message length]] ];
	}
	//usleep(800); //Give a pause
	
	
	int i = 0;
	while(!lastLoop){
		
		//Adjust the range if theres not enough characters left
		if([message length] - idx < byteRange) {
			byteRange = [message length] - idx;
			lastLoop = YES;
			
			//if(!sendID) break;
		}
		
		//Update the range
		range.location = idx;
		range.length = byteRange;
		
		//Get the substring to send
		if(range.length) {
			if(sendID){
				tempStr = [NSString stringWithFormat:@"<%@--%@}}", sendID, [message substringWithRange:range]];
			}
			else {
				tempStr = [message substringWithRange:range];
			}
		}
		else {
			if(!sendID) break;
			
			tempStr = [NSString stringWithString:@""];
		}
		
		//Append End Identifier if this is the last loop
		if(lastLoop && sendID) {
			tempStr = [tempStr stringByAppendingFormat:@"--/%@>}}", sendID];
		}
		
		//Update the index
		idx += byteRange;
		
		
		//Sending code:
		buff = [tempStr UTF8String];
		buffLen = strlen(buff);
		writtenLength = 0;
		
		
		//while(!spaceAvailable);
		//spaceAvailable = NO;
		
		
		for(_outStream in _outStreams) {
			if (_outStream) {
				
				//SHERWIN: As of June 27, 2009, there is only one output stream available, so hang until it is available
				while(![_outStream hasSpaceAvailable]);
				
				if ([_outStream hasSpaceAvailable]) {
					//DLog(@"send:%@", message);
					writtenLength = [_outStream write:(const uint8_t *)buff maxLength:strlen(buff)];
					if (writtenLength != buffLen) {
						DLog(@"Failed sending data to peer, writtenLength = %d, buffLen = %d", writtenLength, buffLen);
						
						buff += writtenLength;
						buffLen -= writtenLength;
						while (buffLen > 0 && writtenLength != -1) {
							writtenLength = [_outStream write:(const uint8_t *)buff maxLength:strlen(buff)];
							DLog(@"Successfully wrote %d bytes", writtenLength);
							buff += writtenLength;
							buffLen -= writtenLength;
						}
						
					} else {
						//DLog(@"Write #%d successful! (Bytes written: %d)", i, writtenLength);
					}
				} else {
					DLog(@"Warning: send: ![_outStream hasSpaceAvailable]");
					
					// Use the stream synchronously
					// https://devforums.apple.com/message/2902#2902
					// turn around and try to write the remaining data.  If buffer space hasn't become available, this will block.
					
					
					/*
					 while (buffLen > 0 && writtenLength != -1) {
					 writtenLength = [_outStream write:(const uint8_t *)buff maxLength:strlen(buff)];
					 DLog(@"successfully wrote %d bytes", writtenLength);
					 buff += writtenLength;
					 buffLen -= writtenLength;
					 }
					 */
					
					
					// Put into a write buffer
					writeBuffer = [writeBuffer stringByAppendingString:message];
					
					
				}
				if (writtenLength == -1) {
					DLog(@"writtenLength == -1");
					// This occurs if we try to do stuff at the point when we say Game Started!
					//[NSException raise:@"send: WriteFailure" format:@"writtenLength = %d, [_outStreams count] = %d, _outStream = %@", writtenLength, [_outStreams count], _outStream];
					
					// Put into a write buffer
					writeBuffer = [writeBuffer stringByAppendingString:message];
					
				}
			} else {
				DLog(@"Warning: !_outStream");
			}
		}
		
		if ([writeBuffer isEqualToString:message]) {
			writeBuffer = @"";
		}
		
		
		i++;
	}
	
	DLog(@"Finished sending large data string by chunks! (#: %d", i);
}

//KONG: this method is used to send message to connected whiteboard 
- (void)send:(NSString *)message {
		
	if(UIAppDelegate.connection.sendingRemoteImage) {
		DLog(@"Currently sending remote image data, blocking all other sends!");
		return;
	}
	
	//DLog(@"%s%@, [_outStreams count] = %d", _cmd, message, [_outStreams count]);
	// Watch out for an infinite loop
	if ([writeBuffer length] > 0 && ![writeBuffer isEqualToString:message]) {
		[self send:writeBuffer];
		writeBuffer = @"";
		//DLog(@"back to %s%@", _cmd, message);
	}
	
	//SHERWIN: Checking what is being sent
	//if([message length] < 50) DLog(@"Sending message: %@", message);
	
	const char *buff = [message UTF8String];
	
	NSUInteger buffLen = strlen(buff);
	NSInteger writtenLength = 0;
	
	 
	NSOutputStream* _outStream = (NSOutputStream *)[(GSLocalWhiteboard *) UIAppDelegate.connection.connectedWhiteboard outStream];
	
//	for(_outStream in _outStreams) {
		if (_outStream) {
			
			//-[__NSCFDictionary hasSpaceAvailable]: unrecognized selector sent to instance 0x20efc0
			//2010-11-05 15:43:38.676 Whiteboard[1727:307] *** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '-[__NSCFDictionary hasSpaceAvailable]: unrecognized selector sent to instance 0x20efc0'
			
//			if ([_outStream respondsToSelector:@selector(hasSpaceAvailable)] == NO) {
//				// this can occur if the peer disconnected by causing an error, e.g. (code == 32)
//				DLog(@"WARNING: _outStream doesn't respond to -hasSpaceAvailable");
//				continue;
//			}

			//			while(![_outStream hasSpaceAvailable]);

			if ([_outStream hasSpaceAvailable]) {
				//DLog(@"send:%@", message);
				writtenLength = [_outStream write:(const uint8_t *)buff maxLength:strlen(buff)];
				if (writtenLength != buffLen) {
					DLog(@"Failed sending data to peer, writtenLength = %d, buffLen = %d", writtenLength, buffLen);
					
					buff += writtenLength;
					buffLen -= writtenLength;
					while (buffLen > 0 && writtenLength != -1) {
						writtenLength = [_outStream write:(const uint8_t *)buff maxLength:strlen(buff)];
						DLog(@"Successfully wrote %d bytes", writtenLength);
						buff += writtenLength;
						buffLen -= writtenLength;
					}
					
				} else {
					//DLog(@"Write successful! (Bytes written: %d)", writtenLength);
				}
			} else {
				DLog(@"Warning: send: ![_outStream hasSpaceAvailable]");
				
				// Use the stream synchronously
				// https://devforums.apple.com/message/2902#2902
				// turn around and try to write the remaining data.  If buffer space hasn't become available, this will block.
				
				
				/*
				 while (buffLen > 0 && writtenLength != -1) {
				 writtenLength = [_outStream write:(const uint8_t *)buff maxLength:strlen(buff)];
				 DLog(@"successfully wrote %d bytes", writtenLength);
				 buff += writtenLength;
				 buffLen -= writtenLength;
				 }
				 */
				
				
				// Put into a write buffer
				writeBuffer = [writeBuffer stringByAppendingString:message];
				
				
			}
			if (writtenLength == -1) {
				DLog(@"writtenLength == -1");
				// This occurs if we try to do stuff at the point when we say Game Started!
				//[NSException raise:@"send: WriteFailure" format:@"writtenLength = %d, [_outStreams count] = %d, _outStream = %@", writtenLength, [_outStreams count], _outStream];
				
				// Put into a write buffer
				writeBuffer = [writeBuffer stringByAppendingString:message];
				
			}
		} else {
			DLog(@"Warning: !_outStream");
		}
//	} // end for loop
	
	if ([writeBuffer isEqualToString:message]) {
		writeBuffer = @"";
	}
}

- (void)sendToConnectedWhiteboard:(NSString *)message {
	[self send:message];
}


// Write to one specific outStream
- (void)send:(NSString *)message toOutStream:(id)destination {
	if (!destination) return;
	
	DLog(@"send:%@ destination:%@", message, destination);
	
	if(UIAppDelegate.connection.sendingRemoteImage) {
		DLog(@"Currently sending remote image data, blocking all other sends!");
		return;
	}
	
	@try {
		[(id <GSOutputStream>)destination sendMessage:message];
	}
	
	@catch (NSException *e) {
		DLog(@"Warning: EXCEPTION: %@", e);
	}
}

- (void) openInStream:(NSInputStream*)_inStream withOutStream:(NSOutputStream*)_outStream
{
	//DLog(@"%s", _cmd);
	[self performSelector:@selector(openStream:) onThread:inStreamThread withObject:_inStream waitUntilDone:YES];
	//DLog(@"mainThread: inStreamThread opened _inStream");
	[self performSelector:@selector(openStream:) onThread:inStreamThread withObject:_outStream waitUntilDone:YES];
	//DLog(@"mainThread: inStreamThread opened _outStream");
	/*
	 _inStream.delegate = self;
	 [_inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	 //[_inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSEventTrackingRunLoopMode];
	 [_inStream open];
	 _outStream.delegate = self;
	 [_outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	 //[_outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSEventTrackingRunLoopMode];
	 [_outStream open];
	 */
}

- (void) openStream:(NSStream*)stream
{
	//DLog(@"%s%@", _cmd, stream);
	stream.delegate = self;
	[stream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[stream open];
}





// Executes on the client (the device on which we tap the server's name - the "guest")
- (void)browserViewController:(BrowserViewController*)bvc didResolveInstance:(NSNetService*)netService {
	DLog(@"AppController: didResolveInstance:");
	
	NSLogMark;
	
	if (!netService) {
		//DLog(@"Warning: %s but !netService", _cmd);
		//[self setup];
//		[self showPicker];
		[UIAppDelegate showPicker];
		return;
	}
	
	NSInputStream* _inStream;
	NSOutputStream* _outStream;
	if (![netService getInputStream:&_inStream outputStream:&_outStream]) {
		[self showNetworkError:@"Failed connecting to server"];
		return;
	}
	
	// TODO: check
	// Keep track of the netService names associated with each stream
	[namesForStreams setObject:[netService name] forKey:[_inStream description]];
	[namesForStreams setObject:[netService name] forKey:[_outStream description]];
	
	// Add _inStream and _outStream to their respective NSMutableArrays
	
	DLog(@"[_inStreams addObject:%@];", _inStream);
	[_inStreams addObject:_inStream];
	
	DLog(@"[_outStreams addObject:%@];", _outStream);
	[_outStreams addObject:_outStream];
	
	[self openInStream:_inStream withOutStream:_outStream];
	
	//KONG: add used streams into appropriate Whiteboard
	GSLocalWhiteboard *waitedWhiteboard = (GSLocalWhiteboard *)UIAppDelegate.connection.waitedWhiteboard;
	if (waitedWhiteboard.type == GSConnectionTypeLocal && waitedWhiteboard.service == netService) {
		waitedWhiteboard.inStream = _inStream;
		waitedWhiteboard.outStream = _outStream;
		DLog(@"resolved waitedWhiteboard: %@", UIAppDelegate.connection.waitedWhiteboard);
	}

	[UIAppDelegate.connection initiateConnection];
}




- (void)enterForeground {
	// start broadcasting on Bonjour
	if ([_server isStopped]) {
		NSError* error = nil;
		BOOL started = [_server start:&error];
		DLog(@"started = %d", started);
		if (error) {
			DLog(@"error = %@", error);
		}
		BOOL enabled = [_server enableBonjourWithDomain:@"local" applicationProtocol:[TCPServer bonjourTypeFromIdentifier:kGameIdentifier] name:nil];
		DLog(@"enabled = %d", enabled);
	}
}

#pragma mark Connection
- (GSConnectionType)type {
	return GSConnectionTypeLocal;
}

- (void)send:(NSString *)message toWhiteboard:(id <GSWhiteboard>)wb {
	[self send:message toOutStream:[(GSLocalWhiteboard *)wb outStream]];
}
/*
- (void)sendRejectMessageAndCloseAllStreamsFrom:(NSString *)name {
	//KONG: close both inStreams and outStreams associated w "name"
	// call from connection
	DLog(@"[namesForStreams count] == %d", [namesForStreams count]);
	
	NSArray* allStreams = [namesForStreams allKeysForObject:name];
	
	DLog(@"[allStreams count] == %d", [allStreams count]);
	
	NSString* strStream;
	// Print streams
	for (strStream in allStreams) {
		DLog(@"stream:%@", strStream);
	}
	
	// Watch out! This is duplicated code from NSStreamEventEndEncountered! 
	
	// Close streams
	NSInputStream* _inStream;
	NSOutputStream* _outStream;
	
	for (int i = 0; i< [_outStreams count]; i++) {
		_outStream = [_outStreams objectAtIndex:i];
		NSString* _outStreamDescription = [NSString stringWithString:[_outStream description]];
		if (_outStream && [allStreams containsObject:_outStreamDescription]) {
#if DEBUG
			if (![_outStream hasSpaceAvailable]) {
				DLog(@"Warning: acceptPendingRequest: ![_outStream hasSpaceAvailable]");
			}
#endif
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
	for (int i = 0; i< [_inStreams count]; i++) {
		_inStream = [_inStreams objectAtIndex:i];
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
	
	//KONG: this is for testing. I think
	
	DLog(@"[_outStreams count] == %d", [_outStreams count]);
	for (_outStream in _outStreams) {
		DLog(@"_outStream:%@", _outStream);
	}
	
	DLog(@"[_inStreams count] == %d", [_inStreams count]);
	for (_inStream in _inStreams) {
		DLog(@"_inStream:%@", _inStream);
	}
	
}
 */



- (void)sendRejectMessageToPeerWithInStream:(id)stream {
	NSUInteger index = [_inStreams indexOfObject:stream];
	if (index == NSNotFound) {
		DLog(@"WARNING: not found stream:%@ in Instreams", stream);
		return;
	}
	
	if (index >= [_outStreams count]) {
		DLog(@"WARNING: not found  out stream of instream:%@ in Outstreams", stream);		
		return;
	}
	
	NSOutputStream *outStream = [_outStreams objectAtIndex:index];
	
	[outStream sendMessage:@"s}}r}}"];
	
	// remove
	
	[_inStreams removeObject:stream];
	[_outStreams removeObject:outStream];
	[namesForStreams removeObjectForKey:[stream description]];
	[namesForStreams removeObjectForKey:[outStream description]];
}

//- (void)sendRejectMessageAndCloseAllStreamsFrom:(NSString *)name {
//	//KONG: close both inStreams and outStreams associated w "name"
//	// call from connection
//	DLog(@"[namesForStreams count] == %d", [namesForStreams count]);
//	
//	NSArray* allStreams = [namesForStreams allKeysForObject:name];
//	
//	DLog(@"[allStreams count] == %d", [allStreams count]);
//	
//	NSString* strStream;
//	// Print streams
//	for (strStream in allStreams) {
//		DLog(@"stream:%@", strStream);
//	}
//	
//	/** Watch out! This is duplicated code from NSStreamEventEndEncountered! **/
//	
//	// Close streams
//	NSInputStream* _inStream;
//	NSOutputStream* _outStream;
//	
//	for (int i = 0; i< [_outStreams count]; i++) {
//		_outStream = [_outStreams objectAtIndex:i];
//		NSString* _outStreamDescription = [NSString stringWithString:[_outStream description]];
//		if (_outStream && [allStreams containsObject:_outStreamDescription]) {
//#if DEBUG
//			if (![_outStream hasSpaceAvailable]) {
//				DLog(@"Warning: acceptPendingRequest: ![_outStream hasSpaceAvailable]");
//			}
//#endif
//			// Send a rejection message only to this _outStream
//			
//			
//			[self send:@"s}}r}}" toOutStream:_outStream];
//			
//			
//			// Close stream
////			[_outStream close];
////			[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
//			//[_outStream release];
//			//_outStream = nil;
//			
//			// Remove stream from NSMutableDictionary
//			[namesForStreams removeObjectForKey:_outStreamDescription];
//			
//			// Remove stream?
//			DLog(@"removeObject:%@", _outStream);
//			[_outStreams removeObject:_outStream];
//			
//			DLog(@"acceptPendingRequest: Removed _outStream");
//		}
//	}
//	
//	DLog(@"looking for _inStream");
//	for (int i = 0; i< [_inStreams count]; i++) {
//		_inStream = [_inStreams objectAtIndex:i];
//		NSString* _inStreamDescription = [NSString stringWithString:[_inStream description]];
//		if (_inStream && [allStreams containsObject:_inStreamDescription]) {
//			
//			// Close stream
////			[_inStream close];
////			[_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
//			//[_inStream release];
//			//_inStream = nil;
//			
//			// Remove stream from NSMutableDictionary
//			[namesForStreams removeObjectForKey:_inStreamDescription];
//			
//			// Remove stream?
//			DLog(@"removeObject:%@", _inStream);
//			[_inStreams removeObject:_inStream];
//			
//			DLog(@"Removed _inStream");
//		}
//	}
//	
//	//KONG: this is for testing. I think
//	
//	DLog(@"[_outStreams count] == %d", [_outStreams count]);
//	for (_outStream in _outStreams) {
//		DLog(@"_outStream:%@", _outStream);
//	}
//	
//	DLog(@"[_inStreams count] == %d", [_inStreams count]);
//	for (_inStream in _inStreams) {
//		DLog(@"_inStream:%@", _inStream);
//	}
//	
//}
//


/*
- (void)sendRejectMessageAndCloseAllStreamsFrom:(NSString *)name {
	 //KONG: close both inStreams and outStreams associated w "name"
	// call from connection
	 DLog(@"[namesForStreams count] == %d", [namesForStreams count]);
	 
	 NSArray* allStreams = [namesForStreams allKeysForObject:name];
	 
	 DLog(@"[allStreams count] == %d", [allStreams count]);
	 
	 NSString* strStream;
	 // Print streams
	 for (strStream in allStreams) {
		 DLog(@"stream:%@", strStream);
	 }
	 
	 // Watch out! This is duplicated code from NSStreamEventEndEncountered! 
	 
	 // Close streams
	 NSInputStream* _inStream;
	 NSOutputStream* _outStream;

	NSMutableArray *shouldBeRemovedStream = [NSMutableArray arrayWithCapacity:[_outStreams count]];
	
	for (NSOutputStream *_outStream in _outStreams) {
		 NSString* _outStreamDescription = [NSString stringWithString:[_outStream description]];
		 if (_outStream && [allStreams containsObject:_outStreamDescription]) {
#if DEBUG
			 if (![_outStream hasSpaceAvailable]) {
				 DLog(@"Warning: acceptPendingRequest: ![_outStream hasSpaceAvailable]");
			 }
#endif
			 // Send a rejection message only to this _outStream
			 
			 
			 [self send:@"s}}r}}" toOutStream:_outStream];
			 
			 			 
			 // Close stream
			 //KONG: test 
//			 [_outStream close];
//			 [_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
			 
			 
			 //[_outStream release];
			 //_outStream = nil;
			 
			 // Remove stream from NSMutableDictionary
			 //KONG: test			 
//			 [namesForStreams removeObjectForKey:_outStreamDescription];
			 
			 // Remove stream?
			 DLog(@"removeObject:%@", _outStream);
			 //KONG: test
//			 [shouldBeRemovedStream addObject:_outStream];
//			 [_outStreams removeObject:_outStream];
		}
	 }
	 
	[_outStreams removeObjectsInArray:shouldBeRemovedStream];
	[shouldBeRemovedStream removeAllObjects];
	DLog(@"acceptPendingRequest: Removed _outStream");

	
	 DLog(@"looking for _inStream");
	for (NSInputStream *_inStream in _inStreams) {
		 NSString* _inStreamDescription = [NSString stringWithString:[_inStream description]];
		 if (_inStream && [allStreams containsObject:_inStreamDescription]) {
			 
			 // Close stream
//			 [_inStream close];
//			 [_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
			 //[_inStream release];
			 //_inStream = nil;
			 
			 // Remove stream from NSMutableDictionary
//			 [namesForStreams removeObjectForKey:_inStreamDescription];
			 
			 // Remove stream?
			 DLog(@"removeObject:%@", _inStream);
//			 [shouldBeRemovedStream addObject:_inStream];
		 }
	 }
	[_inStreams removeObjectsInArray:shouldBeRemovedStream];
	[shouldBeRemovedStream removeAllObjects];
	DLog(@"Removed _inStream");
	
	 //KONG: this is for testing. I think
	 
	 DLog(@"[_outStreams count] == %d", [_outStreams count]);
	 for (_outStream in _outStreams) {
		 DLog(@"_outStream:%@", _outStream);
	 }
	 
	 DLog(@"[_inStreams count] == %d", [_inStreams count]);
	 for (_inStream in _inStreams) {
		 DLog(@"_inStream:%@", _inStream);
	 }
 }
*/
- (void)disconnectFromPeerWithStreamName:(NSString *)name {
	NSInputStream *inStreamForName = nil;
	for (NSInputStream *inStream in _inStreams) {
		NSString *streamName = [namesForStreams objectForKey:[inStream description]];
		if ([streamName isEqualToString:name]) {
			inStreamForName = inStream;
			return;
		}
	}
	
	if (inStreamForName) {
		[self disconnectFromPeerWithStream:inStreamForName];
	}
}

- (void)disconnectFromPeerWithStreamInInstreamThread:(NSStream *)stream {
	[self performSelector:@selector(disconnectFromPeerWithStream:) onThread:inStreamThread withObject:stream waitUntilDone:YES];			
}

- (void)removeInStream:(NSInputStream *)stream {
	NSString* _inStreamDescription = [NSString stringWithString:[stream description]];
	
	// Close stream
	[stream close];
	[stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	//[_inStream release];
	//_inStream = nil;
	
	// Remove stream from NSMutableDictionary
	[namesForStreams removeObjectForKey:_inStreamDescription];
	
	// Remove stream?
	DLog(@"removeObject:%@", stream);
	[_inStreams removeObject:stream];
	DLog(@"Removed stream");
	
}


- (void)removeOutStream:(NSOutputStream *)stream {
	NSString* _outStreamDescription = [NSString stringWithString:[stream description]];
	
	// Close stream
	[stream close];
	[stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	//[_outStream release];
	//_outStream = nil;
	
	// Remove stream from NSMutableDictionary
	[namesForStreams removeObjectForKey:_outStreamDescription];
	
	// Remove stream?
	DLog(@"removeObject:%@", stream);
	[_outStreams removeObject:stream];
	DLog(@"disconnectFromPeerWithStream: Removed _outStream");
}

- (BOOL)closeInOutStreamsWithInStream:(NSStream *)stream {
	NSArray* allStreams;
	NSUInteger index;
	
	//KONG: we should not send nil to this method, unpredictable situation
	if (stream == nil) {
		allStreams = [namesForStreams allKeys];
		
		// allStreams count must be >= 0
		
		if ([allStreams count] == 0) {
			DLog(@"Warning: no streams to disconnect from");
			return NO;
		}
		
		// Assume we're connected to only 1 peer
		// TODO: disconnect from the correct peer only (when selected from list)
		index = 0;
		
		@try {
			stream = [_inStreams objectAtIndex:0];
		}
		
		@catch (NSException *e) {
			DLog(@"Warning: error selecting _inStream 0 (NSRangeException)");
			return NO;
		}
		
	} else {
		//DLog(@"[namesForStreams count] == %d", [namesForStreams count]);
		NSString* name = [namesForStreams objectForKey:[stream description]];
		allStreams = [namesForStreams allKeysForObject:name];
		//DLog(@"[allStreams count] == %d", [allStreams count]);
		
		// Close streams
		// stream is my _inStream
		
		index = [_inStreams indexOfObject:stream];
		if (index == NSNotFound) {
			DLog(@"stream NOT found in inStreams: stream: %@, allStream: %@", stream, allStreams);
			// already disconnected
			return NO;
		}
	}
	
	// setting currentResolve moved to bottom
	
	
	NSOutputStream* _outStream;
	
	@try {
		// this may throw NSRangeException if stream was removed concurrently
		[self removeOutStream:_outStream];
	}
	
	@catch (NSException *e) {
		DLog(@"Warning: error removing stream (NSRangeException)");
		return NO;
	}
	
	// use @finally if an object may need to be released
	
	// close in stream
	[self removeInStream:(NSInputStream *)stream];
	
	//KONG: just for checking
	DLog(@"[_outStreams count] == %d", [_outStreams count]);
	for (_outStream in _outStreams) {
		DLog(@"_outStream:%@", _outStream);
	}
	
	NSInputStream* _inStream;
	DLog(@"[_inStreams count] == %d", [_inStreams count]);
	for (_inStream in _inStreams) {
		DLog(@"_inStream:%@", _inStream);
	}
	return YES;
}

- (void)removeAllStreamsExceptStreamsInWhiteboard:(GSLocalWhiteboard *)whiteboard {
	if (whiteboard.inStream == nil || whiteboard.outStream == nil) {
		return;
	}
	
	// keep my stream
	[_inStreams removeObject:whiteboard.inStream];
	// remove all others
	while ([_inStreams count] > 0) {
		NSInputStream *inStream = [_inStreams objectAtIndex:0];
		[self removeInStream:inStream];
	}
	// restore mine
	[_inStreams addObject:whiteboard.inStream];
	DLog(@"instreams added: %@", whiteboard.inStream);

	// keep my stream
	[_outStreams removeObject:whiteboard.outStream];
	// remove all others
	while ([_outStreams count] > 0) {
		NSOutputStream *outStream = [_outStreams objectAtIndex:0];
		[self removeOutStream:outStream];
	}
	// restore mine
	[_outStreams addObject:whiteboard.outStream];
}

- (BOOL)disconnectFromPeerWithStream:(NSStream *)stream {
	//DLog(@"%s", _cmd);
	
	
	NSArray* allStreams;
	NSUInteger index;
	
	if (stream == nil) {
		allStreams = [namesForStreams allKeys];
		
		// allStreams count must be >= 0
		
		if ([allStreams count] == 0) {
			DLog(@"Warning: no streams to disconnect from");
			return NO;
		}
		
		// Assume we're connected to only 1 peer
		// TODO: disconnect from the correct peer only (when selected from list)
		index = 0;
		
		@try {
			stream = [_inStreams objectAtIndex:0];
		}
		
		@catch (NSException *e) {
			DLog(@"Warning: error selecting _inStream 0 (NSRangeException)");
			return NO;
		}
		
	} else {
		//DLog(@"[namesForStreams count] == %d", [namesForStreams count]);
		NSString* name = [namesForStreams objectForKey:[stream description]];
		allStreams = [namesForStreams allKeysForObject:name];
		//DLog(@"[allStreams count] == %d", [allStreams count]);
		
		// Close streams
		// stream is my _inStream
		
		index = [_inStreams indexOfObject:stream];
		if (index == NSNotFound) {
			// already disconnected
			return NO;
		}
	}
	
	//	Picker *_picker = UIAppDelegate.picker;
	//	if (self.bvc.currentResolve) {
	if (_bvc.currentResolve) {	
		DLog(@"self.bvc.currentResolve.name == %@", _bvc.currentResolve.name);
	} else {
		DLog(@"self.bvc.currentResolve == nil");
	}
	
//	if (_bvc.nextService) {
//		DLog(@"self.bvc.nextService.name == %@", _bvc.nextService.name);
//	} else {
//		DLog(@"self.bvc.nextService == nil");
//	}
	
	// setting currentResolve moved to bottom
	
	// do we need to reload here?
	//[[self.bvc tableView] reloadData];
	
	
	NSOutputStream* _outStream;
	
	@try {
		// this may throw NSRangeException if stream was removed concurrently
		_outStream = [_outStreams objectAtIndex:index];
		
		NSString* _outStreamDescription = [NSString stringWithString:[_outStream description]];
		
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
		DLog(@"disconnectFromPeerWithStream: Removed _outStream");
	}
	
	@catch (NSException *e) {
		DLog(@"Warning: error removing stream (NSRangeException)");
		return NO;
	}
	
	// use @finally if an object may need to be released
	
	NSString* _inStreamDescription = [NSString stringWithString:[stream description]];
	
	// Close stream
	[stream close];
	[stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	//[_inStream release];
	//_inStream = nil;
	
	// Remove stream from NSMutableDictionary
	[namesForStreams removeObjectForKey:_inStreamDescription];
	
	// Remove stream?
	DLog(@"removeObject:%@", stream);
	[_inStreams removeObject:stream];
	DLog(@"Removed stream");
	
	DLog(@"[_outStreams count] == %d", [_outStreams count]);
	for (_outStream in _outStreams) {
		DLog(@"_outStream:%@", _outStream);
	}
	
	NSInputStream* _inStream;
	DLog(@"[_inStreams count] == %d", [_inStreams count]);
	for (_inStream in _inStreams) {
		DLog(@"_inStream:%@", _inStream);
	}
	
	/*
	 for (NSOutputStream * outs in _outStreams) {
	 [outs close];
	 [outs removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	 [outs release], outs = nil;
	 }
	 
	 for (NSInputStream * ins in _inStreams) {
	 [ins close];
	 [ins removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	 [ins release], ins = nil;
	 }
	 
	 [_outStreams removeAllObjects];
	 [_inStreams removeAllObjects];
	 [namesForStreams removeAllObjects];*/
	
	// TODO: check why wee need it here
	// Added this so acceptReject.name indicates that there's an ongoing incoming connection
	DLog(@"disconnectFromPeerWithStream: [UIAppDelegate.connection.acceptReject setName:nil];");
	//	[UIAppDelegate.connection.acceptReject setName:nil];
	
	//KONG: refactor this and the code in create: method
	// when we support multiple collaboration, we should remove this
	if ([_server isStopped]) {
		/*** Start Advertising Again ***/
		DLog(@"Start Advertising Again");
		
		// We should do this only if we are stopped!
		
		assert(_server != nil);
		
		NSError* error;
		if(_server == nil || ![_server start:&error]) {
			DLog(@"Failed creating server: %@", error);
			[self showNetworkError:@"Failed creating server"];
			return YES;
		}
		
		//Start advertising to clients, passing nil for the name to tell Bonjour to pick use default name
		if(![_server enableBonjourWithDomain:@"local" applicationProtocol:[TCPServer bonjourTypeFromIdentifier:kGameIdentifier] name:nil]) {
			[self showNetworkError:@"Failed advertising server"];
			//return;
		}
		
		//DLog(@"success");
	}
	
	//assert([_inStreams count] >= 0 && [_outStreams count] >= 0);
	
	//if ([_inStreams count] == 0 && [_outStreams count] == 0) {
	{	
		/* // Shouldn't do this because it's already taken care of...
		 // For the conflict situation
		 if (self.bvc.nextService) {
		 self.bvc.currentResolve = self.bvc.nextService;
		 // set [self.bvc _nextService] to nil?
		 // release it?
		 self.bvc.nextService = nil;
		 } else {
		 */
		_bvc.currentResolve = nil;
		DLog(@"set currentresolve to nil");
		//}
		// should we do this on MainThread?
		//[self.bvc setConnectedName:nil];
		
		//		[UIAppDelegate.picker setConnectedName:nil];
		
		//((UILabel*)[_picker viewWithTag:kWaitingTag]).text = @"Waiting for others to join whiteboard:";
		//((UILabel*)[_picker viewWithTag:kOrJoinTag]).text = @"Or, join a different whiteboard:";
		
		//#if !IS_WHITEBOARD_HD
		//		[[Beacon shared] endSubBeaconWithName:@"connected"];
		//#endif
		
		//		[FlurryAPI endTimedEvent:@"connected" withParameters:nil];
	}
	
	
	//	UIAppDelegate.connection.amServer = NO;
	//	self.connectedWhiteboard = nil;
	//	DLog(@"showed disconnect msg");	
	return YES;
}

///*
//// Assumes stream is an _inStream
//// Executes on inStreamThread
//- (BOOL)disconnectFromPeerWithStream:(NSStream *)stream {
//	//DLog(@"%s", _cmd);
//	if ([self closeInOutStreamsWithInStream:stream] == NO) {
//		return NO;
//	}
//	
//	/*
//	 for (NSOutputStream * outs in _outStreams) {
//	 [outs close];
//	 [outs removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
//	 [outs release], outs = nil;
//	 }
//	 
//	 for (NSInputStream * ins in _inStreams) {
//	 [ins close];
//	 [ins removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
//	 [ins release], ins = nil;
//	 }
//	 
//	 [_outStreams removeAllObjects];
//	 [_inStreams removeAllObjects];
//	 [namesForStreams removeAllObjects];*/
//	
//	// TODO: check why wee need it here
//	// Added this so acceptReject.name indicates that there's an ongoing incoming connection
//	DLog(@"disconnectFromPeerWithStream: [UIAppDelegate.connection.acceptReject setName:nil];");
////	[UIAppDelegate.connection.acceptReject setName:nil];
//	
//	//KONG: refactor this and the code in create: method
//	// when we support multiple collaboration, we should remove this
//	[self restartServer];
//	
//	
//	//assert([_inStreams count] >= 0 && [_outStreams count] >= 0);
//	
//	//if ([_inStreams count] == 0 && [_outStreams count] == 0) {
//	{	
//		/* // Shouldn't do this because it's already taken care of...
//		 // For the conflict situation
//		 if (self.bvc.nextService) {
//		 self.bvc.currentResolve = self.bvc.nextService;
//		 // set [self.bvc _nextService] to nil?
//		 // release it?
//		 self.bvc.nextService = nil;
//		 } else {
//		 */
//		_bvc.currentResolve = nil;
//		DLog(@"set currentresolve to nil");
//		//}
//		// should we do this on MainThread?
//		//[self.bvc setConnectedName:nil];
//		
////		[UIAppDelegate.picker setConnectedName:nil];
//		
//		//((UILabel*)[_picker viewWithTag:kWaitingTag]).text = @"Waiting for others to join whiteboard:";
//		//((UILabel*)[_picker viewWithTag:kOrJoinTag]).text = @"Or, join a different whiteboard:";
//		
//		//#if !IS_WHITEBOARD_HD
//		//		[[Beacon shared] endSubBeaconWithName:@"connected"];
//		//#endif
//		
////		[FlurryAPI endTimedEvent:@"connected" withParameters:nil];
//	}
//	
//	
////	UIAppDelegate.connection.amServer = NO;
////	self.connectedWhiteboard = nil;
////	DLog(@"showed disconnect msg");	
//	return YES;
//}

- (void)restartServer {
	if ([_server isStopped]) {
		/*** Start Advertising Again ***/
		DLog(@"Start Advertising Again");
		
		// We should do this only if we are stopped!
		
		assert(_server != nil);
		
		NSError* error;
		if(_server == nil || ![_server start:&error]) {
			DLog(@"Failed creating server: %@", error);
			[self showNetworkError:@"Failed creating server"];
			return;
		}
		
		//Start advertising to clients, passing nil for the name to tell Bonjour to pick use default name
		if(![_server enableBonjourWithDomain:@"local" applicationProtocol:[TCPServer bonjourTypeFromIdentifier:kGameIdentifier] name:nil]) {
			[self showNetworkError:@"Failed advertising server"];
			//return;
		}
		
		//DLog(@"success");
	}	
}

- (void)userRejectedConnectionRequest {
	
	
}

- (void)userAcceptedConnectionRequest {
	
	// We stop broadcasting our presence
//	[_server stop];
}


- (void)rejectedSilentlyConnectionRequest:(NSString *)name source:(id)source {
	// TODO: KONG - check memory in name copy
	
//	[self sendInStreamThreadMessage:@"s}}r}}" toOutStream:source];
	/*
	BOOL isSent = [self sendMessage:@"s}}r}}" toPeerWithInStream:source];
	if (isSent == NO) {
		DLog(@"NOT Send reject message");
	}
	 */
//	[self performSelector:@selector(sendRejectMessageAndCloseAllStreamsFrom:) onThread:inStreamThread withObject:[name copy] waitUntilDone:YES];
	
	
	[self performSelector:@selector(sendRejectMessageToPeerWithInStream:) 
				 onThread:inStreamThread withObject:source waitUntilDone:YES];

}


- (BOOL)sendMessage:(NSString *)message toPeerWithInStream:(id)stream {
	
	NSUInteger index = [_inStreams indexOfObject:stream];
	if (index == NSNotFound) {
		return NO;
	}
	
	//KONG: just check
	if ([_outStreams count] < index) {
		return NO;
	}
	
	NSOutputStream *outStream = [_outStreams objectAtIndex:index];
	
	if ([outStream hasSpaceAvailable] == NO) {
		return NO;
	}
	
	[self sendInStreamThreadMessage:message toOutStream:outStream];
	return YES;
}


- (void)sendInStreamThreadMessage:(NSString *)message toOutStream:(id)stream {
	[stream performSelector:@selector(sendMessage:) onThread:inStreamThread withObject:message waitUntilDone:YES];
}

- (void)receivedConnectionRequestWith:(NSString *)message source:(id)source {
	//KONG: defensive programming 
	
	NSStream *stream = source;
		//KONG: local code: recode stream in names
	[namesForStreams setObject:message forKey:[stream description]];
	
		// associate name with _outStream, too
	NSUInteger index = [_inStreams indexOfObject:stream];
	[namesForStreams setObject:message forKey:[[_outStreams objectAtIndex:index] description]];
	
}

- (void)storeStreamsName:(NSString *)name inStream:(NSStream *)inStream {
	NSStream *stream = inStream;
	[namesForStreams setObject:name forKey:[stream description]];
	
	// associate name with _outStream, too
	NSUInteger index = [_inStreams indexOfObject:stream];
	[namesForStreams setObject:name forKey:[[_outStreams objectAtIndex:index] description]];	
}

- (void)waitToSolveConflictWhenReceiveConnectionRequest:(NSArray *)args {
	DLog();
	[args autorelease];
	[self solveConflictWhenReceiveConnectionRequest:[args objectAtIndex:0]
											 source:[args objectAtIndex:1]];
	
}
/*
- (void)solveConflictWhenReceiveConnectionRequest:(NSString *)name source:(id)source {
//	if (_didSendConnectionRequest == NO) {
//		NSArray *args = [[NSArray arrayWithObjects:name, source, nil] retain];
//		[self performSelector:@selector(waitToSolveConflictWhenReceiveConnectionRequest:)
//				   withObject:args afterDelay:1.0];
//		return;
//	}
	
	
	//KONG: connecting and conflict in A

	[self storeStreamsName:name inStream:source];
	
	// I'm trying to connect to a peer who's trying to connect to me
	
	//KONG: based on order of name to solve conflict
	// this has downside when names are the same
	
	// NSOrderedAscending if the receiver precedes aString
	// NSOrderedDescending if the receiver follows aString
	
	//KONG: connecting and conflict in B
	// follow the assumption above, A's name < B's name, and this code run in B
	// B should be the server
	// TODO: KONG - We should send the device ID for a stronger server-selection here 
	if ([[_bvc ownName] compare:name] == NSOrderedAscending) {
		DLog(@"Conflict resolution: I'll be the server");
		
		UIAppDelegate.connection.amServer = YES;
		
		//KONG: close connection for my request , inStream is stored in waitedWhiteboard

		NSInputStream *waitedInputStream  =[(GSLocalWhiteboard *) UIAppDelegate.connection.waitedWhiteboard inStream];
		DLog (@"solving Conflict: close my InputStream: %@", waitedInputStream);
//		[self closeInOutStreamsWithInStream:waitedInputStream];
		
		// Assume whiteboard protocol version 1 until we hear otherwise
		DLog(@"protocolVersion = 1");
		DLog(@"conflict solved: server: check requesting WB: %@", UIAppDelegate.connection.requestingWhiteboard);

		// refactor this also
		UIAppDelegate.connection.waitedWhiteboard = nil;
		UIAppDelegate.connection.protocolVersion = 1;
		
		UIAppDelegate.remoteDevice = iPhoneDevice; // assume remoteDevice is an iPhone until we hear otherwise
		
		
		// Optimize later

//		if (UIAppDelegate.connection.acceptReject == nil)
//			UIAppDelegate.connection.acceptReject = [[AcceptReject alloc] init];
//		[UIAppDelegate.connection.acceptReject setName:name];
		
		DLog(@"requestingWhiteboard: %@", UIAppDelegate.connection.requestingWhiteboard);
		
//		UIAppDelegate->acceptRejectAlertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"“%@” would like to join your whiteboard", name]
//																		  message:nil
//																		 delegate:UIAppDelegate.connection
//																cancelButtonTitle:@"Don't Allow"
//																otherButtonTitles:@"OK", nil];
		 
		// Remember that this code is running on the Server.
		// pendingJoinRequest should be YES already, but since we're not supporting more than 2 peers,
		// it may be NO. So let's make sure:
		pendingJoinRequest = YES; 

		 
//		[UIAppDelegate.connection acceptPendingRequest:YES withName:name];
		
		//
		// Note: at this point, we may want to deselect the row in the tableView with this name
		//
		
//		[_bvc performSelector:@selector(stopActivityIndicator:) onThread:inStreamThread withObject:nil waitUntilDone:YES]; 
		
		
		[UIAppDelegate.connection performSelectorOnMainThread:@selector(userAcceptedConnectionRequestInConnectingRequesting)
												   withObject:nil
												waitUntilDone:YES];

		
		//KONG: show alert view
		[UIAppDelegate.connection showRequestAcceptedAlert];
		
	}
	else {	
		DLog(@"Conflict resolution: I'll be the client");
		UIAppDelegate.connection.amServer = NO;
		
		// Remember that this code is executing on the "server"
		
		// Reject their request, keep my request going
		
		// Don't need to reject? They'll cancel?
		// But this might be asynchronous?
		
		// This stream hit a conflict: they requested me when I was requesting them
		// But the server needs to realize there's a conflict...
		
		//[self disconnectFromPeerWithStream:stream];
		// Fixes an Exception where the array got mutated while being iterated
//		[self performSelector:@selector(disconnectFromPeerWithStream:) onThread:inStreamThread withObject:stream waitUntilDone:YES];

		//		[self performSelector:@selector(disconnectFromPeerWithStreamInInstreamThread:)
//				   withObject:stream afterDelay:30.0];
		
//		NSInputStream *requestingInputStream = [(GSLocalWhiteBoard *) UIAppDelegate.connection.requestingWhiteboard inStream];
		//KONG: I really want to close the connection here
		// but this cause too much problem,
		// I will consider to close unused streams when receive already-connected-signal from peer.
//		[self closeInOutStreamsWithInStream:requestingInputStream];
		
//		[self performSelector:@selector(disconnectFromPeerWithStream:) onThread:inStreamThread withObject:stream waitUntilDone:YES];
		
		//		[UIAppDelegate.picker setConnectedName:name];
		UIAppDelegate.connection.requestingWhiteboard = nil;
		
		
//		DLog(@"conflict solved: server: check requesting WB: %@", UIAppDelegate.connection.requestingWhiteboard);
//		UIAppDelegate.connection.waitedWhiteboard = nil;

		
		
		// wasn't giving checkmark and
		// was't deselecting when I tapped to disconnect
		// then said No!
		
		// at this point, the resolve is done!
		// hope this is right!
//		_bvc.currentResolve = nil;
		// and message is name!
		//[self.bvc setConnectedName:message];
		
		
//		[namesForStreams setObject:name forKey:[stream description]];
		
//		for (NSInputStream *inStream in _inStreams) {
//			NSString *streamName = [namesForStreams objectForKey:[inStream description]];
//			if ([streamName isEqualToString:name]) {
//				
//				break;
//			}
//		}
		
		NSInputStream *waitedInputStream  =[(GSLocalWhiteboard *) UIAppDelegate.connection.waitedWhiteboard inStream];
		
		[UIAppDelegate.connection receivedAcceptedMessageInConnectingWaitingFrom:waitedInputStream];
		
		
		//KONG: should we send color here or waiting until we receive protocol @"2", then call initializeWithPeer?
		DLog(@"sending color and pointSize");
		[UIAppDelegate sendMyColor];
		[UIAppDelegate sendMyPointSize];
		
	}// End resolveing conflict: I am the client		
}

*/


- (void)solveConflictWhenReceiveConnectionRequest:(NSString *)name source:(id)source {
	//KONG: connecting and conflict in A
	
	
	
	
	NSStream *stream = source;
	[namesForStreams setObject:name forKey:[stream description]];
	
	// associate name with _outStream, too
	NSUInteger index = [_inStreams indexOfObject:stream];
	[namesForStreams setObject:name forKey:[[_outStreams objectAtIndex:index] description]];
	
	// I'm trying to connect to a peer who's trying to connect to me
	
	//KONG: based on order of name to solve conflict
	// this has downside when names are the same
	
	// NSOrderedAscending if the receiver precedes aString
	// NSOrderedDescending if the receiver follows aString
	
	//KONG: connecting and conflict in B
	// follow the assumption above, A's name < B's name, and this code run in B
	// B should be the server
	if ([[_bvc ownName] compare:name] == NSOrderedAscending) {
		DLog(@"Conflict resolution: I'll be the server");
		
		UIAppDelegate.connection.amServer = YES;
		
		//KONG: close connection for my request 
		
		// Cancel my request (silently?), accept theirs
		//[disconnectFromPeerWithStream:nil];
		// How do I know my connection's streams?
		// It's the stream that isn't this one (stream)
		NSInputStream* _inStream;
		//				for(_inStream in _inStreams) {
		for(int i = 0; i< [_inStreams count]; i++) {
			_inStream = [_inStreams objectAtIndex:i];
			if (stream != _inStream) {
				DLog(@"going to disconnect from _inStream: %@", _inStream);
				[self performSelector:@selector(disconnectFromPeerWithStreamInInstreamThread:)
						   withObject:_inStream afterDelay:30.0];
				//				[self performSelector:@selector(disconnectFromPeerWithStream:) onThread:inStreamThread withObject:_inStream waitUntilDone:YES];			
				break;
			}
		}
		
		// Assume whiteboard protocol version 1 until we hear otherwise
		DLog(@"protocolVersion = 1");
		DLog(@"conflict solved: server: check requesting WB: %@", UIAppDelegate.connection.requestingWhiteboard);
		
		UIAppDelegate.connection.waitedWhiteboard = nil;
		UIAppDelegate.connection.protocolVersion = 1;
		
		UIAppDelegate.remoteDevice = iPhoneDevice; // assume remoteDevice is an iPhone until we hear otherwise
		
		/*
		 Optimize later
		 */
		//		if (UIAppDelegate.connection.acceptReject == nil)
		//			UIAppDelegate.connection.acceptReject = [[AcceptReject alloc] init];
		//		[UIAppDelegate.connection.acceptReject setName:name];
		
		DLog(@"requestingWhiteboard: %@", UIAppDelegate.connection.requestingWhiteboard);
		
		//		UIAppDelegate->acceptRejectAlertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"“%@” would like to join your whiteboard", name]
		//																		  message:nil
		//																		 delegate:UIAppDelegate.connection
		//																cancelButtonTitle:@"Don't Allow"
		//																otherButtonTitles:@"OK", nil];
		
		// Remember that this code is running on the Server.
		// pendingJoinRequest should be YES already, but since we're not supporting more than 2 peers,
		// it may be NO. So let's make sure:
		pendingJoinRequest = YES; 
		
		
		//		[UIAppDelegate.connection acceptPendingRequest:YES withName:name];
		
		//
		// Note: at this point, we may want to deselect the row in the tableView with this name
		//
		
		//		[_bvc performSelector:@selector(stopActivityIndicator:) onThread:inStreamThread withObject:nil waitUntilDone:YES]; 
		
		
		[UIAppDelegate.connection performSelectorOnMainThread:@selector(userAcceptedConnectionRequestInConnectingRequesting)
												   withObject:nil
												waitUntilDone:YES];
		
		
		//KONG: show alert view
		[UIAppDelegate.connection showRequestAcceptedAlert];
		
	}
	else {	
		DLog(@"Conflict resolution: I'll be the client");
		UIAppDelegate.connection.amServer = NO;
		
		/** Remember that this code is executing on the "server" **/
		
		// Reject their request, keep my request going
		
		// Don't need to reject? They'll cancel?
		// But this might be asynchronous?
		
		// This stream hit a conflict: they requested me when I was requesting them
		// But the server needs to realize there's a conflict...
		
		//[self disconnectFromPeerWithStream:stream];
		// Fixes an Exception where the array got mutated while being iterated
		//		[self performSelector:@selector(disconnectFromPeerWithStream:) onThread:inStreamThread withObject:stream waitUntilDone:YES];
		[self performSelector:@selector(disconnectFromPeerWithStreamInInstreamThread:)
				   withObject:stream afterDelay:30.0];
		
		
		//		DLog(@"conflict solved: server: check requesting WB: %@", UIAppDelegate.connection.requestingWhiteboard);
		//		UIAppDelegate.connection.waitedWhiteboard = nil;
		
		DLog(@"sending color and pointSize");
		[UIAppDelegate sendMyColor];
		[UIAppDelegate sendMyPointSize];
		
		// wasn't giving checkmark and
		// was't deselecting when I tapped to disconnect
		// then said No!
		
		// at this point, the resolve is done!
		// hope this is right!
		//		_bvc.currentResolve = nil;
		// and message is name!
		//[self.bvc setConnectedName:message];
		
		//		[UIAppDelegate.picker setConnectedName:name];
		UIAppDelegate.connection.requestingWhiteboard = nil;
		
		//		[namesForStreams setObject:name forKey:[stream description]];
		
		for (NSInputStream *inStream in _inStreams) {
			NSString *streamName = [namesForStreams objectForKey:[inStream description]];
			if ([streamName isEqualToString:name]) {
				[UIAppDelegate.connection receivedAcceptedMessageInConnectingWaitingFrom:inStream];
				break;
			}
		}
		
		//		UIAppDelegate.connection.waitedWhiteboard];		
	}
	
}


- (void)initializeWithPeersIfNecessaryWithSource:(id)source {
//	// TODO: what this condition is for?
//	// Check for server, pendingJoinRequest
//	// request conflict
//	if (UIAppDelegate.connection.amServer && pendingJoinRequest && [[_bvc ownName] compare:name] == NSOrderedAscending) {
//		ALog(@"WARNING: Server is attempting to initialize a client connection");
//	} else {
//		// reuse
	NSString *serverName;
	
	
	DLog();
	
	//
	//  Client Code
	//
	//  This code executes on the client device.
	//
	
//	[_server stop]; // Stop the existing server (which advertises to clients)
	
	// Stop the activity indicator
	// Generally, this code is already running on the networking thread (inStreamThread), but we do this just in case:
//	[_bvc performSelector:@selector(stopActivityIndicator:) onThread:inStreamThread withObject:nil waitUntilDone:YES];	
	serverName = [namesForStreams objectForKey:[source description]];
	
	//
	// Now we're successfully connected.
	//
	// Currently, Whiteboard only supports 1 connection, so if we have more than 1 connection,
	// we disconnect from the other one.
	//
	const int kMaxConnections = 1;
	// TODO: check here
	if ([_inStreams count] > kMaxConnections) {
		DLog(@"CLIENT: Dropping extra connection");
		NSInputStream *_inStream = nil;
		for (int i = 0; i< [_inStreams count]; i++) {
			_inStream = [_inStreams objectAtIndex:i];
			if (source != _inStream) {
				DLog(@"CLIENT: Disconnecting from _inStream: %@", _inStream);
				[self performSelector:@selector(disconnectFromPeerWithStream:) onThread:inStreamThread withObject:_inStream waitUntilDone:YES];
				//break; // 20100324: Drop all extra connections
			}
		}
	}
	
	
//	[UIAppDelegate.connection receivedAcceptedMessageFrom:source];		
		
//	}	
}
	
- (void)receivedDisconnectedMessageFrom:(id)stream {
	NSString* serverName = [[namesForStreams objectForKey:[stream description]] retain]; // very important to retain here!
	
	DLog(@"serverName == %@", serverName);
	
	DLog(@"NSStreamEventEndEncountered");
	// disappears here!
	if ([self disconnectFromPeerWithStream:stream]) {
		// rejected case covered because rejection message always gets sent?
		
		// We've successfully disconnected, so set acceptReject.name to nil
		// This is used by BrowserViewController bvc
		//				[UIAppDelegate.connection.acceptReject setName:nil];
		
		// if acceptReject alertView is showing, dismiss it
		DLog(@"about to check acceptRejectAlertView"); /******/
//		if (UIAppDelegate.acceptRejectAlertView != nil) {
//			DLog(@"acceptRejectAlertView != nil");
//			//[[_picker bvc] stopActivityIndicator];
//			
//			//DLog(@"it's YES");
//			
//			// TODO: KONG - check for memory here 
//			//					[UIAppDelegate.acceptRejectAlertView dismissWithClickedButtonIndex:2 animated:YES];
//			//					
//			//					[UIAppDelegate.acceptRejectAlertView release];
//			//					UIAppDelegate.acceptRejectAlertView = nil;
//		}
		
		DLog(@"about to show disconnect msg, serverName == %@", serverName);
		
		// kind of a hack? sometimes it's (null) [conflict, or simultaneous, case]
		if (serverName) {
			//KONG: move to disconnectFromPeer method 
//			[UIAppDelegate.connection performSelectorOnMainThread:@selector(showDisconnectedAlert:) withObject:[[serverName copy] autorelease] waitUntilDone:YES];
			
			//					DLog(@"showed disconnect msg");
			
			
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
}	

- (NSOutputStream *)outStreamWithInStream:(NSInputStream *)inStream {
	NSUInteger indexOfBoth = [_inStreams indexOfObject:inStream];
	if (indexOfBoth != NSNotFound && indexOfBoth < [_outStreams count]) {
		return [_outStreams objectAtIndex:indexOfBoth];
	}
	return nil;
}

@end
