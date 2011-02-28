/*

File: BrowserViewController.m
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

#import "BrowserViewController.h"
#import APP_DELEGATE
#import "Picker.h"
#import "GSLocalConnection.h"
#import "GSConnectionController.h"
#import "GSLocalConnection.h"
#import "GSLocalWhiteboard.h"

#if TARGET_OS_IPHONE
	#import "GSFriendsListViewController.h"
#else
	#import "CMAlertTableDialog.h"
#endif


// A category on NSNetService that's used to sort NSNetService objects by their name.
@interface NSNetService (BrowserViewControllerAdditions)
- (NSComparisonResult) localizedCaseInsensitiveCompareByName:(NSNetService*)aService;
@end

@implementation NSNetService (BrowserViewControllerAdditions)
- (NSComparisonResult) localizedCaseInsensitiveCompareByName:(NSNetService*)aService {
	return [[self name] localizedCaseInsensitiveCompare:[aService name]];
}
@end

//
//@interface UITableView (GSReloadDataIfNotWaiting)
//- (void)reloadDataIfNotWaiting;
//@end
//
//@implementation UITableView (GSReloadDataIfNotWaiting)
//- (void)reloadDataIfNotWaiting {
//	
//	// If we are NOT connected AND
//	//    we are NOT waiting
//	
//	if (/*!self.connectedName && !self.currentResolve*/
//		//[(AppController*)[[UIApplication sharedApplication] delegate] streamCount] == 0 &&
////		[[Picker sharedPicker].bvc needsActivityIndicator] == NO) {
//		[AppDelegate.connection.localConnection.bvc needsActivityIndicator] == NO) {
//		[self reloadData];
//	}
//}
//@end

@interface BrowserViewController()
@property (nonatomic, retain, readwrite) NSNetService* ownEntry;
@property (nonatomic, retain, readwrite) NSMutableArray* servicesToRemove;
@property (nonatomic, retain, readwrite) NSNetServiceBrowser* netServiceBrowser;

- (void)didUpdateServicesData;

@end


@implementation BrowserViewController

//@synthesize delegate = _delegate;
@synthesize ownEntry = _ownEntry;
//@synthesize showDisclosureIndicators = _showDisclosureIndicators;
@synthesize currentResolve = _currentResolve;
@synthesize netServiceBrowser = _netServiceBrowser;
@synthesize services = _services;

@synthesize servicesToRemove = _servicesToRemove;

//@synthesize needsActivityIndicator = _needsActivityIndicator;
//@dynamic timer;
//@synthesize initialWaitOver = _initialWaitOver;

//@synthesize connectedName = _connectedName;
//@synthesize nextService = _nextService;

@synthesize displayDelegate = _displayDelegate;

#if LITE
//@synthesize promoRowText = promoRowText_;
//@synthesize promoRowURL = promoRowURL_;
#endif

//- (NSString*)connectedName {
//	return _connectedName;
//}
//
//- (void)setConnectedName:(NSString*)newName {
//	
//	//DLog(@"self.services:%@", self.services);
//	/*
//	if ([NSThread isMainThread]) {
//		DLog(@"%s on MainThread", _cmd);
//	} else {
//		DLog(@"%s NOT on MainThread", _cmd);
//	}
//	 */
//	[newName retain];
//	[_connectedName release];
//	_connectedName = newName;
//
//	//KONG: remove update view here, because we make no change in the services
////	[self reloadDataIfNotWaiting];
//	/*
//	NSNetService* service;
//	for (service in self.services) {
//		if ([service.name isEqual:_connectedName]) {
//			[self.services removeObject:service];
//		}
//	}
//	 */
//}

static GSConnectionController *connection = nil;

- (id)init {
	if ((self = [super init])) {
//		_delegate = delegate;
//		self.title = title;
//		self.connectedName = nil;
		_services = [[NSMutableArray alloc] init];
		
		_servicesToRemove = [[NSMutableArray alloc] init];
		
//		self.showDisclosureIndicators = show;

//		if (showCancelButton) {
//			// add Cancel button as the nav bar's custom right view
//			UIBarButtonItem *addButton = [[UIBarButtonItem alloc]
//										  initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction)];
//			self.navigationItem.rightBarButtonItem = addButton;
//			[addButton release];
//		}

		// Make sure we have a chance to discover devices before showing the user that nothing was found (yet)
//		[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(initialWaitOver:) userInfo:nil repeats:NO];
		
		

	}

	return self;
}

