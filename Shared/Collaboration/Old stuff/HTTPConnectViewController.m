/*
     File: MainViewController.m 
 Abstract: Main table view controller for the application. 
  Version: 1.4 
 */

#import "ConnectViewController.h"
#import "GSWhiteboard.h"
#import "GSInternetConnection.h"
#import "AppController.h"
#import "AppController+NSStreamDelegate.h"

@implementation ConnectViewController

@synthesize listContent, filteredListContent, savedSearchTerm, savedScopeButtonIndex, searchWasActive, connection;


#pragma mark - 
#pragma mark Lifecycle methods

- (void)viewDidLoad
{
	self.title = @"Products";
	
	// create a filtered list that will contain products for the search results table.
	self.filteredListContent = [NSMutableArray arrayWithCapacity:[self.listContent count]];
	
	// restore search settings if they were saved in didReceiveMemoryWarning.
    if (self.savedSearchTerm)
	{
        [self.searchDisplayController setActive:self.searchWasActive];
        [self.searchDisplayController.searchBar setSelectedScopeButtonIndex:self.savedScopeButtonIndex];
        [self.searchDisplayController.searchBar setText:savedSearchTerm];
        
        self.savedSearchTerm = nil;
    }
	
	[self.tableView reloadData];
	self.tableView.scrollEnabled = YES;
}

- (void)viewDidUnload
{
	self.filteredListContent = nil;
}

- (void)viewDidDisappear:(BOOL)animated
{
    // save the state of the search UI so that it can be restored if the view is re-created
    self.searchWasActive = [self.searchDisplayController isActive];
    self.savedSearchTerm = [self.searchDisplayController.searchBar text];
    self.savedScopeButtonIndex = [self.searchDisplayController.searchBar selectedScopeButtonIndex];
}

- (void)dealloc
{
	if ((ConnectViewController *)connection.delegate == self)
		connection.delegate = nil;
	[listContent release];
	[filteredListContent release];
	
	[super dealloc];
}


#pragma mark -
#pragma mark UITableView data source and delegate methods

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {   
//    if (tableView == self.searchDisplayController.searchResultsTableView) {
//        return @"My custom string";
//    } else {
//        return @"";
//    }           
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	/*
	 If the requesting table view is the search display controller's table view, return the count of
     the filtered list, otherwise return the count of the main list.
	 */
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
		if ([self.filteredListContent count] == 0)
			return 1;
        return [self.filteredListContent count];
    }
	else
	{
        return [self.listContent count];
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *kCellID = @"cellID";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];
	if (cell == nil)
	{
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellID] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	/*
	 If the requesting table view is the search display controller's table view, configure the cell using the filtered content, otherwise use the main list.
	 */
	GSWhiteboard *product = nil;
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		if ([self.filteredListContent count] == 0)
			product = [GSWhiteboard whiteboardWithType:@"Internet" name:@"Searching..."];
		else
			product = [self.filteredListContent objectAtIndex:indexPath.row];
    }
	else
	{
        product = [self.listContent objectAtIndex:indexPath.row];
    }
	
	cell.textLabel.text = product.name;
	return cell;
}

