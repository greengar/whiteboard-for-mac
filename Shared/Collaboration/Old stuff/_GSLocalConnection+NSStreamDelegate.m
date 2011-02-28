//
//  AppController+NSStreamDelegate.m
//  Whiteboard
//
//  Created by Elliot Lee on 6/26/09.
//  Copyright 2009 GreenGar Studios <http://www.greengar.com/>. All rights reserved.
//

#import "GSLocalConnection+NSStreamDelegate.h"
#import "AppController.h"
#import "Picker.h"
#import "GSInternetConnection.h"
#import "GSWhiteboard.h"
#import "MainPaintingView.h"
#import "GSConnectionController.h"


//#import "errno.h"

//#if IS_WHITEBOARD_HD
#	import "FlurryAPI.h"
//#else
//#	import "Beacon.h"
//#endif



@implementation GSLocalConnection (NSStreamDelegate)



// move to appcontroller
//- (void)setRemotePointSize:(float)size {
//	if (UIAppDelegate.remoteDevice != iPadDevice && IS_IPAD) { //[[UIScreen mainScreen] bounds].size.width == 768
//		size = size * 2.0f;
//		DLog(@"%f", size);
//	} else {
//		DLog(@"%f", size);
//	}
//	
//	remotePointSize = size;
//	
//	if (usingRemoteColor) {
//		//
//		// We may already be OnMainThread, but it doesn't hurt to make sure.
//		//
//		[self performSelectorOnMainThread:@selector(setRemoteColor) withObject:nil waitUntilDone:YES];
//	}
//}

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
//		if (amServer/* && serverName != nil*/) {
		if (UIAppDelegate.connection.amServer/* && serverName != nil*/) {
		
			/*
			 alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Successfully connected to %@", serverName] message:@"Waiting for response from server" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
			 [alertView show];
			 [alertView release];
			 */
			// wait for point size or rejection
			UIAppDelegate.connection->initializedWithPeers = NO;
		} // else I'm the server, so wait for them to tell us their name
	} else {
		DLog(@"(_inReady && _outReady) == NO");
	}
}

- (void)streamEventHasSpaceAvailable:(id)stream {
	DLog();
	/**
	 * This assumes 1 peer.
	 * The Client sends its name to the Server, but not the other way around!
	 */
	if (needToSendName) {
		needToSendName = NO;
		
//		if ([stream isKindOfClass:[GSWhiteboard class]]) { // || !stream || [stream isKindOfClass:[NSString class]]
//			DLog(@"creating Internet connection (client)");
//			GSWhiteboard *w = stream;
//			UIAppDelegate.connection.internetConnection.connectedWhiteboard = w;
//			[self streamEventOpenCompleted:w.wb]; // act like a local connection
//		}
		
		// Send my name to this output stream
		// (Maybe we could save a little bandwidth by doing this only if I'm the client)
		//[self send:[NSString stringWithFormat:@"n}}%@}}", UIAppDelegate.picker.ownName] toOutStream:(id)stream];
		
		NSOutputStream *waitedOutputStream = [(GSLocalWhiteboard *) UIAppDelegate.connection.waitedWhiteboard outStream];
		
		if (stream == waitedOutputStream) {
			DLog(@"Attempt to send connection request to waitedWhiteboard");
			if ([stream sendMessage:[NSString stringWithFormat:@"n}}%@}}", UIAppDelegate.picker.ownName]]) {
				_didSendConnectionRequest = YES;
			} else {
				// Cannot send message
			DLog(@"SENDING FAILED");
			}
		}
		//
		// Note: we should handle here what happens when my name changes.
		//       That is: listen for the Bonjour event.
		//       Bonjour might change our name when there's a conflict on the network.
		//
	}
	
	// Send any buffered data,
	// but watch out for an infinite loop:
	if ([writeBuffer length] > 0) {
		// TODO: KONG - check this, send buffer for connected user only 
		[self send:writeBuffer];
		writeBuffer = @"";
		DLog(@"done writing buffer");
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
					UIAppDelegate.connection->imageDataSize = 0;
					static NSMutableData *imgData = nil;
					if(UIAppDelegate.connection->receivingRemoteImage && UIAppDelegate.connection->imageDataSize && !USE_HEX_STRING_IMAGE_DATA){
						DLog(@"Retrieving remote image!");
						Byte *buffer = malloc(UIAppDelegate.connection->imageDataSize);
						if(!buffer) {
							DLog(@"Buffer allocation error in Receiving Remote Image!");
							
						}
						else {
							if(!imgData){
								imgData = [[NSMutableData alloc] initWithCapacity:10000];
							}
							
							NSInteger len = [_inStream read:buffer maxLength:UIAppDelegate.connection->imageDataSize];
							[imgData appendBytes:buffer length:len];
							
							if(len == UIAppDelegate.connection->imageDataSize){
								
								DLog(@"Finished receive for remote image! (Bytes: %d", [imgData length]);
								
								[UIAppDelegate.drawingView loadRemoteImageWithByteData:imgData];
								
								UIAppDelegate.connection->imageDataSize = 0;
								UIAppDelegate.connection->receivingRemoteImage = NO;
							}
							else {
								UIAppDelegate.connection->imageDataSize -= len;
								DLog(@"Image retrieval left: %d (%d retrieved)", UIAppDelegate.connection->imageDataSize, len);
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
					
					[UIAppDelegate.connection processMessage:message source:stream];
					
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
			DLog(@"NSStreamEventEndEncountered");
			[UIAppDelegate.connection receivedDisconnectedMessageFrom:stream];
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
	
	NSError *theError = error;
	
	if (!(UIAppDelegate->errorAlert)) {
		NSString *title = nil, *message = nil;
		NSInteger code = [theError code];
		NSString *domain = [theError domain];
		DLog(@"error domain = %@", domain);
		
		if (code == 32) {
			title = @"Peer Disconnected";
			message = [NSString stringWithFormat:@"Error %i: %@", code, [theError localizedDescription]];
			if ([UIAppDelegate.connection receivedPeerUnavailableSignalFrom:stream]) {
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
			if (UIAppDelegate.drawingView.hasUnsavedChanges) {
				// Save drawing
				//[drawingView captureToSavedPhotoAlbum];
				[UIAppDelegate.drawingView captureToWhiteboardTempFile];
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
			if ([UIAppDelegate.connection receivedPeerUnavailableSignalFrom:stream]) {
				return;
			}
			
		} else {
			title = @"Error reading/writing stream";
			message = [NSString stringWithFormat:@"Error %i: %@", code, [theError localizedDescription]];
		}
		UIAppDelegate->errorAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[UIAppDelegate->errorAlert show];
		//[alert release];
		
		NSString *analyticsMessage = [NSString stringWithFormat:@"Error%i", code];
		ANALYTICS_LOG(analyticsMessage);
	}
	
	
	[stream close];
	[stream release], 
	stream = nil;	
}

// Execute on inStreamThread
//KONG: reject silently in local connection means: send reject message & remove all stream w request name 
//- (void)rejectSilentlyWithName:(NSString*)name {
//	[UIAppDelegate.connection acceptPendingRequest:kRejectSilently withName:name];
//}


// Execute on MainThread
- (void)removeServiceWithTimer:(NSTimer*)timer {
	if ([NSThread isMainThread]) {
		DLog(@"%s on MainThread", _cmd);
	} else {
		DLog(@"%s NOT on MainThread", _cmd);
	}
	
	[self.bvc performSelectorOnMainThread:@selector(removeServiceWithName:)
									withObject:[timer userInfo]
								 waitUntilDone:YES];
}

@end