- (void)dealloc {
	// Cleanup any running resolve and free memory
//	[self stopCurrentResolve];
	[self.netServiceBrowser stop];
	self.netServiceBrowser = nil;
	//	[_searchingForServicesString release];
	[_ownEntry release];
	
	self.services = nil;
	self.servicesToRemove = nil;
	
	[super dealloc];
}

- (GSConnectionController *)connection {
	if (connection == nil) {
		connection = AppDelegate.connection;
	}
	return connection;
}

//- (NSString *)searchingForServicesString {
//	return _searchingForServicesString;
//}

// Holds the string that's displayed in the table view during service discovery.
//- (void)setSearchingForServicesString:(NSString *)searchingForServicesString {
//	if (_searchingForServicesString != searchingForServicesString) {
//		[_searchingForServicesString release];
//		_searchingForServicesString = [searchingForServicesString copy];
//
//        // If there are no services, reload the table to ensure that searchingForServicesString appears.
//		if ([self.services count] == 0) {
//			/*
//			if ([NSThread isMainThread]) {
//				DLog(@"%s on MainThread", _cmd);
//			} else {
//				DLog(@"%s NOT on MainThread", _cmd);
//			}
//			 */
//			
//			[self reloadDataIfNotWaiting];
//		}
//	}
//}

//- (NSString *)bvcOwnName {
//	return _bvcOwnName;
//}

// NOT on MainThread. Is that OK?
// Holds the string that's displayed in the table view during service discovery.
//- (void)setBvcOwnName:(NSString *)name {
//	if (_bvcOwnName != name) {
//		_bvcOwnName = [name copy];
//		
//		if (self.ownEntry)
//			[self.services addObject:self.ownEntry];
//		
//		NSNetService* service;
//		
//		for (service in self.services) {
//			if ([service.name isEqual:name]) {
//				self.ownEntry = service;
//				[_services removeObject:service];
//				break;
//			}
//		}
//		
//		if ([NSThread isMainThread]) {
//			DLog(@"%s on MainThread", _cmd);
//		} else {
//			DLog(@"%s NOT on MainThread", _cmd);
//		}
//		[self reloadDataIfNotWaiting];
//	}
//}

- (NSString *)ownName {
	return _ownName;
}

// NOT on MainThread. Is that OK?
// Holds the string that's displayed in the table view during service discovery.
- (void)setOwnName:(NSString *)name {
	if (_ownName != name) {
		//KONG: check memory
		_ownName = [name copy];
		
		if (self.ownEntry) {
			[self.services addObject:self.ownEntry];
//			DLog(@"service added to list: %@", self.ownEntry);
		}
		
		NSNetService* service;
		
		for (service in self.services) {
			if ([service.name isEqual:name]) {
				self.ownEntry = service;
				[_services removeObject:service];
//				DLog(@"service removed out of list: %@", self.ownEntry);				
				break;
			}
		}
		
		// setOwnName: on MainThread when connectButton tapped
//		if ([NSThread isMainThread]) {
//			DLog(@"%s on MainThread", _cmd);
//		} else {
//			DLog(@"%s NOT on MainThread", _cmd);
//		}
		[self didUpdateServicesData];
	}
}

// Creates an NSNetServiceBrowser that searches for services of a particular type in a particular domain.
// If a service is currently being resolved, stop resolving it and stop the service browser from
// discovering other services.
// Executes on MainThread
- (BOOL)searchForServicesOfType:(NSString *)type inDomain:(NSString *)domain {
	//DLog(@"%s", _cmd);
	
//	[self stopCurrentResolve];
	[self.netServiceBrowser stop];
	[self.services removeAllObjects];
	[self didUpdateServicesData];
	DLog(@"services removed all");


	NSNetServiceBrowser *aNetServiceBrowser = [[NSNetServiceBrowser alloc] init];
	if(!aNetServiceBrowser) {
        // The NSNetServiceBrowser couldn't be allocated and initialized.
		return NO;
	}

	aNetServiceBrowser.delegate = self;
	self.netServiceBrowser = aNetServiceBrowser;
	[aNetServiceBrowser release];
	[self.netServiceBrowser searchForServicesOfType:type inDomain:domain];

	/*
	if ([NSThread isMainThread]) {
		DLog(@"%s on MainThread", _cmd);
	} else {
		DLog(@"%s NOT on MainThread", _cmd);
	}
	 */
	
//	[self reloadDataIfNotWaiting];
	
//	[self.tableView flashScrollIndicators];
	
	return YES;
}


