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
//  BSAAdImageAndTextView.m
//  BSAAdFramework
//
//  Created by Rick Fillion on 7/2/10.
//  Copyright 2010 BuySellAds. All rights reserved.
//

#import "BSAAdImageAndTextView.h"
#import "BSAAdView+Private.h"
#import "BSAAdImageView+Private.h"
#import "BSAMiddleAlignedTextField.h"
#import "BSAAd.h"


@implementation BSAAdImageAndTextView

@synthesize titleTextField, descriptionTextField;

- (void)customInit
{
    [super customInit];
    descriptionTextField = [[BSAMiddleAlignedTextField alloc] initWithFrame:NSZeroRect];
    [descriptionTextField setBordered:NO];
    [descriptionTextField setDrawsBackground:NO];
    [descriptionTextField setEditable:NO];
    [self addSubview:descriptionTextField];
    titleTextField = [[BSAMiddleAlignedTextField alloc] initWithFrame:NSZeroRect];
    [titleTextField setFont:[NSFont boldSystemFontOfSize:14.0]];
    [titleTextField setBordered:NO];
    [titleTextField setDrawsBackground:NO];
    [titleTextField setEditable:NO];
    [self addSubview: titleTextField];
    [self setImagePosition:NSImageLeft];
    textPadding = 3.0;
}

- (void)dealloc
{
    [descriptionTextField removeFromSuperview];
    [descriptionTextField release];
    [titleTextField removeFromSuperview];
    [titleTextField release];
    [super dealloc];    
}

- (void)setAd:(BSAAd *)newAd
{
    [super setAd:newAd];
    [titleTextField setStringValue:ad.title ? ad.title : @""];
    [descriptionTextField setStringValue:ad.text ? ad.text : @""];

    [self updateTextFieldFrames];
}

- (void)updateTextFieldFrames
{
    // Start by making them big so that we can figure out how big they need to be.
    NSRect largeFrame = [self bounds];
    NSSize adSize = [self.ad.image size];
    
    largeFrame.size.width -= adSize.width + 2*textPadding;
    largeFrame.origin.x += adSize.width + textPadding;

    [descriptionTextField setFrame:largeFrame];
    [titleTextField setFrame:largeFrame];
    
    NSRect descriptionDrawingRectForBounds = [(BSAMiddleAlignedTextField *)descriptionTextField cellDrawingRectForBounds];
    NSRect titleDrawingRectForBounds = [(BSAMiddleAlignedTextField *)titleTextField cellDrawingRectForBounds];
    
    NSRect descriptionFrame = largeFrame;
    NSRect titleFrame = largeFrame;
    
    descriptionFrame.size.height = descriptionDrawingRectForBounds.size.height;
    titleFrame.size.height = titleDrawingRectForBounds.size.height;
    
    NSInteger totalHeight = NSHeight([self bounds]) - textPadding*2;
    NSInteger interiorPadding = 2.0/5.0 * (totalHeight - NSHeight(descriptionFrame) - NSHeight(titleFrame));
    
    titleFrame.origin.y = textPadding + interiorPadding;
    descriptionFrame.origin.y = titleFrame.origin.y + titleFrame.size.height + interiorPadding/2;
    
    [descriptionTextField setFrame:descriptionFrame];
    [titleTextField setFrame:titleFrame];
}

#pragma mark BSAAdImageView+Private Overrides

- (void)updateImage
{
    [super updateImage];
    [self updateTextFieldFrames];
}

@end
