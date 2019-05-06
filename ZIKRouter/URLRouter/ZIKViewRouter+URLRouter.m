//
//  ZIKViewRouter+URLRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2019/4/18.
//  Copyright © 2019 zuik. All rights reserved.
//

#import "ZIKViewRouter+URLRouter.h"
#import "ZIKViewRouterInternal.h"
#import "ZIKURLRouter.h"
#import "ZIKClassCapabilities.h"

ZIKURLRouteKey ZIKURLRouteKeyTransitionType = @"transition";
static ZIKURLRouter *_viewURLRouter;

static void _createURLRouter() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_viewURLRouter) {
            _viewURLRouter = [ZIKURLRouter new];
        }
    });
}

@implementation ZIKViewRouter (URLRouter)

+ (void)registerURLPattern:(NSString *)pattern {
    _createURLRouter();
    [_viewURLRouter registerURLPattern:pattern];
    [self registerIdentifier:pattern];
}

+ (ZIKURLRouteResult *)routeFromURL:(NSString *)url {
    ZIKURLRouteResult *result = [_viewURLRouter resultForURL:url];
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

+ (ZIKViewRouterType *)routerForURL:(NSString *)url {
    NSString *identifier = [self routeFromURL:url].identifier;
    if (!identifier) {
        return nil;
    }
    return _ZIKViewRouterToIdentifier(identifier);
}

+ (ZIKViewRoutePath *)pathForTransitionType:(NSString *)type source:(XXViewController *)source {
    if (!type) {
        type = @"show";
    }
    ZIKViewRoutePath *path;
    if ([type isEqualToString:@"present"]) {
        path = ZIKViewRoutePath.presentModallyFrom(source);
    } else if ([type isEqualToString:@"push"]) {
#if ZIK_HAS_UIKIT
        path = ZIKViewRoutePath.pushFrom(source);
#else
        path = ZIKViewRoutePath.show;
#endif
    } else if ([type isEqualToString:@"show"]) {
#if ZIK_HAS_UIKIT
        path = ZIKViewRoutePath.showFrom(source);
#else
        path = ZIKViewRoutePath.show;
#endif
    } else if ([type isEqualToString:@"showDetail"]) {
#if ZIK_HAS_UIKIT
        path = ZIKViewRoutePath.showDetailFrom(source);
#else
        path = ZIKViewRoutePath.show;
#endif
    } else if ([type isEqualToString:@"addAsSubview"]) {
        path = ZIKViewRoutePath.addAsSubviewFrom(source.view);
    } else {
#if ZIK_HAS_UIKIT
        path = ZIKViewRoutePath.showFrom(source);
#else
        path = ZIKViewRoutePath.show;
#endif
    }
    return path;
}

+ (ZIKViewRouter *)performURL:(NSString *)url fromSource:(XXViewController *)source {
    return [self performURL:url fromSource:source completion:^(BOOL success, id  _Nullable destination, ZIKRouteAction routeAction, NSError * _Nullable error) {
        
    }];
}

+ (ZIKViewRouter *)performURL:(NSString *)url fromSource:(XXViewController *)source completion:(void(^)(BOOL success, id _Nullable destination, ZIKRouteAction routeAction, NSError *_Nullable error))performerCompletion {
    ZIKURLRouteResult *result = [self routeFromURL:url];
    NSString *identifier = result.identifier;
    if (!identifier) {
        if (performerCompletion) {
            NSError *error = [ZIKViewRouter errorWithCode:ZIKRouteErrorInvalidConfiguration localizedDescriptionFormat:@"Can't find router from url: %@", url];
            performerCompletion(NO, nil, ZIKRouteActionToService, error);
        }
        return nil;
    }
    ZIKViewRouterType *routerType = _ZIKViewRouterToIdentifier(identifier);
    if (!routerType) {
        if (performerCompletion) {
            NSError *error = [ZIKViewRouter errorWithCode:ZIKRouteErrorInvalidConfiguration localizedDescriptionFormat:@"Can't find router with identifier (%@) from url: %@", identifier, url];
            performerCompletion(NO, nil, ZIKRouteActionToService, error);
            [ZIKViewRouter notifyGlobalErrorWithRouter:nil action:ZIKRouteActionToView error:error];
        }
        return nil;
    }
    NSDictionary *userInfo = result.parameters;
    ZIKViewRoutePath *path;
    if ([routerType respondsToSelector:@selector(pathForTransitionType:source:)]) {
        path = [(id)routerType pathForTransitionType:userInfo[ZIKURLRouteKeyTransitionType] source:source];
    } else {
        path = [self pathForTransitionType:userInfo[ZIKURLRouteKeyTransitionType] source:source];
    }
    return [routerType performPath:path configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
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

+ (ZIKViewRouter *)performURL:(NSString *)url path:(ZIKViewRoutePath *)path {
    return [self performURL:url path:path completion:^(BOOL success, id  _Nullable destination, ZIKRouteAction routeAction, NSError * _Nullable error) {
        
    }];
}

+ (ZIKViewRouter *)performURL:(NSString *)url path:(ZIKViewRoutePath *)path completion:(void(^)(BOOL success, id _Nullable destination, ZIKRouteAction routeAction, NSError *_Nullable error))performerCompletion {
    ZIKURLRouteResult *result = [self routeFromURL:url];
    NSString *identifier = result.identifier;
    if (!identifier) {
        if (performerCompletion) {
            NSError *error = [ZIKViewRouter errorWithCode:ZIKRouteErrorInvalidConfiguration localizedDescriptionFormat:@"Can't find router from url: %@", url];
            performerCompletion(NO, nil, ZIKRouteActionToService, error);
        }
        return nil;
    }
    ZIKViewRouterType *routerType = _ZIKViewRouterToIdentifier(identifier);
    if (!routerType) {
        if (performerCompletion) {
            NSError *error = [ZIKViewRouter errorWithCode:ZIKRouteErrorInvalidConfiguration localizedDescriptionFormat:@"Can't find router with identifier (%@) from url: %@", identifier, url];
            performerCompletion(NO, nil, ZIKRouteActionToService, error);
            [ZIKViewRouter notifyGlobalErrorWithRouter:nil action:ZIKRouteActionToView error:error];
        }
        return nil;
    }
    NSDictionary *userInfo = result.parameters;
    return [routerType performPath:path configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
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

- (void)afterSuccessActionFromURL:(ZIKRouteAction)routeAction {
    // URL routing is only from router internal
    if (!self.routingFromInternal) {
        return;
    }
    [super afterSuccessActionFromURL:routeAction];
}

@end

#import "ZIKViewRouteRegistry.h"
#import "ZIKRouteRegistryInternal.h"
#import <objc/runtime.h>

@implementation ZIKViewRoute (URLRouter)

- (ZIKViewRoute<id, ZIKViewRouteConfiguration *> *(^)(NSString *))registerURLPattern {
    _createURLRouter();
    return ^(NSString *pattern) {
        [_viewURLRouter registerURLPattern:pattern];
        [ZIKViewRouteRegistry registerIdentifier:pattern route:self];
        return self;
    };
};

- (ZIKViewRoute<id, ZIKViewRouteConfiguration *> *(^)(void(^)(NSDictionary *, NSURL *, ZIKViewRouteConfiguration *, ZIKViewRouter *)))processUserInfoFromURL {
    return ^(void(^block)(NSDictionary *userInfo, NSURL *url, ZIKViewRouteConfiguration *config, ZIKViewRouter *router)) {
        objc_setAssociatedObject(self, @selector(processUserInfoFromURL), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
        return self;
    };
}

- (ZIKViewRoute<id, ZIKViewRouteConfiguration *> *(^)(void(^)(NSString *, NSDictionary *, NSURL *, ZIKViewRouteConfiguration *, ZIKViewRouter *)))performActionFromURL {
    return ^(void(^block)(NSString *action, NSDictionary *userInfo, NSURL *url, ZIKViewRouteConfiguration *config, ZIKViewRouter *router)) {
        objc_setAssociatedObject(self, @selector(performActionFromURL), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
        return self;
    };
}

- (ZIKViewRoute<id, ZIKViewRouteConfiguration *> *(^)(void(^)(ZIKViewRouteConfiguration *, ZIKViewRouter *)))beforePerformWithConfigurationFromURL {
    return ^(void(^block)(ZIKViewRouteConfiguration *config, ZIKViewRouter *router)) {
        objc_setAssociatedObject(self, @selector(beforePerformWithConfigurationFromURL), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
        return self;
    };
}

- (ZIKViewRoute<id, ZIKViewRouteConfiguration *> *(^)(void(^)(ZIKRouteAction, ZIKViewRouteConfiguration *, ZIKViewRouter *)))afterSuccessActionFromURL {
    return ^(void(^block)(ZIKRouteAction routeAction, ZIKViewRouteConfiguration *config, ZIKViewRouter *router)) {
        objc_setAssociatedObject(self, @selector(afterSuccessActionFromURL), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
        return self;
    };
}

@end

#import "ZIKBlockViewRouter.h"

@interface ZIKBlockViewRouter (URLRouter)
@end

@implementation ZIKBlockViewRouter (URLRouter)

- (void)processUserInfo:(NSDictionary *)userInfo fromURL:(NSURL *)url {
    void(^block)(NSDictionary *userInfo, NSURL *url, ZIKViewRouteConfiguration *config, ZIKViewRouter *router);
    block = objc_getAssociatedObject(self.route, @selector(processUserInfoFromURL));
    if (block) {
        block(userInfo, url, self.configuration, self);
    }
}

- (void)performAction:(NSString *)action userInfo:(NSDictionary *)userInfo fromURL:(NSURL *)url {
    void(^block)(NSString *action, NSDictionary *userInfo, NSURL *url, ZIKViewRouteConfiguration *config, ZIKViewRouter *router);
    block = objc_getAssociatedObject(self.route, @selector(performActionFromURL));
    if (block) {
        block(action, userInfo, url, self.configuration, self);
    }
}

- (void)beforePerformWithConfigurationFromURL:(ZIKViewRouteConfiguration *)configuration {
    void(^block)(ZIKViewRouteConfiguration *config, ZIKViewRouter *router);
    block = objc_getAssociatedObject(self.route, @selector(beforePerformWithConfigurationFromURL));
    if (block) {
        block(configuration, self);
    }
    [super beforePerformWithConfigurationFromURL:configuration];
}

- (void)afterSuccessActionFromURL:(ZIKRouteAction)routeAction {
    [super afterSuccessActionFromURL:routeAction];
    void(^block)(ZIKRouteAction routeAction, ZIKViewRouteConfiguration *config, ZIKViewRouter *router);
    block = objc_getAssociatedObject(self.route, @selector(afterSuccessActionFromURL));
    if (block) {
        block(routeAction, self.configuration, self);
    }
}

@end