//- (NSTimer *)timer {
//	return _timer;
//}
//
//// When this is called, invalidate the existing timer before releasing it.
//- (void)setTimer:(NSTimer *)newTimer {
//	[_timer invalidate];
//	[newTimer retain];
//	[_timer release];
//	_timer = newTimer;
//}



- (void)sortAndUpdateUI {
	// Sort the services by name.
	[self.services sortUsingSelector:@selector(localizedCaseInsensitiveCompareByName:)];
	// Executes on MainThread
	
//	if ([NSThread isMainThread]) {
//		DLog(@"%s on MainThread", _cmd);
//	} else {
//		DLog(@"%s NOT on MainThread", _cmd);
//	}
	 
	[self didUpdateServicesData];
	
//	[self.tableView flashScrollIndicators];
}


- (void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didRemoveService:(NSNetService*)service moreComing:(BOOL)moreComing {
	DLog(@"name: %@", service.name);
	// If a service went away, stop resolving it if it's currently being resolve,
	// remove it from the list and update the table view if no more events are queued.
	
//	DLog(@"netServiceBrowser:%@ didRemoveService.name:%@ moreComing:%d", netServiceBrowser, service.name, moreComing);
	
	/*
	if (self.currentResolve && [service isEqual:self.currentResolve]) {
		[self stopCurrentResolve];
		[self.servicesToRemove addObject:service];
	} else
	 */
	
	// When I've disconnected, I need to set acceptReject.name to nil
	
//	if ([[[(AppController*)[[UIApplication sharedApplication] delegate] acceptReject] name] isEqualToString:service.name] || (self.currentResolve && [service isEqual:self.currentResolve]) || [self.connectedName isEqualToString:service.name]) {
	if ((AppDelegate.connection.requestingWhiteboard.type == GSConnectionTypeLocal
		 && [AppDelegate.connection.requestingWhiteboard.name isEqualToString:service.name]) || 
		(self.currentResolve && [service isEqual:self.currentResolve]) || 
		(AppDelegate.connection.connectedWhiteboard.type == GSConnectionTypeLocal
		 &&  [AppDelegate.connection.connectedWhiteboard.name isEqualToString:service.name])) {
		
		DLog(@"adding to servicesToRemove");
		[self.servicesToRemove addObject:service];
	} else {
		// Remove service only if it's not my currentResolve (which means I'm connected to it)
		// and it's not the one asking me to accept/reject
		//DLog(@"removing from services. acceptReject.name:%@", [[(AppController*)[[UIApplication sharedApplication] delegate] acceptReject] name]); // name = (null)
		[self.services removeObject:service];
//		DLog(@"service removed out of list: %@", service);

		// If my own entry is going away, set self.ownEntry to nil
		if (self.ownEntry == service)
			self.ownEntry = nil;
		
		// If moreComing is NO, it means that there are no more messages in the queue from the Bonjour daemon, so we should update the UI.
		// When moreComing is set, we don't update the UI so that it doesn't 'flash'.
		if (!moreComing) {
			[self sortAndUpdateUI];
		}
		
	}
}


- (void)removeServiceWithName:(NSString*)name {
	//DLog(@"%s%@", _cmd, name);
	
	NSNetService* service;
	for (service in self.servicesToRemove) {
		if ([service.name isEqual:name]) {
			//DLog(@"removing %@", service.name);
			[self.services removeObject:service];
//			DLog(@"service removed out of list: %@", service);
			[self.servicesToRemove removeObject:service];
		}
	}
	
//	if ([NSThread isMainThread]) {
//		DLog(@"%s on MainThread", _cmd);
//	} else {
//		DLog(@"%s NOT on MainThread", _cmd);
//	}
	 
	[self didUpdateServicesData];
	 
}


- (void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didFindService:(NSNetService*)service moreComing:(BOOL)moreComing {
	DLog(@"%@ came online!", service.name);
	// If a service came online, add it to the list and update the table view if no more events are queued.
	if ([service.name isEqual:self.ownName]) {
		self.ownEntry = service;
//		DLog(@"ownEntry set to service");
	} else if ([self.servicesToRemove count] >= 1 && [service.name isEqual:((NSNetService*)[self.servicesToRemove objectAtIndex:0]).name]) {
		// Assumes we're only connected to 1 at a time
		[self.servicesToRemove removeObject:service];
//		DLog(@"removed from servicesToRemove");
	} else {
		[self.services addObject:service];
//		DLog(@"service added to list: %@", service);
	}

	// If moreComing is NO, it means that there are no more messages in the queue from the Bonjour daemon, so we should update the UI.
	// When moreComing is set, we don't update the UI so that it doesn't 'flash'.
	if (!moreComing) {
		[self sortAndUpdateUI];
	}
}


- (void)didUpdateServicesData {
	if ([_displayDelegate respondsToSelector:@selector(localBrowserDidReloadData)]) {
		[(GSConnectViewController *) _displayDelegate performSelectorOnMainThread:@selector(localBrowserDidReloadData)
																	   withObject:nil
																	waitUntilDone:YES];
	}
}


#if TARGET_OS_IPHONE
#pragma mark TableView for iOS
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// If there are no services and searchingForServicesString is set, show one row to tell the user.
	NSUInteger count = [self.services count];
	if (count == 0) {
		count = 1;
	}
	
#ifdef kDefaultPNG
	return 1;
#endif
	
	/*
	 if (self.connectedName)
	 return count + 1;
	 */
	
	//DLog(@"%s returned %d", _cmd, count);
	
#if LITE
	if (self.promoRowText) {
		count++;
	}
#endif
	
	return count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *tableCellIdentifier = @"LocalCell";
	UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:tableCellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:tableCellIdentifier] autorelease];
	}
	
	NSUInteger count = [self.services count];
	
