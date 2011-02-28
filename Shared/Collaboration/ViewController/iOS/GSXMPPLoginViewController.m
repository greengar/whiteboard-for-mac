//
//  GSXMPPLoginViewController.m
//  Whiteboard
//
//  Created by Cong Vo on 12/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GSXMPPLoginViewController.h"
#import "AppController.h"
#import "XMPP.h"
#import "Picker.h"

#import "GSSignUpViewController.h"
#import "GSInternetConnection.h"
#import "GSConnectionController.h"
#import "GSViewHelper.h"
#import "GSXmlRpcHelper.h"
#import "GSConnectViewController.h"
#import "GSUserHelper.h"


@interface GSXMPPLoginViewController ()

@property (nonatomic, retain) UITextField *usernameField, *passwordField;
@property (nonatomic, retain) UIView *footerView;
@property (nonatomic, retain) NSString *xmppPassword;
- (void)hideKeyboard;

@end

@implementation GSXMPPLoginViewController
@synthesize username = _username, password = _password, xmppUsername = _xmppUsername, xmppPassword = _xmppPassword, xmppDomain = _xmppDomain;
@synthesize usernameField = _usernameField, passwordField = _passwordField;
@synthesize signUpButton = _signUpButton, signInButton = _signInButton;
@synthesize connectViewController = _connectViewController;
@synthesize isTextEditing = _isTextEditing;
@synthesize footerView = _footerView;

//@synthesize loginAlertView = _loginAlertView;

//@synthesize signUpView = _signUpView;


// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

//- (id)initWithDelegate:(id)delegate {
//	if ((self == ) {
//		_delegate = delegate;
//	}
//	return self;
//}

- (id)init {
	if ((self = [super init])) {
		_xmppUsername = [[[NSUserDefaults standardUserDefaults] objectForKey:kXMPPCachedUsername] copy];
		if (_xmppUsername != nil && [_xmppUsername length] > 6) {
			_username = [[_xmppUsername substringToIndex:_xmppUsername.length - 6] copy];
		}
		_xmppPassword = [[[NSUserDefaults standardUserDefaults] objectForKey:kXMPPCachedPassword] copy];
		_xmppDomain = [[[NSUserDefaults standardUserDefaults] objectForKey:kXMPPCachedDomain] copy];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticatingNotification:) name:kAuthenticatingNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	}
	return self;
}



- (id)initWithDisplayer:(id)displayer connection:(id <GSConnection>)connection {
	if ((self = [self init])) {
		_displayer = displayer;
		_internetConnection = [connection retain];
		[(XMPPStream *) _internetConnection.xmppStream addDelegate:self];
//		_localBrowser = [bvc retain];
	}
	return self;
}

- (id)initWithFriendsViewController:(UITableViewController *)friendsView 
				internetConnection:(GSInternetConnection *)iConn {
	if ((self = [self init])) {
		_internetConnection = [iConn retain];
		[(XMPPStream *) _internetConnection.xmppStream addDelegate:self];		
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];	
	
	[(XMPPStream *) _internetConnection.xmppStream removeDelegate:self];
	[_internetConnection release];
    
    [_usernameField release];
	[_passwordField release];
	
	[_username release];
	[_password release];
    [_xmppUsername release];
    [_xmppPassword release];
    [_xmppDomain release];

    [_signUpButton release];
	[_signInButton release];
    [_footerView release];
    
	[super dealloc];
}
- (GSConnectionController *)connection {
	return UIAppDelegate.connection;
}

#pragma mark buttons

//- (void)showDoneButton {
//	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
//																						   target:self
//																						   action:@selector(cancelButtonPressed)] autorelease];	
//}

- (void)cancelButtonPressed {
	DLog();
//	[self.navigationController dismissModalViewControllerAnimated:YES];
}


