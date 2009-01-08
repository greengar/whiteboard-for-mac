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

#import "AppController.h"

// A category on NSNetService that's used to sort NSNetService objects by their name.
@interface NSNetService (BrowserViewControllerAdditions)
- (NSComparisonResult) localizedCaseInsensitiveCompareByName:(NSNetService*)aService;
@end

@implementation NSNetService (BrowserViewControllerAdditions)
- (NSComparisonResult) localizedCaseInsensitiveCompareByName:(NSNetService*)aService {
	return [[self name] localizedCaseInsensitiveCompare:[aService name]];
}
@end


@interface BrowserViewController()
@property (nonatomic, retain, readwrite) NSNetService* ownEntry;
@property (nonatomic, assign, readwrite) BOOL showDisclosureIndicators;
@property (nonatomic, retain, readwrite) NSMutableArray* services;
@property (nonatomic, retain, readwrite) NSMutableArray* servicesToRemove;
@property (nonatomic, retain, readwrite) NSNetServiceBrowser* netServiceBrowser;
//@property (nonatomic, retain, readwrite) NSNetService* currentResolve;
@property (nonatomic, retain, readwrite) NSTimer* timer;
@property (nonatomic, assign, readwrite) BOOL needsActivityIndicator;
@property (nonatomic, assign, readwrite) BOOL initialWaitOver;

- (void)stopCurrentResolve;
- (void)initialWaitOver:(NSTimer*)timer;
@end

@implementation BrowserViewController

@synthesize delegate = _delegate;
@synthesize ownEntry = _ownEntry;
@synthesize showDisclosureIndicators = _showDisclosureIndicators;
@synthesize currentResolve = _currentResolve;
@synthesize netServiceBrowser = _netServiceBrowser;
@synthesize services = _services;

@synthesize servicesToRemove = _servicesToRemove;

@synthesize needsActivityIndicator = _needsActivityIndicator;
@dynamic timer;
@synthesize initialWaitOver = _initialWaitOver;

//@synthesize connectedName = _connectedName;
@synthesize nextService = _nextService;

- (NSString*)connectedName {
	return _connectedName;
}

- (void)setConnectedName:(NSString*)newName {
	
	//NSLog(@"self.services:%@", self.services);
	/*
	if ([NSThread isMainThread]) {
		NSLog(@"%s on MainThread", _cmd);
	} else {
		NSLog(@"%s NOT on MainThread", _cmd);
	}
	 */
	[newName retain];
	[_connectedName release];
	_connectedName = newName;

	[self.tableView reloadData];
	/*
	NSNetService* service;
	for (service in self.services) {
		if ([service.name isEqual:_connectedName]) {
			[self.services removeObject:service];
		}
	}
	 */
}

- (id)initWithTitle:(NSString*)title showDisclosureIndicators:(BOOL)show showCancelButton:(BOOL)showCancelButton {
	
	if ((self = [super initWithStyle:UITableViewStyleGrouped/*UITableViewStylePlain*/])) {
		self.title = title;
		self.connectedName = nil;
		_services = [[NSMutableArray alloc] init];
		
		_servicesToRemove = [[NSMutableArray alloc] init];
		
		self.showDisclosureIndicators = show;

		if (showCancelButton) {
			// add Cancel button as the nav bar's custom right view
			UIBarButtonItem *addButton = [[UIBarButtonItem alloc]
										  initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction)];
			self.navigationItem.rightBarButtonItem = addButton;
			[addButton release];
		}

		// Make sure we have a chance to discover devices before showing the user that nothing was found (yet)
		[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(initialWaitOver:) userInfo:nil repeats:NO];
	}

	return self;
}

- (NSString *)searchingForServicesString {
	return _searchingForServicesString;
}

