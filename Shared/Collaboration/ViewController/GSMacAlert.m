//
//  GSMacAlert.m
//  WhiteboardMac
//
//  Created by Cong Vo on 1/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GSMacAlert.h"
#import "WhiteboardMacAppDelegate.h"

@implementation GSMacAlert
@synthesize tag, delegate = _delegate, window = _window;
@synthesize messageField = _messageField, titleField = _titleField;
@synthesize defaultButton = _defaultButton, alternativeButton = _alternativeButton;


+ (id)alertWithDelegate:(id)delegate 
				 title:(NSString *)title message:(NSString *)message
		 defaultButton:(NSString *)defaultButtonTitle otherButton:(NSString *)otherButtonTitle {
	GSMacAlert *alert = [[[self class] alloc] init];

	if (![NSBundle loadNibNamed:@"GSMacAlert" owner:alert]) {
		DLog(@"load nib error");
	}
	
	alert.delegate = delegate;
	[alert.window orderOut:nil];
//	_messageField.title = message;
//	_defaultButton.text = defaultButtonTitle;
	if (title) {
		[alert.titleField setHidden:NO];
		[alert.titleField setStringValue:title];
	}
	
	if (message) {
		[alert.messageField setHidden:NO];
		[alert.messageField setStringValue:message];
	}
	
	if (defaultButtonTitle) {
		[alert.defaultButton setHidden:NO];
		[alert.defaultButton setTitle:defaultButtonTitle];
		[alert.window setDefaultButtonCell:[alert.defaultButton cell]];
//		[alert.defaultButton setNeedsDisplay:YES];

	}
	
	if (otherButtonTitle) {
		[alert.alternativeButton setHidden:NO];
		[alert.alternativeButton setTitle:otherButtonTitle];
	}
	
	
	
	return [alert autorelease];
}

- (void)displaySheetForWindow:(NSWindow *)window {
	if ([window attachedSheet]) {
		[self displaySheetForWindow:[window attachedSheet]];
		return;
	}
	
	DLog(@"show alert as sheet for window: %@", window);
	
	//	[self setShowsHelp:NO];
	//	[self setDelegate:nil];	
	//KONG: will release when dismissed 
	[self retain];
	[NSApp beginSheet:self.window
	   modalForWindow:window
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:NULL];
	[self.window becomeKeyWindow];
}

//- (BOOL)acceptsFirstResponder {
//
//	DLog();
//	return YES;
//}

- (void)show {
	[self displaySheetForWindow:AppDelegate.window];
}

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated {
	DLog();
	DLog(@"NSAlert: retainCount: %d", [self retainCount]);
	
	//	if ([self.delegate respondsToSelector:@selector(alertView:didDismissWithButtonIndex:)]) {
	//		[self.delegate alertView:self didDismissWithButtonIndex:1001 - returnCode];
	//	}	
	
//	[self.window orderOut:nil];	
//	[[self window] orderOut:AppDelegate.window];
//	[[self window] orderOut:nil];
	[NSApp endSheet:[self window]];
//	[[self window] orderOut:AppDelegate.window];	
	[[self window] orderOut:nil];
	if ([self.delegate respondsToSelector:@selector(alertView:didDismissWithButtonIndex:)]) {
		[self.delegate alertView:self didDismissWithButtonIndex:buttonIndex];
	}	
//	DLog(@"NSAlert: retainCount: %d", [self retainCount]);	
	//KONG: release retain when displaying 
	[self release];
	self = nil;
	
}

static int const defaultButtonValue = 1;
static int const alternativeButtonValue = 0;

- (void)clickedButtonIndex:(NSInteger)index {
	if ([self.delegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)]) {
		[self.delegate alertView:self clickedButtonAtIndex:index];
	}	
	
	[self dismissWithClickedButtonIndex:index animated:NO];
	
}

- (IBAction)defaultButtonClicked:(id)sender {
	[self clickedButtonIndex:defaultButtonValue];
}

- (IBAction)alternativeButtonClicked:(id)sender {
	[self clickedButtonIndex:alternativeButtonValue];
}

- (void)setMessage:(NSString *)message {
	[self.messageField setStringValue:message];
}

- (void)dealloc {
	[_window setDefaultButtonCell:nil];
	[_window release];
	[_titleField release];
	
	[_messageField release];
	
	[_defaultButton release];
	[_alternativeButton release];
	[super dealloc];
}
@end