- (IBAction)loginButtonPressed {
	
	_shouldRestoreConnectionsAfterRecreatingAccount = NO;
	
	NSString *username = _usernameField.text;
	NSString *password = _passwordField.text;
	
	if (username == nil || [username isEqualToString:@""]) {
		[GSViewHelper showAlertViewTitle:@"Please type your username"  message:nil cancelButton:@"OK"];
		return;
	}
	
	
	if (password == nil || [password isEqualToString:@""]) {
		[GSViewHelper showAlertViewTitle:@"Please type your password"  message:nil cancelButton:@"OK"];
		return;
	}
	
	// get user name password
	// tell xmpp to authenticate
	[self loginWithUsername:username password:password];
}


- (void)signUpViewButtonPressed {
	NSLog(@"%s", _cmd);
	GSSignUpViewController *signUpView = [[[GSSignUpViewController alloc] 
										   initWithinitWithDelegate:self
										   internetConnection:_internetConnection] autorelease];
	
	if ([_usernameField.text length] > 0) {
		signUpView.username = _usernameField.text;	
	} else {
		signUpView.username = _username;
	}
	
	
	//TODO: KONG: make black background for flip
	
	/*	
	 // animate up view with fade
	 CATransition *animation = [CATransition animation];
	 [animation setDuration:0.5];
	 [animation setType:kCATransitionPush];
	 [animation setSubtype:kCATransitionFromRight];
	 [animation setFillMode:kCAFillModeBoth];
	 [animation setTimingFunction:[CAMediaTimingFunction
	 functionWithName:kCAMediaTimingFunctionLinear]];
	 [[self.navigationController.view layer] removeAllAnimations];
	 [[self.navigationController.view layer] addAnimation:animation forKey:@
	 "pushAnimation"];
	 
	 [[self.navigationController.view layer] setM
	 setModalTransitionStyle:UIModalTransitionStyleCrossDissolve]; // this is the nearest I could get :(
	 
	 [self presentModalViewController:viewController animated:YES];
	 */		

	 [UIView beginAnimations:nil context:nil];
	 [UIView setAnimationDuration:kSignUpViewAnimationDuration];
	 //    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft
	 //                           forView:self.navigationController.view
	 //							 cache:YES];
	 
	 [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft
	 forView:[self.connectViewController.view superview]
	 cache:YES];
	 
	 [self.connectViewController pushViewController:signUpView animated:NO];
	 
	 [UIView commitAnimations];


//	[self.connectViewController pushViewController:signUpView animated:YES];

}

#pragma mark View methods


- (void)updateDisplay {
	DLog();
	[_displayer performSelector:@selector(updateDisplay)];
}
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
/*
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.navigationItem.title  = @"Networking";
	
	[self showDoneButton];
	//	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Nearby" 
	//																			   style:UIBarButtonItemStyleBordered
	//																			  target:self
	//																			  action:@selector(nearbyButtonPressed)] autorelease];	
	
	//	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Login" 
	//																			   style:UIBarButtonItemStyleBordered
	//																			  target:self
	//																			  action:@selector(loginButtonPressed)] autorelease];	
	self.navigationController.toolbarHidden = YES;
	
	
	
	//	[_tableView setTableFooterView:footerView];
	//	
	//	[_tableView setSectionFooterHeight:60.f];
	//	[_tableView reloadData];
	//	NSLog(@"1");
	
}
*/

- (void)viewWillAppear:(BOOL)animated {
	DLog();
	if ([_internetConnection isInAuthenticatingProcess]) {
		[self updateViewWhenSigningIn:YES];
	}
}