// Holds the string that's displayed in the table view during service discovery.
- (void)setSearchingForServicesString:(NSString *)searchingForServicesString {
	if (_searchingForServicesString != searchingForServicesString) {
		[_searchingForServicesString release];
		_searchingForServicesString = [searchingForServicesString copy];

        // If there are no services, reload the table to ensure that searchingForServicesString appears.
		if ([self.services count] == 0) {
			/*
			if ([NSThread isMainThread]) {
				NSLog(@"%s on MainThread", _cmd);
			} else {
				NSLog(@"%s NOT on MainThread", _cmd);
			}
			 */
			
			[self.tableView reloadData];
		}
	}
}

- (NSString *)ownName {
	return _ownName;
}

// NOT on MainThread. Is that OK?
// Holds the string that's displayed in the table view during service discovery.
- (void)setOwnName:(NSString *)name {
	if (_ownName != name) {
		_ownName = [name copy];
		
		if (self.ownEntry)
			[self.services addObject:self.ownEntry];
		
		NSNetService* service;
		
		for (service in self.services) {
			if ([service.name isEqual:name]) {
				self.ownEntry = service;
				[_services removeObject:service];
				break;
			}
		}
		
		if ([NSThread isMainThread]) {
			NSLog(@"%s on MainThread", _cmd);
		} else {
			NSLog(@"%s NOT on MainThread", _cmd);
		}
		[self.tableView reloadData];
	}
}

// Creates an NSNetServiceBrowser that searches for services of a particular type in a particular domain.
// If a service is currently being resolved, stop resolving it and stop the service browser from
// discovering other services.
// Executes on MainThread
- (BOOL)searchForServicesOfType:(NSString *)type inDomain:(NSString *)domain {
	//NSLog(@"%s", _cmd);
	
	[self stopCurrentResolve];
	[self.netServiceBrowser stop];
	[self.services removeAllObjects];

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
		NSLog(@"%s on MainThread", _cmd);
	} else {
		NSLog(@"%s NOT on MainThread", _cmd);
	}
	 */
	
	[self.tableView reloadData];
	return YES;
}


- (NSTimer *)timer {
	return _timer;
}

