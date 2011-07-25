//
//  PaintingView.h
//  WhiteboardMac
//
//  Created by Silvercast on 11/4/10.
//  Copyright 2010-2011 Greengar Studios. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#import <OpenGL/glu.h>

#define kDocumentWidth 1024
#define kDocumentHeight 768

typedef struct {
	unsigned char red;
	unsigned char green;
	unsigned char blue;
	unsigned char alpha;
} pixelStruct;

typedef struct {
	GLdouble x,y;
    GLdouble zoomLevel;
} Transforms;


@interface PaintingView : NSOpenGLView {
//	GLuint textureId;
	GLuint screenTextureId;
	GLuint backgroundTextureId;
	GLuint borderTextureId;
	GLuint framebufferId;
	
	BOOL isImageSent;
	
	// camera handling
	Transforms transforms;
	
	// Fix black color when undo
	BOOL isStartToDrawAndNeedErase;
}

- (void)erase;
- (BOOL)loadImage:(CGImageRef)image;
- (void) drawObject;
- (void)setColor:(CGFloat[4])components;
- (void)renderLineFromPoint:(NSPoint)start toPoint:(NSPoint)end;
- (CGImageRef)glToCGImageCreate;
- (NSImage *) glToNSImage;
- (BOOL)loadRemoteImageWithHexString:(NSString*)imageHexString;
- (void)loadTextureFromBuffer:(void*)buffer width:(int)width height:(int)height;

- (CGImageRef)CGRemoteImageRotate:(CGImageRef)imgRef;
- (void)rotateScreenTexture180degree;

- (void) resetCamera;
@end