- (void)loginWithUsername:(NSString *)username password:(NSString *)password {
	self.username = username;
	self.password = password;
	
//	self.loginAlertView = [GSViewHelper showStatusAlertViewTitle:@"Log in"
//														 message:@"Logging in Greengar server"];

	[self updateViewWhenSigningIn:YES];
	[GSXmlRpcHelper performRequestWithMethod:@"ggs.wb.getUserInfo"
										args:[NSArray arrayWithObjects:username, password, nil]
									delegate:self callback:@selector(xmlRpcDidFinishGetUserInfo:)];
	
//	DLog(@"user: %@ - pass: %@", username, password);
//	XMPPStream *xmppStream = (XMPPStream *) _internetConnection.xmppStream;
//
//	if (username != nil && password != nil) {
//		[xmppStream setMyJID:[XMPPJID jidWithString:
//							  [NSString stringWithFormat:@"%@@chatmask.com", username]
//										   resource:@"wb"]];
//		if ([xmppStream isConnected]) {
//			[xmppStream authenticateWithPassword:password error:nil];
//		} else {
//			_internetConnection.xmppPassword = password;
//			[xmppStream connect:nil];
//		}
//		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
//	}
}
- (void)authenticatingNotification:(NSNotification *)notification {
	DLog();
	[self updateViewWhenSigningIn:YES];
}

static BOOL _isSignningIn = NO;
- (void)updateViewWhenSigningIn:(BOOL)isSigning {
//    DLog();
	_isSignningIn = isSigning;
	[self hideKeyboard];
	// UPdate UI
	[self updateDisplay];	
}

- (BOOL)sendXMPPAuthenticateRequestWithPassword:(NSString *)xmppPassword {
	NSError *error = nil;
	BOOL isSuccessful = [[_internetConnection xmppStream] authenticateWithPassword:xmppPassword error:&error];
	if (isSuccessful == NO || error) {
		NSLog(@"Error authenticating: %@", error);
		return NO;
	}
	
	[self updateViewWhenSigningIn:YES];
	return YES;
}

- (void)loginWithXMPPUsername:(NSString *)username XMPPPassword:(NSString *)XMPPPassword domain:(NSString *)domain {
	DLog(@"user: %@ - pass: %@ - domain %@", username, XMPPPassword, domain);
	self.xmppUsername = username;
	self.xmppPassword = XMPPPassword;
	self.xmppDomain = domain;


	
	XMPPStream *xmppStream = (XMPPStream *) _internetConnection.xmppStream;

	if (_xmppUsername != nil && _xmppPassword != nil && domain != nil) {
		
//		NSString *logingInNetworkServerString = @"Loging in Networking server";
//		if (_loginAlertView == nil) {
//			self.loginAlertView = [GSViewHelper showStatusAlertViewTitle:@"Log in"
//																 message:logingInNetworkServerString];
//		} else {
//			_loginAlertView.message = logingInNetworkServerString;
//		}
		
		[xmppStream setMyJID:[XMPPJID jidWithString:
							  [NSString stringWithFormat:@"%@@%@", _xmppUsername, domain]
										   resource:@"wb-ip"]];
		
		_internetConnection.xmppPassword = _xmppPassword;
		if ([xmppStream isConnected] && [xmppStream.hostName isEqualToString:domain]) {
			if ([self sendXMPPAuthenticateRequestWithPassword:_xmppPassword] == NO) {
				//KONG: I want to stop all authenticating process here 
				return;
			}
		} else {
			[xmppStream setHostName:domain];
			_shouldLoginAfterConnected = YES;
			[xmppStream connect:nil];
		}
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	} else {
		DLog(@"WARNING: should not call w user, name, password, or domain nil");
	}

	
}