// When this is called, invalidate the existing timer before releasing it.
- (void)setTimer:(NSTimer *)newTimer {
	[_timer invalidate];
	[newTimer retain];
	[_timer release];
	_timer = newTimer;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// If there are no services and searchingForServicesString is set, show one row to tell the user.
	NSUInteger count = [self.services count];
	if (count == 0/* && self.searchingForServicesString && self.initialWaitOver*/)
		count = 1;
		//return 1;
	
	/*
	if (self.connectedName)
		return count + 1;
	 */
	
	//NSLog(@"%s returned %d", _cmd, count);
	
	return count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *tableCellIdentifier = @"UITableViewCell";
	UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:tableCellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:tableCellIdentifier] autorelease];
	}
	
	NSUInteger count = [self.services count];
	if (count == 0/* && self.searchingForServicesString*/) {
        // If there are no services and searchingForServicesString is set, show one row explaining that to the user.
		cell.font = [UIFont boldSystemFontOfSize:15.0];
		//NSLog(@"cell.font=%f", cell.font.pointSize);

		//[cell setTextColor:[UIColor whiteColor]];
		//[cell setShadowColor:[UIColor colorWithWhite:0.0 alpha:0.75]];
		//[cell setShadowOffset:CGSizeMake(1,1)];
		//[cell sizeToFit];
		
        cell.text = self.searchingForServicesString;
		cell.textColor = [UIColor colorWithWhite:0.5 alpha:0.5];
		cell.accessoryType = UITableViewCellAccessoryNone;
		//NSLog(@"cell.bounds = %@", NSStringFromCGRect(cell.bounds));
		return cell;
	}
	//cell.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];
	cell.font = [UIFont boldSystemFontOfSize:20.0];
	
	NSNetService* service;
	/*
	if (self.connectedName && indexPath.row == 0) {
		cell.text = self.connectedName;
		service = nil;
	} else {
	 */
		// Set up the text for the cell
		/*
		if (self.connectedName) {
			service = [self.services objectAtIndex:indexPath.row - 1];
		} else {
		 */
			service = [self.services objectAtIndex:indexPath.row];
			//NSLog(@"indexPath.row:%d name:%@", indexPath.row, service.name);
		//}
		cell.text = [service name];
	//}
	
	cell.textColor = [UIColor blackColor];
	cell.accessoryType = self.showDisclosureIndicators ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
	
	//assert(!(self.currentResolve == nil && service == nil));
	
	//NSLog(@"self.needsActivityIndicator == %d, self.currentResolve == %@, service == %@", self.needsActivityIndicator, self.currentResolve, service);
	// Note that the underlying array could have changed, and we want to show the activity indicator on the correct cell
	if (self.needsActivityIndicator && self.currentResolve == service && service != nil) {
		if (!cell.accessoryView) {
			//cell.accessoryType = UITableViewCellAccessoryNone;
			
			//NSLog(@"showing activity indicator");
			
			// show the activity indicator in the status bar
			[UIApplication sharedApplication].isNetworkActivityIndicatorVisible = YES;
			
			CGRect frame = CGRectMake(0.0, 0.0, kProgressIndicatorSize, kProgressIndicatorSize);
			UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithFrame:frame];
			[spinner startAnimating];
			// default is white, which is better
			//spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
			[spinner sizeToFit];
			spinner.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
										UIViewAutoresizingFlexibleRightMargin |
										UIViewAutoresizingFlexibleTopMargin |
										UIViewAutoresizingFlexibleBottomMargin);
			cell.accessoryView = spinner;
			[spinner release];
		}
	} else if (self.connectedName && [self.connectedName isEqualToString:service.name] && cell.accessoryType != UITableViewCellAccessoryCheckmark) {
		/* && indexPath.row == 0 */
		//([self.connectedName isEqualToString:service.name]/* || self.currentResolve == service*/)
		
		// TODO: handle case where Bonjour has done dynamic name conflict resolution
		
		NSLog(@"self.connectedName:%@", self.connectedName);
		
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
		
		// If the value of this property is not nil,
		// the UITableViewCell class uses the given view for the accessory view and
		// ignores the value of the accessoryType property
		cell.accessoryView = nil;
		
		// Checkmark blue (#2D4F85)
		cell.textColor = [UIColor colorWithRed:0.176 green:0.310 blue:0.522 alpha:1.0];
		
		// hide the activity indicator in the status bar
		[UIApplication sharedApplication].isNetworkActivityIndicatorVisible = NO;
	} else if (cell.accessoryView) {
		cell.accessoryType = UITableViewCellAccessoryNone;
		
		// hide the activity indicator in the status bar
		[UIApplication sharedApplication].isNetworkActivityIndicatorVisible = NO;
		
		cell.accessoryView = nil;
	}
	
	return cell;
}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// Ignore the selection if there are no services.
	if ([self.services count] == 0 && !self.connectedName) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Other whiteboards must be connected to the same\nWi-Fi Network"
														message:@"Available devices running Whiteboard on the same\nWi-Fi Network as you will appear in this list."
													   delegate:nil cancelButtonTitle:@"Continue" otherButtonTitles:nil];
		[alert show];
		[alert release];
		
		return nil;
	}

	return indexPath;
}


// Executes on MainThread
- (void)stopCurrentResolve {

	if (self.timer) {
		[self.timer invalidate]; // Hope this doesn't crash...
		self.timer = nil;
	}

	[self.currentResolve stop];
	//self.currentResolve = nil;

	/*
	if ([NSThread isMainThread]) {
		NSLog(@"%s on MainThread", _cmd);
	} else {
		NSLog(@"%s NOT on MainThread", _cmd);
	}
	 */
	
	[self.tableView reloadData];
}

