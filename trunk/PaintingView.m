/*

File: PaintingView.m
Abstract: The class responsible for the finger painting.

*/

#import "PaintingView.h"

#import "AppController.h"

//CLASS IMPLEMENTATIONS:

@implementation PaintingView

@synthesize  location;
@synthesize  previousLocation;

- (id) initWithFrame:(CGRect)frame
{
	
	//NSMutableArray*	recordedPaths;
	CGImageRef		brushImage;
	CGContextRef	brushContext;
	GLubyte			*brushData;
	size_t height;
	
	size_t			width;

	
	if((self = [super initWithFrame:frame pixelFormat:GL_RGB565_OES depthFormat:0 preserveBackbuffer:YES])) {
		[self setCurrentContext];
		
		// multitouch for showing/hiding tools
		[self setMultipleTouchEnabled:YES];

		
		Boolean useBrush = NO;
		
		// Create a texture from an image
		// First create a UIImage object from the data in a image file, and then extract the Core Graphics image
		brushImage = [UIImage imageNamed:@"Particle.png"].CGImage;
		//brushImage = [UIImage imageNamed:@"ParticleInverted.png"].CGImage;
		//brushImage = [UIImage imageNamed:@"ParticleBlack.png"].CGImage;
		//brushImage = [UIImage imageNamed:@"DotTransparent.png"].CGImage;
		
		// Get the width and height of the image
		width = CGImageGetWidth(brushImage);
		height = CGImageGetHeight(brushImage);
		
		// Texture dimensions must be a power of 2. If you write an application that allows users to supply an image,
		// you'll want to add code that checks the dimensions and takes appropriate action if they are not a power of 2.
		
		// Make sure the image exists
		if(brushImage && useBrush) {
			
			
			//glEnable(GL_BLEND);
			//glDisable(GL_DEPTH_TEST);
			
			
			
			
			// Allocate  memory needed for the bitmap context
			brushData = (GLubyte *) malloc(width * height * 4);
			// Use the bitmap creation function provided by the Core Graphics framework. 
			brushContext = CGBitmapContextCreate(brushData,							// data
												 width,								// width
												 width,								// height
												 8,									// bitsPerComponent
												 width * 4,							// bytesPerRow
												 CGImageGetColorSpace(brushImage),	// colorspace
												 kCGImageAlphaPremultipliedLast); //kCGImageAlphaOnly); //kCGImageAlphaPremultipliedLast);	// bitmapInfo
			// After you create the context, you can draw the image to the context.
			CGContextDrawImage(brushContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), brushImage);
			// You don't need the context at this point, so you need to release it to avoid memory leaks.
			CGContextRelease(brushContext);
			// Use OpenGL ES to generate a name for the texture.
			glGenTextures(1, &brushTexture);
			// Bind the texture name. 
			glBindTexture(GL_TEXTURE_2D, brushTexture);
			// Specify a 2D texture image, providing the a pointer to the image data in memory
			
			// This loads the texture
			// GL_ALPHA? Usually GL_RGBA or GL_LUMINANCE_ALPHA
			
			// target, level, internalformat, width, height, border, format, type, pixels
			glTexImage2D(GL_TEXTURE_2D,	// target
						 0,				// level
						 GL_RGBA,//GL_LUMINANCE_ALPHA, //		// internalformat (4 color components)
						 width,			// width
						 height,		// height
						 0,				// border
						 GL_RGBA,		// format (of the pixel data)
						 GL_UNSIGNED_BYTE,
						 brushData);
			// Release the image data; it's no longer needed
            free(brushData);		
			// Set the texture parameters to use a minifying filter and a linear filer (weighted average)
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			
			// Enable use of the texture
			glEnable(GL_TEXTURE_2D);
			// Set a blending function to use
			//glBlendFunc(GL_SRC_ALPHA, GL_ONE);
			// Enable blending
			//glEnable(GL_BLEND);
		}
		 
		
		//Set up OpenGL states
		glDisable(GL_DITHER);
		glMatrixMode(GL_PROJECTION);
		glOrthof(0, frame.size.width, 0, frame.size.height, -1, 1);
		glMatrixMode(GL_MODELVIEW);
		glEnable(GL_TEXTURE_2D);
		glEnableClientState(GL_VERTEX_ARRAY);
	    glEnable(GL_BLEND);
		//glDisable(GL_DEPTH_TEST);
		//glBlendFunc(GL_DST_COLOR,GL_ZERO); // image points, black lines
		// bind the sprite texture
		
		//glBlendFunc(GL_ONE,GL_ONE);
		
		//glDisable(GL_BLEND);
		//glEnable(GL_DEPTH_TEST);
		
		// sfactor, dfactor
		//glBlendFunc(GL_SRC_ALPHA, GL_ONE); // Apple's setting (shows nothing)
		
		//glBlendFunc(GL_ONE, GL_ONE); // shows nothing
		//glBlendFunc(GL_ZERO, GL_SRC_ALPHA); // made sense to me - black square - no circle, uniform transparency
		
		//glBlendFunc(GL_SRC_ALPHA, GL_DST_ALPHA); // sherwin's - darker black square - darker color
		//glBlendFunc(GL_ZERO, GL_DST_ALPHA); // black square - no circle (DotTransparent)
		
		//glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_DST_ALPHA ); // sherwin says to try this - has a box but not too bad
		glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA ); // almost works - looks the same as sherwin's?
		//glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA); // https://devforums.apple.com/message/9278#9278 - nothing (DotTransparent)
		/*
		GLfloat color[4] = { 1.0f, 0.5f, 0.0f, 1 };
		glTexEnvfv(GL_TEXTURE_ENV, GL_TEXTURE_ENV_COLOR, color);
		glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
		glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_REPLACE);
		glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_REPLACE);
		glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB, GL_CONSTANT);
		glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_RGB, GL_SRC_COLOR);
		glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA, GL_TEXTURE);
		glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA, GL_SRC_ALPHA);
		*/
		//glEnable (GL_ALPHA_TEST);
		//glAlphaFunc (GL_GREATER, 0.666f);
		//glAlphaFunc (GL_GREATER, 0.333f);
		//glAlphaFunc (GL_GREATER, 0.0f);

		
		//glBlendFunc(GL_SRC_ALPHA, GL_SRC_ALPHA); // square around it
		
		//glBlendFunc( GL_SRC_COLOR, GL_ONE_MINUS_SRC_ALPHA ); // super bible - transparent? - light colro
		//glBlendFunc(GL_SRC_ALPHA,GL_ZERO); // sherwin's quick fix - dark black square
		
		//glEnable(GL_LINE_SMOOTH); // not necessary?
		//glEnable(GL_POINT_SMOOTH);
		//glEnable(GL_POLYGON_SMOOTH);
		
		glEnable(GL_POINT_SPRITE_OES);
		glTexEnvf(GL_POINT_SPRITE_OES, GL_COORD_REPLACE_OES, GL_TRUE);
		//glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE ); // http://www.nullterminator.net/gltexture.html
		
		//glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_BLEND);
		
		//width = 16;
		
		//glPointSize(width / kBrushScale);
		glPointSize(kMaxPointSize / 2.0);
		//NSLog(@"width = %d / kBrushScale = %f = %f", width, kBrushScale, width / kBrushScale);
		
		// 1 of 2 places to set the background color
		//glClearColor(0.5f, 0.5f, 0.5f, 0.0f);
		glClearColor(1.0f, 1.0f, 1.0f, 0.0f);

		//Make sure to start with a cleared buffer
		[self erase];
		
		//Playback recorded path, which is "Shake Me"
		/*
		recordedPaths = [NSMutableArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Recording" ofType:@"data"]];
		if([recordedPaths count])
			[self performSelector:@selector(playback:) withObject:recordedPaths afterDelay:0.2];
		*/
		
	}
	
	return self;
}

