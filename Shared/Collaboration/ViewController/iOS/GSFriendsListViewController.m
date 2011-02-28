#import "GSFriendsListViewController.h"
#import "AppController.h"

#import "XMPP.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPUserCoreDataStorage.h"
#import "XMPPResourceCoreDataStorage.h"


#import "GSWhiteboard.h"
#import "GSLocalConnection.h"
//#import "GSLocalConnection+NSStreamDelegate.h"
#import "BrowserViewController.h"

#import "GSConnectViewController.h"
#import "GSConnectionController.h"
#import "BrowserViewController.h"
#import "GSAddFriendView.h"
#import "GSWhiteboardUser.h"
#import "GSConnectionController.h"
#import "GSXmlRpcHelper.h"
#import "GSViewHelper.h"
#import "GSAlert.h"
#import "GSAlertHelper.h"

//#import "SphereNetViewController.h"
static NSString *offlineString = @"Go Online";
static NSString *onlineString = @"Go Offline";
static NSString *kDisplayingOfflineFriends = @"kDisplayingOfflineFriends";

@interface GSFriendsListViewController()

@property (nonatomic, retain) UIView *internetFooterView;
@property (nonatomic, retain) UIButton *goOfflineButton;
@end


@implementation GSFriendsListViewController
//@synthesize sphereNetArena = _sphereNetArena;
@synthesize requesterIndexPath = _requesterIndexPath;
@synthesize internetConnection = _internetConnection;
@synthesize restoringConnectionAlertView = _restoringConnectionAlertView;
//@synthesize addFriendText = _addFriendText;
@synthesize internetView = _internetView;
@synthesize onlineFriends = _onlineFriends, offlineFriends = _offlineFriends;
@synthesize internetFooterView = _internetFooterView;
@synthesize goOfflineButton = _goOfflineButton;

static GSConnectionController *connection = nil;

- (id)initWithInternetConnection:(GSInternetConnection *)internetConnection {
	if ((self = [super initWithNibName:@"GSFriendsListView" bundle:nil])) {
		_internetConnection = internetConnection;
		// Check connected information
//		isLogedIn = [UIAppDelegate.connection.xmppStream isConnected] && [UIAppDelegate.connection.xmppStream isAuthenticated];
	}
	return self;
}

- (id)initWithInternetConnection:(GSInternetConnection *)internetConnection
					localBrowser:(BrowserViewController *)bvc {
	if ((self = [self initWithInternetConnection:internetConnection])) {
		_localBrowser = [bvc retain];
	}
	
	return self;
}

- (void)dealloc {
	[_requesterIndexPath release];
	[_localBrowser release];    
    [_requesterIndexPath release];
	[_internetView release];
    [_restoringConnectionAlertView release];
	[super dealloc];
}


- (GSConnectionController *)connection {
	if (connection == nil) {
		connection = UIAppDelegate.connection;
	}
	return connection;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (GSConnectViewController *)connectController {
	return (GSConnectViewController *)self.navigationController;
}

//- (GSConnectionController *)connectionController {
//	return [[self appDelegate] connection];
//}
   
- (XMPPStream *)xmppStream
{
	return [_internetConnection xmppStream];
}

- (XMPPRoster *)xmppRoster
{
	return [_internetConnection xmppRoster];
}

- (XMPPRosterCoreDataStorage *)xmppRosterStorage {
	return [_internetConnection xmppRosterStorage];
}

- (NSManagedObjectContext *)managedObjectContext
{
	return [[self xmppRosterStorage] managedObjectContext];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSFetchedResultsController
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSFetchedResultsController *)fetchedResultsController
{
	if (fetchedResultsController == nil)
	{
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorage"
		                                          inManagedObjectContext:[self managedObjectContext]];
		
		NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"sectionNum" ascending:YES];
		NSSortDescriptor *sd2 = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
		
		NSArray *sortDescriptors = [NSArray arrayWithObjects:sd1, sd2, nil];
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:entity];
		[fetchRequest setSortDescriptors:sortDescriptors];
		[fetchRequest setFetchBatchSize:10];
		
		fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
		                                                               managedObjectContext:[self managedObjectContext]
		                                                                 sectionNameKeyPath:@"sectionNum"
		                                                                          cacheName:nil];
		[fetchedResultsController setDelegate:self];
		
		[sd1 release];
		[sd2 release];
		[fetchRequest release];
		
		NSError *error = nil;
		if (![fetchedResultsController performFetch:&error])
		{
			NSLog(@"Error performing fetch: %@", error);
		}
	}
	
	return fetchedResultsController;
}

- (NSArray *)getOfflineFriendsFromSectionIndex:(NSInteger)sectionIndex {
    NSArray *sections = [[self fetchedResultsController] sections];
    if ([sections count] > sectionIndex) {
        NSMutableArray *offlineFriends = [NSMutableArray array];
        for (NSInteger i = sectionIndex; i < [sections count]; i++) {
            [offlineFriends addObjectsFromArray:[[sections objectAtIndex:i] objects]];
        }
        return [NSArray arrayWithArray:offlineFriends];
    }
    return [NSArray array];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    DLog();
    
	NSArray *sections = [[self fetchedResultsController] sections];
    self.onlineFriends = [NSArray array];
    self.offlineFriends = [NSArray array];
    
	if ([sections count] > 0) {
		id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:0];
		
		if ([sectionInfo.name intValue] != 0) { // there is no online Whiteboard
            self.onlineFriends = [NSArray array];
            self.offlineFriends = [self getOfflineFriendsFromSectionIndex:0];
		} else {
			self.onlineFriends = [sectionInfo objects];
            self.offlineFriends = [self getOfflineFriendsFromSectionIndex:1];
		}
	}	
    
//    DLog(@"onlineFriends count: %d & offlineFriends count: %d", [self.onlineFriends count], [self.offlineFriends count]);
    
	[[self tableView] reloadData];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFriendsListDidChange object:nil];
}

#pragma mark View

- (BOOL)isConnected {
	return [_internetConnection.xmppStream isConnected];
}

