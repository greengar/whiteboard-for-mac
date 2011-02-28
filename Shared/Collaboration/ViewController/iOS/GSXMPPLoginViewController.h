//
//  GSXMPPLoginViewController.h
//  Whiteboard
//
//  Created by Cong Vo on 12/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "BrowserViewController.h"
#import "GSConnectionComponent.h"

#define kSignUpViewAnimationDuration (0.35)

@class GSXMPPLoginViewController;
@class GSInternetConnection;
@class GSConnectViewController;

@protocol GSXMPPLoginViewControllerDelegate <NSObject>

- (void)loginViewDidAuthenticated:(GSXMPPLoginViewController *)loginView;

@end
 


@interface GSXMPPLoginViewController : NSObject <GSConnectionComponent, UITextFieldDelegate> {

    GSConnectViewController *_connectViewController;    // a weak reference
    
	 UITextField *_usernameField;
	 UITextField *_passwordField;
	
	id _displayer;
	
//	UITableView *_tableView;
	GSInternetConnection *_internetConnection;
//	BrowserViewController *_localBrowser;
	
	
	// used to prevent reload tableView when editing -> clear text field
	BOOL _isTextEditing;
	
	NSString *_username;
	NSString *_password;
	NSString *_xmppUsername;
    NSString *_xmppPassword;
	NSString *_xmppDomain;
	
	/* KONG:
	 this help us now if we should send authenticate request when we did connect to xmpp server
	 this is reset, everytime we authenticate but need to connect first then sending authenticate later.
	 */
	BOOL _shouldLoginAfterConnected;
	
	/* KONG:
	 This variable, help us know when we logged in an account, 
	 whether before that we re-create new account, or just a normal log in mistake
	 The purpose is that we can decide whether we call methods: restoreConnectionAfterRecreatingAccount
	 This variable is reset everytime user click sign in button
	 */
	BOOL _shouldRestoreConnectionsAfterRecreatingAccount;
	
//	UIAlertView *_loginAlertView;
	
	/*
	 
	 
	 */

	
	
	UIButton *_signUpButton;
	UIButton *_signInButton;
    
    UIView *_footerView;
}

@property (nonatomic, assign) GSConnectViewController *connectViewController;


@property (nonatomic, retain) NSString *username, *password, *xmppUsername, *xmppDomain;
@property (nonatomic, retain) UIButton *signUpButton, *signInButton;

@property (nonatomic, readonly) BOOL isTextEditing;

//@property (nonatomic, retain) UIAlertView *loginAlertView;

- (IBAction)loginButtonPressed;
//- (IBAction)signInButtonPressed;

//- (id)initWithDelegate:(id)delegate;
//- (id)initWithDelegate:(id)delegate localBrowser:(BrowserViewController *)bvc;
//- (id)initWithDelegate:(id)delegate 
//	internetConnection:(GSInternetConnection *)iConn
//		  localBrowser:(BrowserViewController *)bvc;

//- (id)initWithFriendsViewController:(UITableViewController *)friendsView 
//				internetConnection:(GSInternetConnection *)iConn;


//- (void)localBrowserDidReloadData;
- (void)signUpViewButtonPressed;

- (void)loginWithXMPPUsername:(NSString *)username XMPPPassword:(NSString *)password domain:(NSString *)domain;
- (void)loginWithUsername:(NSString *)username password:(NSString *)password;
- (void)createBrandNewXMPPAccount;
- (void)updateViewWhenSigningIn:(BOOL)isSigning;

- (void)focusToLoginView;
@end
