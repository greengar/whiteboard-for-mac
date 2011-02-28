/*
     File: MainViewController.m 
 Abstract: Main table view controller for the application. 
  Version: 1.4 
 */

#import "GSAddFriendView.h"
#import "GSInternetConnection.h"
#import "AppController.h"
#import "GSLocalConnection.h"
//#import "GSLocalConnection+NSStreamDelegate.h"

#import "GSConnectionController.h"
#import "GSViewHelper.h"
#import "GSXmlRpcHelper.h"
#import "GSConnectViewController.h"

#import "XMPP.h"
#import "XMPPUserCoreDataStorage.h"
#import "GSFriendsListViewController.h"


@interface UISearchDisplayController (NotHideNavigationBar)


@end

@implementation UISearchDisplayController (NotHideNavigationBar)
- (void)setActive:(BOOL)visible animated:(BOOL)animated {
    if (animated == YES) {
        if(self.active == visible) return;
        [self.searchContentsController.navigationController setNavigationBarHidden:YES animated:NO];
        [self setActive:visible animated:NO];
        //self.active = visible;
        [self.searchContentsController.navigationController setNavigationBarHidden:NO animated:NO];
        if (visible) {
            [self.searchBar becomeFirstResponder];
        } else {
            [self.searchBar resignFirstResponder];
        } 
    }
}
@end



@interface GSAddFriendView()

- (GSConnectViewController *)connectionView;
- (GSFriendsListViewController *)friendView;

@end


@implementation GSAddFriendView 

@synthesize listContent, searchWasActive, connection;
//@synthesize sendRequestButton = _sendRequestButton;

#pragma mark - 
#pragma mark Lifecycle methods

- (id)initWithFriendsList:(GSFriendsListViewController *)friendslist {
	if ((self = [super initWithNibName:@"GSAddFriendView" bundle:nil])) {
		_friendsList = friendslist;
		
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(friendsListDidChange) 
													 name:kNotificationFriendsListDidChange
												   object:nil];

	}
	return self;
}


- (void)viewDidLoad
{
	self.title = @"Add friends";
//	self.navigationItem.backBarButtonItem.title = @"Networking";
    self.navigationItem.hidesBackButton = YES;
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Done" 
                                                                               style:UIBarButtonItemStyleBordered
                                                                              target:self
                                                                              action:@selector(doneButtonPressed)] autorelease];
	
	// create a filtered list that will contain products for the search results table.
	self.listContent = [NSArray array];
//	self.listContent = [NSArray arrayWithObject:@"hihihehe"];
//   [self.searchDisplayController setActive:YES];


	
//	self.sendRequestButton = [[[UIBarButtonItem alloc] initWithTitle:@"Send request"
//															   style:UIBarButtonItemStyleBordered
//															  target:self 
//															  action:@selector(sendRequestButtonPressed)] autorelease];
//	_sendRequestButton.enabled = NO;
//	UIBarButtonItem *spaceBarItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
//																				   target:self action:nil] autorelease];
//	self.toolbarItems = [NSArray arrayWithObjects:
//						 spaceBarItem,
//						 _sendRequestButton, nil];
	
//	[self.tableView reloadData];
	self.tableView.scrollEnabled = YES;
	
	self.searchDisplayController.searchBar.placeholder = @"Whiteboard username";
	
	if ([self respondsToSelector:@selector(setContentSizeForViewInPopover:)]) {
		self.contentSizeForViewInPopover = CGSizeMake(320, 460);
	}
}

- (void)doneButtonPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)sendRequestButtonPressed {
    [_requestButton performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.5];
//	NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    	NSIndexPath *selectedIndexPath = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
	if (selectedIndexPath != nil) {
		[self sendFriendRequestToFriend:[self.listContent objectAtIndex:[selectedIndexPath row]]];	
		[self.searchDisplayController.searchResultsTableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
		
		//KONG: debug
//		[_friendsList printRoster];
	}
	
//	_sendRequestButton.enabled = NO;	
}																			   
																			   
- (void)viewDidUnload {

}

//- (void)viewDidAppear:(BOOL)animated {
//	[super viewDidAppear:animated];
//	[self.searchDisplayController.searchBar becomeFirstResponder];
//}

- (void)dealloc {
	[listContent release];
    [_requestButton release];
    
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


#pragma mark -
#pragma mark UITableView data source and delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [self.listContent count];
    }
	return 0;
//    return 3;
}