- (void)updateToolBar {
	if ([self isConnected] == NO) {
		[self.navigationController setToolbarHidden:YES animated:YES];		
		return;
	}
	
	if (self.toolbarItems == nil) {
		UIBarButtonItem *signOutButton = [[[UIBarButtonItem alloc] initWithTitle:@"Sign out" 
																		   style:UIBarButtonItemStyleBordered
																		  target:self.navigationController
																		  action:@selector(logoutTapped:)] autorelease];
		
		// add toolbar	
		UIBarButtonItem *addFriendViewButton = [[[UIBarButtonItem alloc] initWithTitle:@"Add friends"
																				 style:UIBarButtonItemStyleBordered
																				target:self 
																				action:@selector(addFriendButtonPressed)] autorelease];
		UIBarButtonItem *spaceBarItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																					   target:self action:nil] autorelease];
		
		/*
		 UIBarButtonItem *printRoster = [[[UIBarButtonItem alloc] initWithTitle:@"Print roster"
		 style:UIBarButtonItemStyleBordered
		 target:self 
		 action:@selector(printRoster)] autorelease];
		 */
		
		
		self.toolbarItems = [NSArray arrayWithObjects:
							 //						 printRoster,
							 signOutButton,
							 spaceBarItem,
							 addFriendViewButton, nil];	
	}
	

	[self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	if (IS_IPAD) {
		if ([self respondsToSelector:@selector(setContentSizeForViewInPopover:)]) {
			self.contentSizeForViewInPopover = CGSizeMake(320, 460);
		}	
//	} else {
//		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
//																							   target:self.navigationController
//																							   action:@selector(doneTapped:)] autorelease];	
	}

	
	self.navigationItem.title = @"Networking";	
//    self.navigationController.navigationBar.` = [UIColor greenColor];
    self.tableView.backgroundColor = [UIColor colorWithRed:0.90 green:0.91 blue:0.92 alpha:1.0];
    //[UIColor colorWithRed:0.62 green:0.66 blue:0.72 alpha:1.0];
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectedNotification:) name:@"kConnectedNotification" object:nil];

}

//- (void)connectedNotification:(NSNotification *)notification {
//	// show check mark
//}


- (void)viewDidUnload {
	[super viewDidUnload];

	// TODO remove notification
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	DLog();

	if (_internetView) {
		[_internetView viewWillAppear:animated];	
	}
//	[self updateToolBar];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(keyboardWillShow:)
//                                                 name:UIKeyboardWillShowNotification
//                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(keyboardWillHide:)
//                                                 name:UIKeyboardWillHideNotification
//                                               object:nil];    
}

//- (void)viewWillDisappear:(BOOL)animated {
//    [super viewWillDisappear:animated];
//    [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                    name:UIKeyboardWillShowNotification
//                                                  object:nil];
//    
//
//    [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                    name:UIKeyboardWillHideNotification
//                                                  object:nil];
//    
//}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:YES];
	[self.tableView reloadData];
	
	// this doesn't seem to be necessary because UITableViewController already does this in its implementation of -viewDidAppear:
	//[self.tableView flashScrollIndicators];
}

- (void)addFriendButtonPressed {
	GSAddFriendView *_addFriendController = [[[GSAddFriendView alloc] initWithFriendsList:self] autorelease];
	[self.navigationController pushViewController:_addFriendController animated:YES];
}


- (void)goOfflineButtonPressed {
    if ([[_goOfflineButton titleForState:UIControlStateNormal] isEqualToString:offlineString]) {
        [_internetConnection goOnline];
        [_goOfflineButton setTitle:onlineString forState:UIControlStateNormal];
    } else {
        [_internetConnection goOffline];
        [_goOfflineButton setTitle:offlineString forState:UIControlStateNormal];        
    }

}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UITableView
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//	return [[[self fetchedResultsController] sections] count] + 1;
//	[self printRoster];
#if INTERNET_SUPPORTING
	return 2;
#else
	return 1;
#endif
}


static int cellIndexAddFriendsButton = -1;
static int cellIndexOnlineStart = -1;
static int cellIndexOfflineButton = -1;
static int cellIndexOfflineStart = -1;

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
	if (sectionIndex == 0) {
		return [_localBrowser tableView:tableView numberOfRowsInSection:sectionIndex];
	} 
	
	if (_internetView) {
		return [_internetView tableView:tableView numberOfRowsInSection:sectionIndex];
	}
	
    
    NSInteger whiteboardOnlineRow = 0;
    
    cellIndexAddFriendsButton = 0;    
    whiteboardOnlineRow++;

    
    NSArray *sections = [[self fetchedResultsController] sections];
    
    cellIndexOnlineStart = whiteboardOnlineRow;
    if ([sections count] > 0) {
//        whiteboardOnlineRow = [[[self fetchedResultsController] fetchedObjects] count];
        whiteboardOnlineRow += [self.onlineFriends count];
        if ([self.onlineFriends count] == 0) {
            whiteboardOnlineRow++; // there is no online Whiteboard
        }
        
        
        if ([self.offlineFriends count] > 0) {

            cellIndexOfflineButton = whiteboardOnlineRow;
            whiteboardOnlineRow++; // there has offline friends            
            
            cellIndexOfflineStart = whiteboardOnlineRow;
                        
            if ([NSDEF boolForKey:kDisplayingOfflineFriends] == YES) {
                whiteboardOnlineRow += [self.offlineFriends count];
            }
            
        }
    }
    
//	NSArray *sections = [[self fetchedResultsController] sections];
    
//	if ([sections count] > 0) {
//		id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:0];
//		
//		if ([sectionInfo.name intValue] != 0) { 
//			whiteboardOnlineRow = 1; // info message field
//		} else {
//			whiteboardOnlineRow = sectionInfo.numberOfObjects;
//		}
//	}	
    
//    whiteboardOnlineRow +=
//    DLog(@"whiteboardOnlineRow: %d", whiteboardOnlineRow);
    
    return whiteboardOnlineRow; // add friend
		
