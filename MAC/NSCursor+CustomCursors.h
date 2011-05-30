//
//  NSCursor+CustomCursors.h
//  WhiteboardMac
//
//  Created by Hector Zhao on 1/26/11.
//  Copyright 2011 GreenGar studios. All rights reserved.
//

#import <Cocoa/Cocoa.h> 

@interface NSCursor (CustomCursors) 

+ (NSCursor *)panCursor; 
+ (NSCursor *)zoomCursor;
+ (NSCursor *)zoomInCursor;
+ (NSCursor *)zoomOutCursor;

@end 
