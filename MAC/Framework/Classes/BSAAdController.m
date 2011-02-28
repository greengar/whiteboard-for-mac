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
//  AdController.m
//  BSAAdFramework
//
//  Created by Rick Fillion on 10/07/09.
//  Copyright 2009 BuySellAds. All rights reserved.
//

#import "BSAAdController.h"
#import "NSMutableArray+Additions.h"
#import "BSAAd.h"
#import "BSAZone.h"
#import "BSASwitchboard.h"
#import "NSNotificationCenter+BuySellAds.h"


@interface BSAAdController (Private)

- (NSString *)keyForZoneId:(NSNumber *)zoneId;

@end


static BSAAdController *sharedController = nil;

@implementation BSAAdController

+ (BSAAdController *)sharedController
{
    if (!sharedController) [self new];
    return sharedController;
}

- (id)init
{
    [super init];
    if (sharedController) {
        [self release];
        return sharedController;
    }
    if (self)
    {
        zones = [[NSMutableDictionary dictionary] retain];
    }
    sharedController = self;
    return self;
}

- (void)dealloc
{
    [zones release];
    [super dealloc];
}

- (void)loadAdsWithKey:(NSString *)key
{
    //DLog(@"loadAdsWithKey: %@", key);
    [[BSASwitchboard switchboard] adsForKey:key target:self selector:@selector(returnedAds: error:)];
}

- (void)returnedAds:(NSDictionary *)adsAsDictionary error:(NSError *)error
{
    //NSLog(@"returnedAds: %@ error: %@", adsAsDictionary, error);
    if (error || !adsAsDictionary)
        return;
    NSArray *zoneDictionaries = [adsAsDictionary valueForKey:@"zones"];
    for (NSDictionary *zoneDictionary in zoneDictionaries)
    {
        NSNumber *zoneIdentifier = [NSNumber numberWithInt:[(NSString *)[zoneDictionary objectForKey:@"id"] intValue]];
        BSAZone *zone = [[[BSAZone alloc] initWithDictionary:zoneDictionary] autorelease];
        [zones setObject:zone forKey:[self keyForZoneId:zoneIdentifier]];
        [[NSNotificationCenter defaultCenter] postNotificationAdsAvailableForZoneId:zoneIdentifier];
    }
}

- (NSArray *)allAdsForZoneId:(NSNumber *)zoneIdentifier;
{
    BSAZone *zone = [zones objectForKey:[self keyForZoneId:zoneIdentifier]];
    if (!zone)
        return nil;
    
    NSArray *adsArray = zone.ads;
    if (adsArray) {
        return adsArray;
    }
    return [NSArray array];
}

- (NSArray *)randomAdsForZoneId:(NSNumber *)zoneIdentifier howMany:(NSUInteger)howmany;
{
    NSArray *ads = [self allAdsForZoneId:zoneIdentifier];
    if (!ads)
        return nil;
    NSMutableArray *shuffledAds = [NSMutableArray arrayWithArray: ads];
    [shuffledAds shuffle];
    NSMutableArray *returnedAds = [NSMutableArray arrayWithCapacity: howmany];
    
    for (NSUInteger idx = 0; idx < howmany; idx++)
    {
        if (idx < [shuffledAds count])
        {
            BSAAd *ad = [shuffledAds objectAtIndex: idx % [shuffledAds count]];
            [returnedAds addObject: [ad adOrSubAd]];
        }
        else {
            [returnedAds addObject:[BSAAd placeholder]];
        }
        
    }
    
    return [[returnedAds copy] autorelease];
}

- (NSSize)sizeForZoneId:(NSNumber *)zoneIdentifier
{
    BSAZone *zone = [zones objectForKey:[self keyForZoneId:zoneIdentifier]];
    if (!zone)
        return NSZeroSize;
    
   // NSLog(@"sizeForZoneId: %@ returning %@", zoneIdentifier, NSStringFromSize(NSMakeSize([zone.width floatValue], [zone.height floatValue])));
    return NSMakeSize([zone.width floatValue], [zone.height floatValue]);
}

- (NSNumber *)numberOfAdsForZoneId:(NSNumber *)zoneIdentifier
{
    BSAZone *zone = [zones objectForKey:[self keyForZoneId:zoneIdentifier]];
    if (!zone)
        return nil;
    
    return zone.numberOfAds;
}

- (BSAZoneFormat)zoneFormatForZoneId:(NSNumber *)zoneIdentifier
{
    BSAZone *zone = [zones objectForKey:[self keyForZoneId:zoneIdentifier]];
    if (!zone)
        return NSNotFound;
    return zone.format;
}

- (NSNumber *)siteIdForZoneId:(NSNumber *)zoneIdentifier
{
    BSAZone *zone = [zones objectForKey:[self keyForZoneId:zoneIdentifier]];
    if (!zone)
        return nil;
    return zone.siteIdentifier;
}

- (NSString *)buyUrlForZoneId:(NSNumber *)zoneIdentifier
{
    BSAZone *zone = [zones objectForKey:[self keyForZoneId:zoneIdentifier]];
    if (!zone)
        return nil;
    return [NSString stringWithFormat:@"http://buysellads.com/buy/detail/%@/zone/%@", zone.siteIdentifier, zone.identifier];
}

- (BOOL)showsPlaceholderAdForZoneId:(NSNumber *)zoneIdentifier
{
    BSAZone *zone = [zones objectForKey:[self keyForZoneId:zoneIdentifier]];
    return zone.showsPlaceholderAd;
}

- (BOOL)repeatsPlaceholderAdsForZoneId:(NSNumber *)zoneIdentifier
{
    BSAZone *zone = [zones objectForKey:[self keyForZoneId:zoneIdentifier]];
    return zone.repeatsPlaceholderAds;
}


/*
- (NSArray *)ads:(NSInteger)howmany
{
    NSMutableArray *shuffledAds = [NSMutableArray arrayWithArray: ads];
    [shuffledAds shuffle];
    NSMutableArray *returnedAds = [NSMutableArray arrayWithCapacity: howmany];
    
    for (NSInteger idx = 0; idx < howmany; idx++)
    {
        if (idx < [shuffledAds count])
        {
            BSAAd *ad = [shuffledAds objectAtIndex: idx % [shuffledAds count]];
            [returnedAds addObject: [ad adOrSubAd]];
        }
        else {
            [returnedAds addObject:[BSAAd placeholder]];
        }

    }
    
    NSMutableArray  *identifiers = [NSMutableArray array];
    for (BSAAd *ad in returnedAds)
    {
        if (ad.identifier)
            [identifiers addObject:ad.identifier];
    }
    [[BSASwitchboard switchboard] registerImpressionForBannerIds:identifiers target:self selector:@selector(impressionResponse:error:)];

    
    return [[returnedAds copy] autorelease];
}*/

/*
- (void)impressionResponse:(id)response error:(NSError *)error
{
    //NSLog(@"impression got response: %@ error: %@", response, error);
}*/

#pragma mark Private

- (NSString *)keyForZoneId:(NSNumber *)zoneId
{
    return [NSString stringWithFormat:@"%@", [zoneId stringValue]];
}

@end
