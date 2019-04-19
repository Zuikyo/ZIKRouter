//
//  ZIKRouter+URLRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2019/4/19.
//  Copyright © 2019 zuik. All rights reserved.
//

#import "ZIKRouter+URLRouter.h"
#import "ZIKRouterInternal.h"
#import "ZIKRouterPrivate.h"
#import "ZIKRouterRuntime.h"

ZIKURLRouteKey ZIKURLRouteKeyOriginURL = @"origin-url";
ZIKURLRouteKey ZIKURLRouteKeyAction = @"action";

@implementation ZIKRouter (URLRouter)

+ (void)enableDefaultURLRouteRule {
    [ZIKRouter interceptBeforePerformWithConfiguration:^(ZIKRouter * _Nonnull router, ZIKPerformRouteConfiguration * _Nonnull configuration) {
        [router URLRouter_beforePerformWithConfiguration:configuration];
    }];
    [ZIKRouter interceptAfterSuccessAction:^(ZIKRouter * _Nonnull router, ZIKRouteAction  _Nonnull routeAction) {
        [router URLRouter_afterSuccessAction:routeAction];
    }];
}

- (void)URLRouter_beforePerformWithConfiguration:(ZIKPerformRouteConfiguration *)configuration {
    NSDictionary *userInfo = [self.configuration valueForKey:@"_userInfo"];
    if (!userInfo) {
        return;
    }
    NSURL *url = userInfo[ZIKURLRouteKeyOriginURL];
    if (!url || ![url isKindOfClass:[NSURL class]]) {
        return;
    }
    [self processUserInfo:userInfo fromURL:url];
}

- (void)URLRouter_afterSuccessAction:(ZIKRouteAction)routeAction {
    // Only handle perform route acation
    if (![routeAction isEqualToString:ZIKRouteActionPerformRoute]) {
        return;
    }
    NSDictionary *userInfo = [self.configuration valueForKey:@"_userInfo"];
    if (!userInfo) {
        return;
    }
    NSURL *url = userInfo[ZIKURLRouteKeyOriginURL];
    if (!url || ![url isKindOfClass:[NSURL class]]) {
        return;
    }
    NSString *action = userInfo[ZIKURLRouteKeyAction];
    if (action && [action isKindOfClass:[NSString class]]) {
        [self performAction:action userInfo:userInfo fromURL:url];
    }
}

- (void)processUserInfo:(NSDictionary *)userInfo fromURL:(NSURL *)url {
    
}

- (void)performAction:(NSString *)action userInfo:(NSDictionary *)userInfo fromURL:(NSURL *)url {
    
}

+ (NSString *)routerIdentifierFromURL:(NSURL *)url {
    return url.host;
}

+ (NSDictionary *)userInfoFromURL:(NSURL *)url {
    if (!url) {
        return @{};
    }
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[ZIKURLRouteKeyOriginURL] = url;
    
    NSString *query = url.query;
    if (query) {
        NSArray *params = [query componentsSeparatedByString:@"&"];
        for (NSString *param in params) {
            NSArray *kv = [param componentsSeparatedByString:@"="];
            if (kv.count == 2) {
                NSString *key = [kv firstObject];
                NSString *value = [kv lastObject];
                value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                userInfo[key] = value;
            }
        }
    }
    return userInfo;
}

@end

@implementation ZIKRouter (Interceptor)

+ (void)enableDefaultInterceptor {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZIKRouter_replaceMethodWithMethod([ZIKRouter class], @selector(performWithConfiguration:), [ZIKRouter class], @selector(interceptor_performWithConfiguration:));
        ZIKRouter_replaceMethodWithMethod([ZIKRouter class], @selector(notifySuccessWithAction:), [ZIKRouter class], @selector(interceptor_notifySuccessWithAction:));
        ZIKRouter_replaceMethodWithMethod([ZIKRouter class], @selector(endPerformRouteWithError:), [ZIKRouter class], @selector(interceptor_endPerformRouteWithError:));
    });
}

