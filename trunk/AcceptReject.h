//
//  AcceptReject.h
//  Whiteboard
//
//  Created by Elliot Lee on 12/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface AcceptReject : NSObject <UIAlertViewDelegate> {
	NSString* name;
}

@property (nonatomic, copy) NSString* name;

//- (void)setName:(NSString*)newName;

@end
