//
//  BrushPickerPanel.m
//  WhiteboardMac
//
//  Created by Silvercast on 11/29/10.
//  Copyright 2010-2011 Greengar Studios. All rights reserved.
//

#import "BrushPickerPanel.h"


@implementation BrushPickerPanel

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation
{
	windowStyle |= 8223;
	NSRect colorPanelRect = NSMakeRect(10, 10, contentRect.size.width, contentRect.size.height-10);
	return [super initWithContentRect:colorPanelRect styleMask:windowStyle backing:bufferingType defer:deferCreation];
}

@end
