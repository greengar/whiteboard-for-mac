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
//  BSAAdContainerView.m
//  BSAAdFramework
//
//  Created by Rick Fillion on 6/28/10.
//  Copyright 2010 BuySellAds. All rights reserved.
//

#import "BSAAdContainerView.h"
#import "BSAAdController.h"
#import "NSNotificationCenter+BuySellAds.h"
#import "LTPixelAlign.h"
#import "BSAAdView.h"
#import "BSAAdImageView.h"
#import "BSAAdImageAndTextView.h"
#import "BSAAd.h"
#import "BSASwitchboard.h"
#import "BSAZone.h"
#import "BSAAdViewDelegate.h"

@interface BSAAdContainerView (Private)

- (void)refreshAds;
- (void)frameChanged;
- (void)reflowAdViews;
- (NSUInteger)maximumNumberOfAds;

@end


@implementation BSAAdContainerView

@synthesize zoneIdentifier, backgroundColor, bordered, ads, delegate;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        self.backgroundColor = [NSColor colorWithCalibratedWhite:0.1 alpha:0.1];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adsAvailableForZoneIdNotification:) name:BSAAdsAvailableForZoneIdNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsDidChangeNotification:) name:NSViewBoundsDidChangeNotification object:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameDidChangeNotification:) name:NSViewFrameDidChangeNotification object:self];
        [self setPostsFrameChangedNotifications:YES];
        [self setPostsBoundsChangedNotifications:YES];
        self.bordered = YES;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BSAAdsAvailableForZoneIdNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:self];
    [ads release];
    [super dealloc];
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)boundsDidChangeNotification:(NSNotification *)notification
{
    [self frameChanged];
}

- (void)frameDidChangeNotification:(NSNotification *)notification
{
    [self frameChanged];
}

- (void)adsAvailableForZoneIdNotification:(NSNotification *)notification
{
    //NSLog(@"adsAvailableForZoneIdNotification: %@", notification);
    NSDictionary *userInfo = [notification userInfo];
    NSNumber *zoneIdentifierForNewAds = [userInfo objectForKey:@"zoneIdentifier"];
    if (!zoneIdentifierForNewAds || !self.zoneIdentifier)
    {
        return;
    }
    if ([zoneIdentifierForNewAds isEqualToNumber:self.zoneIdentifier])
    {
        //NSLog(@"found new ads for me! (%@)", self.zoneIdentifier);
        //NSArray *adsAvailable = [[BSAAdController sharedController] allAdsForZoneId: self.zoneIdentifier];
        //NSLog(@"ads = %@", adsAvailable);
        [self refreshAds];
    }
}

- (void)setZoneIdentifier:(NSNumber *)aZoneIdentifier
{
    [aZoneIdentifier retain];
    [zoneIdentifier release];
    zoneIdentifier = aZoneIdentifier;
    [self refresh];
}

- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
    
    [[NSColor blueColor] set];
    //NSRectFill([self bounds]);
    
    NSColor *borderColor = [NSColor colorWithCalibratedRed:0.665 green:0.665 blue:0.665 alpha:1.000];
    NSColor *bgColor = self.backgroundColor ? self.backgroundColor : [NSColor clearColor];
    
    CGFloat stroke = 1.0;
    NSRect bounds = [self bounds];
    bounds.size.width -= 1.0;
    bounds.origin.y += 0.5;
    bounds.size.height -= 1.0; 
    bounds.origin.x += 0.5;
    //bounds = [self pixelAlignRect:bounds withStroke:stroke];
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:bounds];
    [path setLineWidth:stroke];
    [bgColor set];
    [path fill];
    [borderColor set];
    if ([self isBordered])
        [path stroke];
}

- (void)refresh
{
    [self refreshAds];
}

- (Class)adViewClass
{
    BSAZoneFormat zoneFormat = [[BSAAdController sharedController] zoneFormatForZoneId:self.zoneIdentifier];
    
    if (zoneFormat == BSAZoneImageFormat)
        return [BSAAdImageView class];
    else if (zoneFormat == BSAZoneImageAndTextFormat)
        return [BSAAdImageAndTextView class];
    else {
        NSLog(@"[BSAAdController adViewClass] encountered a zoneFormat not supported: %i", zoneFormat);
        return nil;
    }
    
}

#pragma mark Private