// Releases resources when they are not longer needed.
- (void) dealloc
{
		
	glDeleteFramebuffersOES(1, &drawingFramebuffer);
	glDeleteTextures(1, &drawingTexture);

	[super dealloc];
}

// Erases the screen
- (void) erase
{
	//Clear the buffer
	glClear(GL_COLOR_BUFFER_BIT);
	
	//Display the buffer
	[self swapBuffers];
}





// Drawings a line onscreen based on where the user touches
- (void) renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end
{
	//NSLog(@"renderLineFromPoint:%@ toPoint:%@", NSStringFromCGPoint(start), NSStringFromCGPoint(end));
	NSUInteger circleSides = 15;	// TODO: vary the # of sides depending on radius?
	NSUInteger numVertices = circleSides * 2; // can't be static?
	GLfloat vertices[numVertices];				// TODO: vary the # of vertices depending on radius?
										// TODO: vary kBrushPixelStep depending on radius?
	GLfloat radius = [(AppController*)[[UIApplication sharedApplication] delegate] pointSize];
	/*
	GLfloat xradius = (firstTouch.x > lastTouch.x) ? (firstTouch.x - lastTouch.x)/2 : (lastTouch.x - firstTouch.x)/2;
	GLfloat yradius = (self.frame.size.height - firstTouch.y > self.frame.size.height - lastTouch.y) ? ((self.frame.size.height - firstTouch.y) - (self.frame.size.height - lastTouch.y))/2 : ((self.frame.size.height - lastTouch.y) - (self.frame.size.height - firstTouch.y))/2; 
	 */
	//NSLog(@"radius:%f end:%@", radius, NSStringFromCGPoint(end));
	NSUInteger	i,
				j,
				count;
	GLfloat	xOffset,
			yOffset;
	// Add points to the buffer so there are drawing points every X pixels
	count = MAX(ceilf(sqrtf((end.x - start.x) * (end.x - start.x) + (end.y - start.y) * (end.y - start.y)) / kBrushPixelStep), 1);
	//NSLog(@"count:%d", count);
	for(i = 0; i < count; ++i) {
		//NSLog(@"i:%d", i);
		/*
		if(vertexCount == vertexMax) {
			vertexMax = 2 * vertexMax;
			vertexBuffer = realloc(vertexBuffer, vertexMax * 2 * sizeof(GLfloat));
		}
		
		vertexBuffer[2 * vertexCount + 0] = start.x + (end.x - start.x) * ((GLfloat)i / (GLfloat)count); // x
		vertexBuffer[2 * vertexCount + 1] = start.y + (end.y - start.y) * ((GLfloat)i / (GLfloat)count); // y
		vertexCount += 1;
		 */
		xOffset = start.x + (end.x - start.x) * ((GLfloat)i / (GLfloat)count);
		yOffset = start.y + (end.y - start.y) * ((GLfloat)i / (GLfloat)count);
		//NSLog(@"xOffset=%f yOffset=%f", xOffset, yOffset);
		// careful... I changed <= to < because it was overwriting i somehow!
		for(j = 0; j < numVertices; j+=2)
		{
			//GLfloat xOffset = end.x;// + radius; //(firstTouch.x > lastTouch.x) ? lastTouch.x + xradius : firstTouch.x + xradius;
			//GLfloat yOffset = end.y;// + radius; //(self.frame.size.height - firstTouch.y > self.frame.size.height - lastTouch.y) ? self.frame.size.height - lastTouch.y + yradius : self.frame.size.height - firstTouch.y + yradius;
			/*
			 vertices[i] = (cos(degreesToRadian(i))*xradius) + xOffset;
			 vertices[i+1] = (sin(degreesToRadian(i))*yradius) + yOffset;
			 */
			vertices[j] = (cos(degreesToRadian(j * 360 / numVertices))*radius) + xOffset;
			vertices[j+1] = (sin(degreesToRadian(j * 360 / numVertices))*radius) + yOffset;
			
		}
		glVertexPointer (2, GL_FLOAT , 0, vertices);	
		glDrawArrays (GL_TRIANGLE_FAN, 0, circleSides);

	}
	
	// Display the buffer
	[self swapBuffers];
	//NSLog(@"swapped buffers. i=%d count=%d", i, count);
	


	
	//////////////////////////////////
	
	/*
	static GLfloat*		vertexBuffer = NULL;
	static NSUInteger	vertexMax = 64;
	NSUInteger			vertexCount = 0,
						count,
						i;
	
	//Allocate vertex array buffer
	if(vertexBuffer == NULL)
		vertexBuffer = malloc(vertexMax * 2 * sizeof(GLfloat));
	*/
	
	//glScissor(1	,int(0.135416f*sheight),swidth-2,int(0.597916f*sheight));	// Define Scissor Region
	//glEnable(GL_SCISSOR_TEST);
	/*
	//Render the vertex array
	glVertexPointer(2,				// size: number of coordinates per vertex; 2, 3, or 4 (default).
					GL_FLOAT,		// data type of each coordinate
					0,				// stride
					vertexBuffer);	// pointer to the first coordinate of the first vertex
	// default
	glDrawArrays(GL_POINTS,		// mode
				 0,				// first: starting index
				 vertexCount);	// count: number of indices to be rendered
	
	//glDrawArrays(GL_LINE_STRIP, 0, vertexCount); // thin line strip effect
	//glDrawArrays(GL_LINE_LOOP, 0, vertexCount); // thin line strip effect
	//glDrawArrays(GL_LINES, 0, vertexCount); // thin line strip effect
	//glDrawArrays(GL_TRIANGLES, 0, vertexCount); // thin line strip effect
	
	//glDisable(GL_SCISSOR_TEST);
	*/

}


