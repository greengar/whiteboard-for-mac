//
//  GSLocalWhiteboard+NSStreamDelegate.m
//  Whiteboard
//
//  Created by Cong Vo on 1/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GSLocalWhiteboard+NSStreamDelegate.h"
#import APP_DELEGATE
#import "Picker.h"


#import "GSWhiteboard.h"
#import "PaintingView.h"
#import "MainPaintingView.h"
#import "GSConnectionController.h"
#import "GSLocalConnection.h"



//#import "errno.h"

//#if IS_WHITEBOARD_HD
#if TARGET_OS_IPHONE
	#import "FlurryAPI.h"
#endif
//#else
//#	import "Beacon.h"
//#endif

@implementation GSLocalWhiteboard(NSStreamDelegate)

// for server AND client
- (void)streamEventOpenCompleted:(id)stream {
	DLog();
//	
//	BOOL setInReady = NO;
//	if (stream && [stream isKindOfClass:[NSStream class]]) {
//		// These lines are commented because we want to keep the server running
//		// which allows us to continue accepting new connections:
//		//[_server release];
//		//_server = nil;
//		//[_server stop];
//		
//		NSInputStream* _inStream;
//		for(_inStream in _inStreams) {
//			if (stream == _inStream) {
//				DLog(@"set _inReady = YES");
//				_inReady = YES;
//				setInReady = YES;
//				break;
//			}
//		}
//		
//		if(setInReady == NO) {
//			_outReady = YES;
//		}
//		/*
//		 NSOutputStream* _outStream;
//		 for(_outStream in _outStreams) {
//		 if (stream == _outStream) {
//		 DLog(@"set _outReady = YES");
//		 _outReady = YES;
//		 break;
//		 }
//		 }
//		 */
//	}
//	
//	DLog(@"check _inReady && _outReady");
//	if (!stream || [stream isKindOfClass:[NSString class]] || (_inReady && _outReady)) {
//		//NSString* serverName = [namesForStreams objectForKey:[stream description]];
//		// when serverName is set, I'm actually the client
//		// when serverName is nil, I'm actually the server
//		//DLog(@"(_inReady && _outReady) == YES, amServer:%d serverName:%@", amServer, serverName);
//		
//		// if I'm the client, I need to initializeWithPeers
//		DLog();
//		//		if (amServer/* && serverName != nil*/) {
//		if (AppDelegate.connection.amServer/* && serverName != nil*/) {
//			
//			/*
//			 alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Successfully connected to %@", serverName] message:@"Waiting for response from server" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
//			 [alertView show];
//			 [alertView release];
//			 */
//			// wait for point size or rejection
//			AppDelegate.connection->initializedWithPeers = NO;
//		} // else I'm the server, so wait for them to tell us their name
//	} else {
//		DLog(@"(_inReady && _outReady) == NO");
//	}
}

- (void)streamEventHasSpaceAvailable:(id)stream {	
	// Send any buffered data,
	// but watch out for an infinite loop:
	
	if (stream != _outStream) {
		DLog(@"UNEXPECTED stream event");
		return;
	}
	
	DLog(@"whiteboard: %@ stream: %@ writeBuffer: %@", _name, stream, _writeBuffer);
	
	if ([_writeBuffer length] > 0) {
		[self send:_writeBuffer];
		self.writeBuffer = @"";
		DLog(@"done writing buffer");
	} else {
		DLog(@"buffer is empty when stream has space available");
	}

}


