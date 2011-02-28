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
#import "NSString+GSURL.h"
#import "AppController+NSStreamDelegate.h"
#import "ASIFormDataRequest.h"

#define kWb ([UIDevice currentDevice].uniqueIdentifier)
#define kGetMessageDelay				0.50f					//2.0f	// second
#define kGetMessageAfterFailureDelay	(kGetMessageDelay/2.0f) //1.0f	// seconds

@interface GSInternetConnection ()
- (void)registerWhiteboard;
- (void)findWhiteboardsWithName:(NSString *)query;
@end

@implementation GSInternetConnection

@synthesize name, sendingBuffer = _sendingBuffer, sendingDestinationWb = _sendingDestinationWb, connectedWhiteboard, delegate;

const NSString *kServerURL = @"http://whiteboardonline.appspot.com/api/";

- (id)initWithName:(NSString *)newName {
	if ((self = [super init])) {
		self.name = newName;
		
		waitingBuffers = [[NSMutableDictionary dictionaryWithCapacity:2] retain];
//		sendingBuffers = [NSMutableDictionary dictionaryWithCapacity:2];
		
//		NSMutableString *waitingBuffer;
//		NSMutableString *sendingBuffer;
//		waitingBuffer = [[NSMutableString alloc] initWithString:@""];
//		sendingBuffer = [[NSMutableString alloc] initWithString:@""];
		
		DLog(@"Internet Connection started");
		
		json = [[SBJSON alloc] init];
		
		[self registerWhiteboard]; // TODO: register sooner
		
		//[self findWhiteboardsWithName:@"E"];
		
		[self getMessages];
	}
	return self;
}

- (void)registerWhiteboard {
	// /api/register?wb=   &long= &lat= &name=  &fbuid=   &email=
	
//	[networkQueue setDownloadProgressDelegate:progressIndicator];
//	[networkQueue setRequestDidFinishSelector:@selector(registrationComplete:)];
//	[networkQueue setShowAccurateProgress:[accurateProgress isOn]];
//	[networkQueue setDelegate:self];
	
	// http://whiteboardonline.appspot.com/api/register?wb=%@&name=%@
	// %@register?wb=%@&name=%@
	
	
	NSString *escapedName = [name escapedURLString];	
	
	NSString *urlString = [NSString stringWithFormat:@"%@register?wb=%@&name=%@", kServerURL, kWb, escapedName];
	DLog(@"urlString = %@", urlString);
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:
							   [NSURL URLWithString:urlString]];
	
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(registrationComplete:)];
	[request setDidFailSelector:@selector(registrationDidFail:)];
	// TODO: handle failure
	[request startAsynchronous];
	
//	[networkQueue addOperation:request];
//	
//	[networkQueue go];
}

- (void)registrationComplete:(ASIHTTPRequest *)request {
	DLog(@"registrationComplete:%@", [request responseString]);
	// register again in 60 sec
	// TODO: only if not connected
	[self performSelector:@selector(registerWhiteboard) withObject:nil afterDelay:60];
}

- (void)registrationDidFail:(ASIHTTPRequest *)request {
	//DLog(@"%s%@", _cmd, [request responseString]); // Conversion specifies type 'char *' but the argument has type 'SEL' (LLVM compiler 1.5)
	// attempt again in 15 sec
	// TODO: only if not connected
	[self performSelector:@selector(registerWhiteboard) withObject:nil afterDelay:15];
}

- (void)findWhiteboardsWithName:(NSString *)query {
	// /api/find?fbuid=   &long=   &lat=    &name=   &email=
	
	[findRequest cancel];
	NSString *urlString = [NSString stringWithFormat:@"%@find?name=%@", kServerURL, [query escapedURLString]];
	DLog(@"%@", urlString);
	findRequest = [ASIHTTPRequest requestWithURL:
				   [NSURL URLWithString:urlString]];
	[findRequest setDelegate:self];
	[findRequest setDidFinishSelector:@selector(findComplete:)];
	[findRequest setDidFailSelector:@selector(findComplete:)]; // TODO: test
	[findRequest startAsynchronous];
}

