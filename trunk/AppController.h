/*

File: AppController.h
Abstract: UIApplication's delegate class, the central controller of the
application.

*/

//#import "TapView.h"
#import "BrowserViewController.h"
#import "Picker.h"
#import "TCPServer.h"

// From GLPaint
#import "PaintingView.h"
#import "SoundEffect.h"

#import "AcceptReject.h"

#define kProgressIndicatorSize 20.0
#define kPreviewAreaSize 64.0

#define kWaitingTag 3
#define kOrJoinTag 4

//CLASS INTERFACES:

@interface AppController : NSObject <UIApplicationDelegate, UIActionSheetDelegate, BrowserViewControllerDelegate, TCPServerDelegate/*, UIAccelerometerDelegate*/>
{
	//UIWindow*			_window;
	Picker*				_picker;
	TCPServer*			_server;
	// Change to NSMutableArray of NS?Streams
	//NSInputStream*		_inStream;
	NSMutableArray*		_inStreams;
	//NSOutputStream*		_outStream;
	NSMutableArray*		_outStreams;
	BOOL				_inReady;
	BOOL				_outReady;
	
	BOOL initializedWithPeers;
	
	BOOL amServer;
	
	BOOL needToSendName;
	BOOL pendingJoinRequest;
	
	//WorkerThread* thread;
	NSThread* inStreamThread;
	//NSLock* colorLock;
	CGFloat components[4];
	BOOL receivingRemoteColor;
	CGFloat remoteComponents[4];
	BOOL usingRemoteColor;
	
	// Message Type: Point Size (s) //
	BOOL receivingRemotePointSize;
	CGFloat remotePointSize;
	BOOL usingRemotePointSize;
	
	// Message Type: Name (n) //
	BOOL receivingRemoteName;
	
	// From GLPaint
	UIWindow			*window;
	PaintingView		*drawingView;
	
	//UIAccelerationValue	myAccelerometer[3];
	SoundEffect			*erasingSound;
	SoundEffect			*selectSound;
	CFTimeInterval		lastTime;
	
	CGFloat _pointSize; // always MY pointSize

	AcceptReject* _acceptReject;

	NSMutableDictionary *namesForStreams;
	
	UIAlertView* acceptRejectAlertView;
	UIAlertView* eraseWaitAlertView;
	
	NSString* writeBuffer;
	
	BOOL firstHide;
}

//@property(nonatomic, readwrite) CGFloat components[4];
@property(nonatomic, readwrite) BOOL receivingRemoteColor;
//@property(nonatomic, readwrite) CGFloat remoteComponents[4];
@property(nonatomic, readwrite) BOOL usingRemoteColor;

@property(nonatomic, readwrite) BOOL receivingRemotePointSize;
@property(nonatomic, readwrite) BOOL usingRemotePointSize;

@property(nonatomic, readwrite) BOOL receivingRemoteName;

@property (nonatomic, copy) AcceptReject* acceptReject;

@property (nonatomic, copy) NSThread* inStreamThread;

//@property CGFloat _pointSize; // always MY pointSize

// not sure if this should be assign
// actually don't think it matters because nobody will be setting this except on app launch
//@property(nonatomic, assign) NSLock* colorLock;

/*
- (void) activateView:(TapView*)view;
- (void) deactivateView:(TapView*)view;
*/
//- (void) openInStream:(NSInputStream*)_inStream withOutStream:(NSOutputStream*)_outStream;
- (void) sendLineFromPoint:(CGPoint)start toPoint:(CGPoint)end;
- (void) renderMyColorLineFromPoint:(CGPoint)start toPoint:(CGPoint)end;
- (void) renderRemoteColorLineWithRect:(NSString *)strRect;
- (void) presentTools;
- (BOOL) pickerIsHidden;
- (void) hideTools;
- (void) changePointSize:(id)sender;
- (CGFloat) pointSize;
- (void) acceptPendingRequest:(NSUInteger)response withName:(NSString*)name;

- (void) sendMyColor;
- (void) sendMyPointSize;

- (void) send:(NSString*)message;
- (void) send:(NSString*)message toOutStream:(NSOutputStream*)_outStream;

- (BOOL) disconnectFromPeerWithStream:(NSStream*)stream;

- (CGColorRef) myColor;

@end