// TODO: include color data
// Reads previously recorded points and draws them onscreen. This is the Shake Me message that appears when the application launches.
- (void) playback:(NSMutableArray*)recordedPaths
{
	NSData*				data = [recordedPaths objectAtIndex:0];
	CGPoint*			point = (CGPoint*)[data bytes];
	NSUInteger			count = [data length] / sizeof(CGPoint),
						i;
	
	//Render the current path
	for(i = 0; i < count - 1; ++i, ++point)
		[self renderLineFromPoint:*point toPoint:*(point + 1)];
	
	//Render the next path after a short delay 
	[recordedPaths removeObjectAtIndex:0];
	if([recordedPaths count])
		[self performSelector:@selector(playback:) withObject:recordedPaths afterDelay:0.01];
}

- (Boolean)toolsAreHidden {
	return [(AppController*)[[UIApplication sharedApplication] delegate] pickerIsHidden];
}

// Handles the start of a touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	//NSLog(@"%s %@", _cmd, touches);
	//NSLog(@"%s [touches count] = %d, [[event allTouches] count] = %d", _cmd, [touches count], [[event allTouches] count]);
	if ([[event allTouches] count] >= 2 && [self toolsAreHidden]) {
		[(AppController*)[[UIApplication sharedApplication] delegate] presentTools];
		//NSLog(@"began: showing tools");
		return;
	}
	
	CGRect				bounds = [self bounds];
    UITouch*	touch = [[event touchesForView:self] anyObject];
	firstTouch = YES;
	//Convert touch point from UIView referential to OpenGL one (upside-down flip)
	location = [touch locationInView:self];
	location.y = bounds.size.height - location.y;
}