// Call this only when we have successfully connected
- (void)stopActivityIndicator:(id)useless {
	NSLog(@"%s", _cmd);
	
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];

	// Say we're connected to self.connectedName
	// TODO: assumes we're connected to only 1
	// self.connectedName = self.currentResolve.name;
	[self setConnectedName:self.currentResolve.name];
	
	// Leave currentResolve until we resolve a different device or disconnect completely
	//self.currentResolve = nil;
	
	self.needsActivityIndicator = NO;
	
	if ([NSThread isMainThread]) {
		NSLog(@"%s on MainThread", _cmd);
	} else {
		NSLog(@"%s NOT on MainThread", _cmd);
	}
	[self.tableView reloadData];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSNetService* service = [self.services objectAtIndex:indexPath.row];
	NSString* message = @"";

	if (self.connectedName) {
		// Already connected case
		if ([self.connectedName isEqual:service.name]) {
			//message = @"";
			self.nextService = nil;
		} else {
			self.nextService = service;//[self.services objectAtIndex:indexPath.row/* - 1*/];
			message = [NSString stringWithFormat:@"You will then connect to “%@”", self.nextService.name];
		}
	} else if (self.currentResolve) {
		// Not yet established case, but connection pending
		if ([self.currentResolve.name isEqual:service.name]) {
			//message = @"";
			self.nextService = nil;
		} else {
			self.nextService = service;//[self.services objectAtIndex:indexPath.row/* - 1*/];
			message = [NSString stringWithFormat:@"You will then connect to “%@”", self.nextService.name];
		}
	} else if ([[(AppController*)[[UIApplication sharedApplication] delegate] acceptReject] name] != nil) {
		//[[[(AppController*)[[UIApplication sharedApplication] delegate] acceptReject] name] isEqualToString:service.name]
		// This peer is waiting for decision from me: Don't try to resolve them!
		// Can't just check that acceptReject is null because it's not reliable?!
		
		// I can do [_acceptReject setName:nil]; anytime, but what streams am I connected to?
		
		[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
		return;
	}
	
	/* else {
	 
		service = 
	}
	 */
	if (self.connectedName/*[self.connectedName isEqualToString:service.name] || self.currentResolve == service*/) {
		// Show disconnect confirmation
		UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Do you want to disconnect from “%@”?", self.connectedName] message:message delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
		[alertView show];
		[alertView release];
	} else if (self.currentResolve) {
		// Show disconnect confirmation
		UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Do you want to disconnect from “%@”?", self.currentResolve.name] message:message delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
		[alertView show];
		[alertView release];
	} else {
	
	/*
	if ([NSThread isMainThread]) {
		NSLog(@"%s on MainThread", _cmd);
	}
	 */

	//NSLog(@"showing activity indicator");
	// show the activity indicator in the status bar
	//[UIApplication sharedApplication].isNetworkActivityIndicatorVisible = YES;
	
	// If another resolve was running, stop it first
	
	[self stopCurrentResolve];
	self.currentResolve = [self.services objectAtIndex:indexPath.row];

	[self.currentResolve setDelegate:self];
	// Attempt to resolve the service. A value of 0.0 sets an unlimited time to resolve it. The user can
	// choose to cancel the resolve by selecting another service in the table view.
	[self.currentResolve resolveWithTimeout:0.0];
	
	// Make sure we give the user some feedback that the resolve is happening.
	// We will be called back asynchronously, so we don't want the user to think
	// we're just stuck.
	
	// don't need retain here?
	//self.timer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(showWaiting:) userInfo:self.currentResolve repeats:NO] retain];
	[self showWaiting/*ForResolve:self.currentResolve*/];
	//NSLog(@"self.timer == %@", self.timer);
	
	if ([NSThread isMainThread]) {
		NSLog(@"%s on MainThread", _cmd);
	} else {
		NSLog(@"%s NOT on MainThread", _cmd);
	}
	[self.tableView reloadData];
		
	}
}


