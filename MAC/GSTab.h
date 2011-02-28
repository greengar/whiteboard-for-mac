//
//  GSTab.h
//  Whiteboard
//
//  Created by GreenGar Studios on 1/21/10.
//  Copyright 2010-2011 Greengar Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TabType.h"


@class GSCircle;

@interface GSTab : NSObject {
	TabType type;
	float pointSize;
	double opacity;
	float x_;
	float y_;
	NSColor *color_;
	
	GSCircle *circle;
	//GSSprayCircle *sprayCircle;
	BOOL isSelected;
	NSView *imageView;
	
	int drawingToolMode;
}

@property(nonatomic, retain)   NSColor *color;
@property(nonatomic, readonly) NSView *view;

@property(nonatomic) int drawingToolMode;

- (id)initEraserWithPointSize:(float)w;
- (id)initPan;
- (id)initZoom;
- (id)initWithType:(TabType)t pointSize:(float)w opacity:(float)o color:(NSColor *)c;

- (void)setSelected;
- (void)setColor:(NSColor *)c x:(float)x y:(float)y;
- (void)setBrushSize2:(float)s;
- (void)setOpacity:(float)o;
- (double)getBrushOpacity;
- (void)setBrushOpacity:(double)o;

- (void)setIndex:(int)index; // load data from persistent store

- (void)showCustomColorPicker;
- (void)updateCustomColorPicker;

@end