// Handles the continuation of a touch.
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	//NSLog(@"%s %@", _cmd, touches);
	//NSLog(@"%s [touches count] = %d, [[event allTouches] count] = %d", _cmd, [touches count], [[event allTouches] count]);
	if ([[event allTouches] count] >= 2 && [self toolsAreHidden]) {
		[(AppController*)[[UIApplication sharedApplication] delegate] presentTools];
		NSLog(@"moved: showing tools");
		return;
	}
	
	if (![self toolsAreHidden]) {
		return;
	}
	
	CGRect				bounds = [self bounds];
	UITouch*			touch = [[event touchesForView:self] anyObject];
		
	//Convert touch point from UIView referential to OpenGL one (upside-down flip)
	if (firstTouch)// {
		firstTouch = NO; // used for taps
	/*
		previousLocation = [touch previousLocationInView:self];
		previousLocation.y = bounds.size.height - previousLocation.y;
	} else {
	 */
		location = [touch locationInView:self];
	    location.y = bounds.size.height - location.y;
		previousLocation = [touch previousLocationInView:self];
		previousLocation.y = bounds.size.height - previousLocation.y;
	//}
		
	// Render the stroke
	[(AppController*)[[UIApplication sharedApplication] delegate] renderMyColorLineFromPoint:previousLocation toPoint:location];
	
	[(AppController*)[[UIApplication sharedApplication] delegate] sendLineFromPoint:previousLocation toPoint:location];	
}

// Handles the end of a touch event when the touch is a tap.
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	//NSLog(@"%s [touches count] = %d, [[event allTouches] count] = %d", _cmd, [touches count], [[event allTouches] count]);
	if ([[event allTouches] count] >= 2 && [self toolsAreHidden]) {
		[(AppController*)[[UIApplication sharedApplication] delegate] presentTools];
		return;
	}
	
	if (![self toolsAreHidden]) {
		return;
	}
	
	//NSLog(@"%s %@", _cmd, touches);
	CGRect				bounds = [self bounds];
    UITouch*	touch = [[event touchesForView:self] anyObject];
	if (firstTouch) {
		firstTouch = NO;
		previousLocation = [touch previousLocationInView:self];
		previousLocation.y = bounds.size.height - previousLocation.y;

		// Draw dots (1.0 / kBrushOpacity) times
		NSUInteger i;
		for (i = 0; i < (1.0 / kBrushOpacity); i++) {
			//NSLog(@"drew once");
			[(AppController*)[[UIApplication sharedApplication] delegate] renderMyColorLineFromPoint:previousLocation toPoint:location];
			[(AppController*)[[UIApplication sharedApplication] delegate] sendLineFromPoint:previousLocation toPoint:location];
		}
	}

}

// Handles the end of a touch event.
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	//NSLog(@"%s %@", _cmd, touches);
	// If appropriate, add code necessary to save the state of the application.
	// This application is not saving state.
}

@end