#if LITE
	const CGFloat searchingFontSize = 15.0f;
#else
	const CGFloat searchingFontSize = 14.0f;
#endif
	
	if ((count == 0) && indexPath.row == 0) {
        // If there are no services and searchingForServicesString is set, show one row explaining that to the user.
		cell.textLabel.font = [UIFont boldSystemFontOfSize:searchingFontSize];
		//DLog(@"cell.font=%f", cell.font.pointSize);
		
		//[cell setTextColor:[UIColor whiteColor]];
		//[cell setShadowColor:[UIColor colorWithWhite:0.0 alpha:0.75]];
		//[cell setShadowOffset:CGSizeMake(1,1)];
		//[cell sizeToFit];
		
        cell.textLabel.text = @"Searching for other whiteboards..."; //self.searchingForServicesString;
		cell.textLabel.textColor = [UIColor colorWithWhite:0.5 alpha:0.5];
		cell.accessoryType = UITableViewCellAccessoryNone;
		//DLog(@"cell.bounds = %@", NSStringFromCGRect(cell.bounds));
		return cell;
	}
	
#ifdef kDefaultPNG
	cell.font = [UIFont boldSystemFontOfSize:searchingFontSize];
	cell.text = @"Searching for other whiteboards..."; //self.searchingForServicesString;
	cell.textColor = [UIColor colorWithWhite:0.5 alpha:0.5];
	cell.accessoryType = UITableViewCellAccessoryNone;
	return cell;
#endif // kDefaultPNG
	
	//cell.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];
#if LITE
	cell.font = [UIFont boldSystemFontOfSize:20.0];
#else
	cell.textLabel.font = [UIFont boldSystemFontOfSize:18.0];
#endif
	cell.textLabel.textColor = [UIColor blackColor];
	//	cell.accessoryType = self.showDisclosureIndicators ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
	cell.accessoryType = UITableViewCellAccessoryNone;
	
	NSNetService* service = nil;
	if (indexPath.row < count) {
		service = [self.services objectAtIndex:indexPath.row];
		cell.textLabel.text = [service name];
	}
#if LITE
	else {
		cell.text = self.promoRowText;
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.accessoryView = nil;
		return cell;
	}
