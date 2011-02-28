//
//  GSSignUpViewController.m
//  Whiteboard
//
//  Created by Cong Vo on 12/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#include <stdlib.h>

#import "GSSignUpViewController.h"
#import "AppController.h"
#import "XMPP.h"

#import "GSXMPPLoginViewController.h"
#import "GSConnectionController.h"


//#import "XMLRPCResponse.h"
//#import "XMLRPCRequest.h"
//#import "XMLRPCConnection.h"
#import "GSXmlRpcHelper.h"
#import "GSViewHelper.h"
#import "GSUserHelper.h"

@interface GSSignUpViewController()


@property (nonatomic, retain) NSString *email, *xmppUsername, *xmppPassword, *xmppDomain;
@property (nonatomic, retain) NSArray *userUsedServices;

- (void)connectToNewService;

@end


@implementation GSSignUpViewController
@synthesize progressStatusView = _progressStatusView;
@synthesize email = _email, xmppUsername = _xmppUsername, xmppPassword = _xmppPassword, xmppDomain = _xmppDomain;
@synthesize username = _username, password = _password;
@synthesize services = _services;
@synthesize userUsedServices = _userUsedServices;

#pragma mark Common View stuff

static NSString *creatingGreengarAccount   = @"Greengar account...";
static NSString *creatingNetworkingAccount = @"Networking account...";

- (void)updateProgressingAlertMessage:(NSString *)status {
	_progressStatusView.message = status;
}

- (void)updateProgressingAlertTitle:(NSString *)title {
	_progressStatusView.title = title;
}


- (void)showStatusAlertView {	
	self.progressStatusView = [GSViewHelper showStatusAlertViewTitle:@"Registering" message:creatingGreengarAccount];
}

- (void)dismissStatusAlertViewAnimated:(BOOL)animated {
	[_progressStatusView dismissWithClickedButtonIndex:-1 animated:animated];
	_progressStatusView = nil;
}

- (void)showAlertForNetworkingAccountRegisteringError {
	NSString *errorMessage = [NSString stringWithFormat:@"Your Greengar account \"%@\" is already registered.\nUnfortunately, Networking service is not available right now. \n\nPlease sign in to Whiteboard online later for continue registering Networking account.\n Thank you!",_username];
	[GSViewHelper showAlertViewTitle:@"Cannot finish registering"
							 message:errorMessage
						cancelButton:@"OK"];	
}

- (void)showAlertViewTitle:(NSString *)title message:(NSString *)msg cancelButton:(NSString *)cancelTitle {
	UIAlertView *errorView = [[[UIAlertView alloc] initWithTitle:title message:msg
														delegate:nil
											   cancelButtonTitle:cancelTitle otherButtonTitles:nil] autorelease];
	[errorView show];
	
}

#pragma mark -
#pragma mark Initialization


//- (id)initWithStyle:(UITableViewStyle)style {
//    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
//    self = [super initWithStyle:style];
//    if (self) {
//        // Custom initialization.
//    }
//    return self;
//}

- (id)initWithinitWithDelegate:(id)delegate 
			internetConnection:(GSInternetConnection *)connection {
	if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
		_delegate = delegate;
		_internetConnection = [connection retain];
		[_internetConnection.xmppStream addDelegate:self];
	}
	return self;
}

- (void)dealloc {
	[_internetConnection.xmppStream removeDelegate:self];
	[_internetConnection release];    
    
	[emailField release];
	[usernameField release];
	[passwordField release];
	[passwordRepeatField release];	
    
	[textFields release];
	
	[_progressStatusView release];
	
	[_username release];
	[_password release];
	[_email release];
	[_xmppUsername release];
    [_xmppPassword release];
	[_xmppDomain release];
    [_services release];
	
	[_userUsedServices release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
 
	self.navigationItem.title  = @"New Account";
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel" 
																			  style:UIBarButtonItemStyleBordered
																			 target:self
																			 action:@selector(cancelButtonPressed)] autorelease];
    
