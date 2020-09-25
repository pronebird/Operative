// OPOperationConditionUserNotification.m
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

#if TARGET_OS_IPHONE

#import "OPOperationConditionUserNotification.h"
#import "OPOperationConditionMutuallyExclusive.h"

#import "NSError+Operative.h"
#import "UIUserNotificationSettings+Operative.h"

static NSString *const kOPUserNotificationPermissionNotificationName = @"UserNotificationPermissionNotification";

NSString * const kCurrentSettings = @"CurrentUserNotificationSettings";
NSString * const kDesiredSettings = @"DesiredUserNotificationSettings";


#pragma mark - OPOperationConditionUserNotification Private
#pragma mark -

@interface OPOperationConditionUserNotification()

@property (strong, nonatomic) UIUserNotificationSettings *settings;
@property (strong, nonatomic) UIApplication *application;
@property (assign, nonatomic) OPOperationConditionUserNotificationBehavior behavior;

@end


#pragma mark - OPUserNotificationPermissionOperation
#pragma mark -


/**
 *  A private `OPOperation` to get notified when notification settings are registered on `UIApplication`.
 *
 *  - note: This operation requires you to call either
 *  `[OPOperationConditionUserNotification didRegisterUserNotificationSettings:]` in the appropriate
 *  `UIApplicationDelegate` method
 */
@interface OPUserNotificationPermissionOperation : OPOperation

@property (strong, nonatomic) UIUserNotificationSettings *settings;
@property (strong, nonatomic) UIApplication *application;
@property (assign, nonatomic) OPOperationConditionUserNotificationBehavior behavior;

@end


@implementation OPUserNotificationPermissionOperation

- (instancetype)initWithSettings:(UIUserNotificationSettings *)settings
                     application:(UIApplication *)application
                        behavior:(OPOperationConditionUserNotificationBehavior)behavior
{
    self = [super init];
    if (!self) {
        return nil;
    }

    _settings = settings;
    _application = application;
    _behavior = behavior;

    [self addCondition:[OPOperationConditionMutuallyExclusive alertPresentationExclusivity]];

    return self;
}

- (void)execute
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

        UIUserNotificationSettings *currentSettings = [self.application currentUserNotificationSettings];
        UIUserNotificationSettings *settingsToRegister;

        switch ([self behavior]) {
            case OPOperationConditionBehaviorMerge:
                settingsToRegister = [currentSettings settingsByMerging:[self settings]];
                break;
            case OPOperationConditionBehaviorReplace:
            default:
                settingsToRegister = [self settings];
                break;
        }
        
        [center addObserver:self selector:@selector(didReceiveUserSettingsRegistrationResponse:) name:kOPUserNotificationPermissionNotificationName object:nil];

        [self.application registerUserNotificationSettings:settingsToRegister];
    });
}

- (void)didReceiveUserSettingsRegistrationResponse:(NSNotification *)note
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self finish];
}

@end


#pragma mark - OPOperationConditionUserNotification Implementation
#pragma mark -

@implementation OPOperationConditionUserNotification

#pragma mark - Class Methods
#pragma mark -

+ (void)didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kOPUserNotificationPermissionNotificationName object:nil];
}

#pragma mark - Lifecycle
#pragma mark -

- (instancetype)initWithSettings:(UIUserNotificationSettings *)settings application:(UIApplication *)application
{
    return [self initWithSettings:settings application:application behavior:OPOperationConditionBehaviorMerge];
}

- (instancetype) initWithSettings:(UIUserNotificationSettings *)settings application:(UIApplication *)application behavior:(OPOperationConditionUserNotificationBehavior)behavior
{
    self = [super init];
    if (!self) {
        return nil;
    }
    _settings = settings;
    _application = application;
    _behavior = behavior;
    
    return self;
}


#pragma mark - OPOperationCondition
#pragma mark -

- (NSString *)name
{
    return @"UserNotification";
}

- (BOOL)isMutuallyExclusive
{
    return YES;
}

- (NSOperation *)dependencyForOperation:(OPOperation *)operation
{
    return [[OPUserNotificationPermissionOperation alloc] initWithSettings:[self settings]
                                                               application:[self application]
                                                                  behavior:[self behavior]];
}

- (void)evaluateConditionForOperation:(OPOperation *)operation
                           completion:(void (^)(OPOperationConditionResultStatus result, NSError *error))completion
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // Satisfied until not
        OPOperationConditionResultStatus result = OPOperationConditionResultStatusSatisfied;

        NSError *error = nil;

        UIUserNotificationSettings *current = [self.application currentUserNotificationSettings];

        if ([current containsSettings:[self settings]]) {
            // No-op
        } else {
            NSDictionary *userInfo = @{
                kOPOperationConditionKey : NSStringFromClass([self class]),
                kCurrentSettings         : current ? : [NSNull null],
                kDesiredSettings         : [self settings]
            };
            error = [NSError errorWithCode:OPOperationErrorCodeConditionFailed userInfo:userInfo];
            result = OPOperationConditionResultStatusFailed;
        }

        completion(result, error);
    });
}

@end

#endif