- (void)findComplete:(ASIHTTPRequest *)request {
	findRequest = nil;
	
	NSString *jsonString = [request responseString];
	DLog(@"%@", jsonString);
	
	//{"message": "whiteboard registered", "result": 0}
	
	//{"message": "1 whiteboards found", "whiteboards": [{"wb": "F36B6157-EDEC-5681-B1FD-A3EAC18B77F2", "long": null, "fbuid": null, "lat": null, "email": null, "name": "ELBOOK"}], "result": 0}
	
	SBJSON *parser = [[SBJSON alloc] init];
	NSDictionary *object = [parser objectWithString:jsonString error:nil];
	[parser release];
	
	//DLog(@"object = %@", object);
//	NSArray *whiteboards = [object objectForKey:@"whiteboards"];
//	NSDictionary *whiteboard = [whiteboards objectAtIndex:0];
//	//DLog(@"whiteboard = %@", whiteboard);
//	
//	//	NSString *whiteboardString = [whiteboards objectAtIndex:0];
//	NSString *aName = [whiteboard objectForKey:@"name"];
//	DLog(@"aName = %@", aName);
	
	if ([delegate respondsToSelector:@selector(findCompleteDictionary:)])
		[delegate findCompleteDictionary:object];
}

- (void)sendBuffer {
	// /api/sendmessage?wb=  &message=
	//[sendRequest cancel];
	if (sendRequest) {
		DLog(@"sendRequest already active");
		return;
	}
	
	if (!self.sendingBuffer) { // can optimize this to not use temp vars
		NSString *waitingBuffer = nil;
		NSString *waitingDestinationWb = nil;
		
		for (NSString *wb in [waitingBuffers allKeys]) {
			waitingBuffer = [waitingBuffers objectForKey:wb];
			if (waitingBuffer && ![waitingBuffer isEqualToString:@""]) {
				[[waitingBuffer retain] autorelease];
				waitingDestinationWb = [[wb retain] autorelease];
				[waitingBuffers removeObjectForKey:wb];
				
				break;
			}
		}
		if (!waitingBuffer || [waitingBuffer isEqualToString:@""]) {
			DLog(@"no waitingBuffer found");
			return;
		}
		
		self.sendingBuffer = [[waitingBuffer mutableCopy] autorelease];
		self.sendingDestinationWb = waitingDestinationWb;
	} else  {
		// check if there's more data to append before retrying
		NSString *waitingBuffer = [waitingBuffers objectForKey:self.sendingDestinationWb];
		if (waitingBuffer && ![waitingBuffer isEqualToString:@""]) {
			[self.sendingBuffer appendString:waitingBuffer];
			[waitingBuffers removeObjectForKey:self.sendingDestinationWb];
		}
	}
	
#define kUseGET 1
#if kUseGET
	
	NSString *urlString = [NSString stringWithFormat:@"%@sendmessage?fromwb=%@&towb=%@&message=%@",
						   kServerURL, kWb, self.sendingDestinationWb, [self.sendingBuffer escapedURLString]];
	DLog(@"%@", urlString);
	sendRequest = [ASIHTTPRequest requestWithURL:
				   [NSURL URLWithString:urlString]];
	// may want to escape the wb's in the future
	
#else // use POST
	
	NSString *urlString = [NSString stringWithFormat:@"%@sendmessage?fromwb=%@&towb=%@",
						   kServerURL, kWb, self.sendingDestinationWb];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:
				   [NSURL URLWithString:urlString]];
	
//	[request setPostValue:kWb forKey:@"fromwb"];
//	[request setPostValue:self.sendingDestinationWb forKey:@"towb"];
	[request setPostValue:[self.sendingBuffer escapedURLString] forKey:@"message"];
	
	sendRequest = request;
	
//	?fromwb=%@&towb=%@&message=%@
//	
//	kWb, self.sendingDestinationWb, [self.sendingBuffer escapedURLString]
//	
//	//DLog(@"%@", urlString);
//	
//	
//	sendRequest = [ASIHTTPRequest requestWithURL:
//				   [NSURL URLWithString:urlString]];
//	
	[sendRequest setRequestMethod:@"POST"];
	
	// may want to escape the wb's in the future
	
#endif // use POST
	
	[sendRequest setDelegate:self];
	[sendRequest setDidFinishSelector:@selector(sendDidFinish:)];
	[sendRequest setDidFailSelector:@selector(sendDidFail:)];
	[sendRequest startAsynchronous];
}

- (void)sendMessage:(NSString *)message toWb:(NSString *)wb {
	NSMutableString *waitingBuffer = [waitingBuffers objectForKey:wb];
	if (!waitingBuffer) {
		waitingBuffer = [[[NSMutableString alloc] initWithString:message] autorelease];
		[waitingBuffers setObject:waitingBuffer forKey:wb];
	} else { // fixed bug
		[waitingBuffer appendString:message];
	}
	if (!sendRequest) {
		[self sendBuffer];
	}
	
	
	//		NSMutableString *waitingBuffer;
	//		NSMutableString *sendingBuffer;
	//		waitingBuffer = [[NSMutableString alloc] initWithString:@""];
	//		sendingBuffer = [[NSMutableString alloc] initWithString:@""];
}

