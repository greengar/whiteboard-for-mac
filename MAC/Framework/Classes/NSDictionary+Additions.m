//
//  NSDictionary+Additions.h
//
//  Copyright (c) 2009, Christopher Verwymeren
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are
//  met:
//
//    * Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright
//      notice, this list of conditions and the following disclaimer in the
//      documentation and/or other materials provided with the distribution.
//    * Neither the name of the <organization> nor the names of its
//      contributors may be used to endorse or promote products derived from
//      this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY Christopher Verwymeren "AS IS" AND ANY EXPRESS
//  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
//  NO EVENT SHALL Christopher Verwymeren BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
//  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
//  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "NSDictionary+Additions.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>


@implementation NSDictionary (Additions)

- (NSString *)URLEncodedString
{
    NSMutableArray *encodedParameters = [NSMutableArray array];

    for (id key in self)
    {
        id value = [self objectForKey:key];

        NSString *encodedKeyString = [[NSString stringWithFormat:@"%@", key]
            stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *encodedValueString = [[NSString stringWithFormat:@"%@", value]
            stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *encodedParameterString = [NSString stringWithFormat:
            @"%@=%@", encodedKeyString, encodedValueString];

        [encodedParameters addObject:encodedParameterString];
    }

    if ([encodedParameters count] != 0)
    {
        return [encodedParameters componentsJoinedByString:@"&"];
    }

    return nil;
}

@end
