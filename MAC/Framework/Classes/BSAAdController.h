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
//  AdController.h
//  BSAAdFramework
//
//  Created by Rick Fillion on 10/07/09.
//  Copyright 2009 BuySellAds. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BSAZoneFormat.h"

@class BSAAd;

/**
 @brief Main controller class that interacts with BuySellAds servers.
 
 This is a singleton class, accessible via the +sharedController method.  The first
 step you'll want to do is use the -loadAdsWithKey: method to load your ads from the 
 servers.  In theory that's the only interaction you'll require to do with this class.
  
 */
@interface BSAAdController : NSObject {
    NSMutableDictionary *zones;
}

/// Returns the singleton instance
+ (BSAAdController *)sharedController;
/// Loads ads from the BuySellAds server associated with the specified key.
- (void)loadAdsWithKey:(NSString *)key;
/// Returns all ads for the specified zone identifier, or nil if the zone hasn't been loaded.
- (NSArray *)allAdsForZoneId:(NSNumber *)zoneIdentifier;
/// Returns a specified number of ads.  If the zone doesn't have a sufficient
/// number of ads to not repeat, then placeholder ads are used. Returns nil if the zone hasn't been loaded.
- (NSArray *)randomAdsForZoneId:(NSNumber *)zoneIdentifier howMany:(NSUInteger)howmany;
/// Returns the size (currently based on the image size) for ads in the specified zone identifier, or NSZeroSize if the zone hasn't been loaded.
- (NSSize)sizeForZoneId:(NSNumber *)zoneIdentifier;
/// Returns the number of ads that should appear in a zone with the specified zone identifier, or nil if the zone hasn't been loaded.
- (NSNumber *)numberOfAdsForZoneId:(NSNumber *)zoneIdentifier;
/// Returns the BSAZoneFormat of the zone with specified zone identifier, or NSNotFound if the zone hasn't been loaded.
- (BSAZoneFormat)zoneFormatForZoneId:(NSNumber *)zoneIdentifier;
/// Returns the site identifier for the zone with specified zone identifier, or nil if the zone hasn't been loaded.
- (NSNumber *)siteIdForZoneId:(NSNumber *)zoneIdentifier;
/// Returns the URL used to buy an ad in the zone with specified identifier, or nil if the zone hasn't been loaded.
- (NSString *)buyUrlForZoneId:(NSNumber *)zoneIdentifier;
/// Returns whether to show a placeholder ad in a zone with specified identifier.
- (BOOL)showsPlaceholderAdForZoneId:(NSNumber *)zoneIdentifier;
/// Returns whether to repeate the placeholder ad in a zone with specified identifier.
- (BOOL)repeatsPlaceholderAdsForZoneId:(NSNumber *)zoneIdentifier;

@end