- (void)readDataWhenInStreamHasSpaceAvailable {
	RUN_IN_STREAM_THREAD
//	
//	
//	if ([NSThread isMainThread]) {
//		DLog(@"attempt to read in Main Thread");
//		[self performInStreamThreadSelector:@selector(readDataWhenInStreamHasSpaceAvailable)
//								 withObject:nil wait:NO];
//		return;
//	}
	
	//DLog(@"NSStreamEventHasBytesAvailable");
//	NSInputStream* _inStream;
//	for(_inStream in _inStreams) {
//		if (stream == _inStream) {
			//DLog(@"stream == _inStream");
			
			
	//Retrieve remote image data
	AppDelegate.connection->imageDataSize = 0;
	static NSMutableData *imgData = nil;
	if(AppDelegate.connection->receivingRemoteImage && AppDelegate.connection->imageDataSize && !USE_HEX_STRING_IMAGE_DATA){

		DLog(@"Retrieving remote image!");
		Byte *buffer = malloc(AppDelegate.connection->imageDataSize);
		if(!buffer) {
			DLog(@"Buffer allocation error in Receiving Remote Image!");
			
		}
		else {
			if(!imgData){
				imgData = [[NSMutableData alloc] initWithCapacity:10000];
			}
			
			NSInteger len = [_inStream read:buffer maxLength:AppDelegate.connection->imageDataSize];
			[imgData appendBytes:buffer length:len];
			
			if(len == AppDelegate.connection->imageDataSize){
				
				DLog(@"Finished receive for remote image! (Bytes: %d", [imgData length]);
				
				//[AppDelegate.drawingView loadRemoteImageWithByteData:imgData];
				
				// copied from Painting View
				CFDataRef imgData = (CFDataRef)imgData;
				
				CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData (imgData);
				CGImageRef image = CGImageCreateWithJPEGDataProvider(imgDataProvider, NULL, NO, kCGRenderingIntentDefault);
				
				//isImageSent = TRUE;
				CGImageRef source = [AppDelegate.drawingView CGRemoteImageRotate:image];
				//isImageSent = FALSE;
				[AppDelegate.drawingView loadImage:source];
				[AppDelegate.drawingView drawObject];
				
				AppDelegate.connection->imageDataSize = 0;
				AppDelegate.connection->receivingRemoteImage = NO;
			}
			else {
				AppDelegate.connection->imageDataSize -= len;
				DLog(@"Image retrieval left: %d (%d retrieved)", AppDelegate.connection->imageDataSize, len);
			}
			free(buffer);
		}
		
		return;
	}
	
	
	uint8_t buff[1024];
	bzero(buff, sizeof(buff));
	
	NSInteger readLength;
	NSString* message = @"";
	NSString *temp = nil;
	
	//
	// Note: We don't explicitly handle incomplete streams here
	//
	int i;
	for(i = 0; i < 1000 && [_inStream hasBytesAvailable]; i++) {
//		printf("* Attempt to read *");
		readLength = [_inStream read:buff maxLength:sizeof(buff) - 1];
		buff[readLength] = '\0';
		
		// Not all chars can be converted to UTF8 Strings
		temp = [NSString stringWithUTF8String:(const char *)buff];
		if (temp) {
			message = [message stringByAppendingString:temp];
			//							readLength = 0; // Value stored to 'readLength' is never read
		} else {
			DLog(@"Non UTF8 String Received!");
			return;
		}
	}
	//KONG: perform in main thread
//	[self performSelectorOnMainThread:@selector(receivedMessage:)
//						   withObject:message
//						waitUntilDone:YES];
	
	[self receivedMessage:message];
	
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
}


//KONG: store message in InActive status
/* Rules:
	+ Message that is brush, stroke, color is stored
	+ Command message that need to alert user, such as "request for start over, tranfer image" will be ignored
 */

static NSSet *commandMessages = nil;
- (NSSet *)commandMessages {
	if (commandMessages == nil) {
		commandMessages = [[NSSet alloc] initWithObjects:
						   @"e", @"L", // start over & cancel
						   @"Z", // cancel Image tranfer
						   nil];
	}
	return commandMessages;
}

- (BOOL)isCommandMessage:(NSString *)message {
	if ([[self commandMessages] containsObject:message]) {
		return YES;
	} 
	
	if ([message hasPrefix:@"<I--N:"]) { // image message: <I--N
		return YES;
	}
	
	return NO;
}