// TODO: handle listContent
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row >= [self.filteredListContent count] || UIAppDelegate.acceptReject.name) {
		[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
		return;
	}
	
	//  Copied from BrowserViewController:
	
	GSWhiteboard *w = [self.filteredListContent objectAtIndex:indexPath.row];
	NSString* message = @"";
	
	if ([connection isConnected] || [connection isResolving]) {
		if ([connection isConnected:w.wb] || [connection isResolving:w.wb]) {
//			self.nextService = nil;
			// TODO: show Disconnect? popover
		} else {
//			self.nextService = service;//[self.services objectAtIndex:indexPath.row/* - 1*/];
//			message = [NSString stringWithFormat:@"You will then connect to “%@”", self.nextService.name];
			// TODO: show Disconnect? popover + "You will then connect to..."
		}
		// Show disconnect confirmation
		NSString *connectedName = [connection connectedWhiteboard].name;
		UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Do you want to disconnect from “%@”?", connectedName] message:message delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
		[alertView show];
		[alertView release];
	} else {
		[UIAppDelegate initiateConnection];
		[UIAppDelegate streamEventHasSpaceAvailable:w];
		
//		// If another resolve was running, stop it first
//		[self stopCurrentResolve];
//		self.currentResolve = [self.services objectAtIndex:indexPath.row];
//		
//		[self.currentResolve setDelegate:self];
//		// Attempt to resolve the service. A value of 0.0 sets an unlimited time to resolve it. The user can
//		// choose to cancel the resolve by selecting another service in the table view.
//		[self.currentResolve resolveWithTimeout:0.0];
//		
//		// Make sure we give the user some feedback that the resolve is happening.
//		// We will be called back asynchronously, so we don't want the user to think
//		// we're just stuck.
//		[self showWaiting/*ForResolve:self.currentResolve*/];
//		[tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
	}
//	[self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
//	[self.tableView reloadDataIfNotWaiting];
	
	
	// send message to w.wb
	
	// /api/sendmessage?wb=  &message=
	
#if 0
    UIViewController *detailsViewController = [[UIViewController alloc] init];
    
	/*
	 If the requesting table view is the search display controller's table view, configure the next view controller using the filtered content, otherwise use the main list.
	 */
	GSWhiteboard *product = nil;
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
        product = [self.filteredListContent objectAtIndex:indexPath.row];
    }
	else
	{
        product = [self.listContent objectAtIndex:indexPath.row];
    }
	detailsViewController.title = product.name;
    
    [[self navigationController] pushViewController:detailsViewController animated:YES];
    [detailsViewController release];
#endif
}


#pragma mark -
#pragma mark Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
	DLog(@"searchText = %@", searchText);
	[connection findWhiteboardsWithName:searchText];
#if 0
	/*
	 Update the filtered array based on the search text and scope.
	 */
	
	[self.filteredListContent removeAllObjects]; // First clear the filtered array.
	
	/*
	 Search the main list for products whose type matches the scope (if selected) and whose name matches searchText; add items that match to the filtered array.
	 */
	for (GSWhiteboard *product in listContent)
	{
		if ([scope isEqualToString:@"All"] || [product.type isEqualToString:scope])
		{
			NSComparisonResult result = [product.name compare:searchText options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) range:NSMakeRange(0, [searchText length])];
            if (result == NSOrderedSame)
			{
				[self.filteredListContent addObject:product];
            }
		}
	}
#endif
}

- (void)findCompleteDictionary:(NSDictionary *)dictionary {
	DLog(@"dictionary = %@", dictionary);
	[self.filteredListContent removeAllObjects];
	NSArray *whiteboards = [dictionary objectForKey:@"whiteboards"];
	if ([whiteboards count] <= 0) {
		GSWhiteboard *w = [GSWhiteboard whiteboardWithType:@"Internet" name:[dictionary objectForKey:@"message"]];
		[self.filteredListContent addObject:w];
	} else {
		for (NSDictionary *d in whiteboards) {
			GSWhiteboard *w = [GSWhiteboard whiteboardWithType:@"Internet" name:[d objectForKey:@"name"]];
			w.wb = [d objectForKey:@"wb"];
			[self.filteredListContent addObject:w];
		}
	}
	[self.searchDisplayController.searchResultsTableView reloadData];
}

#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

// TODO: stop reloading.. is it possible?
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:
			[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
	// this works:
//	UITableView *tableView = controller.searchResultsTableView; //self.searchDisplayController.searchResultsTableView;
//	for( UIView *subview in tableView.subviews ) {
//		if( [subview class] == [UILabel class] ) {
//			UILabel *lbl = (UILabel*)subview;
//			lbl.text = @"My custom string";
//		}
//	}
	
//	[controller.searchResultsTableView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.8]];
//    [controller.searchResultsTableView setRowHeight:800];
	
    // Return YES to cause the search result table view to be reloaded.
//    return YES;
	return NO; // asynchronous search
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
			[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
//	[controller.searchResultsTableView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.8]];
//    [controller.searchResultsTableView setRowHeight:800];
	
    // Return YES to cause the search result table view to be reloaded.
//    return YES;
	return NO;
}

- (void)setConnection:(id)c {
	connection = c;
	connection.delegate = self;
}

- (IBAction)doneTapped:(UIButton *)b {
	// TODO: remove dangerous appDelegate reference:
	[UIAppDelegate.pickerViewController dismissModalViewControllerAnimated:YES];
}

@end
