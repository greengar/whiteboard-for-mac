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
//  BSAAdView+Private.m
//  BSAAdFramework
//
//  Created by Rick Fillion on 7/2/10.
//  Copyright 2010 BuySellAds. All rights reserved.
//

#import "BSAAdView+Private.h"
#import "BSAAd.h"
#import "LTPixelAlign.h"

@implementation BSAAdView (Private)

- (void)customInit
{
    [self setTarget:self];
    [self setAction:@selector(adClicked:)];
    [self setButtonType: NSMomentaryChangeButton];
    [self setBordered:NO];
    [self setTitle:@""];
    [self setImage:[self defaultImage]];
}

- (void)adClicked:(id)sender
{
    if (delegate && ![(id)delegate respondsToSelector:@selector(adClicked:)])
    {
        NSLog(@"delegate set that doesn't respond to adClicked:");
        return;
    }
    [delegate adClicked:self.ad];
}

- (NSImage *)defaultImage
{
    NSImage *image = [[[NSImage alloc] initWithSize:[self bounds].size] autorelease];
    [image lockFocus];
    {
        if (self.ad.identifier)
            [self drawDefaultImageWithString:@"Loading..."];
        else {
            [self drawDefaultImageWithString:@"Advertise Here"];
        }
        
    }
    [image unlockFocus];
    return image;
}

- (void)drawDefaultImageWithString:(NSString *)string
{
    NSColor *borderColor = [NSColor colorWithCalibratedRed:0.756 green:0.756 blue:0.755 alpha:1.000];
    NSColor *bgColor = [NSColor colorWithCalibratedRed:0.883 green:0.883 blue:0.883 alpha:1.000];
    NSColor *textColor = [NSColor colorWithCalibratedRed:0.327 green:0.327 blue:0.327 alpha:1.000];
    
    CGFloat stroke = 1.0;
    NSRect bounds = [self bounds];
    bounds.size.width -= 1.0;
    bounds.origin.y += 0.5;
    bounds.size.height -= 1.0; 
    bounds.origin.x += 0.5;
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:bounds];
    [path setLineWidth:stroke];
    [bgColor set];
    [path fill];
    [borderColor set];
    [path stroke];
    
    NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle
                                                 alloc] init] autorelease];
    [paragraphStyle setAlignment:NSCenterTextAlignment];
    NSDictionary * attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSFont boldSystemFontOfSize:12.0], NSFontAttributeName,
                                 textColor, NSForegroundColorAttributeName,
                                 paragraphStyle, NSParagraphStyleAttributeName,
                                 nil];
    NSRect textRect = [self bounds];
    textRect.size = [string sizeWithAttributes:attributes];
    textRect.origin.y = round(NSHeight([self bounds])/2.0 - textRect.size.height/2.0);
    textRect.size.width = NSWidth([self bounds]);
    [string drawInRect:textRect withAttributes:attributes];
}



@end
