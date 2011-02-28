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
//  BSAAdContainerView.h
//  BSAAdFramework
//
//  Created by Rick Fillion on 6/28/10.
//  Copyright 2010 BuySellAds. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BSAAdView.h"
#import "BSAAdViewDelegate.h"

@class BSAAd;
@class BSAAdContainerView;

/**
 @brief The BSAAdContainerViewDelegate protocol defines the optional methods implemented by delegates of BSAAdContainerView objects.

 */
@protocol BSAAdContainerViewDelegate

/** Sent to the delegate before the container handles the click of an ad.  
 Return NO if the container should not handle it, if for example the 
 delegate will handle it itself.
 */
- (BOOL)adContainerView:(BSAAdContainerView*)adContainerView shouldHandleClickOfAd:(BSAAd *)ad;

@end


/**
 @brief Main view class that will displays ads loaded by BSAAdController.
 
 There is one required property to set in order to use BSAAdContainerView, which
 is the zoneIdentifier property.  
 
 BSAAdContainerView does only basic drawing itself (a background color, and a
 border).  You may find it suitable to subclass it to do custom drawing in 
 -drawRect:.  
 
 */
@interface BSAAdContainerView : NSView <BSAAdViewDelegate> {
    NSNumber *zoneIdentifier;
    NSColor *backgroundColor;
    NSArray *ads;
    id<BSAAdContainerViewDelegate> delegate;
    BOOL bordered;
}

/// The unique zone identifier
@property (nonatomic, retain) NSNumber *zoneIdentifier;
/// The background color used to draw behind ads
@property (nonatomic, retain) NSColor *backgroundColor;
/// Controls whether the container view draws its border or not
@property (nonatomic, assign, getter=isBordered) BOOL bordered;
/// Ads currently being displayed in this container view
@property (nonatomic, readonly) NSArray *ads;
/// delegate
@property (nonatomic, assign) id<BSAAdContainerViewDelegate> delegate;


/**
 @brief Randomly chooses ads to display in the view. 
 
 Randomly chooses ads to display in the view based on what was loaded in the 
 BSAAdController.  You may choose to periodically call this method using
 a timer to display different ads (or different orders of ads) in your 
 application.
 
 */
- (void)refresh;

/**
 @brief Returns the BSAAdView subclass that will be used for ads.
 
 The default implementation of this method looks up the zone format for
 the zone associated with this BSAAdContainerView, and will return 
 either BSAAdImageView for image-only ads or BSAAdImageAndTextView
 for Image and Text ads.
 
 */
- (Class)adViewClass;

@end
