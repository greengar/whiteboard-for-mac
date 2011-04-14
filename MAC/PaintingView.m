//
//  PaintingView.m
//  WhiteboardMac
//
//  Created by Silvercast on 11/4/10.
//  Copyright 2010-2011 Greengar Studios. All rights reserved.
//

#import "WhiteboardMacAppDelegate.h"
#import "PaintingView.h"
#import "NSImage+Transform.h"

#define degreesToRadian(x) (3.14159265358979323846 * x / 180.0)
#define kMaxPointSize			32.0

// Fix Fullscreen image on connection iPhone to iMac
#define AppDelegate          ((WhiteboardMacAppDelegate *)[NSApplication sharedApplication].delegate)
#define iPhoneHeight			960
#define iPhoneWidth				640
#define iPhoneAndiMacXOffset	32
#define iPhoneAndiMacYOffset	64

recVec gOrigin = {0.0, 0.0, 0.0};

@implementation PaintingView

//SHERWIN: The following functions are just for hex/byte conversions
static inline int hexCharToInt(char hexChar){
	switch (hexChar) {
		case '0':
			return 0;
		case '1':
			return 1;
		case '2':
			return 2;
		case '3':
			return 3;
		case '4':
			return 4;
		case '5':
			return 5;
		case '6':
			return 6;
		case '7':
			return 7;
		case '8':
			return 8;
		case '9':
			return 9;
			
		case 'A':
			return 10;
		case 'a':
			return 10;
			
		case 'B':
			return 11;
		case 'b':
			return 11;
			
		case 'C':
			return 12;
		case 'c':
			return 12;
			
		case 'D':
			return 13;
		case 'd':
			return 13;
			
		case 'E':
			return 14;
		case 'e':
			return 14;
			
			
		case 'F':
			return 15;
		case 'f':
			return 15;
			
		default:
			DLog(@"HEX TO INT: Bad conversion!");
			return -1;
	}
}

static inline int hexCharsToByteValue(char c1, char c2){
	return 16 * hexCharToInt(c1) + hexCharToInt(c2);
}


- (id)initWithFrame:(NSRect)frame {
	
	isImageSent = FALSE;
	
	// Fix black color when undo
	isStartToDrawAndNeedErase = TRUE;
	NSOpenGLPixelFormatAttribute   att[] =
	{
		NSOpenGLPFAWindow,
		//NSOpenGLPFADoubleBuffer,
		NSOpenGLPFANoRecovery,
		NSOpenGLPFAColorSize, 24,
		NSOpenGLPFAAlphaSize,  8,
		0
	};
	
	NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:att]; 
	
	// preserveBackbuffer is actually ignored
	//if(self = [super initWithFrame:frame pixelFormat:[NSOpenGLView defaultPixelFormat]]) {
	if(self = [super initWithFrame:frame pixelFormat:pixelFormat]) {

		[self resetCamera];
		[[self openGLContext] makeCurrentContext];
		glDisable(GL_DITHER);

		glEnable(GL_TEXTURE_2D);
		glEnableClientState(GL_VERTEX_ARRAY);
	    glEnable(GL_BLEND);
		
		glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA ); // almost works - looks the same as sherwin's?

		glClearColor(1.0f, 1.0f, 1.0f, 1.0f);

		//[self erase];

		
		// prepare gray backgroundTexture
		glGenTextures( (GLsizei) 1, &backgroundTextureId ); 
		glBindTexture( GL_TEXTURE_2D, backgroundTextureId );
		
		// the texture wraps over at the edges (repeat)
		glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
		glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
		
		const unsigned int backgroundWidth = 1;
		const unsigned int backgroundHeight = 1;
		const unsigned int backgroundArea = backgroundWidth * backgroundHeight; //kDocumentWidth * kDocumentHeight
		
		const unsigned int nbytes = 4; 
		unsigned char * backgroundData = (unsigned char *)malloc( backgroundArea * nbytes ); 
		memset( backgroundData, 0xcc, backgroundArea * nbytes );
		
		gluBuild2DMipmaps( GL_TEXTURE_2D, // 0,
						  GL_RGB, backgroundWidth, backgroundHeight, // 0,
						  GL_RGBA, GL_UNSIGNED_BYTE, backgroundData ); 
		free(backgroundData);
		
		
		// prepare dark borderTexture
		glGenTextures( (GLsizei) 1, &borderTextureId ); 
		glBindTexture( GL_TEXTURE_2D, borderTextureId );
		
		// the texture wraps over at the edges (repeat)
		glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
		glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
		
		unsigned char * borderData = (unsigned char *)malloc( backgroundArea * nbytes ); // (kDocumentWidth + 4) * (kDocumentHeight + 4)
		memset( borderData, 0x50, backgroundArea * nbytes ); // (kDocumentWidth + 4) * (kDocumentHeight + 4)
		
		gluBuild2DMipmaps( GL_TEXTURE_2D, // 0,
						  GL_RGB, backgroundWidth, backgroundHeight //kDocumentWidth + 4, kDocumentHeight + 4
						  , // 0,
						  GL_RGBA, GL_UNSIGNED_BYTE, borderData ); 

		free(borderData);
		
