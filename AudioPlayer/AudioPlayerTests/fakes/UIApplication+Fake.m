//
//  UIApplication+Fake.m
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 22/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

#import <objc/runtime.h>
#import "UIApplication+Fake.h"

@implementation UIApplication (Fake)

+ (void) load {
    Method m1 = class_getInstanceMethod(UIApplication.class, @selector(beginBackgroundTaskWithExpirationHandler:));
    Method m2 = class_getInstanceMethod(UIApplication.class, @selector(fake_beginBackgroundTaskWithExpirationHandler:));
    if (m1 && m2) {
        method_exchangeImplementations(m1, m2);
    }

    Method m3 = class_getInstanceMethod(UIApplication.class, @selector(endBackgroundTask:));
    Method m4 = class_getInstanceMethod(UIApplication.class, @selector(fake_endBackgroundTask:));
    if (m3 && m4) {
        method_exchangeImplementations(m3, m4);
    }
}

- (void) setOnBegin:(UIBackgroundTaskIdentifier (^)(void (^ _Nonnull)()))onBegin {
    objc_setAssociatedObject(self, "begin", onBegin, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (UIBackgroundTaskIdentifier (^)(void (^)())) onBegin {
    return objc_getAssociatedObject(self, "begin");
}

- (void) setOnEnd:(void (^)(UIBackgroundTaskIdentifier))onEnd {
    objc_setAssociatedObject(self, "end", onEnd, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(UIBackgroundTaskIdentifier)) onEnd {
    return objc_getAssociatedObject(self, "end");
}


- (UIBackgroundTaskIdentifier) fake_beginBackgroundTaskWithExpirationHandler:(void (^)(void))handler {
    return self.onBegin ? self.onBegin(handler) : UIBackgroundTaskInvalid;
}

- (void) fake_endBackgroundTask:(UIBackgroundTaskIdentifier)identifier {
    NSLog(@"fake_endBackgroundTask");
    if (self.onEnd) {
        self.onEnd(identifier);
    }
}

@end
