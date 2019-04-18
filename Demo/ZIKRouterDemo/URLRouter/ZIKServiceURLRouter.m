//
//  ZIKServiceURLRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2019/4/18.
//  Copyright © 2019 zuik. All rights reserved.
//

#import "ZIKServiceURLRouter.h"
#import <ZIKRouter/ZIKRouterInternal.h>
#import <ZIKRouter/ZIKServiceRouter+Discover.h>

@implementation ZIKServiceURLRouter

+ (BOOL)isAbstractRouter {
    return YES;
}

+ (ZIKServiceRouterType *)routerForURL:(NSURL *)url {
    NSString *identifier = url.host;
    return _ZIKServiceRouterToIdentifier(identifier);
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

# pragma mark Subclass Override

- (void)performRouteOnDestination:(id)destination configuration:(ZIKPerformRouteConfiguration *)configuration {
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