//	if (sectionIndex < [sections count])
//	{
//		id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
//		
//		if (([sectionInfo.name intValue] == 0) && (sectionInfo.numberOfObjects == 0) {
//			
//		}
//			
//		
////		NSLog(@"section info: %@", sectionInfo);
////		NSLog(@"section title: %@, name: %@", sectionInfo.indexTitle, sectionInfo.name);
//		return sectionInfo.numberOfObjects;
//	}
	
	return 0;
}

- (NSString *)userDisplayNameAfterRemovingEmailDomain:(NSString *)email {
	// input: kong@chatmask.com OR kong
	// output: kong
	NSString *username = email;
	
	NSRange emailSymbol = [email rangeOfString:@"@"];
	
	if (emailSymbol.location !=  NSNotFound) {
		username = [email substringToIndex:emailSymbol.location];
	}
	
	return [GSWhiteboardUser displayNameFromXMPPUser:username];
}

- (void)printRoster {
	DLog();
	NSArray *sections = [[self fetchedResultsController] sections];
	
	for (id <NSFetchedResultsSectionInfo> sectionInfo in sections) {
		NSLog(@"section: name %@, title: %@, number of object: %d", 
			  [sectionInfo name], [sectionInfo indexTitle], [sectionInfo numberOfObjects]);
		
//		NSLog(@"section: name %@, number of object: %d", 
//			  [sectionInfo name], [sectionInfo numberOfObjects]);
		NSArray *objects = [sectionInfo objects];
		for (XMPPUserCoreDataStorage *user in objects) {
			NSLog(@"user: jid %@, subscription: %@, ask: %@, resource: %@",
				  [user jidStr], [user subscription], [user ask], [user resources]);
		}
		NSLog(@"end section");
	}
		
}

- (UITableViewCell *)onlineFriendCellForUser:(XMPPUserCoreDataStorage *)user {
    static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
									   reuseIdentifier:CellIdentifier] autorelease];
	}			

    cell.textLabel.textColor = [UIColor blackColor];
    
    cell.textLabel.text = [self userDisplayNameAfterRemovingEmailDomain:user.displayName];
	cell.accessoryView = nil;
	cell.accessoryType = UITableViewCellAccessoryNone;
    
	// check for connected, if so, display a check symbol
	if (self.connection.status == ConnectionStatusConnected) {
		GSWhiteboard *connectedWhiteboard = [self.connection connectedWhiteboard];
		if (connectedWhiteboard && connectedWhiteboard.type == GSConnectionTypeInternet) {
			NSString *connectedJIDName = [[(GSInternetWhiteboard *)connectedWhiteboard jid] user];
			if ([[user.jid user] isEqualToString:connectedJIDName]) {
				[[self class] setConnectedStatusToCell:cell];
			}
		}		
	} else if (self.connection.status == ConnectionStatusInConnecting) {
		GSWhiteboard *waitedWhiteboard = [self.connection waitedWhiteboard];		
		if (waitedWhiteboard && waitedWhiteboard.type == GSConnectionTypeInternet) {
			NSString *waitedJIDName = [[(GSInternetWhiteboard *)waitedWhiteboard jid] user];
			if ([[user.jid user] isEqualToString:waitedJIDName]) {
				[[self class] addActivityIndicatorToCell:cell];
			}			
		}
	}
    return cell;
}

- (UITableViewCell *)offFriendCellForUser:(XMPPUserCoreDataStorage *)user {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Offline Cell"];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Offline Cell"] autorelease];
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
    cell.textLabel.textColor = [UIColor grayColor];
    cell.textLabel.text = [self userDisplayNameAfterRemovingEmailDomain:user.displayName];
    
    cell.textLabel.text = [self userDisplayNameAfterRemovingEmailDomain:user.displayName];
	cell.accessoryView = nil;
	cell.accessoryType = UITableViewCellAccessoryNone;    
    
	cell.detailTextLabel.text = nil;
	
	if (user != nil) {
//		NSString *subscription = [user subscription];
		NSString *ask = [user ask];
		
		// jidString: huhuhi.g.g.s@binaryfreedom.info subscription: none ask: subscribe
		// jidString: koncer.g.g.s@openjabber.org subscription: both ask: (null)
		
        if ([ask isEqualToString:@"subscribe"]) {
			cell.detailTextLabel.text = @"Pending";
		}
        
	}
    //	cell.text = @"hihi";
	return cell;
}



- (UITableViewCell *)offlineFriendsButtonCell {
    UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                   reuseIdentifier:@"ButtonCell"] autorelease];			
    cell.textLabel.text = @"Offline friends";
    cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0f];		
    cell.textLabel.textColor = [UIColor colorWithRed:0.176 green:0.310 blue:0.522 alpha:1.0];
//    cell.textLabel.textAlignment = UITextAlignmentCenter;
    
    UIImage *disclosureIndicator = nil;
    if ([NSDEF boolForKey:kDisplayingOfflineFriends]) {
        disclosureIndicator = [UIImage imageNamed:@"CloseUpIndicator.png"];
    } else {
        disclosureIndicator = [UIImage imageNamed:@"ExpandIndicator.png"];
    }
    
    cell.accessoryView = [[[UIImageView alloc] initWithImage:disclosureIndicator] autorelease];
    
    return cell;    
}

//static NSInteger offlineButtonIndex = 0;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
		
	if ([indexPath section] == 0) {
		return [_localBrowser tableView:tableView cellForRowAtIndexPath:indexPath];
	}
	
	if (_internetView) {
		return [_internetView tableView:tableView cellForRowAtIndexPath:indexPath];
	}
	

	// section == 1 // online friends
    UITableViewCell *cell = nil;
    
    //KONG: last row: Add friends button
//    DLog(@"[indexPath row] == [tableView numberOfRowsInSection:[indexPath section] - 1]: %d & %d",
//         [indexPath row], [tableView numberOfRowsInSection:[indexPath section]] - 1);
    
    if ([indexPath row] == cellIndexAddFriendsButton) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
									   reuseIdentifier:@"ButtonCell"] autorelease];			
		cell.textLabel.text = @"Add friends";
		cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0f];		
        cell.textLabel.textColor = [UIColor colorWithRed:0.176 green:0.310 blue:0.522 alpha:1.0];
