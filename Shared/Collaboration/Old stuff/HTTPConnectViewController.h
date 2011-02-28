/*
     File: MainViewController.h
 Abstract: Main table view controller for the application.
  Version: 1.4
 */

#import "GSInternetConnection.h"

//@class GSInternetConnection;

@interface ConnectViewController : UITableViewController <UISearchDisplayDelegate, UISearchBarDelegate, GSInternetConnectionDelegate>
{
	NSArray			*listContent;			// The master content.
	NSMutableArray	*filteredListContent;	// The content filtered as a result of a search.
	
	// The saved state of the search UI if a memory warning removed the view.
    NSString		*savedSearchTerm;
    NSInteger		savedScopeButtonIndex;
    BOOL			searchWasActive;
	
	GSInternetConnection *connection;
}

@property (nonatomic, retain) NSArray *listContent;
@property (nonatomic, retain) NSMutableArray *filteredListContent;

@property (nonatomic, copy) NSString *savedSearchTerm;
@property (nonatomic) NSInteger savedScopeButtonIndex;
@property (nonatomic) BOOL searchWasActive;

@property (nonatomic, assign) GSInternetConnection *connection;

- (IBAction)doneTapped:(UIButton *)b;

@end
