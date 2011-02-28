//
//  NSImage+Alpha.m
//  WhiteboardMac
//
//  Created by silvercast on 12/23/10.
//  Copyright 2010-2011 Greengar Studios. All rights reserved.
//

#import "NSImage+Alpha.h"


@implementation NSImage (Alpha)

+ (NSImage *)imageNamed:(NSString *)name inBundleForClass:(Class)cls {
    NSBundle *bundle = [NSBundle bundleForClass:cls];
    NSString *path = [bundle pathForImageResource:name];
    NSImage *image = nil;
    if ([path length]) {
        NSURL *URL = [NSURL URLWithString:path];
        image = [[[NSImage alloc] initWithContentsOfURL:URL] autorelease];
    } 
    if (!image) {
        DLog(@"%s couldnt load image named %@ in bundle %@\npath %@", __PRETTY_FUNCTION__, name, bundle, path);
    }
    return image;
}


- (NSImage *)scaledImageOfSize:(NSSize)size {
    return [self scaledImageOfSize:size alpha:1];
}


- (NSImage *)scaledImageOfSize:(NSSize)size alpha:(CGFloat)alpha {
    return [self scaledImageOfSize:size alpha:alpha hiRez:YES];
}


- (NSImage *)scaledImageOfSize:(NSSize)size alpha:(CGFloat)alpha hiRez:(BOOL)hiRez {
    return [self scaledImageOfSize:size alpha:alpha hiRez:hiRez clip:nil];
}


- (NSImage *)scaledImageOfSize:(NSSize)size alpha:(CGFloat)alpha hiRez:(BOOL)hiRez cornerRadius:(CGFloat)radius {
    //NSBezierPath *path = TDGetRoundRect(NSMakeRect(0, 0, size.width, size.height), radius, 1);
    //return [self scaledImageOfSize:size alpha:alpha hiRez:hiRez clip:path];
	return [self scaledImageOfSize:size alpha:alpha hiRez:hiRez clip:nil];
}


- (NSImage *)scaledImageOfSize:(NSSize)size alpha:(CGFloat)alpha hiRez:(BOOL)hiRez clip:(NSBezierPath *)path {
    NSImage *result = [[[NSImage alloc] initWithSize:size] autorelease];
    [result lockFocus];
    
    // get context
    NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
    
    // store previous state
    BOOL savedAntialias = [currentContext shouldAntialias];
    NSImageInterpolation savedInterpolation = [currentContext imageInterpolation];
    
    // set new state
    [currentContext setShouldAntialias:YES];
    [currentContext setImageInterpolation:hiRez ? NSImageInterpolationHigh : NSImageInterpolationDefault];
    
    // set clip
    [path setClip];
    
    // draw image
    NSSize fromSize = [self size];
    [self drawInRect:NSMakeRect(0, 0, size.width, size.height) fromRect:NSMakeRect(0, 0, fromSize.width, fromSize.height) operation:NSCompositeSourceOver fraction:alpha];
    
    // restore state
    [currentContext setShouldAntialias:savedAntialias];
    [currentContext setImageInterpolation:savedInterpolation];
    
    [result unlockFocus];
    return result;
}

@end
