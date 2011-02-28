//
//  NSImage+Alpha.h
//  WhiteboardMac
//
//  Created by silvercast on 12/23/10.
//  Copyright 2010-2011 Greengar Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSImage (Alpha)
- (NSImage *)scaledImageOfSize:(NSSize)size;
- (NSImage *)scaledImageOfSize:(NSSize)size alpha:(CGFloat)alpha;
- (NSImage *)scaledImageOfSize:(NSSize)size alpha:(CGFloat)alpha hiRez:(BOOL)hiRez;
- (NSImage *)scaledImageOfSize:(NSSize)size alpha:(CGFloat)alpha hiRez:(BOOL)hiRez cornerRadius:(CGFloat)radius;
- (NSImage *)scaledImageOfSize:(NSSize)size alpha:(CGFloat)alpha hiRez:(BOOL)hiRez clip:(NSBezierPath *)path;
@end

