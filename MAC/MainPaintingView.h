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
	
	NSMutableArray * undoImageArray;
	NSMutableArray * redoImageArray;
	BOOL isReceivingStroke;
	BOOL isDrawingStroke;

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
- (void)pushScreenToUndoStack:(CGImageRef)image;
- (void)pushScreenToRedoStack:(CGImageRef)image;
- (void)releaseRedoStack;

- (void)mousePan:(NSPoint)location;
- (void)mousePanWithVector: (NSPoint) location;

- (void)mouseZoom:(GLfloat)aperture;
- (void)mouseZoomWithClick:(NSPoint)location;
- (void)performZoom:(GLfloat)ratio atCenter:(NSPoint)center;

- (NSPoint) pointWithoutCameraEffect:(NSPoint)original;
- (NSPoint) pointWithCameraEffect:(NSPoint)original;
- (NSPoint) pointAfterZoomAtCenter:(NSPoint)original withRatio:(GLfloat)ratio;
- (NSPoint) pointToTexture:(NSPoint)original;
- (NSPoint) pointFromTexture:(NSPoint)original;

- (void)renderLocalLineFromPoint:(NSPoint)start toPoint:(NSPoint)end;
@end
