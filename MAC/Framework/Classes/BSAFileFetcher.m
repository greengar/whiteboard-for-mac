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
//  BSAFileFetcher.m
//  BSAAdFramework
//
//  Created by Chris Verwymeren on 10-04-11.
//  Copyright 2010 BuySellAds. All rights reserved.
//

#import "BSAFileFetcher.h"
#import <Foundation/NSError.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSURLConnection.h>
#import <Foundation/NSURLRequest.h>
#import <Foundation/NSURLResponse.h>


NSString *kFileFetcherConnection = @"connection";
NSString *kFileFetcherCurrentContentLength = @"currentContentLength";
NSString *kFileFetcherExpectedContentLength = @"expectedContentLength";
NSString *kFileFetcherReceivedData = @"receivedData";
NSString *kFileFetcherRequest = @"request";
NSString *kFileFetcherSelector = @"selector";
NSString *kFileFetcherTarget = @"target";

@interface BSAFileFetcher (Private)

//
- (void)closeConnection:(NSURLConnection *)connection;
- (NSURLConnection *)createConnectionWithRequest:(NSURLRequest *)aRequest;
- (NSURLConnection *)createConnectionWithRequest:(NSURLRequest *)aRequest target:(id)aTarget selector:(SEL)aSelector;
- (NSURLConnection *)createConnectionWithURL:(NSURL *)requestURL;
- (NSURLConnection *)createConnectionWithURL:(NSURL *)requestURL target:(id)aTarget selector:(SEL)aSelector;
- (NSMutableDictionary *)infoDictionaryForConnection:(NSURLConnection *)connection;
- (void)removeInfoDictionaryForConnection:(NSURLConnection *)connection;
- (void)setInfoDictionary:(NSMutableDictionary *)infoDictionary forConnection:(NSURLConnection *)connection;

// NSURLConnection Delegate
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;

@end

@implementation BSAFileFetcher (Private)

- (void)closeConnection:(NSURLConnection *)connection
{
    NSMutableDictionary *infoDictionary =
        [self infoDictionaryForConnection:connection];
    if (infoDictionary == nil) { return; }

    NSMutableData *receivedData =
        [infoDictionary objectForKey:kFileFetcherReceivedData];

    id target = [infoDictionary objectForKey:kFileFetcherTarget];
    SEL selector = NSSelectorFromString([infoDictionary objectForKey:kFileFetcherSelector]);

    [target performSelector:selector withObject:receivedData withObject:nil];
}

- (NSURLConnection *)createConnectionWithURL:(NSURL *)requestURL;
{
#ifdef CONFIGURATION_DEBUG
    NSLog(@"[FileFetcher createConnectionWithURL:]");
#endif

    return [self createConnectionWithURL:requestURL target:nil selector:nil];
}

- (NSURLConnection *)createConnectionWithURL:(NSURL *)requestURL target:(id)aTarget selector:(SEL)aSelector
{
#ifdef CONFIGURATION_DEBUG
    NSLog(@"[FileFetcher createConnectionWithURL:target:selector:]");
#endif

    NSMutableURLRequest *request =
        [NSMutableURLRequest requestWithURL:requestURL
                                cachePolicy:cachePolicy
                            timeoutInterval:timeoutInterval];

    return [self createConnectionWithRequest:request target:aTarget selector:aSelector];
}

- (NSURLConnection *)createConnectionWithRequest:(NSURLRequest *)aRequest
{
#ifdef CONFIGURATION_DEBUG
    NSLog(@"[FileFetcher createConnectionWithRequest:]");
#endif

    return [self createConnectionWithRequest:aRequest target:nil selector:nil];
}

- (NSURLConnection *)createConnectionWithRequest:(NSURLRequest *)aRequest target:(id)aTarget selector:(SEL)aSelector
{
#ifdef CONFIGURATION_DEBUG
    NSLog(@"[FileFetcher createConnectionWithRequest:target:selector:]");
#endif

    NSURLConnection *connection =
        [[[NSURLConnection alloc] initWithRequest:aRequest delegate:self] autorelease];
    if (connection == nil)
    {
        [aTarget performSelector:aSelector withObject:nil withObject:nil];
        return nil;
    }

    NSMutableDictionary *infoDictionary =
        [NSMutableDictionary dictionaryWithObjectsAndKeys:
            connection,
            kFileFetcherConnection,
            [NSNumber numberWithUnsignedInteger:0],
            kFileFetcherCurrentContentLength,
            [NSNumber numberWithUnsignedInteger:NSURLResponseUnknownLength],
            kFileFetcherExpectedContentLength,
            aRequest,
            kFileFetcherRequest,
            NSStringFromSelector(aSelector),
            kFileFetcherSelector,
            aTarget,
            kFileFetcherTarget,
            nil
        ];
    [self setInfoDictionary:infoDictionary forConnection:connection];

    return connection;
}

- (NSMutableDictionary *)infoDictionaryForConnection:(NSURLConnection *)connection
{
#ifdef CONFIGURATION_DEBUG
    NSLog(@"[FileFetcher infoDictionaryForConnection:]");
#endif

    id object = [connectionDictionary objectForKey:[NSString stringWithFormat:@"%lu", [connection hash]]];
    if ([object isKindOfClass:[NSMutableDictionary class]])
    {
        return (NSMutableDictionary *)object;
    }

    return nil;
}

- (void)removeInfoDictionaryForConnection:(NSURLConnection *)connection
{
    [connectionDictionary removeObjectForKey:[NSString stringWithFormat:@"%lu", [connection hash]]];
}

