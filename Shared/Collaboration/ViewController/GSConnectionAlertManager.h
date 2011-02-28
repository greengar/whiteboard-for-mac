//
//  GSConnectionAlertManager.h
//  Whiteboard
//
//  Created by Cong Vo on 1/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GSConnectionAlert.h"


@interface GSConnectionAlertManager : NSObject {

	NSMutableArray *_alerts;
	
}

@property (nonatomic, retain) NSMutableArray *alerts;


// make decision to show alert view
- (void)showAlertView:(GSConnectionAlert *)alert;

- (void)alertView:(GSAlert *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;


@end