- (void)xmlRpcDidFinishGetUserInfo:(id)response {
	
	/*
	 2010-12-29 14:36:43.602 TestXMLRPC[31878:207] response: {
	 displayname = abc;
	 "xmpp_domain" = "chatmask.com";
	 "xmpp_user" = "kk.g.g.s";
	 }
	 2010-12-29 14:36:44.101 TestXMLRPC[31878:207] response: {
	 faultCode = 403;
	 faultString = "Bad login/pass combination.";
	 }
	 */
	DLog(@"%@", response);
	if (response == nil || [response isKindOfClass:[NSDictionary class]] == NO) {
		[GSViewHelper showAlertViewTitle:@"Cannot finish login" message:@"Please try again" cancelButton:@"OK"];
		return;
	}
	NSDictionary *result = response;
	// Check for error
	if ([result objectForKey:@"faultCode"] != nil) { // error
//		NSString *faultString = [result objectForKey:@"faultString"];
//		[_loginAlertView dismissWithClickedButtonIndex:-1 animated:YES];
		NSNumber *faultCode = (NSNumber *)[result objectForKey:@"faultCode"];
		if ([faultCode isEqualToNumber:[NSNumber numberWithInt:403]]) { // Bad username/pass combination
			UIAlertView *loginErrorAlert = [[[UIAlertView alloc] initWithTitle:@"Cannot finish login" 
																	   message:@"Please check your username or password"
																	  delegate:self 
															 cancelButtonTitle:@"New account" otherButtonTitles:@"Try again", nil] autorelease];
			loginErrorAlert.tag = 10;
			[loginErrorAlert show];			
		} else {
			[GSViewHelper showAlertViewTitle:@"Cannot finish login" message:[result objectForKey:@"faultString"] cancelButton:@"Try again"];			
		}
		[self updateViewWhenSigningIn:NO];
	} else {
        NSString *kUserID = @"user_id";
        NSString *userID = [result objectForKey:kUserID];
        [GSUserHelper cacheUsername:_username password:_password userID:userID];
            
        
		self.xmppUsername = [result objectForKey:@"xmpp_user"];
		self.xmppDomain = [result objectForKey:@"xmpp_domain"];
		
		// check if user already added
		if (_xmppUsername == nil || _xmppDomain == nil) {
		//
		// TODO: KONG - check for 
			[self createBrandNewXMPPAccount];
		} else {
			[self loginWithXMPPUsername:_xmppUsername XMPPPassword:[GSUserHelper XMPPPasswordForUsername:_username] domain:_xmppDomain];
		}
	}

}

- (void)recreateXMPPAccount {
	GSSignUpViewController *signUpView = [[[GSSignUpViewController alloc] 
										   initWithinitWithDelegate:self
										   internetConnection:_internetConnection] autorelease];
	
	_shouldRestoreConnectionsAfterRecreatingAccount = YES;
	[signUpView recreateXMPPAccountForWBUsername:_username password:_password];
}


- (void)createBrandNewXMPPAccount {
	GSSignUpViewController *signUpView = [[[GSSignUpViewController alloc] 
										   initWithinitWithDelegate:self
										   internetConnection:_internetConnection] autorelease];
	[signUpView createBrandNewXMPPAccountForWBUsername:_username password:_password];
}

#pragma mark tableView


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (NSString *)tableView:(UITableView *)sender titleForHeaderInSection:(NSInteger)sectionIndex
{
	if (sectionIndex == 0) {
		return @"Local Wi-Fi and Bluetooth";
	} else {
		//		sectionIndex--; // minute 1 for index-compatibility w fetchedResultsController
		return @"Whiteboard Online";
	}
	
	return @"";
}