- (void)processMessageInBackground:(NSString *)combinedMessage {
	NSArray* messages = [combinedMessage componentsSeparatedByString:@"}}"];
	
	for (NSString *message in messages) {
		if ([self isCommandMessage:message]) {
			//KONG: we gonna ignore all command messages
			// Why? Because most command message need to show an alert view to ask for user agreement
			// In background, user cannot answer any alert view, so most peer will cancel that alert
			// When we process messages in foreground, we show alert for agreement first, then immediately dismiss it.
			// this cause problem with UI
			
			//KONG: this is just a temporary solution, we can improve this
			DLog(@"ignore command message in background: %@", message);
		} else {
			[self storeMessage:message];
		}
	}
}

- (void)storeMessage:(NSString *)message {
#if TARGET_OS_IPHONE	
	DLog(@"store incomming message: %@ in app state: %d", message, [[UIApplication sharedApplication] applicationState]);
#endif
	if (_readBuffer) {
		[_readBuffer appendString:message];
	} else {
		self.readBuffer = [[[NSMutableString alloc] initWithString:message] autorelease];
	}
	[_readBuffer appendString:@"}}"];
}

//
- (void)processStoredMessages {
    
//	if ([[UIApplication sharedApplication] respondsToSelector:@selector(applicationState)]) {
//		if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
//			//KONG: this methods should only be call in active state
//			DLog(@"WARNING: something wrong here: this methods should only be call in active state");
//			 return;
//		}
//	} 

	if (_readBuffer == nil && [_readBuffer length] == 0) {
		//KONG: no message need to be processed
		return;
	}
	
	if ([NSThread isMainThread]) {
		[self performInStreamThreadSelector:@selector(processStoredMessages) withObject:nil wait:NO]; 
	}
	
	DLog(@"message: %@", _readBuffer);
	[AppDelegate.connection processMessage:_readBuffer source:self];
	
	[_readBuffer release];
	_readBuffer = nil;
}

// on Main thread
- (void)receivedMessage:(NSString *)message {
	DLog(@"receivedMessage: %@", message);
#if TARGET_OS_IPHONE	
	DLog(@"received Message: %@", message);
	if ([[UIApplication sharedApplication] respondsToSelector:@selector(applicationState)]) {
		if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
//		if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
			// don't read bytes if the app is not active (may be inactive or background)
			[self processMessageInBackground:message];
			return;
		}
	} 
#endif	
	
	[AppDelegate.connection processMessage:message source:self];
}

// All incoming stream events go through here
- (void)stream:(NSStream*)stream handleEvent:(NSStreamEvent)eventCode {
//	DLog(@"%@ - stream: %@ - eventCode: %d", _name, stream, eventCode);

	if ([NSThread isMainThread]) {
		DLog(@"WARNING: in MAIN Thread");
	}
	
	/*
	 NSStreamEventNone = 0,
	 NSStreamEventOpenCompleted = 1UL << 0,
	 NSStreamEventHasBytesAvailable = 1UL << 1,
	 NSStreamEventHasSpaceAvailable = 1UL << 2,
	 NSStreamEventErrorOccurred = 1UL << 3,
	 NSStreamEventEndEncountered = 1UL << 4	 
	 */
	
	switch(eventCode) {
		// Executes on both the Server and the Client
		case NSStreamEventOpenCompleted:
		{
			DLog(@"NSStreamEventOpenCompleted");
			[self streamEventOpenCompleted:stream];
			break;
		}
		case NSStreamEventHasBytesAvailable:
		{
			DLog(@"NSStreamEventHasBytesAvailable");
			[self readDataWhenInStreamHasSpaceAvailable];
			break;
		}
		case NSStreamEventEndEncountered:
		{
			DLog(@"NSStreamEventEndEncountered");
			[AppDelegate.connection receivedDisconnectedMessageFrom:self];
			break;
		}
		case NSStreamEventNone:
		{
			DLog(@"NSStreamEventNone");	
			break;
		}
		case NSStreamEventHasSpaceAvailable: // This event occurs only for NSOutputStreams.
		{
			DLog(@"NSStreamEventHasSpaceAvailable");
			[self streamEventHasSpaceAvailable:stream];
			
			break;
		}
		case NSStreamEventErrorOccurred:
		{
			DLog(@"NSStreamEventErrorOccurred");
			DLog(@"NSStreamEventErrorOccurred: %@ - error: %@", stream, [stream streamError]);
			[self stream:stream handleError:[stream streamError]];
			break;
		}
		default:
		{
			DLog(@"unrecognized eventCode:%u", eventCode); // Unsigned 32-bit integer (unsigned int)
			break;
		}
	}
}

