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
        [router beforePerformWithConfigurationFromURL:configuration];
    }];
    [ZIKRouter interceptAfterSuccessAction:^(ZIKRouter * _Nonnull router, ZIKRouteAction  _Nonnull routeAction) {
        [router afterSuccessActionFromURL:routeAction];
    }];
}

- (void)beforePerformWithConfigurationFromURL:(ZIKPerformRouteConfiguration *)configuration {
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

- (void)afterSuccessActionFromURL:(ZIKRouteAction)routeAction {
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

+ (ZIKURLRouteResult *)routeFromURL:(NSString *)url {
    return nil;
}

@end

#import "ZIKServiceRouterInternal.h"
#import "ZIKURLRouter.h"

static ZIKURLRouter *_serviceURLRouter;

static void _createURLRouter() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_serviceURLRouter) {
            _serviceURLRouter = [ZIKURLRouter new];
        }
    });
}

@implementation ZIKServiceRouter (URLRouter)

+ (void)registerURLPattern:(NSString *)pattern {
    _createURLRouter();
    [_serviceURLRouter registerURLPattern:pattern];
    [self registerIdentifier:pattern];
}

+ (ZIKURLRouteResult *)routeFromURL:(NSString *)url {
    ZIKURLRouteResult *result = [_serviceURLRouter resultForURL:url];
    if (!result) {
        return nil;
    }
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[ZIKURLRouteKeyOriginURL] = [NSURL URLWithString:url];
    if (result.parameters) {
        [userInfo addEntriesFromDictionary:result.parameters];
    }
    result.parameters = userInfo;
    return result;
}

+ (ZIKServiceRouterType *)routerForURL:(NSString *)url {
    NSString *identifier = [self routeFromURL:url].identifier;
    if (!identifier) {
        return nil;
    }
    return _ZIKServiceRouterToIdentifier(identifier);
}

+ (ZIKServiceRouter *)performURL:(NSString *)url {
    return [self performURL:url completion:^(BOOL success, id  _Nullable destination, ZIKRouteAction routeAction, NSError * _Nullable error) {
        
    }];
}

+ (ZIKServiceRouter *)performURL:(NSString *)url completion:(void(^)(BOOL success, id _Nullable destination, ZIKRouteAction routeAction, NSError *_Nullable error))performerCompletion {
    ZIKURLRouteResult *result = [self routeFromURL:url];
    NSString *identifier = result.identifier;
    if (!identifier) {
        if (performerCompletion) {
            NSError *error = [ZIKServiceRouter errorWithCode:ZIKRouteErrorInvalidConfiguration localizedDescriptionFormat:@"Can't find router from url: %@", url];
            performerCompletion(NO, nil, ZIKRouteActionToService, error);
        }
        return nil;
    }
    ZIKServiceRouterType *routerType = _ZIKServiceRouterToIdentifier(identifier);
    if (!routerType) {
        if (performerCompletion) {
            NSError *error = [ZIKServiceRouter errorWithCode:ZIKRouteErrorInvalidConfiguration localizedDescriptionFormat:@"Can't find router with identifier (%@) from url: %@", identifier, url];
            performerCompletion(NO, nil, ZIKRouteActionToService, error);
            [ZIKServiceRouter notifyGlobalErrorWithRouter:nil action:ZIKRouteActionToService error:error];
        }
        return nil;
    }
    NSDictionary *userInfo = result.parameters;
    return [routerType performWithConfiguring:^(ZIKPerformRouteConfiguration * _Nonnull config) {
        [config addUserInfo:userInfo];
        if (!performerCompletion) {
            return;
        }
        config.performerSuccessHandler = ^(id  _Nonnull destination) {
            performerCompletion(YES, destination, ZIKRouteActionPerformRoute, nil);
        };
        config.performerErrorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
            performerCompletion(NO, nil, routeAction, error);
        };
    }];
}

@end

#import "ZIKServiceRouteRegistry.h"
#import "ZIKRouteRegistryInternal.h"
#import <objc/runtime.h>

@implementation ZIKServiceRoute (URLRouter)

- (ZIKServiceRoute<id, ZIKPerformRouteConfiguration *> *(^)(NSString *))registerURLPattern {
    _createURLRouter();
    return ^(NSString *pattern) {
        [_serviceURLRouter registerURLPattern:pattern];
        [ZIKServiceRouteRegistry registerIdentifier:pattern route:self];
        return self;
    };
};

