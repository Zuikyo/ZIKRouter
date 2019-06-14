//
//  ZIKViewRouter+URLRouter.h
//  ZIKRouterDemo
//
//  Created by zuik on 2019/4/18.
//  Copyright © 2019 zuik. All rights reserved.
//

#import "ZIKViewRouterType.h"
#import "ZIKRouter+URLRouter.h"
#import "ZIKViewRoute.h"

NS_ASSUME_NONNULL_BEGIN

/// Default is @"transition". You can change this key like: ZIKURLRouteKeyTransitionType = @"displaytype"
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
 
 1. Open view with specific transition type. The url `app://loginView/?transition=present` can present the  login view.
 
 You can implement your URL router if needed.
 */
@interface ZIKViewRouter<__covariant Destination, __covariant RouteConfig: ZIKViewRouteConfiguration *> (URLRouter)

/**
 Register URL pattern, then you can get the router with `+[ZIKAnyViewRouter routerForURL:]` or perform the url with `+[ZIKAnyViewRouter performURL:]`.
 
 Supported patterns:
 
 app://view/path
 app://view/path?k=v&k2&v2
 app://view/path/:id
 app://view/path/:id/:number
 app://view/path/:id/:number?k=v&k2&v2
 app://view/path/:id/path/:number
 */
+ (void)registerURLPattern:(NSString *)pattern;

/// Perform route for the url. It will search router and get parameters with `+routeFromURL:`, then perform route with the path.
+ (nullable ZIKViewRouter<Destination, RouteConfig> *)performURL:(NSString *)url path:(ZIKViewRoutePath *)path;

/// Perform route for the url with completion for current performing. It will search router and get parameters with `+routeFromURL:`, then perform route with the path.
+ (nullable ZIKViewRouter<Destination, RouteConfig> *)performURL:(NSString *)url path:(ZIKViewRoutePath *)path completion:(void(^)(BOOL success, Destination _Nullable destination, ZIKRouteAction routeAction, NSError *_Nullable error))performerCompletion;

/// Get router for identifier from URL.
+ (nullable ZIKViewRouterType<Destination, RouteConfig> *)routerForURL:(NSString *)url;

/// Perform route for the url. It will search router and get userInfo with `+routeFromURL:`, then perform route with path from `+pathForTransitionType:source:`.
#if ZIK_HAS_UIKIT
+ (nullable ZIKViewRouter<Destination, RouteConfig> *)performURL:(NSString *)url fromSource:(UIViewController *)source;
#else
+ (nullable ZIKViewRouter<Destination, RouteConfig> *)performURL:(NSString *)url fromSource:(NSViewController *)source;
#endif

/// Perform route for the url with completion for current performing. It will search router and get parameters with `+routeFromURL:`, then perform route with path from `+pathForTransitionType:source:`.
#if ZIK_HAS_UIKIT
+ (nullable ZIKViewRouter<Destination, RouteConfig> *)performURL:(NSString *)url fromSource:(UIViewController *)source completion:(void(^)(BOOL success, Destination _Nullable destination, ZIKRouteAction routeAction, NSError *_Nullable error))performerCompletion;
#else
+ (nullable ZIKViewRouter<Destination, RouteConfig> *)performURL:(NSString *)url fromSource:(NSViewController *)source completion:(void(^)(BOOL success, Destination _Nullable destination, ZIKRouteAction routeAction, NSError *_Nullable error))performerCompletion;
#endif

/// Generate view route path from URL.
#if ZIK_HAS_UIKIT
+ (ZIKViewRoutePath *)pathForTransitionType:(NSString *)type source:(UIViewController *)source;
#else
+ (ZIKViewRoutePath *)pathForTransitionType:(NSString *)type source:(NSViewController *)source;
#endif
@end

@interface ZIKViewRoute<__covariant Destination, __covariant RouteConfig: ZIKViewRouteConfiguration *> (URLRouter)

/**
 Register URL pattern, then you can get the router with `+[ZIKAnyViewRouter routerForURL:]` or perform the url with `+[ZIKAnyViewRouter performURL:]`.
 
 Supported pattern samples:
 
 app://view/path
 app://view/path?k=v&k2&v2
 app://view/path/:id
 app://view/path/:id/:number
 app://view/path/:id/:number?k=v&k2&v2
 app://view/path/:id/path/:number
 
 @code
 [ZIKAnyViewRoute
    makeRouteWithDestination:[LoginViewController class]
    makeDestination:^id<LoginViewInput> _Nullable(ZIKViewRouteConfig *config, __kindof ZIKRouter *router) {
        LoginViewController *destination = [[LoginViewController alloc] init];
        return destination;
 }]
 .prepareDestination(^(id<LoginViewInput> destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
    // Prepare the destination
 })
 .registerURLPattern(@"app://view/login/:uid")
 .processUserInfoFromURL(^(NSDictionary *userInfo, NSURL *url, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
 
 })
 .performActionFromURL(^(NSString *action, NSDictionary *userInfo, NSURL *url, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
 
 });
 @endcode
 */
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^registerURLPattern)(NSString *pattern);

/// Process the user info from url. This method is called before `performWithConfiguration:`. You can config the configuration with the user info.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^processUserInfoFromURL)(void(^)(NSDictionary *userInfo, NSURL *url, RouteConfig config, ZIKViewRouter *router));

/// Perform `action` from the url (app://loginView/?action=showAlert) after performing ended. You can store a completion handler in userInfo and give some data back to the caller.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^performActionFromURL)(void(^)(NSString *action, NSDictionary *userInfo, NSURL *url, RouteConfig config, ZIKViewRouter *router));

/// Do actions before `-performWithConfiguration:` for URL route rule.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^beforePerformWithConfigurationFromURL)(void(^)(RouteConfig config, ZIKViewRouter *router));

/// Do actions after `-notifySuccessWithAction:` for URL route rule. The routeAction is ZIKRouteActionPerformRoute or ZIKRouteActionRemoveRoute.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^afterSuccessActionFromURL)(void(^)(ZIKRouteAction routeAction, RouteConfig config, ZIKViewRouter *router));
@end

NS_ASSUME_NONNULL_END
