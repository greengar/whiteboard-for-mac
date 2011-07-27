//
//  MainPaintingView.h
//  WhiteboardMac
//
//  Created by Silvercast on 11/4/10.
//  Copyright 2010-2011 Greengar Studios. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PaintingView.h"
#include <math.h>

#define kScreenWidth  1024
#define kScreenHeight 768

@interface MainPaintingView : PaintingView {
	NSPoint pointInView;
	NSPoint pointBeganInView;
    NSPoint pointStartAutomaticZoom;
	
	NSMutableArray * undoImageArray;
	NSMutableArray * redoImageArray;
	BOOL isReceivingStroke;
	BOOL isDrawingStroke;

    // multitouch drawing
    float       initialTouchLocation[2];
    BOOL        followingTouches;
    BOOL        panningTouches;
    
	// Fix opacity range of Whiteboard MAC
	BOOL isEndOfDrawingLine;
	
	BOOL isBeing180Rotated;
}

@property (nonatomic, readonly) NSMutableArray * undoImageArray;
@property (nonatomic, readonly) NSMutableArray * redoImageArray;

- (void)rotate180Degree;

- (BOOL)loadRemoteImageWithHexString:(NSString*)imageHexString;

- (void)receiveBeginStroke;
- (void)receiveEndStroke;
- (void)receiveUndoRequest;
- (void)receiveRedoRequest;
- (void)undoStroke;
- (void)redoStroke;
- (void)pushScreenToUndoStack;

- (void)zoomInAfterToolBarClick;
- (void)zoomOutAfterToolBarClick;
- (BOOL)zoomInable;
- (BOOL)zoomOutable;

- (void)renderLocalLineFromPoint:(NSPoint)start toPoint:(NSPoint)end;
@end