- (ZIKServiceRoute<id, ZIKPerformRouteConfiguration *> *(^)(void(^)(NSDictionary *, NSURL *, ZIKPerformRouteConfiguration *, ZIKServiceRouter *)))processUserInfoFromURL {
    return ^(void(^block)(NSDictionary *userInfo, NSURL *url, ZIKPerformRouteConfiguration *config, ZIKServiceRouter *router)) {
        objc_setAssociatedObject(self, @selector(processUserInfoFromURL), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
        return self;
    };
}

- (ZIKServiceRoute<id, ZIKPerformRouteConfiguration *> *(^)(void(^)(NSString *, NSDictionary *, NSURL *, ZIKPerformRouteConfiguration *, ZIKServiceRouter *)))performActionFromURL {
    return ^(void(^block)(NSString *action, NSDictionary *userInfo, NSURL *url, ZIKPerformRouteConfiguration *config, ZIKServiceRouter *router)) {
        objc_setAssociatedObject(self, @selector(performActionFromURL), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
        return self;
    };
}

- (ZIKServiceRoute<id, ZIKPerformRouteConfiguration *> *(^)(void(^)(ZIKPerformRouteConfiguration *, ZIKServiceRouter *)))beforePerformWithConfigurationFromURL {
    return ^(void(^block)(ZIKPerformRouteConfiguration *config, ZIKServiceRouter *router)) {
        objc_setAssociatedObject(self, @selector(beforePerformWithConfigurationFromURL), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
        return self;
    };
}

- (ZIKServiceRoute<id, ZIKPerformRouteConfiguration *> *(^)(void(^)(ZIKRouteAction, ZIKPerformRouteConfiguration *, ZIKServiceRouter *)))afterSuccessActionFromURL {
    return ^(void(^block)(ZIKRouteAction routeAction, ZIKPerformRouteConfiguration *config, ZIKServiceRouter *router)) {
        objc_setAssociatedObject(self, @selector(afterSuccessActionFromURL), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
        return self;
    };
}

@end

#import "ZIKBlockServiceRouter.h"

@interface ZIKBlockServiceRouter (URLRouter)
@end

@implementation ZIKBlockServiceRouter (URLRouter)

- (void)processUserInfo:(NSDictionary *)userInfo fromURL:(NSURL *)url {
    void(^block)(NSDictionary *userInfo, NSURL *url, ZIKPerformRouteConfiguration *config, ZIKServiceRouter *router);
    block = objc_getAssociatedObject(self.route, @selector(processUserInfoFromURL));
    if (block) {
        block(userInfo, url, self.configuration, self);
    }
}

- (void)performAction:(NSString *)action userInfo:(NSDictionary *)userInfo fromURL:(NSURL *)url {
    void(^block)(NSString *action, NSDictionary *userInfo, NSURL *url, ZIKPerformRouteConfiguration *config, ZIKServiceRouter *router);
    block = objc_getAssociatedObject(self.route, @selector(performActionFromURL));
    if (block) {
        block(action, userInfo, url, self.configuration, self);
    }
}

- (void)beforePerformWithConfigurationFromURL:(ZIKPerformRouteConfiguration *)configuration {
    void(^block)(ZIKPerformRouteConfiguration *config, ZIKServiceRouter *router);
    block = objc_getAssociatedObject(self.route, @selector(beforePerformWithConfigurationFromURL));
    if (block) {
        block(configuration, self);
    }
    [super beforePerformWithConfigurationFromURL:configuration];
}

- (void)afterSuccessActionFromURL:(ZIKRouteAction)routeAction {
    [super afterSuccessActionFromURL:routeAction];
    void(^block)(ZIKRouteAction routeAction, ZIKPerformRouteConfiguration *config, ZIKServiceRouter *router);
    block = objc_getAssociatedObject(self.route, @selector(afterSuccessActionFromURL));
    if (block) {
        block(routeAction, self.configuration, self);
    }
}

@end

@implementation ZIKRouter (Interceptor)

+ (void)enableDefaultInterceptor {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        zix_replaceMethodWithMethod([ZIKRouter class], @selector(performWithConfiguration:), [ZIKRouter class], @selector(interceptor_performWithConfiguration:));
        zix_replaceMethodWithMethod([ZIKRouter class], @selector(notifySuccessWithAction:), [ZIKRouter class], @selector(interceptor_notifySuccessWithAction:));
        zix_replaceMethodWithMethod([ZIKRouter class], @selector(endPerformRouteWithError:), [ZIKRouter class], @selector(interceptor_endPerformRouteWithError:));
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