//        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		return cell;
    }
    
    
	NSArray *sections = [[self fetchedResultsController] sections];

	if ([sections count] == 0) {
		return nil;
	}
    
//	id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:0];



	if ([indexPath row] == cellIndexOnlineStart && [self.onlineFriends count] == 0) { // there is no online Whiteboard
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
									   reuseIdentifier:@"GrayCell"] autorelease];			
		cell.textLabel.text = @"No online friends now";
//        cell.textLabel.textAlignment = UITextAlignmentCenter;
		cell.textLabel.textColor = [UIColor colorWithWhite:0.5 alpha:0.5];
		cell.textLabel.font = [UIFont boldSystemFontOfSize:14.0f];		
		return cell;
	} 

    
//    offlineButtonIndex = [self.onlineFriends count];
//    if (offlineButtonIndex == 0) {
//        offlineButtonIndex = 1;
//    }
    
//    NSInteger offlineButtonIndex = [self.onlineFriends count] + (([self.onlineFriends count] == 0)?1:0);

//    DLog(@"indexPath: %@", indexPath);
//    DLog(@"offlineButtonIndex: %d online friend count: %d", offlineButtonIndex, [_onlineFriends count]);
    XMPPUserCoreDataStorage *user = nil;
    if ([_onlineFriends count] > 0 &&
        [indexPath row] >= cellIndexOnlineStart && [indexPath row] < cellIndexOnlineStart + [_onlineFriends count]) {
        user = [_onlineFriends objectAtIndex:[indexPath row] - cellIndexOnlineStart];
        
        return [self onlineFriendCellForUser:user];
    } else if ([_offlineFriends count] > 0
               && [indexPath row] == cellIndexOfflineButton) {
        
        return [self offlineFriendsButtonCell];
        
    } else if ([_offlineFriends count] > 0
               && [indexPath row] >= cellIndexOfflineStart
               && ([indexPath row] < cellIndexOfflineStart + [_offlineFriends count])) {
   
//        if ([self.offlineFriends > 0] && [indexPath row] == [self.onlineFriends) {
//            
//        }
        
        NSInteger userIndex = [indexPath row] - cellIndexOfflineStart;
//        DLog(@"userIndex: %d", userIndex);
        user = [_offlineFriends objectAtIndex:userIndex];
        return [self offFriendCellForUser:user];

    }
    

	
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([indexPath section] == 1 && _internetView) {
		return [_internetView tableView:tableView heightForRowAtIndexPath:indexPath];
	}
	return 44.0;
}

- (NSString *)tableView:(UITableView *)sender titleForHeaderInSection:(NSInteger)sectionIndex
{
	if (sectionIndex == 0) {
		return @"Local Wi-Fi and Bluetooth";
	} else {
		//		sectionIndex--; // minute 1 for index-compatibility w fetchedResultsController
		return @"Whiteboard Online";
	}
	
	//	NSArray *sections = [[self fetchedResultsController] sections];
	//	
	//	if (sectionIndex < [sections count])
	//	{
	//		id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
	//        
	//		int section = [sectionInfo.name intValue];
	//		switch (section)
	//		{
	//			case 0  : return @"Online WhiteBoard";
	//			case 1  : return @"Away";
	//			default : return @"Offline";
	//		}
	//	}
	
	return @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    if (section == 1 && _internetView) {
//        return 37.0;
//    }
	return 55.0;
}

- (NSString *)tableView:(UITableView *)sender nameForHeaderInSection:(NSInteger)sectionIndex
{
	if (sectionIndex == 0) {
		NSString *localName = [[[self connection] localConnection] myName];
		if (localName) {
			return [NSString stringWithFormat:@"%@", localName];
		}
	} else {
        if ([_internetConnection isLogedInGreengar] && [_internetConnection.xmppStream isConnected]) {
            NSString *internetName = [[[self connection] internetConnection] myName];
            if (internetName) {                
                return [NSString stringWithFormat:@"%@", internetName];
            }            
        } else {
            return @"Collaboration with your Greengar account";
        }

	}
	return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320.0, 100.0)] autorelease];
	
	//KONG: icon
