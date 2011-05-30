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
//  BSAZone.m
//  BSAAdFramework
//
//  Created by Rick Fillion on 6/30/10.
//  Copyright 2010 BuySellAds. All rights reserved.
//

#import "BSAZone.h"
#import "BSAAd.h"

@interface BSAZone (Private)

- (void)populateWithDictionary:(NSDictionary *)dictionary;

@end


@implementation BSAZone

@synthesize identifier, siteIdentifier, width, height, ads, numberOfAds, format;
@synthesize showsPlaceholderAd, repeatsPlaceholderAds;

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    if ((self = [super init]))
    {
        [self populateWithDictionary:dictionary];
    }
    return self;
}

- (void)dealloc
{
    self.identifier = nil;
    self.siteIdentifier = nil;
    self.width = nil;
    self.height = nil;
    self.ads = nil;
    [super dealloc];
}
    
#pragma mark  Private

- (void)populateWithDictionary:(NSDictionary *)dictionary
{
    //NSLog(@"populateWithDictionary: %@", dictionary);
    self.identifier = [NSNumber numberWithInt:[(NSString *)[dictionary objectForKey:@"id"] intValue]];
    self.siteIdentifier = [NSNumber numberWithInt:[(NSString *)[dictionary objectForKey:@"siteid"] intValue]];
    self.width = [NSNumber numberWithInt:[(NSString *)[dictionary objectForKey:@"width"] intValue]];
    self.height = [NSNumber numberWithInt:[(NSString *)[dictionary objectForKey:@"height"] intValue]];
    self.numberOfAds = [NSNumber numberWithInt:[(NSString *)[dictionary objectForKey:@"nads"] intValue]];
    self.format = [(NSString *)[dictionary objectForKey:@"format"] intValue];
    self.showsPlaceholderAd = [(NSString *)[dictionary objectForKey:@"showadhere"] intValue] == 1;
    self.repeatsPlaceholderAds = [(NSString *)[dictionary objectForKey:@"repeathere"] intValue] == 1;


    NSArray *newAdsAsDictionaries = [dictionary valueForKeyPath:@"filters.all.ads"];
    NSMutableArray *newAds = [NSMutableArray array];
    for (NSDictionary *newAdAsDictionary in newAdsAsDictionaries)
    {
        BSAAd *ad = [[[BSAAd alloc] initWithDictionary: newAdAsDictionary] autorelease];
        [newAds addObject: ad];
    }
    self.ads = newAds;
}

@end
