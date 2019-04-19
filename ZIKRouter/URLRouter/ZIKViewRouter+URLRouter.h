//
//  ZIKViewRouter+URLRouter.h
//  ZIKRouterDemo
//
//  Created by zuik on 2019/4/18.
//  Copyright © 2019 zuik. All rights reserved.
//

#import <ZIKRouter/ZIKViewRouterType.h>
#import "ZIKRouter+URLRouter.h"

NS_ASSUME_NONNULL_BEGIN

/// Default is @"transition-type". You can change this key like: ZIKURLRouteKeyTransitionType = @"transition"
FOUNDATION_EXTERN ZIKURLRouteKey ZIKURLRouteKeyTransitionType;
/// Default is @"present". app://loginView/?transition-type=present
FOUNDATION_EXTERN ZIKURLRouteKey ZIKURLRouteKeyTransitionTypePresent;
/// Default is @"push". app://loginView/?transition-type=push
FOUNDATION_EXTERN ZIKURLRouteKey ZIKURLRouteKeyTransitionTypePush;
/// Default is @"show". app://loginView/?transition-type=show
FOUNDATION_EXTERN ZIKURLRouteKey ZIKURLRouteKeyTransitionTypeShow;
/// Default is @"showDetail". app://loginView/?transition-type=showDetail
FOUNDATION_EXTERN ZIKURLRouteKey ZIKURLRouteKeyTransitionTypeShowDetail;
/// Default is @"addAsSubview". app://loginView/?transition-type=addAsSubview
FOUNDATION_EXTERN ZIKURLRouteKey ZIKURLRouteKeyTransitionTypeAddAsSubview;

/**
 A URL router to search and handle view routing from url.
 
 Feature of this view URL router:
 
 1. Open view with specific transition type. The url `app://loginView/?transition-type=present` can present the  login view.
 
 It's easy to add other custom features with a custom URL router parent class, such as:
 
 1. Call any methods of destination via url. the URL router can get parameters and call methods with OC runtime: router://loginView/?action=callMethod&method=fillAccount&account=abc
 
 2. Automatically give data back to html5 after performing action
 
 3. Get multi identifiers from `path` in url , and present multi views in order with `successHandler` in router's configuration.
 
 You can implement these features by yourself if needed.
 */
@interface ZIKViewRouter<__covariant Destination, __covariant RouteConfig: ZIKViewRouteConfiguration *> (URLRouter)

/// Perform route for the url. It will search router with `+routerForURL:`, get userInfo with `+userInfoFromURL:` then perform route with path from `+pathFromURL:source:`.
+ (nullable ZIKViewRouter<Destination, RouteConfig> *)performURL:(NSURL *)url fromSource:(UIViewController *)source;

/// Perform route for the url. It will search router with `+routerForURL:`, get userInfo with `+userInfoFromURL:` then perform route with the path.
+ (nullable ZIKViewRouter<Destination, RouteConfig> *)performURL:(NSURL *)url path:(ZIKViewRoutePath *)path;

/// Get router for identifier from URL.
+ (nullable ZIKViewRouterType<Destination, RouteConfig> *)routerForURL:(NSURL *)url;

/// Generate view route path from URL.
+ (ZIKViewRoutePath *)pathFromURL:(NSURL *)url source:(UIViewController *)source;

@end

NS_ASSUME_NONNULL_END
