/*

File: BrowserViewController.h
Abstract: 
 View controller for the service instance list.
 This object manages a NSNetServiceBrowser configured to look for Bonjour
services.
 It has an array of NSNetService objects that are displayed in a table view.
 When the service browser reports that it has discovered a service, the
corresponding NSNetService is added to the array.
 When a service goes away, the corresponding NSNetService is removed from the
array.
 Selecting an item in the table view asynchronously resolves the corresponding
net service.
 When that resolution completes, the delegate is called with the corresponding
NSNetService.

*/

#if TARGET_OS_IPHONE
	#import <UIKit/UIKit.h>
#import "GSConnectionComponent.h"
#else
	#import <Cocoa/Cocoa.h>
#endif

#import <Foundation/NSNetServices.h>


//@class BrowserViewController;

//@protocol BrowserViewControllerDelegate <NSObject>
//@required
//// This method will be invoked when the user selects one of the service instances from the list.
//// The ref parameter will be the selected (already resolved) instance or nil if the user taps the 'Cancel' button (if shown).
//- (void) browserViewController:(BrowserViewController*)bvc didResolveInstance:(NSNetService*)ref;
//@end

// TODO: implement NSNetServiceBrowserDelegate, NSNetServiceDelegate
@interface BrowserViewController : NSObject <
#if TARGET_OS_IPHONE
GSConnectionComponent, 
#endif
NSNetServiceBrowserDelegate> {

@private
//	id<BrowserViewControllerDelegate> _delegate;
	//NSString* _searchingForServicesString;
	NSString* _ownName;
	NSNetService* _ownEntry;
//	BOOL _showDisclosureIndicators;
	NSMutableArray* _services;
	NSMutableArray* _servicesToRemove;
	NSNetServiceBrowser* _netServiceBrowser;
	NSNetService* _currentResolve;
//	NSTimer* _timer;
//	BOOL _needsActivityIndicator;
//	BOOL _initialWaitOver;
	
//	NSString* _connectedName;
//	NSNetService* _nextService;
	
	// XMPP login view
	id _displayDelegate;
}

//@property (nonatomic, assign) id<BrowserViewControllerDelegate> delegate;
@property (nonatomic, assign) id displayDelegate;
@property (nonatomic, copy) NSString* ownName;

@property (nonatomic, retain, readwrite) NSNetService* currentResolve;
@property (nonatomic, retain, readwrite) NSMutableArray* services;

- (BOOL)searchForServicesOfType:(NSString *)type inDomain:(NSString *)domain;
- (void)removeServiceWithName:(NSString*)name;

#if TARGET_OS_IPHONE
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
#endif

- (NSInteger)numberOfPeers;
- (NSString *)peerNameForRow:(NSUInteger)row;
//- (GSLocalWhiteboard *)peerForRow:(NSUInteger)row;
- (void)didSelectPeerAtRow:(NSUInteger)row;

- (void)startToBrowsing;
- (void)stopBrowsing;
- (void)clearAllServices;
@end
