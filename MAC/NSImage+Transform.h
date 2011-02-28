//
//  NSImage+Transform.h
//  WhiteboardMac
//
//  Created by Silvercast on 12/3/10.
//  Copyright 2010-2011 Greengar Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSImage(Transform)

+ (NSImage *)rotateIndividualImage: (NSImage *)image clockwise: (BOOL)clockwise;

@end