- (void)refreshAds
{
    [self willChangeValueForKey:@"ads"];
    [ads release];
    NSNumber *howMany = [[BSAAdController sharedController] numberOfAdsForZoneId:self.zoneIdentifier];
    ads = [[BSAAdController sharedController] randomAdsForZoneId:self.zoneIdentifier howMany:[howMany integerValue]];
    [ads retain];    
    [self didChangeValueForKey:@"ads"];
    [self reflowAdViews];
    
    // Register the impressions.
    NSMutableArray *adIdentifiers = [NSMutableArray array];
    for (BSAAd *ad in ads)
    {
        if (ad.identifier)
            [adIdentifiers addObject:ad.identifier];
    }
    [[BSASwitchboard switchboard] registerImpressionForAdIds:adIdentifiers zoneId:self.zoneIdentifier target:self selector:@selector(impressionResponse:error:)];
}

- (void)frameChanged
{
    if ([ads count] < [self maximumNumberOfAds])
    {
        [self refreshAds];
    }
    else {
        [self reflowAdViews];
    }
}

- (void)reflowAdViews
{
    //NSLog(@"reflowAdViews");
    
    // get rid of all the old adViews;
    [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSSize adSize = [[BSAAdController sharedController] sizeForZoneId:self.zoneIdentifier];
    if (NSEqualSizes(adSize, NSZeroSize))
    {
        return;
    }
    
    BSAZoneFormat zoneFormat = [[BSAAdController sharedController] zoneFormatForZoneId:self.zoneIdentifier];
    
    // figure out how many ads we can fit horizontally
    NSUInteger boundsWidth = (NSUInteger)NSWidth([self bounds]);
    NSUInteger boundsHeight = (NSUInteger)NSHeight([self bounds]) - ([self isBordered] ? 2.0 : 0.0);
    NSUInteger adWidth = (NSUInteger)adSize.width;
    if (zoneFormat == BSAZoneImageAndTextFormat)
    {
        adWidth = boundsWidth - 2.0;
    }
    NSUInteger adHeight = (NSUInteger)adSize.height;
    
    NSUInteger maximumNumberOfAds = [self maximumNumberOfAds];
    NSUInteger horizontalAmount = boundsWidth / adWidth;
    if (maximumNumberOfAds < horizontalAmount)
        horizontalAmount = maximumNumberOfAds;
    if (horizontalAmount == 0)
        return; // lets avoid some divide by zero action.
    NSUInteger verticalAmount =  [self maximumNumberOfAds] / horizontalAmount;
    if (maximumNumberOfAds > 0 && verticalAmount == 0)
        verticalAmount = 1;
    
    //NSLog(@"horizontalAmount = %i, verticalAmount = %i", horizontalAmount, verticalAmount);
    
    // figure out spacing between ads
    CGFloat horizontalSpacing = ((CGFloat)(boundsWidth - (adWidth * horizontalAmount))) / ((CGFloat) horizontalAmount+1);
    CGFloat verticalSpacing = ((CGFloat)(boundsHeight - (adHeight * verticalAmount))) / ((CGFloat) verticalAmount+1);
    
    NSPoint origin = NSZeroPoint;
    origin.y = ([self isBordered] ? 1.0 : 0.0) + verticalSpacing;
    NSInteger adIndex = 0;
    Class adViewClass = [self adViewClass];
    for (int v = 0; v < verticalAmount; v++)
    {
        origin.x = horizontalSpacing;
        for (int h = 0; h < horizontalAmount; h++)
        {
            if (adIndex < [ads count])
            {
                NSRect frameRect = NSMakeRect(origin.x, origin.y, adWidth, adHeight);
                frameRect = [self pixelAlignRect:frameRect withStroke:0];
                //NSLog(@"creating new BSAAdView for zone id %@ with frame %@", self.zoneIdentifier, NSStringFromRect(frameRect));
                BSAAdView *adView =  [[(BSAAdView *)[adViewClass alloc] initWithFrame:frameRect] autorelease];
                adView.ad = [ads objectAtIndex:adIndex];
                adView.delegate = self;
                [self addSubview:adView];
                origin.x += adSize.width + horizontalSpacing;
            }
            adIndex++;
        }
        origin.y += adSize.height + verticalSpacing;
    }
}

- (NSUInteger)maximumNumberOfAds
{
    NSSize adSize = [[BSAAdController sharedController] sizeForZoneId:self.zoneIdentifier];
    if (NSEqualSizes(adSize, NSZeroSize))
    {
        return 0;
    }
    
    BSAZoneFormat zoneFormat = [[BSAAdController sharedController] zoneFormatForZoneId:self.zoneIdentifier];
    
    // figure out how many ads we can fit horizontally
    NSUInteger boundsWidth = (NSUInteger)NSWidth([self bounds]);
    NSUInteger boundsHeight = (NSUInteger)NSHeight([self bounds]);
    NSUInteger adWidth = (NSUInteger)adSize.width;
    if (zoneFormat == BSAZoneImageAndTextFormat)
    {
        adWidth = boundsWidth - 2.0;
    }
    NSUInteger adHeight = (NSUInteger)adSize.height;
    
    NSUInteger horizontalAmount = boundsWidth / adWidth;
    
    NSUInteger verticalAmount = boundsHeight / adHeight;
    NSUInteger maxAmountThatCanFit = horizontalAmount * verticalAmount;
    //NSLog(@"%i %i %i %i", horizontalAmount, verticalAmount, adWidth, adHeight);
    
    NSInteger proposedNumberOfAdsForZone = [[[BSAAdController sharedController] numberOfAdsForZoneId:self.zoneIdentifier] integerValue];
    NSInteger actualNumberofAdsAvailableForZone = [[[BSAAdController sharedController] allAdsForZoneId:self.zoneIdentifier] count];
    BOOL showsPlaceholderAds = [[BSAAdController sharedController] showsPlaceholderAdForZoneId:self.zoneIdentifier];
    BOOL repeatsPlaceholderAds = [[BSAAdController sharedController] repeatsPlaceholderAdsForZoneId:self.zoneIdentifier];
    
    NSUInteger maximumNumberOfAds = 0;
    
    if (proposedNumberOfAdsForZone <= actualNumberofAdsAvailableForZone)
    {
        // We have more ads than what the advertiser wants.  So now we just need to 
        // Figure out if we can fit that many in the view
        if (maxAmountThatCanFit < proposedNumberOfAdsForZone)
            maximumNumberOfAds = maxAmountThatCanFit;
        else
            maximumNumberOfAds = proposedNumberOfAdsForZone;
    }
    else {
        // There aren't enough ads.
        if (!showsPlaceholderAds)
        {
            // Doesn't want placeholders so just use what we have.
            maximumNumberOfAds = actualNumberofAdsAvailableForZone;
        }
        else {
            // Does want placeholders
            if (!repeatsPlaceholderAds)
            {
                // Only wants one placeholder
                maximumNumberOfAds =  actualNumberofAdsAvailableForZone + 1;
            }
            else {
                // Wants as many placeholders as will fit, up to the max proposed
                if (maxAmountThatCanFit < proposedNumberOfAdsForZone)
                    maximumNumberOfAds = maxAmountThatCanFit;
                else 
                    maximumNumberOfAds = proposedNumberOfAdsForZone;
            }
        }
    }
    return maximumNumberOfAds;
}


#pragma mark BSAAdViewDelegate

- (void)adClicked:(BSAAd *)ad;
{
    //NSLog(@"ad clicked:  %@", ad);
    if (ad.identifier)
    {
        // It's a real ad.
        BOOL shouldHandle = YES;
        if (self.delegate && [(id)self.delegate respondsToSelector:@selector(adContainerView:shouldHandleClickOfAd:)])
        {
            shouldHandle = [self.delegate adContainerView:self shouldHandleClickOfAd:ad];
        }
        
        if (shouldHandle)
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ad.url]];
        
        // Report the click
        [[BSASwitchboard switchboard] registerClickForAdId:ad.identifier zoneId:self.zoneIdentifier target:self selector:@selector(clickResponse:error:)];
    }
    else {
        // It's a spot that's for sale.
        NSString *urlString = [[BSAAdController sharedController] buyUrlForZoneId:self.zoneIdentifier];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
    }
}

#pragma mark BSASwitchboard Responses

// Click and Impression responses return gif data which throws JSON for a loop.
// It'll always return an error.

- (void)clickResponse:(id)response error:(NSError *)error
{

}

- (void)impressionResponse:(id)response error:(NSError *)error
{

}

@end