// Disconnect?
- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	//NSLog(@"bvc alertView buttonIndex:%d", buttonIndex);
	
	if (buttonIndex == 1) {
		// Yes
		
		// Disconnect from all peers
		[(AppController*)[[UIApplication sharedApplication] delegate] disconnectFromPeerWithStream:nil];
		
		// Connect to a different service, if selected
		if (self.nextService) {
			[self stopCurrentResolve];
			self.currentResolve = self.nextService; //[self.services objectAtIndex:indexPath.row];
			
			[self.currentResolve setDelegate:self];
			// Attempt to resolve the service. A value of 0.0 sets an unlimited time to resolve it. The user can
			// choose to cancel the resolve by selecting another service in the table view.
			[self.currentResolve resolveWithTimeout:0.0];
			
			// Make sure we give the user some feedback that the resolve is happening.
			// We will be called back asynchronously, so we don't want the user to think
			// we're just stuck.
			
			// don't need retain here?
			//self.timer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(showWaiting:) userInfo:self.currentResolve repeats:NO] retain];
			[self showWaiting/*ForResolve:self.currentResolve*/];
			//NSLog(@"self.timer == %@", self.timer);
			
			if ([NSThread isMainThread]) {
				NSLog(@"%s on MainThread", _cmd);
			} else {
				NSLog(@"%s NOT on MainThread", _cmd);
			}
			[self.tableView reloadData];
		} else {
			// Deselect if not connecting to a different service
			[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];	
		}
	} else {
		// No
		
		// Deselect if user said No, but only if we are not waiting for something
		// Commented first part b/c while connected if disconnect option is turned down, it should deselect
		if (/*!self.connectedName && */!self.currentResolve) {
			[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
		}
	}
}

/*
// If necessary, sets up state to show an activity indicator to let the user know that a resolve is occurring.
- (void)showWaiting:(NSTimer*)timer {
	NSLog(@"%s", _cmd);
	if (timer == self.timer) {
		//[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
		NSNetService* service = (NSNetService*)[self.timer userInfo];
		if (self.currentResolve == service) {
			self.needsActivityIndicator = YES;
			[self.tableView reloadData];
		}
	}
}
*/

- (void)showWaiting/*ForResolve:(NSNetService*)service*/ {
	NSLog(@"%s", _cmd);

	//if (self.currentResolve == service) {
	self.needsActivityIndicator = YES;
	
	if ([NSThread isMainThread]) {
		NSLog(@"%s on MainThread", _cmd);
	} else {
		NSLog(@"%s NOT on MainThread", _cmd);
	}
	[self.tableView reloadData];
	//}
}

- (void)initialWaitOver:(NSTimer*)timer {
	self.initialWaitOver= YES;
	if (![self.services count]) {
		if ([NSThread isMainThread]) {
			NSLog(@"%s on MainThread", _cmd);
		} else {
			NSLog(@"%s NOT on MainThread", _cmd);
		}
		[self.tableView reloadData];
	}
}


- (void)sortAndUpdateUI {
	// Sort the services by name.
	[self.services sortUsingSelector:@selector(localizedCaseInsensitiveCompareByName:)];
	// Executes on MainThread
	/*
	if ([NSThread isMainThread]) {
		NSLog(@"%s on MainThread", _cmd);
	} else {
		NSLog(@"%s NOT on MainThread", _cmd);
	}
	 */
	[self.tableView reloadData];
}