- (void)setInfoDictionary:(NSMutableDictionary *)infoDictionary forConnection:(NSURLConnection *)connection
{
    [connectionDictionary setObject:infoDictionary forKey:[NSString stringWithFormat:@"%lu", [connection hash]]];
}

#pragma mark NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
#ifdef CONFIGURATION_DEBUG
    NSLog(@"[FileFetcher didFailWithError:]");
#endif

    NSString *errorString = nil;

#if defined MAC_OS_X_VERSION_10_6 && MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_6
    errorString = NSURLErrorFailingURLStringErrorKey;
#else
    errorString = NSErrorFailingURLStringKey;
#endif
    
    // Log the error
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:errorString]);

    NSMutableDictionary *infoDictionary =
        [self infoDictionaryForConnection:connection];
    if (infoDictionary != nil)
    {
        // Remove any partially retrieved data
        NSMutableData *receivedData =
            [infoDictionary objectForKey:kFileFetcherReceivedData];
        [receivedData setLength:0];
    }

    [self closeConnection:connection];

    // Remove the connection information
    [self removeInfoDictionaryForConnection:connection];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
#ifdef CONFIGURATION_DEBUG
    NSLog(@"[FileFetcher didReceiveData:]");
#endif

    NSMutableDictionary *infoDictionary =
        [self infoDictionaryForConnection:connection];
    if (infoDictionary == nil) { return; }

    NSMutableData *receivedData =
        [infoDictionary objectForKey:kFileFetcherReceivedData];
    if (receivedData == nil)
    {
        receivedData = [NSMutableData data];
        [infoDictionary setObject:receivedData forKey:kFileFetcherReceivedData];
    }

    [receivedData appendData:data];

    NSNumber *currentContentLength =
        [NSNumber numberWithUnsignedInteger:[receivedData length]];
    [infoDictionary setObject:currentContentLength forKey:kFileFetcherCurrentContentLength];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
{
#ifdef CONFIGURATION_DEBUG
    NSLog(@"[FileFetcher didReceiveResponse:]");
#endif

    NSMutableDictionary *infoDictionary =
        [self infoDictionaryForConnection:connection];
    if (infoDictionary == nil) { return; }

    // Reset receivedData
    NSMutableData *receivedData = [NSMutableData data];
    [infoDictionary setObject:receivedData forKey:kFileFetcherReceivedData];

    // Reset currentContentLength
    NSNumber *currentContentLength =
        [NSNumber numberWithUnsignedInteger:[receivedData length]];
    [infoDictionary setObject:currentContentLength forKey:kFileFetcherCurrentContentLength];

    // Reset expectedContentLength
    NSNumber *expectedContentLength =
        [NSNumber numberWithUnsignedInteger:[response expectedContentLength]];
    [infoDictionary setObject:expectedContentLength forKey:kFileFetcherExpectedContentLength];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse;
{
#ifdef CONFIGURATION_DEBUG
    NSLog(@"[FileFetcher connection:willSendRequest:redirectResponse:]");
#endif

    // If the response did not cause a redirect, return the original request.
    if (redirectResponse == nil)
    {
        return request;
    }

    // The response caused a redirect, cancel the current connection and create
    // a new one with the redirect request.
    NSMutableURLRequest *newRequest = [[request mutableCopy] autorelease];

    NSMutableDictionary *infoDictionary =
        [self infoDictionaryForConnection:connection];
    if (infoDictionary != nil)
    {
        NSURLRequest *originalRequest =
            [infoDictionary objectForKey:kFileFetcherRequest];
        if (originalRequest != nil)
        {
            newRequest = [[originalRequest mutableCopy] autorelease];
            [newRequest setURL:[request URL]];
        }
    }

    id target = [infoDictionary objectForKey:kFileFetcherTarget];
    SEL selector = NSSelectorFromString([infoDictionary objectForKey:kFileFetcherSelector]);

    // Create a connection with the new request
    [self createConnectionWithRequest:newRequest target:target selector:selector];

    // Cleanup and cancel the original connection
    [self removeInfoDictionaryForConnection:connection];
    [connection cancel];

    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
#ifdef CONFIGURATION_DEBUG
    NSLog(@"[FileFetcher connectionDidFinishLoading:]");
#endif

    [self closeConnection:connection];

    // Remove the connection information
    [self removeInfoDictionaryForConnection:connection];
}

@end

@implementation BSAFileFetcher

static BSAFileFetcher *fetcher = nil;

#pragma mark Class Methods

+ (id)fetcher
{
    @synchronized(self)
    {
        if (fetcher == nil)
        {
            [[[self alloc] init] autorelease];
        }
    }
    return fetcher;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self)
    {
        if (fetcher == nil)
        {
            fetcher = [super allocWithZone:zone];
            // Assignment and return on first allocation
            return fetcher;
        }
    }

    // On subsequent allocation attempts return nil
    return nil;
}
 
- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}
 
- (NSUInteger)retainCount
{
    // Denotes an object that cannot be released
    return NSUIntegerMax;
}
 
- (void)release
{
    // Do nothing
}
 
- (id)autorelease
{
    return self;
}

#pragma mark Initialization

- (id)init
{
    if (!(self = [super init])) { return nil; }

    cachePolicy = NSURLRequestUseProtocolCachePolicy;
    connectionDictionary = [[NSMutableDictionary alloc] init];
    timeoutInterval = 60.0;

    return self;
}

#pragma mark Deallocation

- (void)dealloc
{
    [connectionDictionary release];
    connectionDictionary = nil;

    [super dealloc];
}

- (void)fetchFileWithUrl:(NSString *)urlString target:(id)aTarget selector:(SEL)aSelector
{
    [self createConnectionWithURL:[NSURL URLWithString:urlString] target:aTarget selector:aSelector];
}

@end