//    self.navigationItem.backBarButtonItem = nil;
//	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Sign Up" 
//																			   style:UIBarButtonItemStyleBordered
//																			  target:self
//																			  action:@selector(signUpButtonPressed)] autorelease];	
    self.navigationItem.hidesBackButton = YES;
	self.navigationController.toolbarHidden = YES;
    self.tableView.backgroundColor = [UIColor colorWithRed:0.90 green:0.91 blue:0.92 alpha:1.0];
	
	textFields = [[NSMutableArray arrayWithCapacity:4] retain];
	
//	[self getXMPPServices];
	// test
//	[self showStatusAlertView];
	
//	usernameField.text = _username;
	if ([self respondsToSelector:@selector(setContentSizeForViewInPopover:)]) {
		self.contentSizeForViewInPopover = CGSizeMake(320, 460);
	}
}

- (void)recreateXMPPAccountForWBUsername:(NSString *)username password:(NSString *)password {
	DLog(@"username: %@, password: %@", username, password);
	self.username = username;
	self.password = password;
	[self showStatusAlertView];
	[self updateProgressingAlertTitle:@"Networking error"];
	[self updateProgressingAlertMessage:@"Regenerating Networking account"];

	[self getUserUsedXMPPServices];	
}

- (void)createBrandNewXMPPAccountForWBUsername:(NSString *)username password:(NSString *)password {
	self.username = username;
	self.password = password;
	
	[self showStatusAlertView];
//	[self updateTitle:@"Cannot finish login"];	
	[self updateProgressingAlertMessage:creatingNetworkingAccount];
	
	[self getXMPPServices];		
}

- (void)getUserUsedXMPPServices {
	NSArray *args = [NSArray arrayWithObjects:_username, _password, nil];
	[GSXmlRpcHelper performRequestWithMethod:@"ggs.wb.getXMPPList" 
										args:args
									delegate:self callback:@selector(xmlRpcDidFinishGettingUserUsedServices:)];
	[self retain];
}

- (void)xmlRpcDidFinishGettingUserUsedServices:(id)response {
	DLog(@"response: %@", response);
	/*
	 (
	 {
	 "xmpp_account" = kk;
	 "xmpp_domain" = "chatmask.com";
	 },
	 {
	 "xmpp_account" = "kk.g.g.s";
	 "xmpp_domain" = "chatmask.com";
	 },
	 {
	 "xmpp_account" = "kkk.g.g.s";
	 "xmpp_domain" = "chatmask.com";
	 }
	 )
	 */
	if ([response isKindOfClass:[NSArray class]] == NO) {
		//KONG: error alert for user
		
		return;
	}	 
	
	self.userUsedServices = response;
	
	[self getXMPPServices];
	[self autorelease];
}

- (void)getXMPPServices {
	DLog();
	
	self.services = nil;
	[GSXmlRpcHelper retrieveXmppServicesListWithDelegate:self callback:@selector(xmlRpcDidFinishGettingServices:)];
	[self retain];
}

- (void)xmlRpcDidFinishGettingServices:(NSArray *)services {
	
	// check for error
	if ([services isKindOfClass:[NSError class]]) {
		self.services = [NSMutableArray array];
	}
	
	
	DLog(@"services: %@", services);
	self.services = [NSMutableArray arrayWithArray:services];

	if (_services == nil) {
		//KONG: registering cannot be continue in this situation
		
		DLog(@"WARNING: services should not be nil");
		
		[self dismissStatusAlertViewAnimated:NO];
		[self showAlertForNetworkingAccountRegisteringError];
		
		return;
	}
	
	[self createXMPPAccount];
	[self autorelease]; // retain when starting request network
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}


