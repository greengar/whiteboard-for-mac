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
//  BSAAd.m
//  BSAAdFramework
//
//  Created by Rick Fillion on 10/07/09.
//  Copyright 2009 BuySellAds. All rights reserved.
//

#import "BSAAd.h"
#import "BSAFileFetcher.h"
#import "BSASwitchboard.h"
#import "NSMutableArray+Additions.h"

@interface BSAAd (Private)

- (void)populateWithDictionary:(NSDictionary *)dictionary;

@end


@implementation BSAAd

@synthesize identifier, url, imageUrl, image, title, text;

+ (BSAAd *)placeholder
{
    BSAAd *placeholderAd = [[[BSAAd alloc] init] autorelease];
    placeholderAd.identifier = nil;
    placeholderAd.image = nil;
    placeholderAd.url = nil;
    placeholderAd.text = @"";
    placeholderAd.title = @"";
    return placeholderAd;
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init])
    {
        [self populateWithDictionary:dictionary];
    }
    return self;
}

- (void) dealloc
{
    [image release];
    [imageUrl release];
    [url release];
    [identifier release];
    [subads release];
    [super dealloc];
}



- (void)updateImage:(NSData *)data error:(NSError *)error
{
    if (error)
        return;
    NSImage *newImage = [[[NSImage alloc] initWithData: data] autorelease];
    if (!newImage)
        return;
    
    self.image = newImage;
}


- (BSAAd *)adOrSubAd
{
    if (!subads || [subads count] == 0)
    {
        return self;
    }
    
    NSMutableArray *shuffledAds = [NSMutableArray arrayWithArray: subads];
    [shuffledAds shuffle];
    
    return [shuffledAds objectAtIndex:0];
}
         

#pragma mark Private

- (void)populateWithDictionary:(NSDictionary *)dictionary
{
    // check to see if they have multiple pieces of creative
    NSArray *subadDictionaries = [dictionary valueForKey:@"ads"];
    if (!subadDictionaries)
    {
        //NSLog(@"populateWithDictionary: %@", dictionary);
        self.identifier = [dictionary valueForKey:@"id"];
        self.url = [dictionary valueForKey:@"link"];
        self.imageUrl = [dictionary valueForKey:@"img"];
        self.title = [dictionary valueForKey:@"alt"];
        self.text = [dictionary valueForKey:@"text"];
        [[BSAFileFetcher fetcher] fetchFileWithUrl:self.imageUrl target:self selector:@selector(updateImage: error:)];
    }
    else {
        // fill in with placeholder info, just in case something goes wrong later.
        BSAAd *placeholder = [BSAAd placeholder];
        self.identifier = placeholder.identifier;
        self.image = placeholder.image;
        self.url = placeholder.url;
        self.text = placeholder.text;
        self.title = placeholder.title;
        NSMutableArray *ads = [NSMutableArray array];
        for (NSDictionary *ad in subadDictionaries)
        {
            BSAAd *subad  = [[[BSAAd alloc] initWithDictionary:ad] autorelease];
            [ads addObject:subad];
        }
        subads = [ads retain];
    }
}

@end