- (UIButton *)buttonForSendingRequest {
    if (_requestButton == nil) {
        UIImage *backgroundImage = [UIImage imageNamed:@"MessageEntrySendButton.png"];
        
        backgroundImage = [backgroundImage stretchableImageWithLeftCapWidth:backgroundImage.size.width/2 
                                                               topCapHeight:backgroundImage.size.height/2 + 1];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setFrame:CGRectMake(self.tableView.frame.size.width - 5 - 100, 7, 100 , 30)];
        [button setTitle:@"Send Request" forState:UIControlStateNormal];
        [button.titleLabel setFont:[UIFont boldSystemFontOfSize:12]];
        [button setBackgroundImage:backgroundImage forState:UIControlStateNormal];
        [button addTarget:self action:@selector(sendRequestButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        _requestButton = [button retain];
    }
    return _requestButton;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *kCellID = @"cellID";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kCellID] autorelease];
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	/*
	 If the requesting table view is the search display controller's table view, configure the cell using the filtered content, otherwise use the main list.
	 */

	
	NSDictionary *friendInfo = [self.listContent objectAtIndex:[indexPath row]];
	
	NSString *friendUsername = [friendInfo objectForKey:@"user_login"];
	cell.textLabel.text = friendUsername;
	
//	if ([_friendsList isUsernameInXMPPContactList:friendUsername]) {
//		cell.accessoryType = UITableViewCellAccessoryCheckmark;
//	}
	
	NSString *jidString = [NSString stringWithFormat:@"%@@%@",
						   [friendInfo objectForKey:@"wb_xmpp_user"],
						   [friendInfo objectForKey:@"wb_xmpp_domain"], nil];

	
	
	XMPPUserCoreDataStorage *user = [_friendsList userForJIDString:jidString];
	
	cell.detailTextLabel.text = nil;
	
	if (user != nil) {
		NSString *subscription = [user subscription];
		NSString *ask = [user ask];
		
		DLog(@"jidString: %@ subscription: %@ ask: %@", jidString, subscription, ask);
		// jidString: huhuhi.g.g.s@binaryfreedom.info subscription: none ask: subscribe
		// jidString: koncer.g.g.s@openjabber.org subscription: both ask: (null)
		
		if ([subscription isEqualToString:@"both"]) {
			cell.detailTextLabel.text = @"Friend";
		} else if ([ask isEqualToString:@"subscribe"]) {
			cell.detailTextLabel.text = @"Pending";
		}

	}
//	cell.text = @"hihi";
	return cell;
}

- (void)sendFriendRequestToFriend:(NSDictionary *)friendInfo {
	// @"nam.g.g.s@chatmask.com"
	/*
	 "display_name" = ak;
	 "user_login" = ak;
	 "wb_xmpp_domain" = "chatmask.com";
	 "wb_xmpp_user" = "ak.g.g.s";
	 */
	NSString *friendXMPPAccount = [NSString stringWithFormat:@"%@@%@", 
								   [friendInfo objectForKey:@"wb_xmpp_user"],
								   [friendInfo objectForKey:@"wb_xmpp_domain"]];
	NSString *friendName = [friendInfo objectForKey:@"display_name"];
	[_friendsList sendingSubscribeRequestToXMPPAccount:friendXMPPAccount name:friendName];		
}


// TODO: handle listContent
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//	_sendRequestButton.enabled = YES;
    [_requestButton removeFromSuperview];
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:[tableView indexPathForSelectedRow]];
    [selectedCell.contentView addSubview:[self buttonForSendingRequest]];
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (GSConnectViewController *)connectionView {
	return (GSConnectViewController *) self.navigationController;
}

- (GSFriendsListViewController *)friendView {
	return [[self connectionView] friendsView];
}

- (void)friendsListDidChange {
//	DLog();
	[self.searchDisplayController.searchResultsTableView reloadData];
}

//#pragma mark -
//#pragma mark Content Filtering
//
//- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
//{
//	DLog(@"searchText = %@", searchText);
//	//KONG: I comment this because new code dont use this 
////	[connection findWhiteboardsWithName:searchText];
//#if 0
//	/*
//	 Update the filtered array based on the search text and scope.
//	 */
//	
//	[self.filteredListContent removeAllObjects]; // First clear the filtered array.
//	
//	/*
//	 Search the main list for products whose type matches the scope (if selected) and whose name matches searchText; add items that match to the filtered array.
//	 */
//	for (GSWhiteboard *product in listContent)
//	{
//		if ([scope isEqualToString:@"All"] || [product.type isEqualToString:scope])
//		{
//			NSComparisonResult result = [product.name compare:searchText options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) range:NSMakeRange(0, [searchText length])];
//            if (result == NSOrderedSame)
//			{
//				[self.filteredListContent addObject:product];
//            }
//		}
//	}
//#endif
//}

