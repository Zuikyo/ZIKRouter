//
//  ZIKServiceURLRouter.h
//  ZIKRouterDemo
//
//  Created by zuik on 2019/4/18.
//  Copyright © 2019 zuik. All rights reserved.
//

#import <ZIKRouter/ZIKServiceRouterType.h>

NS_ASSUME_NONNULL_BEGIN

/// A URL router to search and handle view routing from url.
@interface ZIKServiceURLRouter<__covariant Destination, __covariant RouteConfig: ZIKPerformRouteConfiguration *> : ZIKServiceRouter<Destination, RouteConfig>

/// Perform route for the url. It will search router with `+routerForURL:`, get userInfo with `+userInfoFromURL:` then perform route.
+ (nullable ZIKServiceRouter<Destination, RouteConfig> *)performURL:(NSURL *)url;

/// Get router for identifier from URL.
+ (nullable ZIKServiceRouterType<Destination, RouteConfig> *)routerForURL:(NSURL *)url;

// Get user info from URL. Subclass can override and process the url.
+ (NSDictionary *)userInfoFromURL:(NSURL *)url;

# pragma mark Subclass Override

// Process the user info from url. This method is called before destination is created. You can config the configuration with the user info.
- (void)processUserInfo:(NSDictionary *)userInfo fromURL:(NSURL *)url;

// Perform action after the view is displayed when the url has `action` param.
- (void)performAction:(NSString *)action userInfo:(NSDictionary *)userInfo fromURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
