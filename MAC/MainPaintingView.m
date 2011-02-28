//
//  MainPaintingView.m
//  WhiteboardMac
//
//  Created by Silvercast on 11/4/10.
//  Copyright 2010-2011 Greengar Studios. All rights reserved.
//

#import "MainPaintingView.h"
#import "GSTouchData.h"
#import "WhiteboardMacAppDelegate.h"

#define kUndoMaxBuffer 10


GLboolean gDolly = GL_FALSE;
GLboolean gPan = GL_FALSE;
GLint gDollyPanStartPoint[2] = {0, 0};

@implementation MainPaintingView

@synthesize undoImageArray, redoImageArray;

- (void)eraseAndAddToUndoImageArray {
	[super erase];
	
	CGImageRef image = [super glToCGImageCreate];
	[undoImageArray addObject:(id)image];
}

- (id)initWithFrame:(NSRect)frame {
	if ((self = [super initWithFrame:frame])) {
		
		// this does nothing on MacBook Core Duo / Intel GMA 950:
//		[super erase];
		// do it in -eraseAndAddToUndoImageArray instead
		
		isReceivingStroke = FALSE;
		isDrawingStroke = FALSE;
		undoImageArray = [[NSMutableArray alloc] init];
		
		// this crashes on MacBook Core Duo / Intel GMA 950:
//		CGImageRef image = [super glToCGImageCreate];
//		[undoImageArray addObject:(id)image];
		
		// this doesn't crash:
		[self performSelector:@selector(eraseAndAddToUndoImageArray) withObject:nil afterDelay:0];
		
		redoImageArray = [[NSMutableArray alloc] init];
	
		// Fix opacity range of Whiteboard MAC
		isEndOfDrawingLine = FALSE;
		
		isBeing180Rotated = FALSE;
	}
	return self;
}

- (void)rotate180Degree {
	
	[self rotateScreenTexture180degree];

	[self setNeedsDisplay:YES];
	isBeing180Rotated = !isBeing180Rotated;
}

- (void)mouseDown:(NSEvent *)theEvent {
    [super mouseDown:theEvent];
	
	// Release redo stack
	if ([redoImageArray count] >= 0) {
		[self releaseRedoStack];
	}
	
	if ([theEvent modifierFlags] & NSControlKeyMask || [NSAppDelegate getMode] == panMode) { // send to pan
		// Change to pan Cursor
		[[NSCursor panCursor] set];
		[self rightMouseDown:theEvent];
	}
	else if ([NSAppDelegate getMode] == zoomMode) {
		// Change to zoom Cursor
		[[NSCursor zoomCursor] set];
		pointInView = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		
	}
	else if ([theEvent modifierFlags] & NSAlternateKeyMask) { // send to dolly
		// Temporary use arrow Cursor
		[[NSCursor arrowCursor] set];
		[self otherMouseDown:theEvent];
	}
	else {
		// Temporary use arrow Cursor
		[[NSCursor arrowCursor] set];
		gDolly = GL_FALSE; // no dolly
		gPan = GL_FALSE; // no pan
		
		pointInView = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		pointBeganInView = [self convertPoint:[theEvent locationInWindow] fromView:nil];		

		pointInView.x += -camera.viewPos.x;
		pointInView.y += camera.viewPos.y;
		pointInView.x /= camera.aperture;
		pointInView.y /= camera.aperture;
		
		pointBeganInView.x += -camera.viewPos.x;
		pointBeganInView.y += camera.viewPos.y;
		pointBeganInView.x /= camera.aperture;
		pointBeganInView.y /= camera.aperture;
		
		isDrawingStroke = TRUE;
		[AppDelegate sendBeginStroke];
	}
	
}

// ---------------------------------

- (void)rightMouseDown:(NSEvent *)theEvent // pan
{
	NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	camera.viewHeight = 768;
	location.y = camera.viewHeight - location.y;
	gDolly = GL_FALSE; // no dolly
	gPan = GL_TRUE; 
	gDollyPanStartPoint[0] = location.x;
	gDollyPanStartPoint[1] = location.y;
}

/*
- (void)mouseMoved: (NSEvent *)theEvent {
	DLog(@"mouseMoved working");
	[super mouseMoved:theEvent];
}*/

- (void)scrollWheel:(NSEvent *)theEvent
{
    float wheelDelta = [theEvent deltaX] + [theEvent deltaY] + [theEvent deltaZ];
    if (wheelDelta)
    {
		GLfloat deltaAperture = 0;
		if (fabs([theEvent deltaX]) >= fabs([theEvent deltaY])) {
			deltaAperture = wheelDelta * -camera.aperture / 200.0f;
		}
		else {
			deltaAperture = wheelDelta * camera.aperture / 200.0f;
		}
        camera.aperture += deltaAperture;
        if (camera.aperture < 0.2) // do not let aperture <= 0.2
            camera.aperture = 0.2;
        if (camera.aperture > 4.9) // do not let aperture >= 5.0
            camera.aperture = 4.9;
        //[self updateProjection]; // update projection matrix
        [self setNeedsDisplay: YES];
    }
}