#if DEBUG
		GLint  texSize;
		glGetIntegerv( GL_MAX_TEXTURE_SIZE, &texSize );
		DLog( @"GL_MAX_TEXTURE_SIZE %d\n", (int)texSize );
		// 8192 on Mac mini Core 2 Duo
		// 2048 on MacBook Core Duo
		
		const GLubyte * strExt;
		GLboolean isFBOSupported;
		strExt = glGetString (GL_EXTENSIONS); 
		isFBOSupported = gluCheckExtension ((const GLubyte*)"GL_EXT_framebuffer_object",strExt); 
		
		if (isFBOSupported) {
			DLog(@"FBO is supported");
		} else {
			DLog(@"FBO is unsupported");
		}


		
#endif
		
		glGenFramebuffersEXT(1, &framebufferId);
		// Set up the FBO with one texture attachment
		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, framebufferId);

		
		// prepare screenTexture
		glGenTextures( (GLsizei) 1, &screenTextureId ); 
		glBindTexture( GL_TEXTURE_2D, screenTextureId );
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

//		const unsigned int nbytes = 3; 
		unsigned char * data = (unsigned char *)malloc( kDocumentWidth * kDocumentWidth * nbytes ); 
		memset( data, 0xff, kDocumentWidth * kDocumentWidth * nbytes );

		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, kDocumentWidth, kDocumentWidth, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
		glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, screenTextureId, 0);
		gluBuild2DMipmaps( GL_TEXTURE_2D, // 0,
							GL_RGB, kDocumentWidth, kDocumentWidth, // 0,
							GL_RGBA, GL_UNSIGNED_BYTE, data ); 
		
		free(data);
		
		GLenum status = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);
		
		if (status != GL_FRAMEBUFFER_COMPLETE_EXT) {
			DLog(@"error when binding framebuffer object");
			exit(1);
		}
		
		glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE );
		
	}
	
	[pixelFormat release];

	return self;
}

- (void)rotateScreenTexture180degree {
	DLog();
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, framebufferId);
	glBindTexture( GL_TEXTURE_2D, screenTextureId );
	
	const unsigned int nbytes = 4; 

	// glGetTexImage only works with arrays whose sizes are power-of-two 
	// so we have to allocate a 1024x1024 array

	pixelStruct potTextureData[kDocumentWidth * kDocumentWidth];
	memset( potTextureData, 0xff, kDocumentWidth * kDocumentWidth * nbytes );
		
	// copy texture data to potTextureData
	glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, potTextureData);
	
	// rotate 180 degree means reversing the array
	for (int i = 0; i < kDocumentWidth*kDocumentWidth/2; ++i) {
		pixelStruct tmp = potTextureData[i];
		potTextureData[i] = potTextureData[kDocumentWidth*kDocumentWidth - 1 - i];
		potTextureData[kDocumentWidth*kDocumentWidth - 1 - i] = tmp;
	}
	
	pixelStruct * actualbmdata = (pixelStruct *)malloc(kDocumentWidth * kDocumentWidth * nbytes);	
	
	memset( actualbmdata, 0xff, kDocumentWidth * kDocumentWidth * nbytes );
	
	// copy to actualbmData, from (kDocumentWidth-kDocumentHeight)*kDocumentWidth offset
	memcpy( actualbmdata, &potTextureData[(kDocumentWidth-kDocumentHeight)*kDocumentWidth], kDocumentWidth * kDocumentHeight * nbytes );
	gluBuild2DMipmaps( GL_TEXTURE_2D, 
						GL_RGB, kDocumentWidth, kDocumentWidth,
						GL_RGBA, GL_UNSIGNED_BYTE, actualbmdata ); 	
	
	free(actualbmdata);
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
}

