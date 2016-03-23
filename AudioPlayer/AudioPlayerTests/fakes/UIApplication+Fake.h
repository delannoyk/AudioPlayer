//
//  UIApplication+Fake.h
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 22/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIApplication (Fake)

@property (nonatomic, copy, nullable) UIBackgroundTaskIdentifier(^onBegin)(void(^)());
@property (nonatomic, copy, nullable) void(^onEnd)(UIBackgroundTaskIdentifier);

- (UIBackgroundTaskIdentifier) fake_beginBackgroundTaskWithExpirationHandler:(void (^)(void))handler;
- (void) fake_endBackgroundTask:(UIBackgroundTaskIdentifier)identifier;

@end

NS_ASSUME_NONNULL_END
