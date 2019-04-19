//
//  ZIKViewRouter+URLRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2019/4/18.
//  Copyright © 2019 zuik. All rights reserved.
//

#import "ZIKViewRouter+URLRouter.h"
#import "ZIKViewRouterInternal.h"

ZIKURLRouteKey ZIKURLRouteKeyTransitionType = @"transition-type";

@implementation ZIKViewRouter (URLRouter)

+ (ZIKViewRouterType *)routerForURL:(NSURL *)url {
    NSString *identifier = [self routerIdentifierFromURL:url];
    return _ZIKViewRouterToIdentifier(identifier);
}

+ (ZIKViewRoutePath *)pathFromURL:(NSURL *)url source:(UIViewController *)source {
    NSDictionary *userInfo = [self userInfoFromURL:url];
    return [self pathForTransitionType:userInfo[ZIKURLRouteKeyTransitionType] source:source];
}

+ (ZIKViewRoutePath *)pathForTransitionType:(NSString *)type source:(UIViewController *)source {
    if (!type) {
        return ZIKViewRoutePath.showFrom(source);
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
        return ZIKViewRoutePath.showFrom(source);
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

- (void)URLRouter_afterSuccessAction:(ZIKRouteAction)routeAction {
    // URL routing is only from router internal
    if (!self.routingFromInternal) {
        return;
    }
    [super URLRouter_afterSuccessAction:routeAction];
}

@end