#endif
	
	// TODO: handle case where Bonjour has done dynamic name conflict resolution
	
	// check for connected, if so, display a check symbol
	cell.accessoryView = nil;
	if (self.connection.status == ConnectionStatusConnected) {
		GSWhiteboard *connectedWhiteboard = [self.connection connectedWhiteboard];
		if (connectedWhiteboard && connectedWhiteboard.type == GSConnectionTypeLocal) {
			NSString *connectedJIDName = [(GSInternetWhiteboard *)connectedWhiteboard name];
			if ([[service name] isEqualToString:connectedJIDName]) {
				[GSFriendsListViewController setConnectedStatusToCell:cell];
			}
		}		
	} else if (self.connection.status == ConnectionStatusInConnecting) {
		GSWhiteboard *waitedWhiteboard = [self.connection waitedWhiteboard];		
		if (waitedWhiteboard && waitedWhiteboard.type == GSConnectionTypeLocal) {
			NSString *waitedJIDName = [(GSInternetWhiteboard *)waitedWhiteboard name];
			if ([[service name] isEqualToString:waitedJIDName]) {
				[GSFriendsListViewController addActivityIndicatorToCell:cell];
			}			
		}
	} else {
		cell.accessoryView = nil;
	}
	
	
	//	if ([NSThread isMainThread]) {
	//		DLog(@"%s on MainThread", _cmd);
	//	} else {
	//		DLog(@"%s NOT on MainThread", _cmd);
	//	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	// An otherwise invalid row selection
	if (indexPath.row >= [self.services count]) {
		//		[self.tableView deselectRowAtIndexPath:indexPath animated:YES]; //[self.tableView indexPathForSelectedRow]
		
		// Display an alert if there are no services and they tapped row 0
		if ([self.services count] == 0 && indexPath.row == 0) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Other whiteboards may be connected to the same\nWi-Fi Network"
															message:@"Available devices running Whiteboard on the same\nWi-Fi Network as you will\nappear in this list.\n\nIf your device supports Bluetooth peer-to-peer, and it is enabled, Whiteboard will automatically search for others using Bluetooth."
														   delegate:nil cancelButtonTitle:@"Continue" otherButtonTitles:nil];
			[alert show];
			[alert release];
			return;
		}
		
#if LITE
		// They must have tapped the promo row
		[(AppController*)[[UIApplication sharedApplication] delegate] showPromoUsingRowURL:YES];
#endif
		
		return;
	}
	
	NSNetService* service = [self.services objectAtIndex:indexPath.row];
	
	//	GSLocalWhiteboard *selectedWhiteboard = [[GSLocalWhiteboard alloc] initWithName:service.name];
	GSLocalWhiteboard *selectedWhiteboard = [[GSLocalWhiteboard alloc] initWithNetService:service name:service.name];	
	DLog (@"selected service: index: %d in list: %@", [indexPath row], self.services);
	
	//	selectedWhiteboard.service = [self.services objectAtIndex:indexPath.row];
	[AppDelegate.connection userSelectedWhiteboard:selectedWhiteboard];
	
	// info: it's on MainThread
	if ([NSThread isMainThread]) {
		DLog(@"%s on MainThread", _cmd);
	} else {
		DLog(@"%s NOT on MainThread", _cmd);
	}
	//		
	//		// showWaiting does reloadData
	//		//	[self reloadDataIfNotWaiting];
	//		
	//	}
	//	[self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
	//	[self reloadDataIfNotWaiting];
}

//#if LITE
//- (void)addPromoRowWithText:(NSString *)rowText {//openURL:(NSString *)openURL {
//	DLog(@"%s", _cmd);
//	
//	self.promoRowText = rowText;
//	//self.promoRowURL = openURL;
//	[self reloadDataIfNotWaiting];
//}
//#endif
#endif

- (NSInteger)numberOfPeers {
	// If there are no services and searchingForServicesString is set, show one row to tell the user.
	NSUInteger count = [self.services count];
	if (count == 0) {
		count = 1;
	}
	return count;
}

- (NSString *)peerNameForRow:(NSUInteger)row {
	
	if (row < [_services count]) {
		NSNetService *service = [_services objectAtIndex:row];
		return [service name];
	} else {
#if !TARGET_OS_IPHONE		
		if ([AppDelegate.customAlertTableDialogWindow isEnableNetworking] == NO) {
			return @"Networking is disabled!";
		}
#endif		
		
		return @"Searching for nearby Whiteboard...";
	}

	
	return nil;
}

- (void)didSelectPeerAtRow:(NSUInteger)row {
	if (row > [_services count]) {
		return;
	}
	
	NSNetService* service = [_services objectAtIndex:row];
	
	//	GSLocalWhiteboard *selectedWhiteboard = [[GSLocalWhiteboard alloc] initWithName:service.name];
	GSLocalWhiteboard *selectedWhiteboard = [[GSLocalWhiteboard alloc] initWithNetService:service name:service.name];	
	DLog (@"selected service: index: %d in list: %@", row, _services);
	
	//	selectedWhiteboard.service = [self.services objectAtIndex:indexPath.row];
	[AppDelegate.connection userSelectedWhiteboard:selectedWhiteboard];
	
}

- (void)clearAllServices {
	[_services removeAllObjects];
	[self didUpdateServicesData];
}

- (void)stopBrowsing {
	[self clearAllServices];
	[_netServiceBrowser stop];
}

- (void)startToBrowsing {
	[self searchForServicesOfType:[TCPServer bonjourTypeFromIdentifier:kGameIdentifier] inDomain:@"local"];
}

@end
