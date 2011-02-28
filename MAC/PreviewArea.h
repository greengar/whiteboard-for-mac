//
//  PreviewArea.h
//  Whiteboard
//
//  Created by Elliot Lee on 1/7/09.
//  Copyright 2010-2011 Greengar Studios. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PreviewArea : NSView {
	CGFloat widthRadius;
}

@property(nonatomic, readwrite) CGFloat widthRadius;

- (void)setWidthRadius:(CGFloat)radius;

@end