//	UIImageView *iconImageView = [[[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 30.0, 30.0)] autorelease];
//	iconImageView.image = [UIImage imageNamed:@"ConnectButton.png"];
//	[headerView addSubview:iconImageView];
	
    headerView.opaque = YES;
    headerView.backgroundColor = [UIColor clearColor];

    
	//KONG: title
	UILabel *titleView = [[[UILabel alloc] initWithFrame:CGRectMake(20, 10, 320, 25)] autorelease];
	titleView.opaque = YES;
	titleView.backgroundColor = [UIColor clearColor]; //background color
	
	titleView.font = [UIFont boldSystemFontOfSize:18];
	
	titleView.textColor = [UIColor colorWithRed:0.298039 green:0.337255 blue:0.423529 alpha:1];
	titleView.shadowColor = [UIColor whiteColor];
	titleView.shadowOffset = CGSizeMake(0, 1.0);
	titleView.text = [self tableView:tableView titleForHeaderInSection:section];
	[headerView addSubview:titleView];
	
	//KONG: name
	UILabel *nameView = [[[UILabel alloc] initWithFrame:CGRectMake(20, 34, 320, 15)] autorelease];
	nameView.opaque = YES;
	nameView.backgroundColor = [UIColor clearColor]; //background color
	
	nameView.font = [UIFont systemFontOfSize:14];
	nameView.textColor = [UIColor darkGrayColor];
	nameView.shadowColor = [UIColor whiteColor];
	nameView.shadowOffset = CGSizeMake(0, 1.0);
	nameView.text = [self tableView:tableView nameForHeaderInSection:section];
	[headerView addSubview:nameView];
	
    if (section == 1 && [_internetConnection isLogedInGreengar] && [_internetConnection.xmppStream isConnected]) {
        UIImage *statusImage = nil;
        
        if (_internetConnection.isOnline) {
            statusImage = [UIImage imageNamed:@"online.png"];
        } else {
            statusImage = [UIImage imageNamed:@"offline.png"];
        }
        
        UIImageView *statusView = [[[UIImageView alloc] initWithFrame:CGRectMake(20, 37, 9, 9)] autorelease];
        [statusView setImage:statusImage];
        [headerView addSubview:statusView];
        
        // Move name view:
        CGRect newNameViewFrame = nameView.frame;
        newNameViewFrame.origin.x += statusView.frame.size.width * 2;
        nameView.frame = newNameViewFrame;
    }
    
	
	return headerView;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection: (NSInteger)section {
    
    if (section == 1) {
        if (_internetView) {
            return [_internetView tableView:tableView viewForFooterInSection:section];
        } else {
            if (_internetFooterView == nil) {
//                self.internetFooterView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320.f, 60.f)] autorelease];
                self.internetFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320.f, 60.f)];
                _internetFooterView.opaque = YES;
                _internetFooterView.backgroundColor = [UIColor clearColor];
                //	footerView.alpha = 0.0;
                _internetFooterView.contentMode = UIViewContentModeTopRight;

                // go offline button
                self.goOfflineButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                _goOfflineButton.frame = CGRectMake(10, 10, 140, 40);
                
                [_goOfflineButton addTarget:self 
                                  action:@selector(goOfflineButtonPressed)
                        forControlEvents:UIControlEventTouchUpInside];
                
                _goOfflineButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
                [_internetFooterView addSubview:_goOfflineButton];
                                
                // sign out button
                UIButton *signUpButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                signUpButton.frame = CGRectMake(170, 10, 140, 40);
                [signUpButton setTitle:@"Sign out" forState:UIControlStateNormal];
                [signUpButton addTarget:self.navigationController 
                                 action:@selector(signOutButtonPressed:)
                       forControlEvents:UIControlEventTouchUpInside];
                
                signUpButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
                [_internetFooterView addSubview:signUpButton];    
            }
            
            // update status
            if (_internetConnection.isOnline) {
                [_goOfflineButton setTitle:onlineString forState:UIControlStateNormal];
            } else {
                [_goOfflineButton setTitle:offlineString forState:UIControlStateNormal];
            }
            
            return _internetFooterView;
        }
	}
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection: (NSInteger) section {
    if (section == 1) {
        if (_internetView) {
            return [_internetView tableView:tableView heightForFooterInSection:section];
        } else {
            return 60.f;            
        }
    }
	return 0.0;
}


static UIActivityIndicatorView *_connectingIndicator = nil;

+ (void)addActivityIndicatorToCell:(UITableViewCell *)cell {
	if (_connectingIndicator == nil) {
		_connectingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		_connectingIndicator.frame = CGRectMake(0, 0, 20, 20);		
	}

	if ([_connectingIndicator isAnimating] == NO) {
		[_connectingIndicator startAnimating];		
	}

	cell.accessoryType = UITableViewCellAccessoryNone;
	[cell setAccessoryView:_connectingIndicator];
	
}

+ (void)setConnectedStatusToCell:(UITableViewCell *)cell {
	if (cell.accessoryView == _connectingIndicator) {
		[self removeActivityIndicatorOutOfCell:cell];
	}
	cell.accessoryType = UITableViewCellAccessoryCheckmark;
	// Checkmark blue (#2D4F85)
	cell.textLabel.textColor = [UIColor colorWithRed:0.176 green:0.310 blue:0.522 alpha:1.0];
	
}


+ (void)removeActivityIndicatorOutOfCell:(UITableViewCell *)cell {
	
//	UIView *waitingIndicator = [[self.tableView cellForRowAtIndexPath:indexPath] accessoryView];
	if (_connectingIndicator/* && cell.accessoryView == _connectingIndicator*/) {
		if ([_connectingIndicator isAnimating]) {
			[_connectingIndicator stopAnimating];
		}
		[_connectingIndicator removeFromSuperview];
		[cell setAccessoryView:nil];			
	}
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == 1 && _internetView) {
        return [_internetView tableView:tableView willSelectRowAtIndexPath:indexPath];
    }
	return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
//	[self.view addSubview:waitingIndicator];
//	NSIndexPath *originIndexPath = indexPath;
	
	
//	NSString *connectingName = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
    
	if ([indexPath section] == 0) {
		[_localBrowser tableView:tableView didSelectRowAtIndexPath:indexPath];
	
		if ([[_localBrowser services] count] > 0) {
//			[self addActivityIndicatorToCellAtIndexPath:indexPath];
//			[[self connectController] friendsViewDidChooseToConnectTo:connectingName type:[indexPath section]];					
			return;
		}
        return;
	} //else {
//		
//	}
	
	if (_internetView) {
        indexPath = [NSIndexPath indexPathForRow:[indexPath row] inSection:[indexPath section] - 1];
		return [_internetView tableView:tableView didSelectRowAtIndexPath:indexPath];
	}
	
	
    if ([indexPath row] == cellIndexAddFriendsButton) {
        [self addFriendButtonPressed];
        return;
    } else if ([_onlineFriends count] > 0 &&
              [indexPath row] >= cellIndexOnlineStart && [indexPath row] < cellIndexOnlineStart + [_onlineFriends count]) {
        XMPPUserCoreDataStorage *user = [_onlineFriends objectAtIndex:[indexPath row] - cellIndexOnlineStart];
        XMPPJID *connectingJID = [user jid];
		NSLog(@"ConnectViewController: selected friend: %@", connectingJID);
		
		// Create a GSWhiteboard		
		GSInternetWhiteboard *selectedWhiteboard = [_internetConnection peerWithJIDString:[connectingJID bare]];
		
		// Tell AppDelegate to Initialize a session
		[UIAppDelegate.connection userSelectedWhiteboard:selectedWhiteboard];

    } else if ([_offlineFriends count] > 0
               && [indexPath row] == cellIndexOfflineButton) {
        
        BOOL isDisplayingOfflineFriends = [NSDEF boolForKey:kDisplayingOfflineFriends];
        [NSDEF setBool:!isDisplayingOfflineFriends forKey:kDisplayingOfflineFriends];
        
        [self.tableView reloadData];

        
    } else if ([_offlineFriends count] > 0
               && [indexPath row] >= cellIndexOfflineStart
               && ([indexPath row] < cellIndexOfflineStart + [_offlineFriends count])) {
        // offline friends
//		[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
    }
}


