//
//  CMAlertTableDialog.m
//  WhiteboardMac
//
//  Created by Hector Zhao on 1/24/11.
//  Copyright 2011 GreenGar studios. All rights reserved.
//

#import "CMAlertTableDialog.h"
#import "WhiteboardMacAppDelegate.h"
#import "GSConnectionController.h"
#import "GSLocalConnection.h"
#import "BrowserViewController.h"

@implementation CMAlertTableDialog
@synthesize deviceTableView;
@synthesize deviceList;
@synthesize networkingButton;

static BrowserViewController *localBrowser = nil;
- (BrowserViewController *)localBrowser {
	if (localBrowser == nil) {
		localBrowser = AppDelegate.connection.localConnection.bvc;
		localBrowser.displayDelegate = self;
	}
	return localBrowser;
}


- (id) init {
	if (self = [super init]) {
		deviceList = [NSMutableDictionary dictionaryWithCapacity:2];
		[deviceList retain];
		
		[[self localBrowser] setDisplayDelegate:self];
	}
	return (self);
}


- (void) dealloc {
	[deviceList release];
	[super dealloc];
}

static GSConnectionController *connection = nil;

- (GSConnectionController *)connection {
	if (connection == nil) {
		connection = AppDelegate.connection;
	}
	return connection;
}

- (void)setNetworkingButtonToTitle:(NSString *)title {
	
	if ([title isEqualToString:networkingDisableString]) {
		// enable networking 
		// also enable by default
		[AppDelegate.connection startToConnect];
		[networkingButton setTitle:networkingDisableString];						
	} else {
		// disable networking
		[AppDelegate.connection stopConnecting];		
		[networkingButton setTitle:networkingEnableString];
		
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:networkingButton.title
											  forKey:kNetworkingEnableKey];
	
	[deviceTableView reloadData];	
	
	[AppDelegate networkingEnableDidChange:[self isEnableNetworking]];
}


- (void)awakeFromNib {
	NSMutableArray			*deviceName, *deviceStatus;
	
	if (deviceList != nil) {
		
//		deviceName = [NSMutableArray array];
//		deviceStatus = [NSMutableArray array];

		deviceName = [NSMutableArray arrayWithObjects:@"hihi", @"hhee", nil];
		deviceStatus = [NSMutableArray arrayWithObjects:@"aaa", @"bbb", nil];
		
		[deviceList setObject:deviceName forKey:@"name"];
		[deviceList setObject:deviceStatus forKey:@"status"];
		
		// send a reload request
		[[self deviceTableView] reloadData];		
	}
}


- (void) tableView:(NSTableView *)aTbl setObjectValue:(id)aArg forTableColumn:(NSTableColumn *)aCol row:(int)aRow {
	DLog();
	
}

- (int)numberOfRowsInTableView:(NSTableView *)aTbl {
	DLog();
	return [[self localBrowser] numberOfPeers];
//	return 2;
//	return ([[[self deviceList] objectForKey:@"name"] count]);
}

- (id)tableView:(NSTableView *)aTbl objectValueForTableColumn:(NSTableColumn *)aCol row:(int)aRow {
	DLog(@"column: %@ row: %d", aCol, aRow);
	DLog(@"column: data cell: %@", [aCol dataCell]);
	
	if ([[aCol identifier] isEqualTo:@"device"]) {
		return [[self localBrowser] peerNameForRow:aRow];
	} else {
		// identifier: status
		
		if (self.connection.status == ConnectionStatusConnected) {
			GSWhiteboard *connectedWhiteboard = [self.connection connectedWhiteboard];
			if (connectedWhiteboard && connectedWhiteboard.type == GSConnectionTypeLocal) {
				NSString *connectedName = [connectedWhiteboard name];
				NSString *deviceName = [[self localBrowser] peerNameForRow:aRow];
				if ([deviceName isEqualToString:connectedName]) {
					return @"Connected";
				}
			}		
		} else if (self.connection.status == ConnectionStatusInConnecting) {
			GSWhiteboard *waitedWhiteboard = [self.connection waitedWhiteboard];		
			if (waitedWhiteboard && waitedWhiteboard.type == GSConnectionTypeLocal) {
				NSString *waitedName = [waitedWhiteboard name];
				NSString *deviceName = [[self localBrowser] peerNameForRow:aRow];
				if ([deviceName isEqualToString:waitedName]) {
					return @"Connecting";
				}			
			}
		}
		
		return @"";
	}

	return @"";

	
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	DLog(@"%@", aNotification);
	// do thing here
	NSInteger selectedIndex = [deviceTableView selectedRow];
	[[self localBrowser] didSelectPeerAtRow:selectedIndex];
	[deviceTableView deselectAll:nil];
}

- (NSDictionary *)getData; {
	NSMutableDictionary		*dataRow;
	int	row;
	
	// retrieve the currently selected row
	row = [[self deviceTableView] selectedRow];
	if (row >= 0) {
		// instantiate the data dictionary
		dataRow = [NSMutableDictionary dictionaryWithCapacity:4];
		if (dataRow != nil) {
			// update the data dictionary
			[dataRow setObject:[[[self deviceList] objectForKey:@"name"] objectAtIndex:row] forKey:@"name"];
			
			[dataRow setObject:[[[self deviceList] objectForKey:@"status"] objectAtIndex:row] forKey:@"status"];
			
			[dataRow setObject: [NSNumber numberWithInt:row] forKey:@"row"];
		}
	}
	// return the retrieval results
	return (dataRow);
}

- (void)setData:(NSDictionary *) data
{
	id	dataRow;
	int	row;
	
	// parametre check
	if ((data != nil) && ([data count] == 4))
	{
		// retrieve the row to be updated
		row = [[data objectForKey:@"row"] intValue];
		
		// update the data buffer
		dataRow = [data objectForKey:@"name"];
		[[deviceList objectForKey:@"name"] replaceObjectAtIndex:row withObject:dataRow];
		
		dataRow = [data objectForKey:@"status"];
		[[deviceList objectForKey:@"status"] replaceObjectAtIndex:row withObject:dataRow];
		
		// submit a reload request
		[deviceTableView reloadData];
	}
}

- (void)localBrowserDidReloadData {
	DLog();
	[deviceTableView reloadData];
}

- (void)connectionControllerDidChangeStatus {
	DLog();
	[deviceTableView reloadData];
}

- (void)networkUnavailable:(GSConnectionType)networkType {
	DLog();	
	[deviceTableView reloadData];
}

- (IBAction)networkingButtonClicked:(id)sender {
	DLog(@"current title: %@", networkingButton.title);
	if ([networkingButton.title isEqualToString:networkingDisableString]) {
		[self setNetworkingButtonToTitle:networkingEnableString];
	} else {
		[self setNetworkingButtonToTitle:networkingDisableString];		
	}
}

- (BOOL)isEnableNetworking {
	if ([networkingButton.title isEqualToString:networkingDisableString]) {
		return YES;
	} else {
		return NO;
	}
}

@end
