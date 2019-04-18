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
    return ZIKViewRouter.toIdentifier(identifier);
}

+ (nullable instancetype)performPath:(ZIKViewRoutePath *)path url:(NSURL *)url {
    ZIKViewRouterType *routerType = [self routerForURL:url];
    NSDictionary *userInfo;
    if ([routerType respondsToSelector:@selector(userInfoFromURL:)]) {
        userInfo = [(id)routerType userInfoFromURL:url];
    }
    
    return (id)[routerType performPath:path configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
        [config addUserInfo:userInfo];
    }];
}

# pragma mark Override

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
                userInfo[key] = value;
            }
        }
    }
    return userInfo;
}

- (void)performRouteOnDestination:(id)destination configuration:(ZIKViewRouteConfiguration *)configuration {
    [self processUserInfo:configuration.userInfo url:configuration.userInfo[@"origin-url"]];
    [super performRouteOnDestination:destination configuration:configuration];
}

- (void)endPerformRouteWithSuccess {
    [super endPerformRouteWithSuccess];
    NSString *action = self.configuration.userInfo[@"action"];
    if (action) {
        [self performAction:action url:self.configuration.userInfo[@"origin-url"]];
    }
}

- (void)processUserInfo:(NSDictionary *)userInfo url:(NSURL *)url {
    
}

- (void)performAction:(NSString *)action url:(NSURL *)url {
    
}

@end
