/*
 * AppController.h
 * Classes
 * 
 * Created by Gregory Barchard on 23/09/2010.
 * 
 * Copyright (c) 2010 BuySellAds.com
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the project's author nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

//
//  NSObject+Additions.m
//  BSAAdFramework
//
//  Created by Rick Fillion on 09-09-02.
//  Copyright 2009 BuySellAds. All rights reserved.
//

#import "NSObject+Additions.h"
#import <objc/message.h>


@implementation NSObject (Additions)

- (void)performSelector:(SEL)selector withObject:(id)object1 withObject:(id)object2 withObject:(id)object3
{
    (void)objc_msgSend(self, selector, object1, object2, object3);
}

- (void)performSelector:(SEL)selector withObject:(id)object1 withObject:(id)object2 withObject:(id)object3 afterDelay:(NSTimeInterval)delay
{
    NSMutableDictionary *args = [NSMutableDictionary dictionary];
    [args setValue:object1 forKey:@"object1"];
    [args setValue:object2 forKey:@"object2"];
    [args setValue:object3 forKey:@"object3"];
    [args setValue:NSStringFromSelector(selector) forKey:@"selector"];
    [self performSelector:@selector(_tripleObjectDelay:) withObject:args afterDelay:delay];
}

- (void)_tripleObjectDelay:(NSDictionary *)args
{
    id object1 = [args valueForKey:@"object1"];
    id object2 = [args valueForKey:@"object2"];
    id object3 = [args valueForKey:@"object3"];
    SEL selector = NSSelectorFromString([args valueForKey:@"selector"]);
    [self performSelector:selector withObject:object1 withObject:object2 withObject:object3];
}

@end