- (NSString *)tableView:(UITableView *)sender nameForHeaderInSection:(NSInteger)sectionIndex {
	if (sectionIndex == 0) {
		NSString *localName = [[[self connection] localConnection] myName];
		if (localName) {
			return [NSString stringWithFormat:@"%@", localName];
		}
	} else {
		NSString *internetName = [[[self connection] internetConnection] myName];
		if (internetName) {
			return [NSString stringWithFormat:@"%@", internetName];
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
	
	//KONG: title
	UILabel *titleView = [[[UILabel alloc] initWithFrame:CGRectMake(20, 10, 320, 25)] autorelease];
	titleView.opaque = NO;
	titleView.backgroundColor = [UIColor clearColor]; //background color
	
	titleView.font = [UIFont boldSystemFontOfSize:18];
	
	titleView.textColor = [UIColor colorWithRed:0.298039 green:0.337255 blue:0.423529 alpha:1];
	titleView.shadowColor = [UIColor whiteColor];
	titleView.shadowOffset = CGSizeMake(0, 1.0);
	titleView.text = [self tableView:tableView titleForHeaderInSection:section];
	[headerView addSubview:titleView];
	if (section == 0) {
		//KONG: name
		UILabel *nameView = [[[UILabel alloc] initWithFrame:CGRectMake(20, 34, 320, 15)] autorelease];
		nameView.opaque = NO;
		nameView.backgroundColor = [UIColor clearColor]; //background color
		
		nameView.font = [UIFont systemFontOfSize:14];
		nameView.textColor = [UIColor darkGrayColor];
		nameView.shadowColor = [UIColor whiteColor];
		nameView.shadowOffset = CGSizeMake(0, 1.0);
		nameView.text = [self tableView:tableView nameForHeaderInSection:section];
		[headerView addSubview:nameView];
	}
	return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if (section == 0) {
		return 55.0;
	}
	return 40.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {	
//	DLog(@"_isSignningIn: %d", _isSignningIn);
    
//	return (sectionIndex == 1)?
//
//	:[_localBrowser tableView:tableView numberOfRowsInSection:(sectionIndex - 1)];
	return (_isSignningIn == YES)? 1: 2;
}

- (UITextField *)textFieldForInputCell {
	UITextField *playerTextField = [[UITextField alloc] initWithFrame:CGRectMake(110, 12, 195, 22)];
	playerTextField.adjustsFontSizeToFitWidth = YES;
	playerTextField.textColor = [UIColor blackColor];
	playerTextField.backgroundColor = [UIColor clearColor];
//    	playerTextField.backgroundColor = [UIColor yellowColor];
	playerTextField.autocorrectionType = UITextAutocorrectionTypeNo; // no auto correction support
	playerTextField.autocapitalizationType = UITextAutocapitalizationTypeNone; // no auto capitalization support
	playerTextField.textAlignment = UITextAlignmentLeft;
    playerTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
	//playerTextField.tag = 0;
	playerTextField.delegate = self;
	
	playerTextField.clearButtonMode = UITextFieldViewModeWhileEditing; // no clear 'x' button to the right
	[playerTextField setEnabled: YES];	
	return playerTextField;
}

- (UITableViewCell *)signinCellForTableView:(UITableView *)tableView {
	
	UITableViewCell *cell = nil;	
	NSString *kSigningCellIdentifier = @"SigningInCell";
	cell = [tableView dequeueReusableCellWithIdentifier:kSigningCellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
									   reuseIdentifier:kSigningCellIdentifier] autorelease];
        cell.textLabel.text = @"Signing in...";
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        //	cell.textLabel.frame = CGRectMake(50, 10, 200, 40);
        
        UIActivityIndicatorView *signinIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
        
        signinIndicator.frame = CGRectMake(80, 35, 20, 20);
        [signinIndicator startAnimating];
        signinIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin 
        | UIViewAutoresizingFlexibleRightMargin;
        [cell addSubview:signinIndicator];
        
	}
	
	return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

//	if ([indexPath section] == 0) {
//		return [_localBrowser tableView:tableView cellForRowAtIndexPath:indexPath];
//	}	
	
	
	// change the indexpath for signin field
//	[NSIndexPath indexPathForRow:[indexPath row] inSection:[indexPath section] - 1]];
	
	UITableViewCell *cell = nil;	
	if (_isSignningIn) {
		return [self signinCellForTableView:tableView];
	}
	
	// ref: http://snipplr.com/view/43894/uitextfield-added-to-a-uitableviewcell/
	if ([indexPath row] == 0) {
//		NSString *kCellIdentifier = @"UsernameTextInputCell";
//		cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
//		
//		if (cell == nil) {
//			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
//										   reuseIdentifier:kCellIdentifier] autorelease];
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
									   reuseIdentifier:nil] autorelease];		
			cell.accessoryType = UITableViewCellAccessoryNone;
			UITextField *playerTextField = [self textFieldForInputCell];
			[cell addSubview:playerTextField];
			[playerTextField release];		

			// username specific
			playerTextField.placeholder = @"Required";
			playerTextField.keyboardType = UIKeyboardTypeDefault;
			playerTextField.returnKeyType = UIReturnKeyNext;
			self.usernameField = playerTextField;
			_usernameField.text = self.username;
			cell.textLabel.text = @"Username";
//		}
	} else { // indexpath row 1
//		NSString *kCellIdentifier = @"PasswordTextInputCell";
//		cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
//		
//		if (cell == nil) {
//			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
//										   reuseIdentifier:kCellIdentifier] autorelease];
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
										   reuseIdentifier:nil] autorelease];		
			cell.accessoryType = UITableViewCellAccessoryNone;
			UITextField *playerTextField = [self textFieldForInputCell];
			[cell addSubview:playerTextField];
			[playerTextField release];		
			
			// password specific
			playerTextField.placeholder = @"Required";
			playerTextField.keyboardType = UIKeyboardTypeDefault;
			playerTextField.returnKeyType = UIReturnKeyDone;
			playerTextField.secureTextEntry = YES;
			//playerTextField.delegate = self;
			self.passwordField = [playerTextField retain];
			_passwordField.text = self.password;
			cell.textLabel.text = @"Password";
			
