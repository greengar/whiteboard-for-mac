//
//  GSSignUpViewController.h
//  Whiteboard
//
//  Created by Cong Vo on 12/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GSInternetConnection.h"


@interface GSSignUpViewController : UITableViewController <UITextFieldDelegate> {
	id _delegate; // weak reference

	UITextField *emailField;
	UITextField *usernameField;
	UITextField *passwordField;
	UITextField *passwordRepeatField;	
		
	NSMutableArray *textFields;
	
	GSInternetConnection *_internetConnection;
	
	UIAlertView *_progressStatusView;
	
	NSString *_username;
	NSString *_password;
	NSString *_email;
	NSString *_xmppUsername;
    NSString *_xmppPassword;
	NSString *_xmppDomain;
    
	NSMutableArray *_services;
	
	BOOL _isWaitingXMPPStreamDisconnect;
	BOOL _shouldRegisterWhenConnected;
	
	NSArray *_userUsedServices;
}

@property (nonatomic, retain) UIAlertView *progressStatusView;
@property (nonatomic, retain) NSMutableArray *services;
@property (nonatomic, retain) NSString *username, *password;

- (id)initWithinitWithDelegate:(id)delegate 
			internetConnection:(GSInternetConnection *)connection;

- (void)createXMPPAccountFor:(NSString *)username password:(NSString *)password xmppDomain:(NSString *)domain;

- (void)updateProgressingAlertMessage:(NSString *)status;
- (void)getXMPPServices;
- (void)sendRegistration;
- (void)createXMPPAccount;
- (void)getUserUsedXMPPServices;
- (void)recreateXMPPAccountForWBUsername:(NSString *)username password:(NSString *)password;
- (void)createBrandNewXMPPAccountForWBUsername:(NSString *)username password:(NSString *)password;
- (void)hideKeyboard;
@end