- (void)setColor:(CGFloat[4])components {
	
	[[super openGLContext] makeCurrentContext];
	
	glColor4f(components[0], components[1], components[2], components[3]);
	[[self openGLContext] update];
}

// Drawings a line onscreen based on where the user touches
- (void) renderLineFromPoint:(NSPoint)start toPoint:(NSPoint)end
{

	//DLog(@"%s hasUnsavedChanges = YES", _cmd);
	//hasUnsavedChanges = YES;
	
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, framebufferId);

	//[[self openGLContext] makeCurrentContext];
	glLoadIdentity(); 
	
	//glTranslatef(camera.viewPos.x, -camera.viewPos.y, 0);

	if (isStartToDrawAndNeedErase) {
		[self erase];
		isStartToDrawAndNeedErase = FALSE;
	}
	
	GLfloat radius = NSAppDelegate.pointSize;
	NSUInteger circleSides = 2 * M_PI * radius;
	NSUInteger numVertices = circleSides * 2;
	GLfloat vertices[numVertices];
	
	NSUInteger	i, j, count;
	
	GLfloat	xOffset, yOffset;
	//float kBrushPixelStep = 1.0f;
	// Add points to the buffer so there are drawing points every X pixels
	count = MAX(ceilf(sqrtf((end.x - start.x) * (end.x - start.x) + (end.y - start.y) * (end.y - start.y)) / kBrushPixelStep), 1);
	//DLog(@"count:%d", count);
	for(i = 0; i < count; ++i) {
		//DLog(@"i:%d", i);
		
		xOffset = start.x + (end.x - start.x) * ((GLfloat)i / (GLfloat)count);
		yOffset = start.y + (end.y - start.y) * ((GLfloat)i / (GLfloat)count);
		//DLog(@"xOffset=%f yOffset=%f", xOffset, yOffset);
		// careful... I changed <= to < because it was overwriting i somehow!
		for(j = 0; j < numVertices; j+=2)
		{
			//GLfloat xOffset = end.x;// + radius; //(firstTouch.x > lastTouch.x) ? lastTouch.x + xradius : firstTouch.x + xradius;
			//GLfloat yOffset = end.y;// + radius; //(self.frame.size.height - firstTouch.y > self.frame.size.height - lastTouch.y) ? self.frame.size.height - lastTouch.y + yradius : self.frame.size.height - firstTouch.y + yradius;
			
			vertices[j] = (cos(degreesToRadian(j * 360 / numVertices))*radius) + xOffset;
			vertices[j+1] = (sin(degreesToRadian(j * 360 / numVertices))*radius) + yOffset;
			
		}
		glVertexPointer (2, GL_FLOAT , 0, vertices);	
		glDrawArrays (GL_TRIANGLE_FAN, 0, circleSides);
		
	}
	
	// update screen texture for further rendering
	glBindTexture( GL_TEXTURE_2D, screenTextureId );
	//glCopyTexSubImage2D( GL_TEXTURE_2D, 0, 0, 0, camera.viewPos.x, -camera.viewPos.y, kDocumentWidth, kDocumentHeight );
	glCopyTexSubImage2D( GL_TEXTURE_2D, 0, 0, 0, 0, 0, kDocumentWidth, kDocumentHeight );
	  
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);

	GLenum err = glGetError();
    if (err != GL_NO_ERROR)
        DLog(@"glGetError(): %d", (int)err);
	
	// Display the buffer
	[self setNeedsDisplay:YES];
}

// Erases the screen
- (void)erase {
//	[[self openGLContext] makeCurrentContext];
//	
//	// Clear the buffer
//	glClear(GL_COLOR_BUFFER_BIT);
//	
//	// update screen texture for further rendering
//	glBindTexture( GL_TEXTURE_2D, screenTextureId );
//	glCopyTexSubImage2D( GL_TEXTURE_2D, 0, 0, 0, camera.viewPos.x, -camera.viewPos.y, kDocumentWidth, kDocumentHeight );

	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, framebufferId);
	
	pixelStruct* buffer = (pixelStruct *)malloc(kDocumentWidth * kDocumentWidth * 4);
	memset(buffer, 0xff, kDocumentWidth * kDocumentWidth * 4 );
	
	[self loadTextureFromBuffer:buffer width:kDocumentWidth height:kDocumentWidth];

	free(buffer);
	
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
	
	// Display the buffer
	[self setNeedsDisplay:YES];
}


