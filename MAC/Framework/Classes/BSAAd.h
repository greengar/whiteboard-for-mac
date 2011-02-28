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
//  BSAAd.h
//  BSAAdFramework
//
//  Created by Rick Fillion on 10/07/09.
//  Copyright 2009 BuySellAds. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 @brief The BSAAd class is the model class used to represent ads in BuySellAds.
 
 */
@interface BSAAd : NSObject {
    NSNumber *identifier;
    NSString *url;
    NSString *imageUrl;
    NSImage *image;
    NSString *title;
    NSString *text;
    NSArray *subads;
}

/// Unique identifier for the ad
@property (nonatomic, retain) NSNumber *identifier;
/// URL associated with the ad
@property (nonatomic, copy) NSString *url;
/// URL to the image file associated with the ad
@property (nonatomic, copy) NSString *imageUrl;
/// Image associated with the ad (loaded asynchronously upon initialization)
@property (nonatomic, retain) NSImage *image;
/// Title associated with the ad ("alt" property)
@property (nonatomic, copy) NSString *title;
/// Text associated with the ad ("text" property)
@property (nonatomic, copy) NSString *text;

/// Returns a placeholder ad that has its properties set to nil
+ (BSAAd *)placeholder;
/// Initializer used to create a BSAAd based on the JSON response from BuySellAds
/// converted into a NSDictionary
- (id)initWithDictionary:(NSDictionary *)dictionary;
/// Returns either self if the ad has no subads, or a random subad if the ad
/// contains any subads.  You should use this method instead of assuming that
/// a BSAAd instance is a full ad.
- (BSAAd *)adOrSubAd;

@end
