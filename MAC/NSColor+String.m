//
//  UIColor+String.m
//  Whiteboard
//
//  Created by Elliot on 6/27/10.
//  Copyright 2010-2011 Greengar Studios. All rights reserved.
//

#import "NSColor+String.h"


@implementation NSColor (String)
- (NSString *)stringWithX:(float)x y:(float)y {
	CGFloat components[4];
	[self getComponents:components];
	NSString *string = [NSString stringWithFormat:@"%f|%f|%f|%f|%f|%f", components[0], components[1], components[2], components[3], x, y];
	return string;
}

// error:(NSError **)error
+ (NSColor *)colorFromString:(NSString *)string x:(float *)x y:(float *)y {
	NSArray *components = [string componentsSeparatedByString:@"|"];
	NSColor *color = [NSColor colorWithCalibratedRed:[[components objectAtIndex:0] floatValue] 
											   green:[[components objectAtIndex:1] floatValue] 
												blue:[[components objectAtIndex:2] floatValue] 
											   alpha:[[components objectAtIndex:3] floatValue]];
	*x = [[components objectAtIndex:4] floatValue];
	*y = [[components objectAtIndex:5] floatValue];
	return color;
}
@end