//		}
	}
	
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
	return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection: (NSInteger)section 
{

	if (section == 1) {
        if (_footerView == nil) {
            self.footerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320.f, 60.f)] autorelease];
            _footerView.opaque = YES;
            _footerView.backgroundColor = [UIColor clearColor];

            //	footerView.alpha = 0.0;
            _footerView.contentMode = UIViewContentModeTopLeft;
            
            // sign up button
            self.signUpButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            _signUpButton.frame = CGRectMake(10, 10, 140, 40);
            [_signUpButton setTitle:@"New account" forState:UIControlStateNormal];
            [_signUpButton addTarget:self 
                              action:@selector(signUpViewButtonPressed)
                    forControlEvents:UIControlEventTouchUpInside];
            
            _signUpButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
            [_footerView addSubview:_signUpButton];
            
            
            // sign in button
            self.signInButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            _signInButton.frame = CGRectMake(170, 10, 140, 40);
            [_signInButton setTitle:@"Sign in" forState:UIControlStateNormal];
            [_signInButton addTarget:self 
                              action:@selector(loginButtonPressed)
                    forControlEvents:UIControlEventTouchUpInside];
            
            [_footerView addSubview:_signInButton];
            
            _signInButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;            
        }
        
		// disable when signing in
		_signInButton.enabled = !_isSignningIn;
