/*
     File: MainViewController.h
 Abstract: Main table view controller for the application.
  Version: 1.4
 */

#import "GSInternetConnection.h"
@class GSFriendsListViewController;

//@class GSInternetConnection;

@interface GSAddFriendView : UITableViewController <UISearchDisplayDelegate, UISearchBarDelegate, GSInternetConnectionDelegate> {
    GSFriendsListViewController *_friendsList; // a weak reference
    
	NSArray			*listContent;			// The master 
    // The saved state of the search UI if a memory warning removed the view.
//    NSString		*savedSearchTerm;
    NSInteger		savedScopeButtonIndex;
    BOOL			searchWasActive;
	
	GSInternetConnection *connection;
	
//	UIBarButtonItem *_sendRequestButton;
	
	
    
    UIButton *_requestButton;
}

@property (nonatomic, retain) NSArray *listContent;
//@property (nonatomic, retain) NSMutableArray *filteredListContent;

//@property (nonatomic, copy) NSString *savedSearchTerm;
//@property (nonatomic) NSInteger savedScopeButtonIndex;
@property (nonatomic) BOOL searchWasActive;

@property (nonatomic, assign) GSInternetConnection *connection;
//@property (nonatomic, retain) UIBarButtonItem *sendRequestButton;

- (id)initWithFriendsList:(GSFriendsListViewController *)friendslist;

//- (IBAction)doneTapped:(UIButton *)b;
- (void)setStatus:(NSString *)status;

- (void)sendFriendRequestToFriend:(NSDictionary *)friendInfo;

@end
