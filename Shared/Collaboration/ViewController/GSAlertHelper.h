//
//  GSObjectAlert.h
//  Whiteboard
//
//  Created by Cong Vo on 1/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GSAlert.h"

@class GSAlertHelper;

static NSString * const AcceptRejectQuestionTypeFriendSubscribe = @"FriendSubscribe";
static NSString * const AcceptRejectQuestionTypeConnection = @"FriendConnection";
@protocol GSAlertHelperDelegate <NSObject>

- (void)alertHelper:(GSAlertHelper *)ar didClickedButton:(NSInteger)index
	forQuestionType:(NSString *)type callbackObject:(id)obj;

@end


@interface GSAlertHelper : NSObject <GSAlertDelegate> {
	id _delegate;
	NSString *_questionType;
	id _callbackObject;
	
}


@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) id callbackObject;
@property (nonatomic, retain) NSString *questionType;

- (id)initWithQuestionType:(NSString *)type 
				  delegate:(id)delegate 
			callbackObject:(id)object;


@end
