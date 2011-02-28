//
//  GSViewHelper.m
//  Whiteboard
//
//  Created by Cong Vo on 12/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GSViewHelper.h"


@implementation GSViewHelper

+ (void)showAlertViewTitle:(NSString *)title message:(NSString *)msg cancelButton:(NSString *)cancelTitle {
	GSAlert *errorView = [GSAlert alertWithDelegate:nil
											  title:title
											message:msg
									  defaultButton:cancelTitle
										otherButton:nil];
	[errorView show];
}
#if TARGET_OS_IPHONE
+ (GSAlert *)showStatusAlertViewTitle:(NSString *)title message:(NSString *)msg {
	GSAlert *progressStatusView = [GSAlert alertWithDelegate:nil
											  title:title
											message:msg
									  defaultButton:nil
										otherButton:nil];
		
//	_progressStatusView.tag = 60;
	//	_progressStatusView.frame = CGRectMake(0.f, 0.f, 20.f, 20.f)
	
	
	UIActivityIndicatorView* activityView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
	// -22 y if name is 6 chars or less
	//	activityView.frame = CGRectMake(226.0f, 46.0f, 20.f, 20.f); //30.0f, 68.0f, 225.0f, 13.0f); //139.0f-18.0f, 80.0f, 37.0f, 37.0f);
	activityView.frame = CGRectMake(127.0f, 80.0f, 37.0f, 37.0f);	
	[progressStatusView addSubview:activityView];
	[activityView startAnimating];
	
	[progressStatusView show];
	[progressStatusView autorelease];
	return progressStatusView;
}
#endif

@end