- (NSString *)tableView:(UITableView *)sender titleForHeaderInSection:(NSInteger)sectionIndex {
    if (sectionIndex == 0) {
        return @"Registering your Greengar account";
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 2;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	UITableViewCell *cell = nil;	
	static NSString *kCellIdentifier = @"TextInputCell";
	cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
	
	// ref: http://snipplr.com/view/43894/uitextfield-added-to-a-uitableviewcell/
	
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
									   reuseIdentifier:kCellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryNone;

		UITextField *playerTextField = [[UITextField alloc] initWithFrame:CGRectMake(110, 10, 185, 30)];
		playerTextField.adjustsFontSizeToFitWidth = YES;
		playerTextField.textColor = [UIColor blackColor];
		
		if ([indexPath section] == 0) { // Email & Password Section
			if ([indexPath row] == 0) {
				cell.textLabel.text = @"Username";				
				playerTextField.placeholder = @"Required";
				playerTextField.keyboardType = UIKeyboardTypeDefault;
				usernameField = [playerTextField retain];
				
				//KONG: Username is get from Login view 
				usernameField.text = _username;
			} else {
				cell.textLabel.text = @"Email";				
				playerTextField.placeholder = @"name@gmail.com";
				playerTextField.keyboardType = UIKeyboardTypeEmailAddress;
				emailField = [playerTextField retain];
			}
			playerTextField.returnKeyType = UIReturnKeyNext;
		} else {
			if ([indexPath row] == 0) {
				cell.textLabel.text = @"Password";				
				playerTextField.returnKeyType = UIReturnKeyNext;
				passwordField = [playerTextField retain];
			} else {
				cell.textLabel.text = @"Repeat";			
				playerTextField.returnKeyType = UIReturnKeyDone;
				passwordRepeatField = [playerTextField retain];
			}			
			
			playerTextField.placeholder = @"Required";
			playerTextField.keyboardType = UIKeyboardTypeDefault;
			playerTextField.secureTextEntry = YES;	
		}
		playerTextField.backgroundColor = [UIColor whiteColor];
		playerTextField.autocorrectionType = UITextAutocorrectionTypeNo; // no auto correction support
		playerTextField.autocapitalizationType = UITextAutocapitalizationTypeNone; // no auto capitalization support
		playerTextField.textAlignment = UITextAlignmentLeft;
        playerTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		//playerTextField.tag = 0;
		playerTextField.delegate = self;
		
		playerTextField.clearButtonMode = UITextFieldViewModeNever; // no clear 'x' button to the right
		[playerTextField setEnabled:YES];
		
		[cell addSubview:playerTextField];
		[textFields addObject:playerTextField];
		[playerTextField release];
	}

	return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection: (NSInteger)section {
    if (section == 1) {
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320.f, 60.f)];
        footerView.opaque = NO;
        //	footerView.alpha = 0.0;
        footerView.contentMode = UIViewContentModeTopRight;
        
        // sign up button
        UIButton *signUpButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        signUpButton.frame = CGRectMake(170, 10, 140, 40);
        [signUpButton setTitle:@"Sign up" forState:UIControlStateNormal];
        [signUpButton addTarget:self 
                         action:@selector(signUpButtonPressed)
               forControlEvents:UIControlEventTouchUpInside];
        
        signUpButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
        [footerView addSubview:signUpButton];
        
        return footerView;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection: (NSInteger) section {
	return 60.f;
}



/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    /*
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
    [detailViewController release];
    */
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


#pragma mark XMPP

- (void)resetFlagsAndVariablesForNewRegister {
	self.userUsedServices = nil;
}

- (IBAction)cancelButtonPressed {

	[UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:kSignUpViewAnimationDuration];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft
                           forView:[self.navigationController.view superview]
							 cache:YES];
	
	//    [self.navigationController.view addSubview:settingsView.view];
	[self.navigationController popViewControllerAnimated:NO];
	
    [UIView commitAnimations];

//	[self.navigationController popViewControllerAnimated:YES];	
}

- (void)testRegister {
	//username, password, email
}

//static NSString *server = @"http://www.greengarstudios.com.php5-18.dfw1-2.websitetestlink.com/wordpress/xmlrpc.php"; // the server



- (BOOL)validateEmail:(NSString *)candidate {
	//KONG: ref: http://stackoverflow.com/questions/800123/best-practices-for-validating-email-address-in-objective-c
	
	NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"; 
	NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex]; 	
	return [emailTest evaluateWithObject:candidate];
}

