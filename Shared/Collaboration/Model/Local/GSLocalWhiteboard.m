//
//  GSLocalWhiteboard.m
//  Whiteboard
//
//  Created by Cong Vo on 1/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GSLocalWhiteboard.h"
#import APP_DELEGATE
#import "GSConnectionController.h"
#import "GSWhiteboard.h"
#import "GSLocalConnection.h"
#import "GSLocalWhiteboard+NSStreamDelegate.h"

@interface GSLocalWhiteboard ()


- (void)openInStream:(NSInputStream*)inStream withOutStream:(NSOutputStream*)outStream;
- (void)startToResolveService;
- (void)stopCurrentResolve;

@end


@implementation GSLocalWhiteboard

@synthesize inStream = _inStream, outStream = _outStream;
@synthesize service = _service;
@synthesize writeBuffer = _writeBuffer;
@synthesize readBuffer = _readBuffer;

static GSLocalConnection *connection = nil;

- (id)initWithName:(NSString *)name {
	if ((self = [super initWithName:name])) {
		_type = GSConnectionTypeLocal;
		connection = AppDelegate.connection.localConnection;		
	}
	return self;
}


- (void)dealloc {
	DLog(@"%@", _name);
	
	[_inStream release];
	[_outStream release];
	[_writeBuffer release];
	[_service release];
	
	[super dealloc];
}

- (GSConnectionType)connectionType {
	return GSConnectionTypeLocal;
}

- (id <GSConnection>)connection {
	return connection;
}


- (id)source {
	return _inStream;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@; instream: %@; outStream: %@", [super description], _inStream, _outStream];
}

#pragma mark Stream & Networking


- (id)initWithNetService:(NSNetService *)service name:(NSString *)name {
	if ((self = [self initWithName:name])) {
		_type = GSConnectionTypeLocal;
		_service = [service retain];
		_writeBuffer = [[NSString alloc] init];
		connection = AppDelegate.connection.localConnection;
	}
	return self;
}

- (id)initWithInStream:(NSInputStream *)inStream outStream:(NSOutputStream *)outStream {
	if ((self = [super init])) {
		_type = GSConnectionTypeLocal;
		_inStream = [inStream retain];
		_outStream = [outStream retain];
		_writeBuffer = [[NSString alloc] init];
		connection = AppDelegate.connection.localConnection;
		[self openInStream:_inStream withOutStream:_outStream];
	}
	return self;
}


- (void)initiateConnection {
//	needToSendName = YES;

	[self startToResolveService];
}

- (void)resetStateForNewConnection {
    
}

//KONG: this is a heristic method, to check if I did send connection request. 
// I use this when I'm in a conflict request.
- (BOOL)didSendConnectionRequest {
	// if my buffer length < 3 => YES
	// or my buffer does not begin by "n}}" => YES
	
	if (_writeBuffer.length >= 3) {
		DLog(@"buffer prefix: %@",[_writeBuffer substringToIndex:3]);		
	}
	
	return (_writeBuffer.length < 3 
			|| [[_writeBuffer substringToIndex:3] isEqualToString:@"n}}"] == NO);
}

- (void)openInStream:(NSInputStream*)inStream withOutStream:(NSOutputStream*)outStream {
	DLog(@"%s", _cmd);
	
	
//	self.writeBuffer = @"";
	[self performSelector:@selector(openStream:) onThread:connection.streamThread
			   withObject:inStream waitUntilDone:NO];
	[self performSelector:@selector(openStream:) onThread:connection.streamThread
			   withObject:outStream waitUntilDone:NO];
}