-(void)drawRect:(NSRect)rect {
	DLog();
//	DLog(@"%@", NSStringFromRect(rect));
//	{{0, 0}, {1024, 768}}
//	{{0, 0}, {1177, 802}}
//	{{0, 0}, {1143, 875}}
	
	GLfloat borderVertices[8] = {	
		1024+4, 0.0f,
		1024+4, 768+4,
		0.0f,	768+4,
		0.0f,	0.0f 
	};
	
	GLfloat borderTextureCoord[8] = { 
		1.0f, 0.0f, 
		1.0f, 0.754f,
		0.0f, 0.754f,
		0.0f, 0.0f};
	
	GLfloat backgroundVertices[8] = {	
		rect.size.width, 0.0f,
		rect.size.width, rect.size.height,
		0.0f,	rect.size.height,
		0.0f,	0.0f 
	};
	
	GLfloat quatVertices[8] = {	
		1024, 0.0f,
		1024, 768,
		0.0f,	768,
		0.0f,	0.0f 
	};
	
	GLfloat textureCoord[8] = { 
		1.0f, 0.0f, 
		1.0f, 0.75f,
		0.0f, 0.75f,
		0.0f, 0.0f};
	
	
	glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
	//glClearColor(0.8f, 0.8f, 0.8f, 1.0f);
	// Clear the buffer
	glClear(GL_COLOR_BUFFER_BIT);

	glLoadIdentity(); 

	glPushMatrix();
	//Enable texturing
	// configure texture environment
	glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE ); 
	glEnable( GL_TEXTURE_2D );
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	
	
	glBindTexture( GL_TEXTURE_2D, backgroundTextureId );
	glColor4f(1.0f,1.0f, 1.0f, 1.0f);
	glVertexPointer(2, GL_FLOAT, 0, backgroundVertices);
	glTexCoordPointer(2, GL_FLOAT, 0, textureCoord);
	glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
	
	glTranslatef(camera.viewPos.x-2, camera.viewPos.y-2, 0);
	glScalef(camera.aperture, camera.aperture, 1.0);
	glBindTexture( GL_TEXTURE_2D, borderTextureId );
	glColor4f(1.0f,1.0f, 1.0f, 1.0f);
	glVertexPointer(2, GL_FLOAT, 0, borderVertices);
	glTexCoordPointer(2, GL_FLOAT, 0, borderTextureCoord);
	glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
	
	glLoadIdentity(); 
	glTranslatef(camera.viewPos.x, camera.viewPos.y, 0);
	glScalef(camera.aperture, camera.aperture, 1.0);
	
	glBindTexture( GL_TEXTURE_2D, screenTextureId );
	
	
	glColor4f(1.0f,1.0f, 1.0f, 1.0f);
	glVertexPointer(2, GL_FLOAT, 0, quatVertices);
	glTexCoordPointer(2, GL_FLOAT, 0, textureCoord);
	glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
	
	//Disable texturing
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisable(GL_TEXTURE_2D);	
					  
	glPopMatrix();
	
	// complete rendering & swap 
	glFlush();
	[[self openGLContext] flushBuffer];
    GLenum err = glGetError();
    if (err != GL_NO_ERROR)
        DLog(@"glGetError(): %d", (int)err);
}

void releaseScreenshotData(void *info, const void *data, size_t size) {
	free((void *)data);
};