- (void)interceptor_performWithConfiguration:(ZIKPerformRouteConfiguration *)configuration {
    {
        void(^_Nullable interceptor)(ZIKRouter *, ZIKPerformRouteConfiguration *) = [[self class] interceptorBeforePerformWithConfiguration];
        if (interceptor) {
            interceptor(self, configuration);
        }
    }
    
    [self interceptor_performWithConfiguration:configuration];
    
    {
        void(^_Nullable interceptor)(ZIKRouter *, ZIKPerformRouteConfiguration *) = [[self class] interceptorAfterPerformWithConfiguration];
        if (interceptor) {
            interceptor(self, configuration);
        }
    }
}

- (void)interceptor_notifySuccessWithAction:(ZIKRouteAction)routeAction {
    [self interceptor_notifySuccessWithAction:routeAction];
    
    void(^_Nullable interceptor)(ZIKRouter *, ZIKRouteAction) = [[self class] interceptorAfterSuccessAction];
    if (interceptor) {
        interceptor(self, routeAction);
    }
}

- (void)interceptor_endPerformRouteWithError:(NSError *)error {
    [self interceptor_endPerformRouteWithError:error];
    void(^_Nullable interceptor)(ZIKRouter *, NSError *) = [[self class] interceptorAfterEndPerformWithError];
    if (interceptor) {
        interceptor(self, error);
    }
}

static void(^_Nullable _interceptorBeforePerformWithConfiguration)(ZIKRouter *, ZIKPerformRouteConfiguration *);

+ (void)interceptBeforePerformWithConfiguration:(void(^)(ZIKRouter *router, ZIKPerformRouteConfiguration *configuration))handler {
    [self enableDefaultInterceptor];
    _interceptorBeforePerformWithConfiguration = handler;
}

+ (void(^_Nullable)(ZIKRouter *, ZIKPerformRouteConfiguration *))interceptorBeforePerformWithConfiguration {
    return _interceptorBeforePerformWithConfiguration;
}

static void(^_Nullable _interceptorAfterPerformWithConfiguration)(ZIKRouter *, ZIKPerformRouteConfiguration *);

+ (void)interceptAfterPerformWithConfiguration:(void(^)(ZIKRouter *router, ZIKPerformRouteConfiguration *configuration))handler {
    [self enableDefaultInterceptor];
    _interceptorAfterPerformWithConfiguration = handler;
}

+ (void(^_Nullable)(ZIKRouter *, ZIKPerformRouteConfiguration *))interceptorAfterPerformWithConfiguration {
    [self enableDefaultInterceptor];
    return _interceptorAfterPerformWithConfiguration;
}

static void(^_Nullable _interceptorAfterSuccessAction)(ZIKRouter *, ZIKRouteAction);

+ (void)interceptAfterSuccessAction:(void(^)(ZIKRouter *router, ZIKRouteAction action))handler {
    [self enableDefaultInterceptor];
    _interceptorAfterSuccessAction = handler;
}

+ (void(^_Nullable)(ZIKRouter *, ZIKRouteAction))interceptorAfterSuccessAction {
    return _interceptorAfterSuccessAction;
}

static void(^_Nullable _interceptorAfterEndPerformWithError)(ZIKRouter *, NSError *);

+ (void)interceptAfterEndPerformWithError:(void(^)(ZIKRouter *router, NSError *error))handler; {
    [self enableDefaultInterceptor];
    _interceptorAfterEndPerformWithError = handler;
}

+ (void(^_Nullable)(ZIKRouter *, NSError *))interceptorAfterEndPerformWithError {
    return _interceptorAfterEndPerformWithError;
}

@end

#import "ZIKServiceRouterInternal.h"

@implementation ZIKServiceRouter (URLRouter)

+ (ZIKServiceRouterType *)routerForURL:(NSURL *)url {
    NSString *identifier = [self routerIdentifierFromURL:url];
    return _ZIKServiceRouterToIdentifier(identifier);
}

+ (ZIKServiceRouter *)performURL:(NSURL *)url {
    ZIKServiceRouterType *routerType = [self routerForURL:url];
    if (!routerType) {
        return nil;
    }
    NSDictionary *userInfo;
    if ([routerType respondsToSelector:@selector(userInfoFromURL:)]) {
        userInfo = [(id)routerType userInfoFromURL:url];
    }
    
    return [routerType performWithConfiguring:^(ZIKPerformRouteConfiguration * _Nonnull config) {
        [config addUserInfo:userInfo];
    }];
}

@end
