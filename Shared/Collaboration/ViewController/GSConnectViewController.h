// Cong Vo

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#import "GSFriendsListViewController.h"

#import "GSXMPPLoginViewController.h"

@class BrowserViewController;


@interface GSConnectViewController : UINavigationController <GSXMPPLoginViewControllerDelegate>  {
	GSFriendsListViewController *_friendsView;
	BrowserViewController *_localBrowser;
	
	GSInternetConnection *_internetConnection;

	// subscribe
//	NSString *_pendingFriendName;
//	
//	// colaboration
//	NSString *_pendingFriend;
//	NSUInteger _pendingType;
	
//	NSString *_connectedFriend;
//	NSUInteger _connectedType;
	
//	GSXMPPLoginViewController *_loginView;
    
    BOOL _isDisplayingKeyboard;
	
}

@property (nonatomic, retain) GSFriendsListViewController *friendsView;
//@property (nonatomic, copy) NSString *connectedFriend;
//@property (nonatomic, assign) NSUInteger connectedType;

//- (id)initWithInternetConnection:(GSInternetConnection *)internetConnection;

- (id)initWithInternetConnection:(GSInternetConnection *)internetConnection 
	  localBrowser:(BrowserViewController *)bvc;

- (GSInternetConnection *)internetConnection;

- (IBAction)doneTapped:(UIButton *)b;
- (IBAction)signOutButtonPressed:(UIButton *)b;

#pragma mark Subscribe

/*

 - Step 1: host: A send request B
 - Step 2: client: B receive a request. Check if request from X (a new friend, not in friend list)
 - Step 3: client: if request from strange, ask user: 
 - Step 4: client: if user answer yes, send subscribed to A and send request to A (save to _pendingFriend)
 - Step 5: host: A receive subscribed, check if from a pending request user alert user
 - Step 6: host: A receive subscribe from Y (check if it is B) then silently reply YES
 - Step 7: client: B receive subscribed from X (check if X is in pending & friendlist) -> silent YES.

 */

/*
 For recreate connection request
 
 - Step 1: host: A send request B
 - Step 2: client: B receive a request. Check if request from X (a new friend, not in friend list)
 - Step 3.1: client: if request from strange, ask user: 
 - Step 3.2: client: if request from a person in friend list, or contact list, silently accepted
 - Step 4: client: if user answer yes, send subscribed to A and send request to A (save to _pendingFriend)
 - Step 5: host: A receive subscribed, check if from a contact list, yes: silently, NO: alert user
 - Step 6: host: A receive subscribe from Ycheck if from a contact list, yes: then silently reply YES, NO: alert user
 - Step 7: client: B receive subscribed from X (check if X is in pending & friendlist) -> silent YES.
 
 */



//- (void)friendsViewDidChooseToConnectTo:(NSString *)connectionName type:(NSUInteger)connectionType;


- (void)setConnected:(GSWhiteboard *)connectedWhiteboard;
- (void)localBrowserDidReloadData;

- (void)connectionControllerDidChangeStatus;
- (void)networkUnavailable:(GSConnectionType)networkType;

- (void)restoreConnectionAfterRecreatingAccount;

- (void)focusToLoginView;
@end