//		_signInButton.highlighted = _isSignningIn;
		_signUpButton.enabled = !_isSignningIn;	
        
        
		
		return _footerView;
	}
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection: (NSInteger) section {
	return 60.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return (_isSignningIn)?88.0:44.0;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath row] == 0) {
        [_usernameField becomeFirstResponder];
    } else {
        [_passwordField becomeFirstResponder];
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

//- (void)localBrowserDidReloadData {
//	// TODO: update after editing
//	if (!_isTextEditing) {
//		[self reloadData];		
//	}
//
//}

#pragma mark XMPP

- (void)xmppStreamDidConnect:(XMPPStream *)sender {
	if (_shouldLoginAfterConnected) {
		_shouldLoginAfterConnected = NO;
		if (_xmppPassword) {
			[self sendXMPPAuthenticateRequestWithPassword:_xmppPassword];
		}		
	}	
}


- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
	
	// save to User default
	NSString *username = _internetConnection.xmppStream.myJID.user;
	NSString *password = _internetConnection.xmppPassword;
	NSString *domain = _internetConnection.xmppStream.hostName;	
	if (username != nil && password!= nil) {
		[[NSUserDefaults standardUserDefaults] setValue:username forKey:kXMPPCachedUsername];
		[[NSUserDefaults standardUserDefaults] setValue:password forKey:kXMPPCachedPassword];
		[[NSUserDefaults standardUserDefaults] setValue:domain forKey:kXMPPCachedDomain];
	}
		
	
//	[_loginAlertView dismissWithClickedButtonIndex:-1 animated:YES];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	[self updateViewWhenSigningIn:NO];
	
	// dismiss by telling delegate
	if (_shouldRestoreConnectionsAfterRecreatingAccount) {
		
		_shouldRestoreConnectionsAfterRecreatingAccount = NO;
		
		[UIAppDelegate.connection.connectionView restoreConnectionAfterRecreatingAccount];
	}
	
	
	// pop to friend list view :)
	[UIAppDelegate.connection.connectionView loginViewDidAuthenticated:self];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error {
	//KONG: this method can be called multiple time
	NSLog(@"---------- xmppStream:didNotAuthenticate: ----------");
	DLog(@"sender: %@ error: %@", sender.hostName, error);
	
	// failed to disconnected.

	//KONG: this method can be called multiple time
	if (_isSignningIn == NO) {
		return;
	}
	
	[self updateViewWhenSigningIn:NO];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	// check the error
	/*
	<failure xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><not-authorized/></failure>
	<failure xmlns="urn:ietf:params:xml:ns:xmpp-sasl"><not-authorized></not-authorized></failure>
	 */
	
	// _username == nil when logging in is performed using cache data
	if (_username == nil) {
		return;
	}
	
	if ([error elementForName:@"not-authorized"] == nil) {
		return;
	}
	
	
	[self recreateXMPPAccount];		
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error {
    if (_isSignningIn) {
        [self updateViewWhenSigningIn:NO];
        [GSViewHelper showAlertViewTitle:@"Connection error" 
                                 message:@"Please try to login again." 
                            cancelButton:@"OK"];		
    }		
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	DLog(@"%d %@", alertView.tag, alertView.title);
	if (alertView.tag == 10 && buttonIndex == 0) {
//	if (buttonIndex == 0) {
		[self signUpViewButtonPressed];
		// TODO: KONG - add username for user
	}
}

/**
 * This method is called after authentication has successfully finished.
 * If authentication fails for some reason, the xmppStream:didNotAuthenticate: method will be called instead.
 **/

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField.returnKeyType == UIReturnKeyDone) {
//		[textField resignFirstResponder];	
		[self hideKeyboard];
		[self loginButtonPressed];
	} else {
		[_passwordField becomeFirstResponder];
	}

	return YES;
}
#pragma mark keyboard show/hide

- (void)hideKeyboard {
	[_usernameField resignFirstResponder];
	[_passwordField resignFirstResponder];
}

- (void)keyboardWillShow:(NSNotification *)notification {
	
//	if (!IS_IPAD) {
//		UIViewController *friendsList = (UIViewController *) _displayer;	
//		friendsList.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel" 
//																				   style:UIBarButtonItemStyleBordered
//																				  target:self
//																				  action:@selector(hideKeyboard)] autorelease];	
//	}

//    DLog(@"%@", [(UITableViewController *) _displayer tableView]);
     //scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]
//						  atScrollPosition:UITableViewScrollPositionNone animated:YES];
//    
    [self performSelector:@selector(scrollView) withObject:nil afterDelay:0.1];
//    [self scrollView];
    
	_isTextEditing = YES;
    
//    [_displayTableview scrollToRect:_signInButton.frame];
	
}

- (void)scrollView {	
    UITableView *tableView = [(UITableViewController *) _displayer tableView];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
    CGRect frame = cell.frame;
    frame.origin.y += _signInButton.frame.size.height + 13;
    [tableView scrollRectToVisible:frame animated:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification {
	
//	[self showDoneButton];
//	if (!IS_IPAD) {	
//		UIViewController *friendsList = (UIViewController *) _displayer;
//		friendsList.navigationItem.rightBarButtonItem = nil;
//	}
	_isTextEditing = NO;
	
	self.username = _usernameField.text;
	self.password = _passwordField.text;
	
	[self updateDisplay];
}

- (void)focusToLoginView {
    DLog();
    [_usernameField becomeFirstResponder];
}

@end