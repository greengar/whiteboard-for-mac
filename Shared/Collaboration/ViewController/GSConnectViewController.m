#import "GSConnectViewController.h"


#import "AppController.h"
#import "XMPP.h"
#import "BrowserViewController.h"


#import "GSConnectionController.h"
#import "GSXmlRpcHelper.h"
#import "GSWhiteboardUser.h"

#import "GSViewHelper.h"

#import "XMPP.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPUserCoreDataStorage.h"
#import "XMPPResourceCoreDataStorage.h"
#import "PickerViewController.h"

#import "GSUserHelper.h"

@interface GSConnectViewController()

- (void)displayLoginView;
- (void)dismissKeyboardButtonPressed;
@property (nonatomic, retain) UIAlertView *restoringConnectionAlertView;

@end


@implementation GSConnectViewController
@synthesize friendsView = _friendsView;
@synthesize restoringConnectionAlertView = _restoringConnectionAlertView;
//@synthesize connectedFriend = _connectedFriend, connectedType = _connectedType;

//- (id)initWithInternetConnection:(GSInternetConnection *)internetConnection rootView:(UIViewController *)friendView {
//	if ((self = [super initWithRootViewController:friendView])) {
//		_friendsView = [friendView retain];
//		_internetConnection = [internetConnection retain];
////		internetConnection.delegate = self;
//		internetConnection.delegate = _friendsView;
//	}
//	return self;
//}

- (id)initWithInternetConnection:(GSInternetConnection *)internetConnection rootView:(UIViewController *)friendView {
	if ((self = [super initWithRootViewController:friendView])) {
		_friendsView = [friendView retain];
		_internetConnection = [internetConnection retain];
        //		internetConnection.delegate = self;
		internetConnection.delegate = _friendsView;
	}
	return self;
}


- (id)initWithInternetConnection:(GSInternetConnection *)internetConnection 
	  localBrowser:(BrowserViewController *)bvc {

	UIViewController *friendView = [[[GSFriendsListViewController alloc] 
									 initWithInternetConnection:internetConnection
									 localBrowser:bvc] autorelease];			

	if ((self = [self initWithInternetConnection:internetConnection rootView:friendView])) {
		_localBrowser = [bvc retain];
		_localBrowser.displayDelegate = self;
	}
	return self;
}

- (void) dealloc {
	[_friendsView release];
	[_localBrowser release];
	[_internetConnection release];
//	[_loginView release];
	[super dealloc];
}


- (GSInternetConnection *)internetConnection {
	return [self.friendsView internetConnection];
}

- (void)viewDidLoad {
	[_localBrowser release];
	[super viewDidLoad];
}