- (BOOL)validateInput {
	if (_username == nil || _username.length < 6) {
		[self showAlertViewTitle:@"Username should have at least 6 character"  message:nil cancelButton:@"OK"];
		[usernameField becomeFirstResponder];
		return NO;
	}
	
	
	if (_email == nil || [self validateEmail:_email] == NO) {
		[self showAlertViewTitle:@"Email address is not correct"  message:nil cancelButton:@"OK"];
		[emailField becomeFirstResponder];
		return NO;
	}
	
	
	if (_password == nil || _password.length < 6) {
		[self showAlertViewTitle:@"Password should have at least 6 character"  message:nil cancelButton:@"OK"];
		[passwordField becomeFirstResponder];
		return NO;
	}

	if (passwordRepeatField.text == nil || [passwordRepeatField.text isEqualToString:_password] == NO) {
		[self showAlertViewTitle:@"Repeat password does not match"  message:nil cancelButton:@"OK"];
		[passwordRepeatField becomeFirstResponder];
		return NO;
	}	
	return YES;
}


- (IBAction)signUpButtonPressed {
	
	self.username = usernameField.text;
	self.password = passwordField.text;
	self.email = emailField.text;
		
	if ([self validateInput] == NO) {
		return;
	}
	// Finish validation
    [self hideKeyboard];
//	[_signUp
	
	// show status
	[self showStatusAlertView];
	
	NSArray *args = [NSArray arrayWithObjects:_username, _password, _email, nil];
	NSString *method = @"ggs.register"; // the method
	[GSXmlRpcHelper performRequestWithMethod:method args:args
									delegate:self callback:@selector(xmlRpcDidFinishRegister:)];
	
//	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:server]];
//	
//	
//	[request setMethod:method withObjects:args];
//	id response = [self executeXMLRPCRequest:request];


//	[request release];
}



- (void)xmlRpcDidFinishRegister:(id)response {
	DLog(@"response: %@", response);
	/* KONG: sample response
	 {
	 email = "t@g.co";
	 "user_id" = 9;
	 "user_login" = hehehe;
	 }	 
	 */
	
	NSString *kUserID = @"user_id";
	NSString *userID = [(NSDictionary *)response objectForKey:kUserID];
	if ([response isKindOfClass:[NSDictionary class]] && userID != nil) {
		// go to step 2
//		[self createXMPPAccount];
        
        [GSUserHelper cacheUsername:_username password:_password userID:userID];
        
		[self getXMPPServices];
		
	} else { // error
		NSString *errorMsg = @"";
		if ([response isKindOfClass:[NSDictionary class]] && [(NSDictionary *)response objectForKey:@"faultString"] != nil) {
			errorMsg = [(NSDictionary *)response objectForKey:@"faultString"];
			//KONG: flurry error
		}
		
		if ([errorMsg isEqualToString:@""]) { //KONG: when we got unexpected (unknown) error
			errorMsg = @"Registering is not available now";
		}
		
		// dismiss status alert view
		[self dismissStatusAlertViewAnimated:NO];
		//showError
		[self showAlertViewTitle:@"Register Error" message:errorMsg cancelButton:@"Try again"];		
	}
}

- (NSString *)randomServiceDomain {
	if (_services == nil || [_services count] == 0) {
		return nil;
	}
	
	// remove used services
	NSMutableDictionary *unusedServices = [NSMutableDictionary dictionaryWithObjects:
										   [NSMutableArray arrayWithArray:_services] 
																			 forKeys:
										   [NSMutableArray arrayWithArray:_services]];
	
	
	if (_userUsedServices && [_userUsedServices count] > 0) {
		for (NSDictionary *usedService in _userUsedServices) {
			/*
			{
				"xmpp_account" = kk;
				"xmpp_domain" = "chatmask.com";
			},
			 */
			[unusedServices removeObjectForKey:[usedService objectForKey:@"xmpp_domain"]];
		}
	}
	
	self.services = [NSMutableArray arrayWithArray:[unusedServices allKeys]];
	
	if (_services == nil || [_services count] == 0) {
		return nil;
	}
	
	// random server
	// get a random number 

	NSUInteger r = arc4random() % [_services count];
	
	NSString *xmppDomain = [_services objectAtIndex:r];
	DLog(@"Choosed random XMPP services: %@", xmppDomain);
	//		NSString *xmppDomain = @"2"; 
	//		NSString *xmppDomain = @"xmpp.ws";
	//		NSString *xmppDomain = @"x23.eu"; // seem not register
	//		NSString *xmppDomain = @"xmpp.us";
	//		NSString *xmppDomain = @"chatmask.com"; // cannot send friend request
	return xmppDomain;
}

