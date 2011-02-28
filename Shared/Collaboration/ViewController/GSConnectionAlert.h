//
//  UIConnectionAlertView.h
//  Whiteboard
//
//  Created by Cong Vo on 1/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GSWhiteboard.h"
#import "GSAlert.h"

typedef enum AlertAction {
	AlertActionNone,
	AlertActionDecideToDisconnect,
	AlertActionAskForConnect,
	AlertActionDisconnected,
	AlertActionRejected,
	AlertActionAccepted,
	AlertActionSwitch
} AlertAction;

@interface GSConnectionAlert : GSAlert {

	AlertAction _action;
	GSWhiteboard *_affectedPeer;
	
	AlertAction _secondAction;
	GSWhiteboard *_secondAffectedPeer;
	
}

@property (nonatomic, assign) AlertAction action;
@property (nonatomic, retain) GSWhiteboard *affectedPeer;


@property (nonatomic, assign) AlertAction secondAction;
@property (nonatomic, retain) GSWhiteboard *secondAffectedPeer;

//+ (GSConnectionAlert *)alertWithDelegate:(id)delegate 
//						 title:(NSString *)title message:(NSString *)message
//				 defaultButton:(NSString *)defaultButtonTitle otherButton:(NSString *)otherButtonTitle;

@end
