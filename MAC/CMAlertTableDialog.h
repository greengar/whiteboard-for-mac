//
//  CMAlertTableDialog.h
//  WhiteboardMac
//
//  Created by Hector Zhao on 1/24/11.
//  Copyright 2011 GreenGar studios. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GSConnection.h"

static NSString *const kNetworkingEnableKey = @"kNetworkingEnableKey";
static NSString *const networkingEnableString = @"Enable Networking";
static NSString *const networkingDisableString = @"Disable Networking";

@interface CMAlertTableDialog : NSWindow {
	IBOutlet NSTableView	*deviceTableView;
	
	NSMutableDictionary		*deviceList;
	
	IBOutlet NSButton *networkingButton;
}

@property (nonatomic, retain) NSTableView *deviceTableView;
@property (nonatomic, retain) NSMutableDictionary *deviceList;
@property (nonatomic, retain) NSButton *networkingButton;

- (void)connectionControllerDidChangeStatus;
- (void)networkUnavailable:(GSConnectionType)networkType;

- (IBAction)networkingButtonClicked:(id)sender;
- (void)setNetworkingButtonToTitle:(NSString *)title;

- (BOOL)isEnableNetworking;
@end
