//
//  ZIKViewURLRouter.h
//  ZIKRouterDemo
//
//  Created by zuik on 2019/4/18.
//  Copyright © 2019 zuik. All rights reserved.
//

#import <ZIKRouter/ZIKViewRouterType.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A URL router to search and handle view routing from url.
 
 It's easy to add other custom features with a custom URL router parent class, such as:
 
 1. Call any methods of destination via url. the URL router can get parameters and call methods with OC runtime: router://loginView/?action=callMethod&method=fillAccount&account=abc
 
 2. Automatically give data back to h5 after performing action. If you are using JavaScriptBridge, the you can pass the `responseCallback` to router's userInfo and call it after performing action.
 
 3. Get multi identifiers from `path` in url , and present multi views in order with `successHandler` in router's configuration.
 
 You can implement these features by yourself if needed.
 */
@interface ZIKViewURLRouter<__covariant Destination, __covariant RouteConfig: ZIKViewRouteConfiguration *> : ZIKViewRouter<Destination, RouteConfig>

/// Perform route for the url. It will search router with `+routerForURL:`, get userInfo with `+userInfoFromURL:` then perform route with path from `+pathFromURL:source:`.
+ (nullable ZIKViewRouter<Destination, RouteConfig> *)performURL:(NSURL *)url fromSource:(UIViewController *)source;

/// Perform route for the url. It will search router with `+routerForURL:`, get userInfo with `+userInfoFromURL:` then perform route with the path.
+ (nullable ZIKViewRouter<Destination, RouteConfig> *)performURL:(NSURL *)url path:(ZIKViewRoutePath *)path;

/// Get router for identifier from URL.
+ (nullable ZIKViewRouterType<Destination, RouteConfig> *)routerForURL:(NSURL *)url;

// Get user info from URL. Subclass can override and process the url.
+ (NSDictionary *)userInfoFromURL:(NSURL *)url;

+ (ZIKViewRoutePath *)pathFromURL:(NSURL *)url source:(UIViewController *)viewController;

# pragma mark Subclass Override

// Process the user info from url. This method is called before destination is created. You can config the configuration with the user info.
- (void)processUserInfo:(NSDictionary *)userInfo fromURL:(NSURL *)url;

// Perform action after the view is displayed when the url has `action` param.
- (void)performAction:(NSString *)action userInfo:(NSDictionary *)userInfo fromURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