- (CGImageRef)glToCGImageCreate {
	int backingWidth  = kDocumentWidth;
	int backingHeight = kDocumentHeight;
	const unsigned int nbytes = 4; 
	
	glBindTexture( GL_TEXTURE_2D, screenTextureId );
	
	pixelStruct * potTextureData = (pixelStruct *)malloc(backingWidth * backingWidth * nbytes);
	memset( potTextureData, 0xff, backingWidth * backingWidth * nbytes );
	
	// copy texture data to potTextureData
	glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, potTextureData);
	
	NSInteger myDataLength = backingWidth * backingHeight * nbytes;	// GL_RGBA
	pixelStruct *buffer = (pixelStruct *) malloc(myDataLength);
	// copy to actualbmData, from (kDocumentWidth-kDocumentHeight)*kDocumentWidth offset
	memcpy( buffer, potTextureData, myDataLength );
	
	// gl renders "upside down" so swap top to bottom into new array.
	
	int y;
	for(y = 0; y < backingHeight / 2; y++) {
		int x;
		for(x = 0; x < backingWidth; x++) {
			//Swap top and bottom bytes
			pixelStruct top = buffer[y * backingWidth + x];
			pixelStruct bottom = buffer[(backingHeight - 1 - y) * backingWidth + x];
			buffer[(backingHeight - 1 - y) * backingWidth + x] = top;
			buffer[y * backingWidth + x] = bottom;
		}
	}
	
	// make data provider with data.
	CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, myDataLength, releaseScreenshotData);
	
	// prep the ingredients
	const int bitsPerComponent = 8;
	const int bitsPerPixel = 4 * bitsPerComponent;
	const int bytesPerRow = 4 * backingWidth;
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNone;
	
	CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
	
	// make the cgimage
	CGImageRef imageRef = CGImageCreate(backingWidth, backingHeight, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent); // 320, 480
	CGColorSpaceRelease(colorSpaceRef);
	CGDataProviderRelease(provider);
	
	free(potTextureData);
	
	return imageRef;
}

// Create a blank image with width and height
- (CGImageRef)glCGBlankImageCreate:(int)backingWidth :(int)backingHeight {
	
	int nBytes = 4; // 3 for RGB, 4 for RGBA
	
	NSInteger myDataLength = backingWidth * backingHeight * nBytes;
	pixelStruct *buffer = (pixelStruct *) malloc(myDataLength);
	memset(buffer, 0xff, backingWidth * backingHeight * nBytes);
	
	// Create blank white image
	for (int i = 0; i < backingWidth * backingHeight; ++i) {
		pixelStruct temp = {255, 255, 255, 255};
		buffer[i] = temp;
	}
	
	// make data provider with data.
	CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, myDataLength, releaseScreenshotData);
	
	// prep the ingredients
	const int bitsPerComponent = 8;
	const int bitsPerPixel = nBytes * bitsPerComponent;
	const int bytesPerRow = nBytes * backingWidth;
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrder16Big | kCGImageAlphaNoneSkipLast;
	
	CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
	
	// make the cgimage
	CGImageRef imageRef = CGImageCreate(backingWidth, backingHeight, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent); // 320, 480
	CGColorSpaceRelease(colorSpaceRef);
	CGDataProviderRelease(provider);
	
	return imageRef;
}

- (NSImage *) glToNSImage {
	CGImageRef imageRef = [self glToCGImageCreate];
	
	NSSize size = NSMakeSize(kDocumentWidth, kDocumentHeight);
	// then make the UIImage from that
	NSImage *myImage = [[NSImage alloc] initWithCGImage:imageRef size:size];
	CGImageRelease(imageRef);
	
	return myImage;
}

