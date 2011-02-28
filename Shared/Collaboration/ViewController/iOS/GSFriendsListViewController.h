#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>



#import "GSInternetConnection.h"

#import "GSAddFriendView.h"
#import "GSConnectionComponent.h"

@class XMPPUserCoreDataStorage;

@class BrowserViewController;

static NSString *const kNotificationFriendsListDidChange = @"kNotificationFriendsListDidChange";

@interface GSFriendsListViewController : UITableViewController <NSFetchedResultsControllerDelegate, GSInternetConnectionDelegate> {
	NSFetchedResultsController *fetchedResultsController;
	NSIndexPath *_requesterIndexPath;
	
    
	GSInternetConnection *_internetConnection; // keep a weak reference
		
	BOOL isLogedIn;
	BrowserViewController *_localBrowser;
	
//	GSAddFriendView *_addFriendController;
		
//	GSWhiteboard *_nextWhiteboard;
	UIAlertView *_restoringConnectionAlertView;
	
	id <GSConnectionComponent> _internetView;
    
    
//    CGFloat keyboardHeight;
//    BOOL keyboardIsShowing;

    NSArray *_onlineFriends;
    NSArray *_offlineFriends;
    
//    BOOL _isDisplayingOfflineFriends;
    
    UIView *_internetFooterView;
    
    UIButton *_goOfflineButton;
}

//@property (nonatomic, retain) SphereNetViewController *sphereNetArena;
@property (nonatomic, retain) NSIndexPath *requesterIndexPath;
@property (nonatomic, assign) GSInternetConnection *internetConnection;
@property (nonatomic, retain) UIAlertView *restoringConnectionAlertView;
@property (nonatomic, retain) id <GSConnectionComponent> internetView;
@property (nonatomic, retain) NSArray *onlineFriends, *offlineFriends;
- (id)initWithInternetConnection:(GSInternetConnection *)internetConnection;

- (id)initWithInternetConnection:(GSInternetConnection *)internetConnection
					localBrowser:(BrowserViewController *)bcv;

//- (void)receiveRequestFromUsername:(NSString *)username;

//- (IBAction)doneTapped:(UIButton *)b;

- (void)localBrowserDidReloadData;

- (BOOL)containsUsername:(NSString *)username;

//- (void)addActivityIndicatorToCellAtIndexPath:(NSIndexPath *)indexPath;

+ (void)addActivityIndicatorToCell:(UITableViewCell *)cell;
+ (void)removeActivityIndicatorOutOfCell:(UITableViewCell *)cell;
+ (void)setConnectedStatusToCell:(UITableViewCell *)cell;

- (NSFetchedResultsController *)fetchedResultsController;

- (void)sendingSubscribeRequestToXMPPAccount:(NSString *)jid name:(NSString *)name;

- (XMPPUserCoreDataStorage *)userForJIDString:(NSString *)jidString;

- (void)restoreConnectionAfterRecreatingAccount;
- (void)sendingSubscribeRequestToXMPPAccount:(NSString *)jid name:(NSString *)name;
- (BOOL)isUsernameInXMPPContactList:(NSString *)username;



- (void)internetConnection:(GSInternetConnection *)iconn 
  didReceiveSubscribedFrom:(NSString *)JIDString;

- (void)internetConnection:(GSInternetConnection *)iconn 
   didReceiveSubscribeFrom:(NSString *)JIDString;

- (void)internetConnection:(GSInternetConnection *)iconn 
didReceiveUnsubscribedFrom:(NSString *)friendJID;

- (void)updateDisplay;

//KONG: this method is used for testing: Log Friends list to console 
- (void)printRoster;
@end
