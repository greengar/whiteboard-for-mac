//
//  GSXmlRpcHelper.m
//  Whiteboard
//
//  Created by Cong Vo on 12/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GSXmlRpcHelper.h"


#import "XMLRPCResponse.h"
#import "XMLRPCRequest.h"
#import "XMLRPCConnection.h"

#import "AppController.h"
#import "GSConnectionController.h"
#import "GSInternetConnection.h"
#import "GSUserHelper.h"

// the server
//static NSString *server = @"http://www.greengarstudios.com.php5-18.dfw1-2.websitetestlink.com/wordpress/xmlrpc.php"; 
//static NSString *server = @"http://www.greengarstudios.com.php5-18.dfw1-2.websitetestlink.com/user/greengar.php";  
static NSString *server = @"https://www.greengarstudios.com/user/xmlrpc.php"; 

@implementation GSXmlRpcHelper
@synthesize delegate = _delegate, callback = _callback;

- (id)initWithRequest:(XMLRPCRequest *)request delegate:(id)delegate callback:(SEL)callback {
	if ((self = [super init])) {
		_request = [request retain];
		_delegate = delegate;
		_callback = callback;
	}
	return self;
}

- (void) dealloc {
	[_request release];
	
	[super dealloc];
}


+ (void)performRequest:(XMLRPCRequest *)request delegate:(id)delegate callback:(SEL)callback {
	GSXmlRpcHelper *requestHelper = [[GSXmlRpcHelper alloc] initWithRequest:request
																   delegate:delegate
																   callback:callback];
	
	[NSThread detachNewThreadSelector:@selector(executeRequestInBackground) toTarget:requestHelper withObject:nil];
}

+ (void)performRequestWithMethod:(NSString *)method args:(NSArray *)args
						delegate:(id)delegate callback:(SEL)callback {
//	DLog(@"method: %@ args: %@", method, args);
	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:server]];
	[request setMethod:method withObjects:args];
	
	[self performRequest:request delegate:delegate callback:callback];
	[request release];
}

+ (void)performAuthRequestWithMethod:(NSString *)method args:(NSArray *)args
						delegate:(id)delegate callback:(SEL)callback {
	DLog(@"method: %@ args: %@", method, args);
	
	NSString *username = [NSDEF objectForKey:kGreengarCachedUsername];
	NSString *password = [NSDEF objectForKey:kGreengarCachedPassword];

	if (username == nil || password == nil) {
		DLog(@"WARNING: BAD request with username: %@ password %@", username, password);
	}
	
	NSMutableArray *fullArgs = [NSMutableArray arrayWithObjects:username, password, nil];
	[fullArgs addObjectsFromArray:args];
	
	[self performRequestWithMethod:method args:[NSArray arrayWithArray:fullArgs]
						  delegate:delegate callback:callback];
}


- (void)executeRequestInBackground {  
      
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];  
//	id response = [self executeXMLRPCRequest:_request];
	
	XMLRPCResponse *userInfoResponse = [XMLRPCConnection sendSynchronousXMLRPCRequest:_request];
	id response = nil;
	if ([userInfoResponse isKindOfClass:[XMLRPCResponse class]]) {
		response = [userInfoResponse object];
		
	} else if([userInfoResponse isKindOfClass:[NSError class]]) {
		NSError *error = (NSError *) userInfoResponse;
		DLog(@"XMLRPC ERROR: %@", userInfoResponse);
		/*
		 faultCode = 403;
		 faultString = "Bad login/pass combination.";
		 */
		NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithInt:error.code], @"faultCode",
									 @"Cannot reach server.", @"faultString", nil];
		response = errorInfo;				
	}
	
    [self performSelectorOnMainThread:@selector(requestDidFinish:) withObject:response waitUntilDone:NO];  
	
    [pool release];  
      
}  

- (void)requestDidFinish:(id)response {
	[_delegate performSelector:_callback withObject:response];
}

static NSArray *cachedServices = nil;

static NSString *servicesURLString = @"http://www.greengarstudios.com/files/xmppservices.txt";

//"http://www.greengarstudios.com/files/whiteboard/whiteboard-beta1.9.9.ipa"

+ (void)retrieveXmppServicesListWithDelegate:(id)delegate callback:(SEL)callback {
	if (cachedServices) {
		[delegate performSelector:callback withObject:cachedServices];
		return;
	}
	
	
	GSXmlRpcHelper *requestHelper = [[GSXmlRpcHelper alloc] init];
	requestHelper.delegate = delegate;
	requestHelper.callback = callback;
	
	
	
	[NSThread detachNewThreadSelector:@selector(retrieveDataForURLString:) 
							 toTarget:requestHelper withObject:servicesURLString];
	
}

- (void)retrieveDataForURLString:(NSString *)URLString  {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];  

//	NSData *data = [NSData dataWithContentsOfURL:];
	NSError *error;
	NSString *servicesString = [[[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:URLString] 
															  encoding:NSASCIIStringEncoding
																 error:&error] autorelease];
	DLog(@"servicesString: %@", servicesString);
	
	/*
	 xmpp.ws
	 xmpp.us
	 binaryfreedom.info
	 openjabber.org
	 */
	
	NSArray *rawServices = [servicesString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	DLog(@"raw services: %@", rawServices);
	
	NSMutableArray *services = [NSMutableArray array];

	for (NSString *service in rawServices) {
		if (service.length > 3) { // 3 is a made-up number for long enough domain name
			[services addObject:service];
		}
	}
	
	//KONg: testing
	//[services addObject:@"openjabber.org"];
//	services = [NSArray arrayWithObjects:@"openjabber.org", @"binaryfreedom.info", nil];
//	services = [NSArray arrayWithObjects:@"xmpp.ws", @"xmpp.us", nil];
//	services = [NSArray array];	
	//
	
//	DLog(@"services: %@", services);

	// save cached service
	cachedServices = [[NSArray arrayWithArray:services] retain];
	
	[self performSelectorOnMainThread:@selector(requestDidFinish:) withObject:services waitUntilDone:NO];
	[pool release];
}

@end