- (BOOL)containsUsername:(NSString *)username {
	NSArray *users= [[self fetchedResultsController] fetchedObjects];
	for (XMPPUserCoreDataStorage *user in users) {
		if ([username isEqualToString:[self userDisplayNameAfterRemovingEmailDomain:[user displayName]]]) {
			return YES;
		}
	}
	return NO;
}

- (void)updateDisplay {
	if ([NSThread isMainThread] == NO) {
		DLog(@"local update table View NOT in MAIN thread");
		[self performSelectorOnMainThread:@selector(updateDisplay) withObject:nil
							waitUntilDone:YES];
		return;
	}
	
	[self localBrowserDidReloadData];
	
	
//	[self.tableView reloadData];
//	[self updateToolBar];
}


- (void)localBrowserDidReloadData {
	if ([NSThread isMainThread] == NO) {
		DLog(@"local update table View NOT in MAIN thread");
		[self performSelectorOnMainThread:@selector(localBrowserDidReloadData) withObject:nil
							waitUntilDone:YES];
		return;
	}

	//KONG: When I am editing text (in Login Fields), UI should not load again
	if (_internetView 
		&& [_internetView isKindOfClass:[GSXMPPLoginViewController class]]
		&& [_internetView respondsToSelector:@selector(isTextEditing)]) {
		if ([(GSXMPPLoginViewController *) _internetView isTextEditing]) {
			return;
		}
	}
	[self.tableView reloadData];
}

#pragma mark Add Friend


////////////////
- (BOOL)isUsernameInWhiteboardContactList:(NSString *)username  {
	NSUserDefaults *userDefaults = [[[NSUserDefaults alloc] initWithUser:_internetConnection.username] autorelease];
	NSArray* contactList = [userDefaults objectForKey:@"connection_list"];
	if (userDefaults == nil) {
		return NO;
	}
	
	for (NSDictionary* friendInfo in contactList) {
		NSString *friendUsername = [friendInfo objectForKey:@"user_login"];
		if ([friendUsername isEqualToString:username]) {
			return YES;
		}
	}
	return NO;
}

- (XMPPUserCoreDataStorage *)userForJIDString:(NSString *)jidString {
//	DLog();
	
	XMPPJID *jid = [XMPPJID jidWithString:jidString];
	NSString *bareJIDString = [jid bare];
	
	NSArray *sections = [[self fetchedResultsController] sections];
	
	for (id <NSFetchedResultsSectionInfo> sectionInfo in sections) {
		NSArray *objects = [sectionInfo objects];
		for (XMPPUserCoreDataStorage *user in objects) {
			NSString *contactBareJIDString = [[user jid] bare];
			if ([contactBareJIDString isEqualToString:bareJIDString]) {
				return user;
			}
		}
	}
	return nil;
}

- (BOOL)isUsernameInXMPPContactList:(NSString *)username  {
	
	// section == 1 // online friends
	NSArray *sections = [[self fetchedResultsController] sections];
	
	if ([sections count] == 0) {
		return NO;
	}
	
	for (id <NSFetchedResultsSectionInfo> sectionInfo in sections) {
		DLog (@"sectionInfo: %@", sectionInfo);
		NSArray *usersInfo = [sectionInfo objects];
		for (XMPPUserCoreDataStorage *user in usersInfo) {
			NSString *myFriendUsername = [GSWhiteboardUser displayNameFromJIDString:[user jidStr]];
			DLog(@"username: %@", myFriendUsername);
			if ([myFriendUsername isEqualToString:username]) {
				return YES;
			}
		}		
	}
	return NO;
}

- (BOOL)isJIDInXMPPContactList:(NSString *)jid  {
	
	// section == 1 // online friends
	NSArray *sections = [[self fetchedResultsController] sections];
	
	if ([sections count] == 0) {
		return NO;
	}
	
	NSString *bareJID = [[XMPPJID jidWithString:jid] bare];
	
	for (id <NSFetchedResultsSectionInfo> sectionInfo in sections) {
		DLog (@"sectionInfo: %@", sectionInfo);
		NSArray *usersInfo = [sectionInfo objects];
		for (XMPPUserCoreDataStorage *user in usersInfo) {
			
			if ([[GSWhiteboardUser displayNameFromXMPPUser:[user.jid bare]] isEqualToString:bareJID]) {
				return YES;
			}
		}		
	}
	return NO;
}


////////////



- (void)sendingSubscribeRequestToXMPPAccount:(NSString *)jid name:(NSString *)name {
	// Step 1
	// check if in friend list already
	
//	_pendingFriendName = [jid copy];
//	[[self internetConnection] sendSubscribePresenceToJIDString:jid];
	[[[self internetConnection] xmppRoster] addBuddy:[XMPPJID jidWithString:jid]
										withNickname:name];
	// show indicator
}


