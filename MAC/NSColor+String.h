//
//  UIColor+String.h
//  Whiteboard
//
//  Created by Elliot on 6/27/10.
//  Copyright 2010-2011 Greengar Studios. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSColor (String)
- (NSString *)stringWithX:(float)x y:(float)y;
+ (NSColor *)colorFromString:(NSString *)string x:(float *)x y:(float *)y;
@end