- (void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didRemoveService:(NSNetService*)service moreComing:(BOOL)moreComing {
	// If a service went away, stop resolving it if it's currently being resolve,
	// remove it from the list and update the table view if no more events are queued.
	
	NSLog(@"netServiceBrowser:%@ didRemoveService.name:%@ moreComing:%d", netServiceBrowser, service.name, moreComing);
	
	/*
	if (self.currentResolve && [service isEqual:self.currentResolve]) {
		[self stopCurrentResolve];
		[self.servicesToRemove addObject:service];
	} else
	 */
	
	// When I've disconnected, I need to set acceptReject.name to nil
	
	if ([[[(AppController*)[[UIApplication sharedApplication] delegate] acceptReject] name] isEqualToString:service.name] || (self.currentResolve && [service isEqual:self.currentResolve]) || [self.connectedName isEqualToString:service.name]) {
		
		NSLog(@"adding to servicesToRemove");
		[self.servicesToRemove addObject:service];
	} else {
		// Remove service only if it's not my currentResolve (which means I'm connected to it)
		// and it's not the one asking me to accept/reject
		NSLog(@"removing from services. acceptReject.name:%@", [[(AppController*)[[UIApplication sharedApplication] delegate] acceptReject] name]);
		[self.services removeObject:service];
	
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
	//NSLog(@"%s%@", _cmd, name);
	
	NSNetService* service;
	for (service in self.servicesToRemove) {
		if ([service.name isEqual:name]) {
			//NSLog(@"removing %@", service.name);
			[self.services removeObject:service];
			[self.servicesToRemove removeObject:service];
		}
	}
	
	if ([NSThread isMainThread]) {
		NSLog(@"%s on MainThread", _cmd);
	} else {
		NSLog(@"%s NOT on MainThread", _cmd);
	}
	 
	//[self.tableView reloadData];
	 
}


- (void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didFindService:(NSNetService*)service moreComing:(BOOL)moreComing {
	NSLog(@"%@ came online!", service.name);
	// If a service came online, add it to the list and update the table view if no more events are queued.
	if ([service.name isEqual:self.ownName]) {
		self.ownEntry = service;
		NSLog(@"ownEntry set to service");
	} else if ([self.servicesToRemove count] >= 1 && [service.name isEqual:((NSNetService*)[self.servicesToRemove objectAtIndex:0]).name]) {
		// Assumes we're only connected to 1 at a time
		[self.servicesToRemove removeObject:service];
		NSLog(@"removed from servicesToRemove");
	} else {
		[self.services addObject:service];
		NSLog(@"service added to list");
	}

	// If moreComing is NO, it means that there are no more messages in the queue from the Bonjour daemon, so we should update the UI.
	// When moreComing is set, we don't update the UI so that it doesn't 'flash'.
	if (!moreComing) {
		[self sortAndUpdateUI];
	}
}	


// This should never be called, since we resolve with a timeout of 0.0, which means indefinite
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
	[self stopCurrentResolve];
	
	if ([NSThread isMainThread]) {
		NSLog(@"%s on MainThread", _cmd);
	} else {
		NSLog(@"%s NOT on MainThread", _cmd);
	}
	[self.tableView reloadData];
}


// ignore this if currentResolve got set to nil?
- (void)netServiceDidResolveAddress:(NSNetService *)service {
	NSLog(@"%s", _cmd);
	if (service) {
		NSLog(@"service.name == %@", service.name);
	} else {
		NSLog(@"service == nil");
	}
	if (self.currentResolve) {
		NSLog(@"self.currentResolve.name == %@", self.currentResolve.name);
	} else {
		NSLog(@"self.currentResolve == nil");
	}
	
	if (self.currentResolve == nil)
		return;
	
	assert(service == self.currentResolve);
	
	[service retain];
	[self stopCurrentResolve];
	
	[self.delegate browserViewController:self didResolveInstance:service];
	[service release];
}


- (void)cancelAction {
	[self.delegate browserViewController:self didResolveInstance:nil];
}


- (void)dealloc {
	// Cleanup any running resolve and free memory
	[self stopCurrentResolve];
	self.services = nil;
	[self.netServiceBrowser stop];
	self.netServiceBrowser = nil;
	[_searchingForServicesString release];
	[_ownName release];
	[_ownEntry release];
	
	[super dealloc];
}


@end