- (CGImageRef)CGRemoteImageRotate:(CGImageRef)imgRef {
	CGFloat angleInRadians = -90 * (M_PI / 180);
	CGImageRef blankImage = [self glCGBlankImageCreate:kDocumentHeight:kDocumentWidth];
	CGFloat width = CGImageGetWidth(blankImage);
	CGFloat height = CGImageGetHeight(blankImage);
	
	CGRect imgRect = CGRectMake(0, 0, width, height);
	CGAffineTransform transform = CGAffineTransformMakeRotation(angleInRadians);
	CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, transform);
	
	CGColorSpaceRef colorSpace = CGImageGetColorSpace(imgRef);
	CGContextRef bmContext = CGBitmapContextCreate(NULL,
												   rotatedRect.size.width,
												   rotatedRect.size.height,
												   8,
												   rotatedRect.size.width * 4,
												   colorSpace,
												   kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast );
	
	CGContextSetAllowsAntialiasing(bmContext, FALSE);
	CGContextSetInterpolationQuality(bmContext, kCGInterpolationNone);
	CGColorSpaceRelease(colorSpace);
	CGContextScaleCTM(bmContext, rotatedRect.size.width/rotatedRect.size.height, rotatedRect.size.height/rotatedRect.size.width);
	CGContextTranslateCTM(bmContext, 0.0, rotatedRect.size.height* (rotatedRect.size.width/rotatedRect.size.height));
	CGContextRotateCTM(bmContext, angleInRadians);
	
	int blankImageWidth = CGImageGetWidth(blankImage);
	int blankImageHeight = CGImageGetHeight(blankImage);
	
	int receivedImageWidth = CGImageGetWidth(imgRef);
	int receivedImageHeight = CGImageGetHeight(imgRef);
	
	CGFloat ratioX = blankImageWidth/receivedImageWidth;
	CGFloat ratioY = blankImageHeight/receivedImageHeight;
	
	//DLog(@"------------Size:%d,%d,%d,%d,%d,%d", blankImageWidth, blankImageHeight, receivedImageWidth, receivedImageHeight, (int) kReceiveiPhoneWidth*ratioX, (int) kReceiveiPhoneHeight*ratioX);
	//DLog(@"------------Ratio:%f,%f", ratioX, ratioY);
	
	if ([NSAppDelegate getRemoteDevice] == iPhoneDevice) {
		CGContextDrawImage(bmContext, CGRectMake(0, 0, blankImageHeight, blankImageWidth), blankImage);
		CGContextDrawImage(bmContext, CGRectMake(iPhoneAndiMacXOffset, iPhoneAndiMacYOffset, iPhoneHeight, iPhoneWidth), imgRef);
		
	}
	else {
		if (ratioX >= 1 && ratioY >= 1)
			CGContextScaleCTM(bmContext, ratioX, ratioY);
		CGContextDrawImage(bmContext, CGRectMake(0, 0, blankImageHeight, blankImageWidth), imgRef);
	}

	CGImageRef rotatedImage = CGBitmapContextCreateImage(bmContext);
	
	CGContextRelease(bmContext);
	
	return rotatedImage;
}

// moved from PaintingView.m
-(BOOL)loadRemoteImageWithHexString:(NSString*)imageHexString {
	
	BOOL successful = NO;
	
	//RECEIVING END CODE:
	//Receiving user would receive the hex string and decode it using the following: 
	
	DLog(@"Loading remote image hex data");
	//DLog(@"Image Hex Data: %@", imageHexString);
	DLog(@"Image Hex String Length: %d", [imageHexString length]);
	
	if([imageHexString length] % 2) {
		DLog(@"App Delegate - Image Transfer Fail: Unsuccessful image to byte conversion!");
		successful = NO;
	}
	else {
		int idx = 0; //index of the hex string char
		int len = [imageHexString length]; //length of the hex string
		
		//Create an array of bytes to store the hex values of the hex string (2 hex digits = 1 byte!)
		Byte *dataBytes = (Byte*)malloc(len/2+1); //Byte dataBytes[len/2]; //Don't know what len is, so better to malloc
		if(!dataBytes) { //Pointer is nil, meaning no memory to allocate!
			successful = NO;
		}
		else {
			//Memory allocated			
			dataBytes[len/2] = '\0';
			
			//Begin the conversion of hex string to actual hex value:
			while(idx < len){
				dataBytes[idx/2] = hexCharsToByteValue([imageHexString characterAtIndex:idx], [imageHexString characterAtIndex:idx+1]);
				idx += 2;
			}
			NSData *imageData =  [[NSData alloc] initWithBytes:dataBytes length:len/2];
			DLog(@"Image hex to data converted successfully! (Data Bytes: %d)", [imageData length]);			
			
			CFDataRef imgData = (CFDataRef)imageData;
			
			CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData (imgData);
			CGImageRef image = CGImageCreateWithJPEGDataProvider(imgDataProvider, NULL, NO, kCGRenderingIntentDefault);

			//isImageSent = TRUE;
			CGImageRef source = [self CGRemoteImageRotate:image];
			//isImageSent = FALSE;
			successful = [self loadImage:source];
			
			if (successful) {
				[NSAppDelegate.drawingView pushScreenToUndoStack:source];
			}

			
			CGImageRelease(source);
			CGImageRelease(image);
			CGDataProviderRelease(imgDataProvider);
			
			//Create a UIImage using the hex value
			
//			CGImageSourceRef source;
//
//			source = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
//			CGImageRef image =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
						
			[imageData release];
			free(dataBytes);
		}
		
	}
	
	
	//WAIT FOR UIIMAGE TO SAVE TO PHOTOS ALBUM THEN DRAW!
	
	 if(successful){
		 DLog(@"Remote Image Loaded Successfully!!");
		
		 //[self erase];
		 [self drawObject];

	 }

	return successful;
}

