/*

File: PaintingView.h
Abstract: The class responsible for the finger painting.

*/

#import "EAGLView.h"
#import "Constants.h"

//CONSTANTS: // draw dots the inverse of this many times (1.0 / kBrushOpacity)
// optimization ideas: no opacity, draw only 1/2 (or a little more?) of the circle
#define kBrushOpacity		(1.0 / 3.0)//1.0//(1.0 / 10.0)////(1.0 / 4.0)////(1.0 / 3.0)//1.0//(1.0 / 3.0)
#define kBrushPixelStep		3
//#define kBrushScale			2
#define kLuminosity			0.75
#define kSaturation			1.0

//CLASS INTERFACES:

@interface PaintingView : EAGLView
{
	GLuint			    brushTexture;
	GLuint				drawingTexture;
	GLuint				drawingFramebuffer;
	CGPoint				location;
	CGPoint				previousLocation;
	Boolean				firstTouch;
	
	Boolean presentedTools;
}
@property(nonatomic, readwrite) CGPoint location;
@property(nonatomic, readwrite) CGPoint previousLocation;


- (void) erase;
- (void) renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end;
@end