- (void)createXMPPAccount {
	DLog();	
	
	NSString *xmppDomain = [self randomServiceDomain];
	
	if (xmppDomain == nil) {
		// Error
		[self dismissStatusAlertViewAnimated:NO];
		[self showAlertForNetworkingAccountRegisteringError];
		return;
	}
	
	[self createXMPPAccountFor:_username password:_password xmppDomain:xmppDomain];
	[self retain]; // release when finish request
}



- (void)createXMPPAccountFor:(NSString *)username password:(NSString *)password xmppDomain:(NSString *)domain {
	DLog(@"username: %@ password: %@ xmppDomain: %@", username, password, domain);
	
	if (username == nil || password == nil || domain == nil) {
		DLog(@"WARNING: invalid args for creating account");
		return;
	}
	
	// get user name password
//	NSString *username = usernameField.text;
//	NSString *password = passwordField.text;
//	NSString *passwordRepeat = passwordRepeatField.text;
	
	
	// update the status view
	[self updateProgressingAlertMessage:creatingNetworkingAccount];
	
	
	self.xmppUsername = [NSString stringWithFormat:@"%@.g.g.s", username];
	self.xmppDomain = domain;
	self.xmppPassword = [GSUserHelper XMPPPasswordForUsername:username];
	
	
	
	
	// check correct password
//	if ([password isEqualToString:passwordRepeat]) {
		// create new myJID
		// tell xmpp to authenticate
	

	

//	}
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[self connectToNewService];
//	}
	
}

- (void)connectToNewService {
	DLog();

	XMPPStream *xmppStream = _internetConnection.xmppStream;
	if ([xmppStream isDisconnected] == NO) {
		DLog(@"not in Disconnect status, so start to disconnect");
		_isWaitingXMPPStreamDisconnect = YES;		
		[xmppStream disconnect];		
		return;
	}
	
	[xmppStream setHostName:_xmppDomain];
	BOOL isAbleToRegister = [xmppStream supportsInBandRegistration];
	
	NSLog(@"supportsInBandRegistration: %d", isAbleToRegister);
	
	[xmppStream setMyJID:[XMPPJID jidWithString:
						  [NSString stringWithFormat:@"%@@%@", _xmppUsername, _xmppDomain]
									   resource:@"wb"]];		
	DLog(@"xmppStream isDisconnected: %d", [xmppStream isDisconnected]);
	NSError *error = nil;
	_internetConnection.xmppPassword = _xmppPassword;
	_shouldRegisterWhenConnected = YES;
	[xmppStream connect:&error];
	if (error) {
		DLog (@"xmpp connect error: %@", error);
	}
}

- (void)sendRegistration {
	// check if register info
	if (_internetConnection.xmppPassword == nil || [_internetConnection.xmppPassword isEqualToString:@""]) {
		if (_password == nil) {
			DLog (@"WARNING: register with NO password");
			return;
		}
		_internetConnection.xmppPassword = _xmppPassword;
	}
	
	if ([_internetConnection.xmppStream isConnected]) {
		NSError *error = nil;
		
		BOOL reg = [_internetConnection.xmppStream registerWithPassword:_internetConnection.xmppPassword error:&error];
		if (reg == NO || error) {
			NSLog(@"register error: %@", error);
			/*
			 Error Domain=XMPPStreamErrorDomain Code=1 "Please wait until the stream is connected." UserInfo=0x5e888b0 {NSLocalizedDescription=Please wait until the stream is connected.}
			 */
			if ([error.domain isEqualToString:XMPPStreamErrorDomain] && error.code == 1) {
				DLog(@"WARNING: unexpected should not go to this");
				[self performSelector:@selector(sendRegistration) withObject:nil afterDelay:2];
			}
		} // end reg error
	} else {
		DLog(@"WARNING: xmppStream isConnected == NO");
		// This should be happen again
		[self performSelector:@selector(sendRegistration) withObject:nil afterDelay:1];
	}	
}

- (void)xmppStreamDidRegister:(XMPPStream *)sender {
	NSLog(@"---------- xmppStream:%@ xmppStreamDidRegister: ----------", sender);
	// associate xmpp server for username
	NSArray *args = [NSArray arrayWithObjects:_username, _password, _xmppUsername, _xmppDomain, nil];
	NSString *method = @"ggs.wb.addXMPP";                        // the method

	// TODO: KONG - I commented these line for testing, I should re-enable it 
	[GSXmlRpcHelper performRequestWithMethod:method args:args
									delegate:self callback:@selector(xmlRpcDidFinishAddingXMPP:)];
	
}