- (void)performZoom: (NSPoint) location {
	float wheelDelta = pointInView.x - location.x + pointInView.y - location.y;
	GLfloat deltaAperture = wheelDelta * -camera.aperture / 200.0f;
	camera.aperture += deltaAperture;
	if (camera.aperture < 0.2) // do not let aperture <= 0.2
		camera.aperture = 0.2;
	if (camera.aperture > 4.9) // do not let aperture >= 5.0
		camera.aperture = 4.9;
	[self setNeedsDisplay: YES];
}

// move camera in x/y plane
- (void)mousePan: (NSPoint) location
{
	GLfloat panX = (gDollyPanStartPoint[0] - location.x) ;/// (1024.0f / -camera.viewPos.z);
	GLfloat panY = (gDollyPanStartPoint[1] - location.y) ;/// (768.0f / -camera.viewPos.z);
	camera.viewPos.x -= panX;
	camera.viewPos.y -= panY;
	gDollyPanStartPoint[0] = location.x;
	gDollyPanStartPoint[1] = location.y;
	
}

- (void)mouseDragged:(NSEvent *)theEvent {
	//DLog(@"dragged");
    // determine if I handle theEvent
    // if not...
    [super mouseDragged:theEvent];
	
	// Release redo stack
	if ([redoImageArray count] >= 0) {
		[self releaseRedoStack];
	}
	
	if (gDolly) {
//		[self mouseDolly: location];
//		[self updateProjection];  // update projection matrix (not normally done on draw)
//		[self setNeedsDisplay: YES];
	} else if (gPan) {
		NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		location.y = camera.viewHeight - location.y;
		[self mousePan: location];
		[self setNeedsDisplay: YES];
	} else if ([NSAppDelegate getMode] == zoomMode) {
		[self scrollWheel:theEvent];
		NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		[self performZoom:location];
	} else {
		
		NSPoint locationInView = [self convertPoint:[theEvent locationInWindow]	fromView:nil];
		
		locationInView.x += -camera.viewPos.x;
		locationInView.y += camera.viewPos.y;
		locationInView.x /= camera.aperture;
		locationInView.y /= camera.aperture;
		
		NSPoint start2 = NSMakePoint(self.frame.size.height - pointInView.y, pointInView.x);
		NSPoint end2 = NSMakePoint(self.frame.size.height - locationInView.y, locationInView.x);
		
		// Fix opacity range of Whiteboard MAC
		CGFloat trueColorAndOpacity[4];
		trueColorAndOpacity[0] = [AppDelegate getRedValue];
		trueColorAndOpacity[1] = [AppDelegate getGreenValue];
		trueColorAndOpacity[2] = [AppDelegate getBlueValue];
		trueColorAndOpacity[3] = [AppDelegate getAlphaValue];
		CGFloat opacity = trueColorAndOpacity[3];
		
		trueColorAndOpacity[3] = 1.0 - powf(1.0 - trueColorAndOpacity[3], 1.0 / (2.0 * [AppDelegate getPointSize]));
		glColor4f(trueColorAndOpacity[0], trueColorAndOpacity[1], trueColorAndOpacity[2], trueColorAndOpacity[3]);
		
		//	DLog(@"%f", trueColorAndOpacity[3]);
		
		[AppDelegate setTrueColorAndOpacity:trueColorAndOpacity];
		
		if (isBeing180Rotated) {
			start2.x = kDocumentWidth - start2.x;	start2.y = kDocumentHeight - start2.y;
			end2.x = kDocumentWidth - end2.x;	end2.y = kDocumentHeight - end2.y;
		}
		
		[AppDelegate sendLineFromPoint:start2 toPoint:end2];
		
		if (AppDelegate.usingRemotePointSize || AppDelegate.usingRemoteColor) { // performance optimization
			//[AppDelegate changePointSize];
			AppDelegate.usingRemotePointSize = NO;
			[AppDelegate setMyColorSend:NO]; // BUGFIX
		}
		
		
		[self renderLocalLineFromPoint:pointInView toPoint:locationInView];
		
		
		pointInView = locationInView;
		
		// Fix opacity range of Whiteboard MAC
		trueColorAndOpacity[3] = opacity;
		[AppDelegate setTrueColorAndOpacity:trueColorAndOpacity];
		isEndOfDrawingLine = TRUE;
		
	}
}