// this method assumes that the input image is 1024x768 size
// will fix it later so that it can load images with any size

- (BOOL)loadImage:(CGImageRef)image {
	
	if( image )
	{
		//size_t imageW = CGImageGetWidth( image );  // 768
		//size_t imageH = CGImageGetHeight( image ); // 1024
		
		//size_t imageW = self.bounds.size.width;
		//size_t imageH = self.bounds.size.height;
		size_t imageW = kDocumentWidth;
		size_t imageH = kDocumentHeight;
		
		DLog(@"load Image size: %d %d %d %d", imageW, imageH, CGImageGetWidth(image), CGImageGetHeight(image));
		
		CFDataRef cfDataRef = CGDataProviderCopyData(CGImageGetDataProvider(image));
		
		DLog(@"%u" , CFDataGetLength(cfDataRef));
		
		// currently loadTextureFromBuffer only works with RGB buffer
		// we need to scale down if the image buffer is RGBA
		
		if (CGImageGetBitsPerPixel(image) == 24) {

			// TODO: support 24bit images
			return FALSE;
//			GLubyte *textureData = (GLubyte *)CFDataGetBytePtr(cfDataRef);
//			
//			pixelStruct* buffer = (pixelStruct *)malloc(imageW * imageW * 3);
//			memset(buffer, 0xff, imageW * imageW * 3 );
//			memcpy(buffer, textureData, imageW * imageH * 3);
//			
//			int y;
//			for(y = 0; y < imageH / 2; y++) {
//				int x;
//				for(x = 0; x < imageW; x++) {
//					//Swap top and bottom bytes
//					pixelStruct top = buffer[y * imageW + x];
//					pixelStruct bottom = buffer[(imageH - 1 - y) * imageW + x];
//					buffer[(imageH - 1 - y) * imageW + x] = top;
//					buffer[y * imageW + x] = bottom;
//				}
//			}
//			
//			[self loadTextureFromBuffer:buffer width:imageW height:imageW];
			
		} else if (CGImageGetBitsPerPixel(image) == 32) {
			
			GLubyte *textureData = (GLubyte *)CFDataGetBytePtr(cfDataRef);

			pixelStruct* buffer = (pixelStruct *)malloc(imageW * imageW * 4);
			memset(buffer, 0xff, imageW * imageW * 4 );
			memcpy(buffer, textureData, imageW * imageH * 4);
			
			int y;
			for(y = 0; y < imageH / 2; y++) {
				int x;
				for(x = 0; x < imageW; x++) {
					//Swap top and bottom bytes
					pixelStruct top = buffer[y * imageW + x];
					pixelStruct bottom = buffer[(imageH - 1 - y) * imageW + x];
					buffer[(imageH - 1 - y) * imageW + x] = top;
					buffer[y * imageW + x] = bottom;
				}
			}			
			
			[self loadTextureFromBuffer:buffer width:imageW height:imageW];
			
			free(buffer);
			
		} else {
			// unsupported
			return NO;
		}

		
		CFRelease(cfDataRef);


	}
	
//	return ( textureId != 0 );
	return TRUE;
}


- (void)loadTextureFromBuffer:(void*)buffer width:(int)width height:(int)height {

	gluBuild2DMipmaps( GL_TEXTURE_2D, // 0,
					  GL_RGB, width, height, // 0,
					  GL_RGBA, GL_UNSIGNED_BYTE, buffer ); 
	
	GLenum err = glGetError();
	if (err != GL_NO_ERROR) { // Error uploading texture. glError: 0x0501
		DLog(@"Error uploading texture. glError: 0x%04X", err);
	}
}

- (void) drawObject {
	[self setNeedsDisplay:YES];
	
}

- (void) renderImage {
	//if(textureId) {
	if (TRUE) {
		
		DLog(@"Rendering image!");
		
		//[self saveThenErase:YES]; //Resets hasUnsavedChanges
		//[self erase];
		
		[self drawObject];
		
		//[(AppController*)[[UIApplication sharedApplication] delegate] setMyColor];
		
	}
	else DLog(@"No texture loaded!");
}


