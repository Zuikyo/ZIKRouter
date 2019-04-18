//
//  ZIKViewURLRouter.h
//  ZIKRouterDemo
//
//  Created by zuik on 2019/4/18.
//  Copyright © 2019 zuik. All rights reserved.
//

#import <ZIKRouter/ZIKViewRouterType.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZIKViewURLRouter<__covariant Destination, __covariant RouteConfig: ZIKViewRouteConfiguration *> : ZIKViewRouter<Destination, RouteConfig>

+ (ZIKViewRouterType<Destination, RouteConfig> *)routerForURL:(NSURL *)url;

+ (nullable instancetype)performPath:(ZIKViewRoutePath *)path url:(NSURL *)url;

# pragma mark Override

// Get user info from url.
+ (NSDictionary *)userInfoFromURL:(NSURL *)url;

// Process the user info from url. You can config the configuration with the user info.
- (void)processUserInfo:(NSDictionary *)userInfo url:(NSURL *)url;

// Perform action when the url has `action` param. This is called after the view is displayed.
- (void)performAction:(NSString *)action url:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