- (void)mouseUp:(NSEvent *)theEvent {
	
	// Back to arrow Cursor
	[[NSCursor arrowCursor] set];

    // determine if I handle theEvent
    // if not...
    [super mouseUp:theEvent];
	
	if (gDolly) { // end dolly
		gDolly = GL_FALSE;
	} else if (gPan) { // end pan
		gPan = GL_FALSE;
		
		[super reshape];

	} else {
		
		NSPoint locationInView = [self convertPoint:[theEvent locationInWindow]	fromView:nil];
		
		locationInView.x += -camera.viewPos.x;
		locationInView.y += camera.viewPos.y;
		locationInView.x /= camera.aperture;
		locationInView.y /= camera.aperture;
		
		if( (pointBeganInView.x == locationInView.x) && (pointBeganInView.y == locationInView.y)) {
			
			// Fix opacity range of Whiteboard MAC
            //KONG: I commented this if, this caused a bug of drawing a white point, after drawing a line
//			if (!isEndOfDrawingLine) {
				CGFloat trueColorAndOpacity[4];
				trueColorAndOpacity[0] = [AppDelegate getRedValue];
				trueColorAndOpacity[1] = [AppDelegate getGreenValue];
				trueColorAndOpacity[2] = [AppDelegate getBlueValue];
				trueColorAndOpacity[3] = [AppDelegate getAlphaValue];
				glColor4f(trueColorAndOpacity[0], trueColorAndOpacity[1], trueColorAndOpacity[2], trueColorAndOpacity[3]);
//			}
			
			NSPoint p1 = locationInView;
			
			if (isBeing180Rotated) {
				p1.x = kDocumentWidth - p1.x;	p1.y = kDocumentHeight - p1.y;
			}
			
			NSPoint pp = NSMakePoint(self.frame.size.height - p1.y, p1.x);
			
			[AppDelegate sendLineFromPoint:pp toPoint:pp];
			
			if (AppDelegate.usingRemotePointSize || AppDelegate.usingRemoteColor) { // performance optimization
				//[AppDelegate changePointSize];
				AppDelegate.usingRemotePointSize = NO;
				[AppDelegate setMyColorSend:NO]; // BUGFIX
			}
			
			[self renderLocalLineFromPoint:locationInView toPoint:locationInView];
			
			// Fix opacity range of Whiteboard MAC
			isEndOfDrawingLine = FALSE;
		}
		
		isDrawingStroke = FALSE;
		[AppDelegate sendEndStroke];
		if (!isReceivingStroke) {
			
			[self pushScreenToUndoStack];
			
		}
		
	}
}

- (void)receiveBeginStroke
{
	DLog(@"begin stroke receive!");
	isReceivingStroke = TRUE;
}

- (void)receiveEndStroke
{
	isReceivingStroke = FALSE;
	if (!isDrawingStroke) {
		[self performSelectorOnMainThread:@selector(pushScreenToUndoStack) withObject:nil waitUntilDone:YES];
		//[self pushScreenToUndoStack];
	}
	DLog(@"end stroke receive!");
}

- (void)pushScreenToUndoStack {
	CGImageRef image = [super glToCGImageCreate];
	[undoImageArray addObject:(id)image];
	if ([undoImageArray count] > kUndoMaxBuffer) {
		
		CGImageRef img = (CGImageRef)[undoImageArray objectAtIndex:0];
		[undoImageArray removeObjectAtIndex:0];
		CGImageRelease(img);
	}
}

// Use together with Redo Stack
- (void)pushScreenToUndoStack:(CGImageRef)image {
	[undoImageArray addObject:(id)image];
	if ([undoImageArray count] > kUndoMaxBuffer) {
		
		CGImageRef img = (CGImageRef)[undoImageArray objectAtIndex:0];
		[undoImageArray removeObjectAtIndex:0];
		CGImageRelease(img);
	}
}

// Use together with Undo Stack
- (void)pushScreenToRedoStack:(CGImageRef) image{
	[redoImageArray addObject:(id)image];
	if ([redoImageArray count] > kUndoMaxBuffer) {
		
		CGImageRef img = (CGImageRef)[redoImageArray objectAtIndex:0];
		[redoImageArray removeObjectAtIndex:0];
		CGImageRelease(img);
	}
}

- (void)rejectedSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
}