- (void)sendDidFinish:(ASIHTTPRequest *)request {
	sendRequest = nil;
	self.sendingBuffer = nil;
	self.sendingDestinationWb = nil;
	DLog(@"%@", [request responseString]);
	
	[self sendBuffer];
}

- (void)sendDidFail:(ASIHTTPRequest *)request {
	sendRequest = nil;
	DLog(@"%@", [request responseString]);
	
	[self sendBuffer];
}

- (void)getMessages {
	// /api/getmessages?wb= 
	//
	// array of dictionaries:
	// [
	//  {'from':12342, 'message':'alskfaljf",'time':'1234'}, // WRONG - actually just an array of messages (OK)
	//  {'from':12342, 'message':'alskfaljf",'time':'1234'},
	//  {'from':12342, 'message':'alskfaljf",'time':'1234'},
	//  {'from':12342, 'message':'alskfaljf",'time':'1234'},
	// ]
	
	NSString *urlString = [NSString stringWithFormat:@"%@getmessages?wb=%@", kServerURL, kWb];
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:
							   [NSURL URLWithString:urlString]];
	
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(receiveDidFinish:)];
	[request setDidFailSelector:@selector(receiveDidFail:)]; // TODO: handle failure
	
	lastGetMessageTime = [NSDate timeIntervalSinceReferenceDate];
	
	[request startAsynchronous];
	
	
}

- (void)receiveDidFinish:(ASIHTTPRequest *)request {
	//DLog(@"%s%@", _cmd, [request responseString]);
	
	NSString *jsonString = [request responseString];
	//DLog(@"%@", jsonString);
	
	//receiveDidFinish:{"message": "1 messages found", "messages": ["n}}Elliot Lee\u2019s iPad}}"], "result": 0}
	
	//{"message": "0 messages found", "messages": [], "result": 0}
	
	//{"message": "whiteboard registered", "result": 0}
	
	//{"message": "1 whiteboards found", "whiteboards": [{"wb": "F36B6157-EDEC-5681-B1FD-A3EAC18B77F2", "long": null, "fbuid": null, "lat": null, "email": null, "name": "ELBOOK"}], "result": 0}
	
	//SBJSON *parser
	NSDictionary *receiveDictionary = [json objectWithString:jsonString error:nil];
	NSArray *messages = [receiveDictionary objectForKey:@"messages"];
	if ([messages count] > 0) {
		
		
		//DLog(@"messages = %@", messages);
		//	NSArray *whiteboards = [object objectForKey:@"whiteboards"];
		//	NSDictionary *whiteboard = [whiteboards objectAtIndex:0];
		//	//DLog(@"whiteboard = %@", whiteboard);
		//	
		//	//	NSString *whiteboardString = [whiteboards objectAtIndex:0];
		//	NSString *aName = [whiteboard objectForKey:@"name"];
		//	DLog(@"aName = %@", aName);
		
		//if ([delegate respondsToSelector:@selector(receivedMessages:)])
		//	[delegate receivedMessages:messages];
		
		[UIAppDelegate receivedMessages:messages];
	}
//	else {
//		DLog(@"no messages");
//	}
	
	NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
	// time to next fetch
	NSTimeInterval delay = kGetMessageDelay - (currentTime - lastGetMessageTime);
	if (delay < 0)
		delay = 0;
	
	//[self getMessages];
	[self performSelector:@selector(getMessages) withObject:nil afterDelay:delay];
}

- (void)receiveDidFail:(ASIHTTPRequest *)request {
	DLog(@"%@", [request responseString]);
	
	NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
	// time to next fetch
	NSTimeInterval delay = kGetMessageAfterFailureDelay - (currentTime - lastGetMessageTime);
	if (delay < 0)
		delay = 0;
	
	//[self getMessages];
	[self performSelector:@selector(getMessages) withObject:nil afterDelay:delay];
}

- (BOOL)isConnected { return [self isConnected:nil]; }
- (BOOL)isConnected:(NSString *)wb { return NO; }
- (BOOL)isResolving { return [self isResolving:nil]; }
- (BOOL)isResolving:(NSString *)wb { return NO; }
//- (GSWhiteboard *)connectedWhiteboard { return connectedWhiteboard; }

@end