- (void)alertHelper:(GSAlertHelper *)ar didClickedButton:(NSInteger)index
	forQuestionType:(NSString *)type callbackObject:(id)obj {
	
	XMPPUserCoreDataStorage *user = [self userForJIDString:[(XMPPJID *)obj bare]];
	NSString *subscription = [user subscription];
	NSString *ask = [user ask];
	
	DLog (@"answered `subscrible` from: %@ subscription: %@ ask %@", [user jidStr], subscription, ask);	
	
	
	if ([type isEqualToString:AcceptRejectQuestionTypeFriendSubscribe]) {
		if (index == 0) { // cancel
			// send deny message
			[_internetConnection.xmppRoster rejectBuddyRequest:obj];
//			[[self internetConnection] sendUnsubscribedPresenceToJIDString:[(XMPPJID *)obj full]];
			[_internetConnection.xmppRoster removeBuddy:obj];
			[[self internetConnection] sendSubscribePresenceType:@"unavailable" toWBUsername:[(XMPPJID *)obj full]];
		} else { // yes
			// step 4: client
			//		_pendingFriendName = [(XMPPJID *)obj user];
			
			[(GSInternetConnection *) [self internetConnection] sendSubscribedPresenceToJIDString:[(XMPPJID *)obj full]];

			// subscribe to friend presence also
			[_internetConnection.xmppRoster addBuddy:obj withNickname:[GSWhiteboardUser displayNameFromJID:obj]];
//			
//			
//			
//			[(GSInternetConnection *) [self internetConnection] sendSubscribePresenceToJIDString:[(XMPPJID *)obj full]];
//			
			//KONG: send to server 
			[GSXmlRpcHelper performAuthRequestWithMethod:@"ggs.wb.addFriend" 
													args:[NSArray arrayWithObject:[GSWhiteboardUser displayNameFromJID:obj]]														
												delegate:self 
												callback:@selector(xmlRpcDidFinishAddingUser:)];	
			
		}
	}
	
	
	
	else if ([type isEqualToString:AcceptRejectQuestionTypeConnection]) {
		
		if (index == 0) { // cancel
			// send deny message
			[[self internetConnection] sendUnsubscribedPresenceToJIDString:[(XMPPJID *)obj full]];
			[[self internetConnection] sendSubscribePresenceType:@"unavailable" toWBUsername:[(XMPPJID *)obj full]];
		} else { // yes
			// step 4: client
			//		_pendingFriendName = [(XMPPJID *)obj user];
			[(GSInternetConnection *) [self internetConnection] sendSubscribedPresenceToJIDString:[(XMPPJID *)obj full]];
			// subscribe to friend presence also
			[(GSInternetConnection *) [self internetConnection] sendSubscribePresenceToJIDString:[(XMPPJID *)obj full]];
			// TODO: check
			//		[self didConnectWithFriend:[(XMPPJID *)obj bare]];
		}
	}
//	[ar autorelease];
}

- (void)askUserForFriendRequestFrom:(NSString *)JIDString {
	XMPPJID *fromJID = [XMPPJID jidWithString:JIDString];


	GSAlertHelper *alertHelper = [[GSAlertHelper alloc] initWithQuestionType:AcceptRejectQuestionTypeFriendSubscribe
																	delegate:self
															  callbackObject:fromJID];
	
	NSString *alertTitle = [NSString stringWithFormat:@"“%@” would like to be your friend in Whiteboard Online", [GSWhiteboardUser displayNameFromJID:fromJID]];	
	GSAlert *friendRequestAlertView = [GSAlert alertWithDelegate:alertHelper
														   title:alertTitle
														 message:nil
												   defaultButton:@"OK"
													 otherButton:@"Don't Allow"];	
	[friendRequestAlertView show];
}

- (void)internetConnection:(GSInternetConnection *)iconn 
   didReceiveSubscribeFrom:(NSString *)JIDString {
	
	// check if pending user
	// if yes not show, just answer yes
	// if no, ask	
	
	
	XMPPUserCoreDataStorage *user = [self userForJIDString:JIDString];
	
	if (user == nil) {
		// Step 2:
		// else no pending name, isFriendInContactList == NO && isFriendInContactList == NO
		[self askUserForFriendRequestFrom:JIDString];
		return;
	}
	
	// check for subscription & ask
	/*
	 2011-01-12 14:57:17.035 Whiteboard[22535:207] user: jid athanhcong.g.g.s@binaryfreedom.info, subscription: none, ask: subscribe, resource:
	 */
	NSString *subscription = [user subscription];
	/*
	 none,
	 from,
	 to,
	 both
	 */
	NSString *ask = [user ask];
	/*
	 subscribe,
	 
	 */
	
	
	DLog (@"received `subscrible` from: %@ subscription: %@ ask %@", JIDString, subscription, ask);

	if ([subscription isEqualToString:@"none"]) {
		[self askUserForFriendRequestFrom:JIDString];
		return;
	}
	
	// received `subscrible` from: hihihi.g.g.s@xmpp.ws subscription: to ask (null)

	if ([subscription isEqualToString:@"to"]) {
		[[self internetConnection] sendSubscribedPresenceToJIDString:JIDString];
		//[self askUserForFriendRequestFrom:JIDString];
		return;
	}
	
/*	
	if (_pendingFriendName != nil && [JIDString isEqualToString:_pendingFriendName]){
		[[self internetConnection] sendSubscribedPresenceToJIDString:_pendingFriendName];		
		return;
	}
	
	
	if ([self isJIDInXMPPContactList:JIDString]) {
		[[self internetConnection] sendSubscribedPresenceToJIDString:_pendingFriendName];
		return;
	} else {
		NSString *friendUsername = [GSWhiteboardUser displayNameFromJIDString:JIDString];
		BOOL isFriendInXMPPList = [self isUsernameInXMPPContactList:friendUsername];
		if (isFriendInXMPPList == YES) {
			[[self internetConnection] sendSubscribedPresenceToJIDString:_pendingFriendName];		
			// subscribe to friend presence also
			[(GSInternetConnection *) [self internetConnection] sendSubscribePresenceToJIDString:JIDString];			
			return;
		}
		// else
		// step 6
		BOOL isFriendInContactList = [self isUsernameInWhiteboardContactList:friendUsername];
		if (isFriendInContactList == YES) { //isFriendInXMPPList == NO
			[(GSInternetConnection *) [self internetConnection] sendSubscribedPresenceToJIDString:JIDString];
			// subscribe to friend presence also
			[(GSInternetConnection *) [self internetConnection] sendSubscribePresenceToJIDString:JIDString];
			return;
		}		
	}
	
 */

}