- (void)reshape {
	
	// NSWindowWillMiniaturizeNotification
	
	// Code to handle when the window resizes.
	DLog(@"reshape %f", [self frame].size.height);
	glViewport(0, 0, [self frame].size.width, [self frame].size.height);
	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	// Set the view coordinates to match the NSView since
	// an OpenGL view defaults to -1, 1 for each coordinate.
	glOrtho(0, [self bounds].size.width, // Sets left side to be zero and right side to be the view with.
			0, [self bounds].size.height, // Sets bottom to be zero and top to be the view height. 
			1, -1); // Not important for 2D
	
	glMatrixMode(GL_MODELVIEW);
//	glLoadIdentity();
//	[self erase];
}

// sets the camera data to initial conditions
- (void) resetCamera
{
	camera.aperture = 1.0;
	camera.rotPoint = gOrigin;
	
	camera.viewPos.x = 0.0;
	camera.viewPos.y = 0.0;
	camera.viewPos.z = -10.0;
	camera.viewDir.x = -camera.viewPos.x; 
	camera.viewDir.y = -camera.viewPos.y; 
	camera.viewDir.z = -camera.viewPos.z;
	
	camera.viewUp.x = 0;  
	camera.viewUp.y = 1; 
	camera.viewUp.z = 0;
}


// handles resizing of GL need context update and if the window dimensions change, a
// a window dimension update, reseting of viewport and an update of the projection matrix
- (void) resizeGL
{
	NSRect rectView = [self bounds];
	
	// ensure camera knows size changed
	if ((camera.viewHeight != rectView.size.height) ||
	    (camera.viewWidth != rectView.size.width)) {
		camera.viewHeight = rectView.size.height;
		camera.viewWidth = rectView.size.width;
		
		glViewport (0, 0, camera.viewWidth, camera.viewHeight);
		[self updateProjection];  // update projection matrix
		//[self updateInfoString];
	}
}


// update the projection matrix based on camera and view info
- (void) updateProjection
{
	GLdouble ratio, radians, wd2;
	GLdouble left, right, top, bottom, near, far;
	
    [[self openGLContext] makeCurrentContext];
	
	// set projection
	glMatrixMode (GL_PROJECTION);
	glLoadIdentity ();
	near = -camera.viewPos.z - shapeSize * 0.5;
	if (near < 0.00001)
		near = 0.00001;
	far = -camera.viewPos.z + shapeSize * 0.5;
	if (far < 1.0)
		far = 1.0;
	radians = 0.0174532925 * camera.aperture / 2; // half aperture degrees to radians 
	wd2 = near * tan(radians);
	ratio = camera.viewWidth / (float) camera.viewHeight;
	if (ratio >= 1.0) {
		left  = -ratio * wd2;
		right = ratio * wd2;
		top = wd2;
		bottom = -wd2;	
	} else {
		left  = -wd2;
		right = wd2;
		top = wd2 / ratio;
		bottom = -wd2 / ratio;	
	}
	glFrustum (left, right, bottom, top, near, far);
	//[self updateCameraString];
}

// ---------------------------------

// updates the contexts model view matrix for object and camera moves
- (void) updateModelView
{
    [[self openGLContext] makeCurrentContext];
	
	// move view
	glMatrixMode (GL_MODELVIEW);
	glLoadIdentity ();
	gluLookAt (camera.viewPos.x, camera.viewPos.y, camera.viewPos.z,
			   camera.viewPos.x + camera.viewDir.x,
			   camera.viewPos.y + camera.viewDir.y,
			   camera.viewPos.z + camera.viewDir.z,
			   camera.viewUp.x, camera.viewUp.y ,camera.viewUp.z);
	
//	// if we have trackball rotation to map (this IS the test I want as it can be explicitly 0.0f)
//	if ((gTrackingViewInfo == self) && gTrackBallRotation[0] != 0.0f) 
//		glRotatef (gTrackBallRotation[0], gTrackBallRotation[1], gTrackBallRotation[2], gTrackBallRotation[3]);
//	else {
//	}
//	// accumlated world rotation via trackball
//	glRotatef (worldRotation[0], worldRotation[1], worldRotation[2], worldRotation[3]);
//	// object itself rotating applied after camera rotation
//	glRotatef (objectRotation[0], objectRotation[1], objectRotation[2], objectRotation[3]);
//	rRot[0] = 0.0f; // reset animation rotations (do in all cases to prevent rotating while moving with trackball)
//	rRot[1] = 0.0f;
//	rRot[2] = 0.0f;
//	[self updateCameraString];
}

@end
