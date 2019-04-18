//
//  ZIKViewURLRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2019/4/18.
//  Copyright © 2019 zuik. All rights reserved.
//

#import "ZIKViewURLRouter.h"
#import <ZIKRouter/ZIKRouterInternal.h>
#import <ZIKRouter/ZIKViewRouter+Discover.h>

@implementation ZIKViewURLRouter

+ (BOOL)isAbstractRouter {
    return YES;
}

+ (ZIKViewRouterType *)routerForURL:(NSURL *)url {
    NSString *identifier = url.host;
    return _ZIKViewRouterToIdentifier(identifier);
}

+ (NSDictionary *)userInfoFromURL:(NSURL *)url {
    if (!url) {
        return @{};
    }
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[@"origin-url"] = url;
    
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

+ (ZIKViewRoutePath *)pathFromURL:(NSURL *)url source:(UIViewController *)source {
    NSDictionary *userInfo = [self userInfoFromURL:url];
    return [self pathForTransitionType:userInfo[@"transition-type"] source:source];
}

+ (ZIKViewRoutePath *)pathForTransitionType:(NSString *)type source:(UIViewController *)source {
    if (!type) {
        if (@available(iOS 8.0, *)) {
            return ZIKViewRoutePath.showFrom(source);
        } else {
            return ZIKViewRoutePath.presentModallyFrom(source);
        }
    }
    ZIKViewRoutePath *path;
    if ([type isEqualToString:@"present"]) {
        path = ZIKViewRoutePath.presentModallyFrom(source);
    } else if ([type isEqualToString:@"push"]) {
        path = ZIKViewRoutePath.pushFrom(source);
    } else if ([type isEqualToString:@"show"]) {
        path = ZIKViewRoutePath.showFrom(source);
    } else if ([type isEqualToString:@"showDetail"]) {
        path = ZIKViewRoutePath.showDetailFrom(source);
    } else if ([type isEqualToString:@"addAsSubview"]) {
        path = ZIKViewRoutePath.addAsSubviewFrom(source.view);
    } else {
        if (@available(iOS 8.0, *)) {
            path = ZIKViewRoutePath.showFrom(source);
        } else {
            path = ZIKViewRoutePath.presentModallyFrom(source);
        }
    }
    return path;
}

+ (ZIKViewRouter *)performURL:(NSURL *)url fromSource:(UIViewController *)source {
    ZIKViewRouterType *routerType = [self routerForURL:url];
    if (!routerType) {
        return nil;
    }
    NSDictionary *userInfo;
    if ([routerType respondsToSelector:@selector(userInfoFromURL:)]) {
        userInfo = [(id)routerType userInfoFromURL:url];
    }
    ZIKViewRoutePath *path;
    if ([routerType respondsToSelector:@selector(pathFromURL:source:)]) {
        path = [(id)routerType pathFromURL:url source:source];
    } else {
        path = [self pathFromURL:url source:source];
    }
    return [routerType performPath:path configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
        [config addUserInfo:userInfo];
    }];
}

+ (ZIKViewRouter *)performURL:(NSURL *)url path:(ZIKViewRoutePath *)path {
    ZIKViewRouterType *routerType = [self routerForURL:url];
    if (!routerType) {
        return nil;
    }
    NSDictionary *userInfo;
    if ([routerType respondsToSelector:@selector(userInfoFromURL:)]) {
        userInfo = [(id)routerType userInfoFromURL:url];
    }
    
    return [routerType performPath:path configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
        [config addUserInfo:userInfo];
    }];
}

# pragma mark Subclass Override

- (void)performRouteOnDestination:(id)destination configuration:(ZIKViewRouteConfiguration *)configuration {
    [self processUserInfo:configuration.userInfo fromURL:configuration.userInfo[@"origin-url"]];
    [super performRouteOnDestination:destination configuration:configuration];
}

- (void)endPerformRouteWithSuccess {
    [super endPerformRouteWithSuccess];
    NSDictionary *userInfo = self.configuration.userInfo;
    NSString *action = userInfo[@"action"];
    if (action) {
        [self performAction:action userInfo:userInfo fromURL:userInfo[@"origin-url"]];
    }
}

- (void)processUserInfo:(NSDictionary *)userInfo fromURL:(NSURL *)url {
    
}

- (void)performAction:(NSString *)action userInfo:(NSDictionary *)userInfo fromURL:(NSURL *)url {
    
}

@end