- (void)displayLoginView {
//	_loginView = [[GSXMPPLoginViewController alloc] initWithDelegate:self 
//													internetConnection:_internetConnection
//														  localBrowser:_localBrowser];
//	[self pushViewController:_loginView animated:NO];
	
	GSXMPPLoginViewController *loginView = [[GSXMPPLoginViewController alloc] initWithDisplayer:_friendsView
																					 connection:_internetConnection];
	_friendsView.internetView = loginView;
	loginView.connectViewController = self;
	
	[_friendsView updateDisplay];
	
//	UITableViewController *displayedTableView = (UITableViewController *) self.topViewController;
//	displayedTableView.tableView.tableHeaderView = loginView.view;
	
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
//    return NO;
//}


- (void)viewWillAppear:(BOOL)animated {
	// check for if user enter username, password
	// by checking appdelegate xmpp active
	if (![_internetConnection.xmppStream isConnected] || ![_internetConnection.xmppStream isAuthenticated]) {
		// display login screen
		[self displayLoginView];
	}
	
	// else display Friends list controller as usual		
	[super viewWillAppear:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil]; 
    
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	// this doesn't seem necessary because [self.friendsView viewDidAppear:] is called automatically,
	// if/when -[GSConnectViewController viewDidAppear:] is called
	//[self.friendsView viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (_isDisplayingKeyboard) {
        [self dismissKeyboardButtonPressed];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    
}

- (void)keyboardWillShow:(NSNotification *)notification {
    DLog();
    
    if (IS_IPAD == NO) {
        if ([self.topViewController respondsToSelector:@selector(hideKeyboard)]) {
            UIButton *dismissKeyboardButton = [UIButton buttonWithType:UIButtonTypeCustom];
            UIImage *dismissImage = [UIImage imageNamed:@"dismissKeyboard.png"];
            CGFloat buttonWidth = dismissImage.size.width;
            CGFloat buttonHeight = dismissImage.size.height;
//            dismissKeyboardButton.frame = CGRectMake(320 - buttonWidth - 13, 480 - 216 - buttonHeight - 50, buttonWidth, buttonHeight);
            dismissKeyboardButton.frame = CGRectMake(320 - buttonWidth - 8, 480 - 216 - buttonHeight - 45, buttonWidth, buttonHeight);
            //    dismissKeyboardButton.imageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"dismissKeyboard.png"]] autorelease];
            [dismissKeyboardButton setImage:dismissImage forState:UIControlStateNormal];
            [dismissKeyboardButton addTarget:self action:@selector(dismissKeyboardButtonPressed) forControlEvents:UIControlEventTouchUpInside];
            //setSelected:@selector(dismissKeyboardButtonPressed)];
            [dismissKeyboardButton setTag:101];
            [[self.view superview] performSelector:@selector(addSubview:) withObject:dismissKeyboardButton afterDelay:0.3];         
        }    
        
        _isDisplayingKeyboard = YES;
        [AppDelegate.pickerViewController setAutorotate:NO];
    }
    
}
     
- (void)dismissKeyboardButtonPressed {
    DLog();
    
    if ([self.topViewController respondsToSelector:@selector(hideKeyboard)]) {
        [self.topViewController performSelector:@selector(hideKeyboard)];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    DLog();
    if (IS_IPAD == NO) {
        [[[self.view superview] viewWithTag:101] removeFromSuperview];
        _isDisplayingKeyboard = NO;
        [AppDelegate.pickerViewController setAutorotate:YES];
    }
}

- (IBAction)doneTapped:(UIButton *)b {
	// TODO: remove dangerous appDelegate reference:
//	[UIAppDelegate.pickerViewController dismissModalViewControllerAnimated:YES];
	[self dismissModalViewControllerAnimated:YES];
}

static int const kAlertViewLogout = 10;


- (void)logout {
    
    _internetConnection.isLogedInGreengar = NO;
	[UIAppDelegate.connection receivedNetworkUnavailableSignal:GSConnectionTypeInternet];
	
	[_internetConnection goOffline];
	[_internetConnection.xmppStream disconnect];
	
	// user pressed logout button - kong
	//	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"username"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kXMPPCachedPassword];
//	_loginView.password = nil;
	[self displayLoginView];
}

- (IBAction)signOutButtonPressed:(UIButton *)b {
	// logout
//	NSLog(@"%s", _cmd);
    [_friendsView printRoster];
    
	UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:
							   [NSString stringWithFormat:@"Do you want to sign out of \"%@\"?", [_internetConnection username]]
														 message:nil
														delegate:self
											   cancelButtonTitle:@"Cancel"
											   otherButtonTitles:@"Sign out", nil] autorelease];
	alertView.tag = kAlertViewLogout;
	[alertView show];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (alertView.tag == kAlertViewLogout) {
		if (buttonIndex == 1) {
			[self logout];
		}
	}
}

- (void)setConnected:(GSWhiteboard *)connectedWhiteboard {
	if (connectedWhiteboard) {
		[self doneTapped:nil];
		[AppDelegate.picker hideConnectionViewWithAnimation:NO];
	}
}

- (void)loginViewDidAuthenticated:(GSXMPPLoginViewController *)loginView {
	_friendsView.internetView = nil;
	[_friendsView.tableView reloadData];
}

- (void)localBrowserDidReloadData {
	[_friendsView localBrowserDidReloadData];
//	[_loginView localBrowserDidReloadData];
}


- (void)connectionControllerDidChangeStatus {
	[_friendsView localBrowserDidReloadData];
	if (AppDelegate.connection.status == ConnectionStatusConnected 
		|| AppDelegate.connection.status == ConnectionStatusNotYetConnected) {
		[self setConnected:AppDelegate.connection.connectedWhiteboard];		
	}
//	[_loginView localBrowserDidReloadData];	
}


- (void)networkUnavailable:(GSConnectionType)networkType {
	if(networkType == GSConnectionTypeInternet) {
		[self displayLoginView];
	}
}

- (void)restoreConnectionAfterRecreatingAccount {
	[_friendsView restoreConnectionAfterRecreatingAccount];
}

- (void)focusToLoginView {
    [_friendsView.internetView focusToLoginView];
}
@end