- (void)undoStroke {
	if ([undoImageArray count] <= 1) {
		DLog(@"can't undo anymore!");
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:[NSString stringWithFormat:@"You can't undo any more!"]];
		[alert setAlertStyle:NSInformationalAlertStyle];
		[alert setIcon:[NSImage imageNamed:kAlertIcon]];
		[alert runModal];
		[alert release];
		return;
	}
	
	DLog(@"number of image in undo stack: %u", [undoImageArray count]);
	CGImageRef img = (CGImageRef)[undoImageArray objectAtIndex:[undoImageArray count] - 2];
	if (!img) {
		DLog(@"why!");
		return;
	}

	if ([self loadImage:img]) {	
	//	[super erase];
		[self drawObject];
	}
	
	CGImageRef img2 = (CGImageRef)[undoImageArray lastObject];
	
	// Push to redo stack
	[self pushScreenToRedoStack:img2];
	
	[undoImageArray removeLastObject];
	
	[AppDelegate sendUndoRequest];
}

- (void)redoStroke {
	if ([redoImageArray count] <= 0) {
		DLog(@"Can't redo anymore!");
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:[NSString stringWithFormat:@"You can't redo any more!"]];
		[alert setAlertStyle:NSInformationalAlertStyle];
		[alert setIcon:[NSImage imageNamed:kAlertIcon]];
		[alert runModal];
		[alert release];
		return;
	}
	
	CGImageRef img = (CGImageRef)[redoImageArray lastObject];
	
	if ([self loadImage:img]) {	
		[self drawObject];
	}
	
	// Push to undo stack
	[self pushScreenToUndoStack:img];
	
	[redoImageArray removeLastObject];
	
	[AppDelegate sendRedoRequest];
}

- (void)receiveUndoRequest
{
	if ([undoImageArray count] <= 1) {
		DLog(@"can't undo anymore!");
//		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"You can't undo any more!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//		[alert show];
//		[alert release];
		return;
	}
	
	DLog(@"number of image in undo stack: %d", [undoImageArray count]);
	CGImageRef img = (CGImageRef)[undoImageArray objectAtIndex:[undoImageArray count] - 2];
	if (!img) {
		DLog(@"why!");
		return;
	}
	
	if ([self loadImage:img]) {	
		[self drawObject];
	}

	CGImageRef img2 = (CGImageRef)[undoImageArray lastObject];

	// Push to redo stack
	[self pushScreenToRedoStack:img2];
	
	[undoImageArray removeLastObject];
}

- (void)receiveRedoRequest
{
	if ([redoImageArray count] <= 0) {
		DLog(@"Can't redo anymore!");
		return;
	}
	
	DLog(@"Number of image in redo stack: %d", [redoImageArray count]);
	CGImageRef img = (CGImageRef)[redoImageArray objectAtIndex:[redoImageArray count] - 1];
	if (!img) {
		DLog(@"why!");
		return;
	}
	
	if ([self loadImage:img]) {	
		[self drawObject];
	}
	
	CGImageRef img2 = (CGImageRef)[redoImageArray lastObject];

	// Push to redo stack
	[self pushScreenToUndoStack:img2];
	
	[redoImageArray removeLastObject];
}

- (void)renderLocalLineFromPoint:(NSPoint)start toPoint:(NSPoint)end {
	[super renderLineFromPoint:start toPoint:end];
}


- (void)renderLineFromPoint:(NSPoint)start toPoint:(NSPoint)end {
	// render in landscape mode
	

	
	NSPoint start2 = NSMakePoint(start.y, self.frame.size.height - start.x);
	NSPoint end2 = NSMakePoint(end.y, self.frame.size.height - end.x);
	
	
	
	if (isBeing180Rotated) {
		start2.x = kDocumentWidth - start2.x;	start2.y = kDocumentHeight - start2.y;
		end2.x = kDocumentWidth - end2.x;	end2.y = kDocumentHeight - end2.y;
	}
	
//	start2.x += -camera.viewPos.x;
//	start2.y += -camera.viewPos.y;
//	end2.x += -camera.viewPos.x;
//	end2.y += -camera.viewPos.y;	
	
	[super renderLineFromPoint:start2 toPoint:end2];
//	[super renderLineFromPoint:start toPoint:end];
}

- (BOOL)loadRemoteImageWithHexString:(NSString*)imageHexString {
	BOOL result = [super loadRemoteImageWithHexString:imageHexString];
	
	return result;
}

- (void)releaseRedoStack {
	while ([redoImageArray count]) {
		CGImageRef img = (CGImageRef)[redoImageArray lastObject];
		CGImageRelease(img);
		[redoImageArray removeLastObject];
	}
	[redoImageArray removeAllObjects];
}

- (void)erase {
	[super erase];
	
	// clear undoImageArray
	while ([undoImageArray count]) {
		CGImageRef img = (CGImageRef)[undoImageArray lastObject];
		CGImageRelease(img);
		[undoImageArray removeLastObject];
	}
	[undoImageArray removeAllObjects];
	
	
	[self releaseRedoStack];
	
	CGImageRef image = [super glToCGImageCreate];
	[undoImageArray addObject:(id)image];
}

@end