- (void)internetConnection:(GSInternetConnection *)iconn 
  didReceiveSubscribedFrom:(NSString *)JIDString {
	//	[self.navigationController popViewControllerAnimated:YES];	
	
	
	XMPPUserCoreDataStorage *user = [self userForJIDString:JIDString];
	NSString *subscription = [user subscription];
	NSString *ask = [user ask];

	DLog (@"received `subscribled` from: %@ subscription: %@ ask %@", JIDString, subscription, ask);
	
	// received `subscribled` from: koncer.g.g.s@openjabber.org subscription: to ask (null)
	// received `subscribled` from: koncer.g.g.s@openjabber.org subscription: both ask (null)
		
	NSString *greengarUsername = [GSWhiteboardUser displayNameFromJIDString:JIDString];
	
	//KONG: send to server 
	[GSXmlRpcHelper performAuthRequestWithMethod:@"ggs.wb.addFriend" 
											args:[NSArray arrayWithObject:greengarUsername]								
										delegate:self 
										callback:@selector(xmlRpcDidFinishAddingUser:)];
	
	if ([subscription isEqualToString:@"to"]) {
		UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"“%@” accepted your friend request", greengarUsername]
															 message:nil
															delegate:nil cancelButtonTitle:@"OK"
												   otherButtonTitles:nil] autorelease];
		[alertView show];		
	}
	
	
	/*
	 XMPPJID *fromJID = [XMPPJID jidWithString:JIDString];
	 // step 5: host
	 // check if this is pending user	 
	if ((_pendingFriendName && [[fromJID bare] isEqualToString:_pendingFriendName])) {
		if ([self.navigationController.viewControllers count] > 1) {
			[self.navigationController popToRootViewControllerAnimated:YES];
		}
		
		//		UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"“%@” accepted your friend request", [fromJID user]]
		//															 message:nil
		//															delegate:nil cancelButtonTitle:@"OK"
		//												   otherButtonTitles:nil] autorelease];
		//		[alertView show];
		
		UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"“%@” accepted your friend request", [GSWhiteboardUser displayNameFromJID:fromJID]]
															 message:nil
															delegate:nil cancelButtonTitle:@"OK"
												   otherButtonTitles:nil] autorelease];
		[alertView show];
		
		
		//KONG: send to server 
		[GSXmlRpcHelper performAuthRequestWithMethod:@"ggs.wb.addFriend" 
												args:[NSArray arrayWithObject:[GSWhiteboardUser displayNameFromJID:fromJID]]														
											delegate:self 
											callback:@selector(xmlRpcDidFinishAddingUser:)];
	} else {
		// step 7: client
		// silently
	}
	 */
}

- (void)xmlRpcDidFinishAddingUser:(id)response {
	DLog (@"%@", response);
	// TODO: KONG - handle failure situation
	[self printRoster];
}

- (void)internetConnection:(GSInternetConnection *)iconn 
didReceiveUnsubscribedFrom:(NSString *)friendJID {
	
//	[_internetConnection.xmppRoster removeBuddy:[XMPPJID jidWithString:friendJID]];
	[_internetConnection sendSubscribePresenceType:@"unsubscribe" toWBUsername:friendJID];
	[_internetConnection.xmppRoster removeBuddy:[XMPPJID jidWithString:friendJID]];
	XMPPJID *fromJID = [XMPPJID jidWithString:friendJID];
	UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"“%@” rejected your friend request", [GSWhiteboardUser displayNameFromJID:fromJID]]
														 message:nil
														delegate:nil cancelButtonTitle:@"OK"
											   otherButtonTitles:nil] autorelease];
	[alertView show];
	[self.tableView reloadData];
}

#pragma mark re-establish connection request

- (void)restoreConnectionAfterRecreatingAccount {
	DLog();
	if (_restoringConnectionAlertView == nil) {
		self.restoringConnectionAlertView = [GSViewHelper showStatusAlertViewTitle:@"Networking" 
																		   message:@"Restoring your friend connections"];
	}
	
	[GSXmlRpcHelper performAuthRequestWithMethod:@"ggs.wb.getFriends" args:[NSArray array]
										delegate:self callback:@selector(xmlRpcDidFinishGettingFriends:)];
}

- (void)xmlRpcDidFinishGettingFriends:(id)response {
	DLog(@"friends: %@", response);
	/*
	 (
	 {
	 "display_name" = ai;
	 "user_login" = ai;
	 "wb_xmpp_domain" = "binaryfreedom.info";
	 "wb_xmpp_user" = "ai.g.g.s";
	 },
	 {
	 "display_name" = freebin;
	 "user_login" = freebin;
	 "wb_xmpp_domain" = "binaryfreedom.info";
	 "wb_xmpp_user" = "freebin.g.g.s";
	 }
	 )
	 */
	
	// check for error
	if ([response isKindOfClass:[NSArray class]] == NO) {
		// alert user
		[_restoringConnectionAlertView dismissWithClickedButtonIndex:2 animated:YES];
		
		[GSViewHelper showAlertViewTitle:@"Cannot get your friends list"
								 message:nil cancelButton:@"OK"];
		 //showStatusAlertViewTitle:@"Cannot get your friends list" message:@"OK"];
		return;
	}
	
	// store connection table
	NSUserDefaults *userDefaults = [[[NSUserDefaults alloc] initWithUser:_internetConnection.username] autorelease];
	[userDefaults setObject:response forKey:@"connection_list"];
	
	// sending connection request
	
	for (NSDictionary* friendInfo in response) {
		NSString *friendName = [friendInfo objectForKey:@"display_name"];
		NSString *friendXMPPUser = [friendInfo objectForKey:@"wb_xmpp_user"];
		NSString *friendXMPPDomain = [friendInfo objectForKey:@"wb_xmpp_domain"];
		NSString *friendXMPPJID = [[NSString alloc] initWithFormat:@"%@@%@", friendXMPPUser, friendXMPPDomain];
		
		[self sendingSubscribeRequestToXMPPAccount:friendXMPPJID name:friendName];
		
		[friendXMPPJID release];
	}
	[_restoringConnectionAlertView dismissWithClickedButtonIndex:2 animated:YES];
}


- (void)hideKeyboard {
    if (_internetView) {
        [_internetView performSelector:@selector(hideKeyboard)];
    }
}
@end