//- (void)findCompleteDictionary:(NSDictionary *)dictionary {
//	DLog(@"dictionary = %@", dictionary);
//	[self.filteredListContent removeAllObjects];
//	NSArray *whiteboards = [dictionary objectForKey:@"whiteboards"];
//	if ([whiteboards count] <= 0) {
//		GSWhiteboard *w = [GSWhiteboard whiteboardWithType:GSConnectionTypeInternet name:[dictionary objectForKey:@"message"]];
//		[self.filteredListContent addObject:w];
//	} else {
//		for (NSDictionary *d in whiteboards) {
//			GSWhiteboard *w = [GSWhiteboard whiteboardWithType:GSConnectionTypeInternet name:[d objectForKey:@"name"]];
//			w.wb = [d objectForKey:@"wb"];
//			[self.filteredListContent addObject:w];
//		}
//	}
//}

#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

//- (void) searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
//    DLog();
//    [self.navigationController setNavigationBarHidden:YES animated:NO];
////    [controller 
//}

//- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller {
//    DLog();
//    [self.navigationController setNavigationBarHidden:NO animated:YES];
//}


// TODO: stop reloading.. is it possible?
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    
	// this works:
	UITableView *tableView = controller.searchResultsTableView; //self.searchDisplayController.searchResultsTableView;
	for( UIView *subview in tableView.subviews ) {
		if( [subview class] == [UILabel class] ) {
			UILabel *lbl = (UILabel*)subview;
			lbl.text = @"";
		}
	}
	
//	[controller.searchResultsTableView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.8]];
//    [controller.searchResultsTableView setRowHeight:800];
	
    // Return YES to cause the search result table view to be reloaded.
//    return YES;
	return NO; // asynchronous search
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
//	[controller.searchResultsTableView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.8]];
//    [controller.searchResultsTableView setRowHeight:800];
	
    // Return YES to cause the search result table view to be reloaded.
//    return YES;
	return NO;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	DLog();
	[self setStatus:@"Loading..."];
	NSString *friendName = searchBar.text;
//	//KONG: check
//	if (friendName == nil || friendName.length < 2) {
//		[GSViewHelper showAlertViewTitle:@"Search string is too short"  message:nil cancelButton:@"Try again"];
//		return;
//	}
	
	NSString *method = @"ggs.wb.findFriends";                        // the method
	[GSXmlRpcHelper performAuthRequestWithMethod:method args:[NSArray arrayWithObject:friendName]
										delegate:self callback:@selector(serverDidFinishFindingFriends:)];
	
}


- (void)setStatus:(NSString *)status {
	UITableView *tableView = self.searchDisplayController.searchResultsTableView; //self.searchDisplayController.searchResultsTableView;
	for( UIView *subview in tableView.subviews ) {
		if( [subview class] == [UILabel class] ) {
			UILabel *lbl = (UILabel*)subview;
			lbl.text = status;
		}
	}
}

- (void)serverDidFinishFindingFriends:(id)response {
	DLog(@"%@", response);
	/*
	 (
	 {
	 "display_name" = ak;
	 "user_login" = ak;
	 "wb_xmpp_domain" = "chatmask.com";
	 "wb_xmpp_user" = "ak.g.g.s";
	 },
	 {
	 "display_name" = nam;
	 "user_login" = nam;
	 "wb_xmpp_domain" = "chatmask.com";
	 "wb_xmpp_user" = "nam.g.g.s";
	 },
	 {
	 "display_name" = aa;
	 "user_login" = aa;
	 "wb_xmpp_domain" = "chatmask.com";
	 "wb_xmpp_user" = "aa.g.g.s";
	 }
	 )
	 */
	
	// add objects to listContent
	[self setStatus:@""];	
	if ([response isKindOfClass:[NSArray class]]) {
		self.listContent = response;
        if ([self.listContent count] == 0 ) {
            [self setStatus:@"No result"];
        }
        
	} else {
		// check for error
		
	}

	[self.searchDisplayController.searchResultsTableView reloadData];
}

@end
