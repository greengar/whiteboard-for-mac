//
//  GSMacAlert.h
//  WhiteboardMac
//
//  Created by Cong Vo on 1/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GSMacAlert;

@protocol GSMacAlertDelegate <NSObject>
- (void)alertView:(GSMacAlert *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
- (void)alertView:(GSMacAlert *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;

@end


@interface GSMacAlert : NSObject {
	NSInteger tag;
	
	id <GSMacAlertDelegate> _delegate;
	
	NSWindow *_window;
    NSWindow *parentWindow;
	NSTextField *_titleField;
	NSTextField *_messageField;
	
	NSButton *_defaultButton;
	NSButton *_alternativeButton;
}
@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, assign) id <GSMacAlertDelegate> delegate;
@property (nonatomic, retain) IBOutlet NSWindow *window;
@property (nonatomic, retain) NSWindow *parentWindow;

@property (nonatomic, retain) IBOutlet NSTextField *titleField;
@property (nonatomic, retain) IBOutlet NSTextField *messageField;

@property (nonatomic, retain) IBOutlet NSButton *defaultButton;
@property (nonatomic, retain) IBOutlet NSButton *alternativeButton;

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated;

+ (id)alertWithDelegate:(id)delegate 
				 title:(NSString *)title message:(NSString *)message
		 defaultButton:(NSString *)defaultButtonTitle otherButton:(NSString *)otherButtonTitle;
	
- (void)show;

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated;

- (IBAction)defaultButtonClicked:(id)sender;
- (IBAction)alternativeButtonClicked:(id)sender;

- (void)setMessage:(NSString *)message;
@end