- (void)stream:(NSStream *)stream handleError:(NSError *)error {
	//
	// A better user experience would be to show only 1 error alert.
	// Currently, this alert can appear multiple times.
	//
	
	/*
	 error: Error Domain=NSPOSIXErrorDomain Code=54 "The operation couldn’t be completed. Connection reset by peer" UserInfo=0xcaeb480 {}
	 */
	
	DLog(@"%@ \nerror: %@", self, error);
	
	if ([AppDelegate.connection receivedPeerUnavailableSignalFrom:self]) {
		return;
	}

#if TARGET_OS_IPHONE	
	NSError *theError = error;
	
	if (!(AppDelegate->errorAlert)) {
		NSString *title = nil, *message = nil;
		NSInteger code = [theError code];
		NSString *domain = [theError domain];
		DLog(@"error domain = %@", domain);
		
		if (code == 32) {
			title = @"Peer Disconnected";
			message = [NSString stringWithFormat:@"Error %i: %@", code, [theError localizedDescription]];
			if ([AppDelegate.connection receivedPeerUnavailableSignalFrom:self]) {
				return;
			}
			
			//		[self disconnectFromPeerWithStream:nil];
			
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
			if (AppDelegate.drawingView.hasUnsavedChanges) {
				// Save drawing
				//[drawingView captureToSavedPhotoAlbum];
				[AppDelegate.drawingView captureToWhiteboardTempFile];
				message = @"Your drawing will be restored when you restart. ";
			}
			message = [message stringByAppendingString:@"Please restart Whiteboard\nand try again."];
		} else if (code == ETIMEDOUT /*60*/) {
			// Error 60 / NSPOSIXErrorDomain / The operation couldn't be completed. Operation timed out
			//					title = @"Network Error";
			//					message = @"The other device disconnected.";
			title = @"Connection timeout";
			message = @"The other device has not responded";					
			// socket has been dropped (by the server / other device) and is no longer there
			
			// TODO: try to reconnect for 5-10 sec. depending on what the error is
			
			// TODO: clean up connection
		} else if (code == 61) {
			
			title = @"Peer Unavailable";			
			if ([AppDelegate.connection receivedPeerUnavailableSignalFrom:self]) {
				return;
			}
			
		} else {
			title = @"Error reading/writing stream";
			message = [NSString stringWithFormat:@"Error %i: %@", code, [theError localizedDescription]];
		}
		AppDelegate->errorAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[AppDelegate->errorAlert show];
		//[alert release];
		
		NSString *analyticsMessage = [NSString stringWithFormat:@"Error%i", code];
		ANALYTICS_LOG(analyticsMessage);
	}
#endif
	
	[self disconnect];
//	[self release];
/*
	DLog(@"%@ attempt to release stream: %@", _name, stream);
	[stream close];
	[stream release], 
	stream = nil;	
 */
}

// Execute on inStreamThread
//KONG: reject silently in local connection means: send reject message & remove all stream w request name 
//- (void)rejectSilentlyWithName:(NSString*)name {
//	[AppDelegate.connection acceptPendingRequest:kRejectSilently withName:name];
//}


// Execute on MainThread
- (void)removeServiceWithTimer:(NSTimer*)timer {
	if ([NSThread isMainThread]) {
		DLog(@" on MainThread");
	} else {
		DLog(@" NOT on MainThread");
	}
/*	
	[self.bvc performSelectorOnMainThread:@selector(removeServiceWithName:)
							   withObject:[timer userInfo]
							waitUntilDone:YES];
 
 */
}



@end
