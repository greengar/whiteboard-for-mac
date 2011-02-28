//
//  GSViewHelper.h
//  Whiteboard
//
//  Created by Cong Vo on 12/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GSAlert.h"

@interface GSViewHelper : NSObject {

}

+ (void)showAlertViewTitle:(NSString *)title message:(NSString *)msg cancelButton:(NSString *)cancelTitle;
#if TARGET_OS_IPHONE
+ (GSAlert *)showStatusAlertViewTitle:(NSString *)title message:(NSString *)msg;
#endif
@end