// streamThread
- (void)openStream:(NSStream*)stream {
	//DLog(@"%s%@", _cmd, stream);
	stream.delegate = self;
	[stream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[stream open];
}

- (BOOL)isResolved {
	return (_inStream != nil && _outStream != nil);
}

- (void)sendDisconnectMessage {
    //KONG: in local colaboration, currently we do not need to send disconnect message
}

- (void)disconnect {
	// If I haven't resolve yet
	if ([self isResolved] == NO) {
		[self stopCurrentResolve];
		return;
	}
	
	// If I did resolve
	DLog(@"whiteboard: %@", self);
	[self performInStreamThreadSelector:@selector(disconnectInStreamThread) withObject:nil wait:NO];
}

// in Stream thead
- (void)disconnectInStreamThread {
	[_inStream close];
	[_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	DLog(@"closed Instream: %@", _inStream);
	self.inStream = nil;

	
	[_outStream close];	 
	[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	DLog(@"closed Outstream: %@", _outStream);
	self.outStream = nil;
}


#pragma mark NetService resolving

//KONG: Base on Witap, at one moment, these should have only one resolving service
static NSNetService *currentResolve = nil;

- (void)stopCurrentResolve {
	[currentResolve stop];
	currentResolve = nil;
}
- (void)startToResolveService {
	[self stopCurrentResolve];
	
	currentResolve = _service; //[self.services objectAtIndex:indexPath.row];
	
	[_service setDelegate:self];
	
	// Attempt to resolve the service. A value of 0.0 sets an unlimited time to resolve it. The user can
	// choose to cancel the resolve by selecting another service in the table view.
	[_service resolveWithTimeout:0.0];
	
	// Make sure we give the user some feedback that the resolve is happening.
	// We will be called back asynchronously, so we don't want the user to think
	// we're just stuck.	
}



// This should never be called, since we resolve with a timeout of 0.0, which means indefinite
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
	DLog(@"error: %@", errorDict);
	
	if (sender == _service) {
		[_service stop];
	}
	
	//	if ([NSThread isMainThread]) {
	//		DLog(@"%s on MainThread", _cmd);
	//	} else {
	//		DLog(@"%s NOT on MainThread", _cmd);
	//	}
	//	[self didUpdateServicesData];
}


// Executes on the client (the device on which we tap the server's name - the "guest")
- (void)netServiceDidResolveAddress:(NSNetService *)service {
	if (service) {
		DLog(@"service.name == %@", service.name);
	} else {
		DLog(@"service == nil");
	}
	if (currentResolve) {
		DLog(@"self.currentResolve.name == %@", currentResolve.name);
	} else {
		DLog(@"self.currentResolve == nil. END METHOD");
	}
	
	if (currentResolve == nil) {
		return;
	}
	assert(service == currentResolve);		
	
	//KONG: 
	if (service != _service) {
		DLog(@"currentResolve != _service. END METHOD");
		return;
	}
	
	[_service stop];
	
	
	if ([_service getInputStream:&_inStream outputStream:&_outStream] == NO) {
		[connection showNetworkError:@"Failed connecting to server"];
		return;
	}
	
	//KONG: consider to remove this 
	needToSendName = YES;
	
	[self openInStream:_inStream withOutStream:_outStream];
}

- (void)send:(NSString *)message {
	
	if ([NSThread isMainThread]) {
		DLog(@"send in MAIN Thread. Put it into Stream thread");
		[self performInStreamThreadSelector:@selector(send:) withObject:message wait:NO];
		return;
	}

	if ([NSThread isMainThread]) {
		DLog(@"UNEXPECTED: IN MAIN Thread");
	}
	
	if(AppDelegate.connection.sendingRemoteImage) {
		DLog(@"Currently sending remote image data, blocking all other sends!");
		return;
	}
	
	if (_outStream == nil) {
		self.writeBuffer = [_writeBuffer stringByAppendingString:message];
		DLog(@"not resolved yet, added to buffer: %@", _writeBuffer);
		return;
	}
	
	//DLog(@"%s%@, [_outStreams count] = %d", _cmd, message, [_outStreams count]);
	// Watch out for an infinite loop
	if ([_writeBuffer length] > 0 && ![_writeBuffer isEqualToString:message]) {
		[self send:_writeBuffer];
		self.writeBuffer = @"";
		//DLog(@"back to %s%@", _cmd, message);
	}
	
	//SHERWIN: Checking what is being sent
	//if([message length] < 50) DLog(@"Sending message: %@", message);
	
	const char *buff = [message UTF8String];
	
	NSUInteger buffLen = strlen(buff);
	NSInteger writtenLength = 0;
	

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
		self.writeBuffer = [_writeBuffer stringByAppendingString:message];
		
		
	}
	if (writtenLength == -1) {
		DLog(@"writtenLength == -1");
		// This occurs if we try to do stuff at the point when we say Game Started!
		//[NSException raise:@"send: WriteFailure" format:@"writtenLength = %d, [_outStreams count] = %d, _outStream = %@", writtenLength, [_outStreams count], _outStream];
		
		// Put into a write buffer
		self.writeBuffer = [_writeBuffer stringByAppendingString:message];
		
	}
	
	if ([_writeBuffer isEqualToString:message]) {
		self.writeBuffer = @"";
	}
}
/*
- (void)send:(NSString *)message {
	DLog(@"whiteboard: %@ send: %@", _name, message);
	
	// Put into a write buffer
//	if (_writeBuffer.length > 0) {
//		
//	}
	self.writeBuffer = [_writeBuffer stringByAppendingString:message];
	
	if (_writeBuffer.length == 0) {
		return;
	}
	
	if(AppDelegate.connection.sendingRemoteImage) {
		DLog(@"Currently sending remote image data, blocking all other sends!");
		return;
	}
	
	if (_outStream == nil) {
		DLog(@"send to: %@ out stream has not resolved yet", _name);
		return;
	}
	
	if ([_outStream hasSpaceAvailable] == NO) {
		DLog(@"Warning: send: ![_outStream hasSpaceAvailable]");
		
		// Use the stream synchronously
		// https://devforums.apple.com/message/2902#2902
		// turn around and try to write the remaining data.  If buffer space hasn't become available, this will block.
		
		return;
	}
	
	
	//KONG: what this is for?
	
	//DLog(@"%s%@, [_outStreams count] = %d", _cmd, message, [_outStreams count]);
	// Watch out for an infinite loop
//	if ([_writeBuffer length] > 0 && ![_writeBuffer isEqualToString:message]) {
//		[self send:_writeBuffer];
//		self.writeBuffer = @"";
//		DLog(@"back to %s%@", _cmd, message);
//	}
	
	//SHERWIN: Checking what is being sent
	//if([message length] < 50) DLog(@"Sending message: %@", message);
	
	const char *buff = [_writeBuffer UTF8String];
	
	NSUInteger buffLen = strlen(buff);
	NSInteger writtenLength = 0;
	printf("* Attempt to write *");
	writtenLength = [_outStream write:(const uint8_t *)buff maxLength:strlen(buff)];
	printf(" - written length %d - ", writtenLength);
	
	if (writtenLength != buffLen) {
		
		DLog(@"Failed sending data to peer, writtenLength = %d, buffLen = %d", writtenLength, buffLen);
		
		if (writtenLength == -1) {
			//KONG: an old comment, after move the code, change some logic
			// I still keep it here, for later reference
			
			// This occurs if we try to do stuff at the point when we say Game Started!
			//[NSException raise:@"send: WriteFailure" format:@"writtenLength = %d, [_outStreams count] = %d, _outStream = %@", writtenLength, [_outStreams count], _outStream];
			
			DLog(@"writtenLength == -1 => stop sending now");
			return;
		}
		
		//KONG: this may block the app 
		buff += writtenLength;
		buffLen -= writtenLength;
		while (buffLen > 0 && writtenLength != -1) {
			printf("* Attempt to write *");
			writtenLength = [_outStream write:(const uint8_t *)buff maxLength:strlen(buff)];
			DLog(@"Successfully wrote %d bytes", writtenLength);
			buff += writtenLength;
			buffLen -= writtenLength;
		}
		
		DLog(@"HANDLE THIS: unexpectedly write to stream");
	} else {
		DLog(@"Write successful! (Bytes written: %d)", writtenLength);
		self.writeBuffer = @"";
	}	
}

*/


- (void)sendLargeDataByChunks:(NSString*)message {
	if ([NSThread isMainThread]) {
		[self performInStreamThreadSelector:@selector(sendLargeDataByChunks:)
								 withObject:message wait:NO]; //KONG: this my block the app, check this
	}
	
	
	if(![message length]) return; //Don't send message with no data
	
	if ([_writeBuffer length] > 0 && ![_writeBuffer isEqualToString:message]) {
		[self send:_writeBuffer];
		self.writeBuffer = @"";
		//DLog(@"back to %s%@", _cmd, message);
	}
	
	
	//KONG: Last implementation have param `identifier:(NSString *)sendID`
	// I remove that, but dont want to change inside code
	NSString *sendID = nil;
	
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
	
/*	
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
	
 */
	
	int chunkIndex = 0;
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
			
			tempStr = @"";
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
			self.writeBuffer = [_writeBuffer stringByAppendingString:message];
			
			
		}
		if (writtenLength == -1) {
			DLog(@"writtenLength == -1");
			// This occurs if we try to do stuff at the point when we say Game Started!
			//[NSException raise:@"send: WriteFailure" format:@"writtenLength = %d, [_outStreams count] = %d, _outStream = %@", writtenLength, [_outStreams count], _outStream];
			
			// Put into a write buffer
			self.writeBuffer = [_writeBuffer stringByAppendingString:message];
			
		}
		
		if ([_writeBuffer isEqualToString:message]) {
			self.writeBuffer = @"";
		}
		
		
		chunkIndex++;
	}
	
	DLog(@"Finished sending large data string by chunks! (#: %d", chunkIndex);
	
	[AppDelegate.connection finishSendingImageHexData];
}


#pragma mark TEST

- (void)setWriteBuffer:(NSString *)string {
	[_writeBuffer release];
	_writeBuffer = [string retain];
	DLog(@"whiteboard: %@ writeBuffer: %@", _name, _writeBuffer);
}

- (void)performInStreamThreadSelector:(SEL)selector withObject:(id)object wait:(BOOL)willWait {
	[self performSelector:selector onThread:connection.streamThread
			   withObject:object waitUntilDone:willWait];
}


@end