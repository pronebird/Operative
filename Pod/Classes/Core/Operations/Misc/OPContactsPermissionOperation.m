// OPContactsPermissionOperation.m
// Copyright (c) 2015 Tom Wilson <tom@toms-stuff.net>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "OPContactsPermissionOperation.h"
#import "OPOperationConditionMutuallyExclusive.h"
#import <Contacts/Contacts.h>

@implementation OPContactsPermissionOperation

- (instancetype)init
{
    self = [super init];
    if(!self) {
        return nil;
    }
    
    [self addCondition:[OPOperationConditionMutuallyExclusive alertPresentationExclusivity]];
    
    return self;
}

- (void)execute
{
    CNEntityType entityType = CNEntityTypeContacts;
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:entityType];
    
    if(status == CNAuthorizationStatusNotDetermined)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            CNContactStore *store = [[CNContactStore alloc] init];
            
            [store requestAccessForEntityType:entityType completionHandler:^(BOOL granted, NSError *error) {
                [self finish];
            }];
        });
    }
    else
    {
        [self finish];
    }
}

@end