- (void)xmlRpcDidFinishAddingXMPP:(id)response {
	DLog(@"response: %@", response);
	
	// Check for error
	[(GSXMPPLoginViewController *) _delegate setUsername:_username];
	[_delegate loginWithXMPPUsername:_xmppUsername XMPPPassword:_xmppPassword domain:_xmppDomain];
	[self dismissStatusAlertViewAnimated:YES];
	// back to login view
	[self.navigationController popViewControllerAnimated:NO];	
	
	[self autorelease]; // release for retain when starting to retreive
//	[_delegate loginWithUsername:_username password:_password domain:_xmppDomain];	
}

/**
 * This method is called if registration fails.
 **/
- (void)xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement *)error {
	NSLog(@"---------- xmppStream:didNotRegister: ----------");	
	DLog(@"sender: %@ error: %@", sender.hostName, error);
	
	/* Error
	 Error Domain=XMPPStreamErrorDomain Code=1 "Please wait until the stream is connected." UserInfo=0x5e888b0 {NSLocalizedDescription=Please wait until the stream is connected.}
	 
	 
	 <iq from='openjabber.org' type='error'><query xmlns='jabber:iq:register'><username>kong2.g.g.s</username><password>ko</password></query><error code='500' type='wait'><resource-constraint xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/><text xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>Users are not allowed to register accounts so fast</text></error></iq>
	 
	 openjabber.org error: <iq from="openjabber.org" type="error"><query xmlns="jabber:iq:register"><username>athanhcong.g.g.s</username><password>thanhcong</password></query><error code="409" type="cancel"><conflict xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"></conflict></error></iq>
	 
	 */
	
//	[sender disconnect];
	
	// TODO: KONG - Test this more 
	[_services removeObject:_xmppDomain];
	
	if ([_services count] > 0) {
		[self createXMPPAccount];
		[self release];  // release for retain when starting to register		
		return;
	} else {
		[self dismissStatusAlertViewAnimated:NO];
		[self showAlertForNetworkingAccountRegisteringError];
		
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;		
		[self release];  // release for retain when starting to register		
		return;
	}

	
	
	// TODO: check conflict
	//<iq type="error" to="chatmask.com/cc93a420"><query xmlns="jabber:iq:register"><username>test</username><password>test</password></query><error code="409" type="cancel"><conflict xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/></error></iq>
	

	
	// KONG: unexpected situation, dismiss alert view
	[self dismissStatusAlertViewAnimated:NO];		
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender {
	NSLog(@"---------- xmppStream: %@ DidConnect: ----------", sender);
	if (_shouldRegisterWhenConnected) {
		// xmpp Stream is still not fully connected
		[self sendRegistration];
		_shouldRegisterWhenConnected  = NO;
	}
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender {
	if (_isWaitingXMPPStreamDisconnect) {
		DLog(@"change: _shouldRegisterWhenConnected from YES to NO");
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		_isWaitingXMPPStreamDisconnect  = NO;
		[self connectToNewService];
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	
	NSUInteger textFieldIndex = [textFields indexOfObject:textField];
	
	if (textFieldIndex == [textFields count] - 1) { // last field
		[self signUpButtonPressed];
	} else {
		[[textFields objectAtIndex:(textFieldIndex + 1)] becomeFirstResponder];
	}
	//KONG: This code parse username@gmail.com and auto fill username for user
/*
	if (textFieldIndex == 0) {
		// autocomplete for username
		NSString *email = emailField.text;
		NSRange atLocation = [email rangeOfString:@"@"];
		if (atLocation.location == NSNotFound) {
			
		} else {
			NSString *autoUsername = [email substringToIndex:atLocation.location];
			usernameField.text = autoUsername;
			usernameField.selected = YES;
		}
	}
 */
	return YES;
}

- (void)hideKeyboard {
    for (UITextField *textField in textFields) {
		[textField resignFirstResponder];
	}    
}


@end
