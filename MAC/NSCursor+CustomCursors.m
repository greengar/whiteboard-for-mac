//
//  NSCursor+CustomCursors.m
//  WhiteboardMac
//
//  Created by Hector Zhao on 1/26/11.
//  Copyright 2011 GreenGar studios. All rights reserved.
//

#import "NSCursor+CustomCursors.h" 

@implementation NSCursor (CustomCursors) 

+ (NSCursor *)panCursor 
{ 
    static NSCursor *panCursor = nil; 
    if (!panCursor) { 
        NSImage *pan = [NSImage imageNamed:@"Pan_Cursor"]; 
        NSPoint hotspot = NSMakePoint(10.0f, 10.0f); 
        panCursor = [[NSCursor alloc] 
					   initWithImage:pan hotSpot:hotspot]; 
    } 
    return panCursor; 
} 

+ (NSCursor *)zoomCursor 
{ 
    static NSCursor *zoomCursor = nil; 
    if (!zoomCursor) { 
        NSImage *zoom = [NSImage imageNamed:@"Zoom_Icon"]; 
        NSPoint hotspot = NSMakePoint(10.0f, 10.0f); 
        zoomCursor = [[NSCursor alloc] 
					 initWithImage:zoom hotSpot:hotspot]; 
    } 
    return zoomCursor; 
}

+ (NSCursor *)zoomInCursor 
{ 
    static NSCursor *zoomInCursor = nil; 
    if (!zoomInCursor) { 
        NSImage *zoomIn = [NSImage imageNamed:@"ZoomIn_Cursor"]; 
        NSPoint hotspot = NSMakePoint(10.0f, 10.0f); 
        zoomInCursor = [[NSCursor alloc] 
                      initWithImage:zoomIn hotSpot:hotspot]; 
    } 
    return zoomInCursor; 
}

+ (NSCursor *)zoomOutCursor 
{ 
    static NSCursor *zoomOutCursor = nil; 
    if (!zoomOutCursor) { 
        NSImage *zoomOut = [NSImage imageNamed:@"ZoomOut_Cursor"]; 
        NSPoint hotspot = NSMakePoint(10.0f, 10.0f); 
        zoomOutCursor = [[NSCursor alloc] 
                      initWithImage:zoomOut hotSpot:hotspot]; 
    } 
    return zoomOutCursor; 
}

@end 
