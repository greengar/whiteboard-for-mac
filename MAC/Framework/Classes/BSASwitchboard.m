/*
 * AppController.h
 * Classes
 * 
 * Created by Gregory Barchard on 23/09/2010.
 * 
 * Copyright (c) 2010 BuySellAds.com
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the project's author nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

//
//  BSASwitchboard.m
//  BSAAdFramework
//
//  Created by Rick Fillion on 1/25/10.
//  Copyright 2010 BuySellAds. All rights reserved.
//

#import "BSASwitchboard.h"
#import "NSDictionary+Additions.h"
#import "JSON.h"
#import "NSObject+Additions.h"
#import <stdlib.h>


#define USER_DEFAULTS_GUID_KEY @"BuySellAdsGuid"

static BSASwitchboard * sharedSwitchboard =  nil;

@interface BSASwitchboard (Private)

- (NSString *)_parametersForBannerIds:(NSArray *)bannerIds zoneId:(NSNumber *)zoneId;
- (NSString *)_cleanBuySellAdsJSON:(NSString *)json;
- (NSString *)_systemVersionString;
- (NSString *)_guid;

- (void) _sendRequest:(NSString *)verb
             withData:(NSDictionary *)data
              forPath:(NSString *)subpath
    relativeToBaseUrl:(NSString *)baseUrl
               target:(id)target
             selector:(SEL)sel;
- (void) _sendRequest:(NSString *)verb
             withData:(NSDictionary *)data
              forPath:(NSString *)subpath
    relativeToBaseUrl:(NSString *)baseUrl
               target:(id)target
             selector:(SEL)sel
              context:(id)context;
- (void)_returnResponseForConnection:(NSURLConnection *)connection;
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection; 

@end

@implementation BSASwitchboard

+ (NSString *)baseAdsURL
{
    return @"http://s3.buysellads.com/";
}

+ (NSString *)baseStatsURL
{
    return @"http://stats.buysellads.com/";
}

+ switchboard
{
    if (!sharedSwitchboard) [[self alloc] init];
    return sharedSwitchboard;
}

- init
{
    [super init];
    if (sharedSwitchboard) {
        [self release];
        return sharedSwitchboard;
    }
    connections = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks,
                                            &kCFTypeDictionaryValueCallBacks);
    connectionsData = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks,
                                                &kCFTypeDictionaryValueCallBacks);
    defaults = [NSUserDefaults standardUserDefaults];
    sharedSwitchboard = self;
    return self;
}

- (void)dealloc
{
    [defaults release];
    CFRelease(connections);
    CFRelease(connectionsData);
    [super dealloc];
}

- (void) adsForKey:(NSString *)key target: (id)target selector:(SEL)sel;
{
    if (!key)
    {
        NSLog(@"can't pass nil key");
        return;
    }
    
    NSString *path = [NSString stringWithFormat:@"r/s_%@.js", key];
    //NSLog(@"path = %@", path);
    [self _sendRequest: @"GET"
              withData: nil
               forPath: path
     relativeToBaseUrl:[BSASwitchboard baseAdsURL]
                target: target
              selector: sel];
}

- (void) registerImpressionForAdIds:(NSArray *)adIdentifiers zoneId:(NSNumber *)zoneIdentifier target:(id)target selector:(SEL)sel
{
    NSString *parameters = [self _parametersForBannerIds:adIdentifiers zoneId:zoneIdentifier];
    NSString *path = [NSString stringWithFormat:@"imp.gif?%@", parameters];
    
    //NSLog(@"path = %@", path);
    [self _sendRequest: @"GET"
              withData: nil
               forPath: path
     relativeToBaseUrl:[BSASwitchboard baseStatsURL]
                target: target
              selector: sel];
    
}

- (void) registerClickForAdId:(NSNumber *)adIdentifier zoneId:(NSNumber *)zoneIdentifier target:(id)target selector:(SEL)sel;
{
    if (!adIdentifier)
        return;
    NSArray *bannerIds = [NSArray arrayWithObject:adIdentifier];
    NSString *parameters = [self _parametersForBannerIds:bannerIds zoneId:zoneIdentifier];
    NSString *path = [NSString stringWithFormat:@"click.gif?%@", parameters];
    [self _sendRequest: @"GET"
              withData: nil
               forPath: path
     relativeToBaseUrl:[BSASwitchboard baseStatsURL]
                target: target
              selector: sel];
}


@end

@implementation BSASwitchboard (Private)

- (NSString *)_parametersForBannerIds:(NSArray *)bannerIds zoneId:(NSNumber *)zoneId
{
    if (!bannerIds)
        return @"";
    NSString *parameterFormat = @"z=%@&b=%@;&g=%@&s=%@&sw=%@&sh=%@&br=%@,%@,%@&r=%@";
    NSString *bannerIdString = [bannerIds componentsJoinedByString:@";"];
    NSString *guid = [self _guid];
    NSString *sessionId = @"-1";
    NSString *browserName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    if (!browserName)
        browserName = @"Unknown";
    NSString *browserVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *screenWidth = [NSString stringWithFormat:@"%i", (NSInteger) NSWidth([[NSScreen mainScreen] frame])];
    NSString *screenHeight = [NSString stringWithFormat:@"%i", (NSInteger) NSHeight([[NSScreen mainScreen] frame])];
    NSString *operatingSystemVersion = [self _systemVersionString];
    srandomdev();
    NSString *randomNumberString = [NSString stringWithFormat:@"%i", random()];
    NSString *parameters = [NSString stringWithFormat:parameterFormat,
                         [zoneId stringValue],
                         bannerIdString,
                         guid,
                         sessionId,
                         screenWidth,
                         screenHeight,
                         browserName,
                         browserVersion,
                         operatingSystemVersion,
                         randomNumberString];

    return parameters;
}

- (NSString *)_cleanBuySellAdsJSON:(NSString *)json
{
    NSString *weirdStart = @"_bsap.interpret_json(";
    if ([json hasPrefix:weirdStart])
    {
        json = [json substringFromIndex:[weirdStart length]];
        json = [json substringToIndex:[json length] - 2];
    }
    return json;
}

// Contents of method was taken from Sparkle's +[SUHost systemVersionString]
- (NSString *)_systemVersionString
{
    // This returns a version string of the form X.Y.Z
	// There may be a better way to deal with the problem that gestaltSystemVersionMajor
	//  et al. are not defined in 10.3, but this is probably good enough.
	NSString* verStr = nil;
#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_4
	SInt32 major, minor, bugfix;
	OSErr err1 = Gestalt(gestaltSystemVersionMajor, &major);
	OSErr err2 = Gestalt(gestaltSystemVersionMinor, &minor);
	OSErr err3 = Gestalt(gestaltSystemVersionBugFix, &bugfix);
	if (!err1 && !err2 && !err3)
	{
		verStr = [NSString stringWithFormat:@"%d.%d.%d", major, minor, bugfix];
	}
	else
#endif
	{
	 	NSString *versionPlistPath = @"/System/Library/CoreServices/SystemVersion.plist";
		verStr = [[NSDictionary dictionaryWithContentsOfFile:versionPlistPath] objectForKey:@"ProductVersion"];
	}
	return verStr;
}

- (NSString *)_guid
{
    // Check to see if we already have a GUID, if so return it.
    NSString *guid = [defaults stringForKey:USER_DEFAULTS_GUID_KEY];
    if (guid)
        return guid;
    
    // Create a GUID
    CFUUIDRef cfUuid = CFUUIDCreate(NULL);
    CFStringRef cfUuidString = CFUUIDCreateString(NULL, cfUuid);
    NSString *uuidString = [(NSString *)cfUuidString lowercaseString];
    CFRelease(cfUuidString);
    CFRelease(cfUuid);
    
    // Save it to defaults
    guid = uuidString;
    [defaults setObject:guid forKey:USER_DEFAULTS_GUID_KEY];
    
    return guid;
}

- (void)_sendRequest:(NSString *)verb
            withData:(NSDictionary *)data
             forPath:(NSString *)subpath
   relativeToBaseUrl:(NSString *)baseUrl
              target:(id)target
            selector:(SEL)sel
{
    [self _sendRequest:verb
              withData:data
               forPath:subpath
     relativeToBaseUrl:baseUrl
                target:target
              selector:sel
               context:nil];
}

- (void)_sendRequest:(NSString *)verb
            withData:(NSDictionary *)data
             forPath:(NSString *)subpath
   relativeToBaseUrl:(NSString *)baseUrl
              target:(id)target
            selector:(SEL)sel
             context:(id)context
{
    NSURL *requestURL =
    [NSURL URLWithString:subpath relativeToURL:[NSURL URLWithString:baseUrl]];
    NSMutableURLRequest *request =
    [NSMutableURLRequest requestWithURL:requestURL];
    [request setHTTPMethod: verb];
    
    if ([data count] != 0)
    {
        [request setHTTPBody:[[data URLEncodedString] dataUsingEncoding:NSUTF8StringEncoding]];
        //NSLog(@"HTTP Request Body = %@", [data URLEncodedString]);
    }
    
    NSURLConnection *connection = [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
    if (!connection)
    {
        NSError *error = [NSError errorWithDomain: @"BSASwitchboardError"
                                             code: 1
                                         userInfo: nil];
        [target performSelector:sel withObject:nil withObject:error];
        return;
    }
    
    CFDictionarySetValue(connectionsData, connection, [NSMutableData data]);
    
    NSValue * selector = [NSValue value: &sel withObjCType: @encode(SEL)];
    NSDictionary * targetInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 selector, @"selector",
                                 target, @"target",
                                 context ? context: [NSNull null], @"context",
                                 nil];
    CFDictionarySetValue(connections, connection, targetInfo);
}

- (void) connection: (NSURLConnection *)connection didReceiveResponse: (NSHTTPURLResponse *)response
{
    NSMutableDictionary * targetInfo = (id)CFDictionaryGetValue(connections, connection);
    [targetInfo setValue: response forKey: @"response"];
}

- (void) connection: (NSURLConnection *)connection didReceiveData: (NSData *)data
{
    NSMutableData * connectionData = (id)CFDictionaryGetValue(connectionsData, connection);
    [connectionData appendData: data];
}

- (void) connection: (NSURLConnection *)connection didFailWithError: (NSError *)error
{
    NSMutableDictionary * targetInfo = (id)CFDictionaryGetValue(connections, connection);
    [targetInfo setValue: error forKey: @"error"];
    [self _returnResponseForConnection: connection];
}

- (void) connectionDidFinishLoading: (NSURLConnection *)connection
{
    [self _returnResponseForConnection: connection];
}

- (void) _returnResponseForConnection: (NSURLConnection *)connection
{
    NSMutableDictionary * targetInfo = (id)CFDictionaryGetValue(connections, connection);
    NSMutableData * data = (id)CFDictionaryGetValue(connectionsData, connection);
    id target = [targetInfo valueForKey: @"target"];
    SEL selector;
    [[targetInfo valueForKey: @"selector"] getValue: &selector];

    NSError *error = nil;
    id errorObject = [targetInfo valueForKey: @"error"];
    if (errorObject != [NSNull null] && [errorObject isKindOfClass:[NSError class]])
    {
        NSHTTPURLResponse * response = [targetInfo valueForKey: @"response"];
        NSInteger status = [response statusCode];
        if (status != 200) error = [NSError errorWithDomain: @"APIError" code: status userInfo: nil];
    }

    NSDictionary * dataDictionary = nil;
    if ([data length] && [error code] != 401) {
        NSString * json = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
        //NSLog(@"got response: %@", json);
        json = [self _cleanBuySellAdsJSON:json];
        dataDictionary = [json BSAJSONValue];
    }
    id context = [targetInfo valueForKey:@"context"];
    if ([context isEqual: [NSNull null]])
        context = nil;
    
    //NSLog(@"buy sell ads returned : %@", dataDictionary);
    [target performSelector: selector withObject: dataDictionary withObject: error withObject: context];
    CFDictionaryRemoveValue(connections, connection);
    CFDictionaryRemoveValue(connectionsData, connection);
}



@end