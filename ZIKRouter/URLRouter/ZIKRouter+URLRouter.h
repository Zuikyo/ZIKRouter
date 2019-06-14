//
//  ZIKRouter+URLRouter.h
//  ZIKRouterDemo
//
//  Created by zuik on 2019/4/19.
//  Copyright © 2019 zuik. All rights reserved.
//

#import "ZIKServiceRouterType.h"
#import "ZIKServiceRoute.h"
#import "ZIKURLRouteResult.h"

NS_ASSUME_NONNULL_BEGIN

/// Key for data in router.configuration.userInfo
typedef NSString *ZIKURLRouteKey NS_EXTENSIBLE_STRING_ENUM;

/// Default is @"origin-url". You can change this key like: ZIKURLRouteKeyOriginURL = @"originURL"
FOUNDATION_EXTERN ZIKURLRouteKey ZIKURLRouteKeyOriginURL;
/// Default is @"action". You can change this key like: ZIKURLRouteKeyAction = @"action-name"
FOUNDATION_EXTERN ZIKURLRouteKey ZIKURLRouteKeyAction;

/**
 This provides basic URL router features. Call +enableDefaultURLRouteRule if you want to use this URL router.
 
 This uses the standard URL format: scheme://host/path/?query
 
 Features of this URL router:
 
 1. Save origin url to router.configuration.userInfo: userInfo = @{ZIKURLRouteKeyOriginURL: url}
 
 2. Use url as identifier to fetch destination router with `toIdentifier`. In url `scheme://host/path1/path2?k=v`, the identifier is `scheme://host/path1/path2`
 
 2. Get parameters from url to router.configuration.userInfo: app://loginView/?account=abc&pwd=123  => @{@"account": @"abc", @"pwd": @"123"}
 
 3. Process the userInfo before performing
 
 4. Perform action from the url after performing: app://loginView/?action=showAlert
 
 If you need more features, you can implement your custom URL rules by intercepting or hooking ZIKRouter's state control methods, or creating a parent URL router class overriding these methods for custom rules.
 */
@interface ZIKRouter (URLRouter)

/// Enable default URL router. You can implement your rules.
+ (void)enableDefaultURLRouteRule;

/// Get identifier and user info from url for fetching its router. Custom router parent class can override and process the url.
+ (ZIKURLRouteResult *)routeFromURL:(NSString *)url;

# pragma mark Subclass Override

/**
 Process the user info from url. This method is called before `performWithConfiguration:`. You can configure the configuration with the user info.
 
 If the router uses module config protocol (`makeDestinationWith` in configuration), you can get parameters from userInfo and call `configuration.makeDestinationWith`.
 */
- (void)processUserInfo:(NSDictionary *)userInfo fromURL:(NSURL *)url;

/// Perform `action` from the url (app://loginView/?action=showAlert) after performing ended. You can store a completion handler in userInfo and give some data back to the caller.
- (void)performAction:(NSString *)action userInfo:(NSDictionary *)userInfo fromURL:(NSURL *)url;

/// Do actions before `-performWithConfiguration:` for URL route rule.
- (void)beforePerformWithConfigurationFromURL:(ZIKPerformRouteConfiguration *)configuration NS_REQUIRES_SUPER;

/// Do actions after `-notifySuccessWithAction:` for URL route rule. The routeAction is ZIKRouteActionPerformRoute or ZIKRouteActionRemoveRoute.
- (void)afterSuccessActionFromURL:(ZIKRouteAction)routeAction NS_REQUIRES_SUPER;

@end

/**
 URL router to search and call service from url.
 
 It's easy to add other custom features with a custom URL router parent class.
 */
@interface ZIKServiceRouter<__covariant Destination, __covariant RouteConfig: ZIKPerformRouteConfiguration *> (URLRouter)

/**
 Register URL pattern, then you can get the router with `+[ZIKAnyServiceRouter routerForURL:]` or perform the url with `+[ZIKAnyServiceRouter performURL:]`.
 
 Supported patterns:
 
 app://service/path
 app://service/path?k=v&k2&v2
 app://service/path/:id
 app://service/path/:id/:number
 app://service/path/:id/:number?k=v&k2&v2
 app://service/path/:id/path/:number
 */
+ (void)registerURLPattern:(NSString *)pattern;

/// Perform route for the url. It will search router and get parameters with `+routeFromURL:`, then perform route.
+ (nullable ZIKServiceRouter<Destination, RouteConfig> *)performURL:(NSString *)url;

/// Perform route for the url with completion for current performing. It will search router and get parameters with `+routeFromURL:`, then perform route.
+ (nullable ZIKServiceRouter<Destination, RouteConfig> *)performURL:(NSString *)url completion:(void(^)(BOOL success, Destination _Nullable destination, ZIKRouteAction routeAction, NSError *_Nullable error))performerCompletion;

/// Get router for identifier from URL.
+ (nullable ZIKServiceRouterType<Destination, RouteConfig> *)routerForURL:(NSString *)url;

@end

@interface ZIKServiceRoute<__covariant Destination, __covariant RouteConfig: ZIKPerformRouteConfiguration *> (URLRouter)

/**
 Register URL pattern, then you can get the router with `+[ZIKAnyServiceRouter routerForURL:]` or perform the url with `+[ZIKAnyServiceRouter performURL:]`.
 
 Supported pattern samples:
 
 app://service/path
 app://service/path?k=v&k2&v2
 app://service/path/:id
 app://service/path/:id/:number
 app://service/path/:id/:number?k=v&k2&v2
 app://service/path/:id/path/:number
 
 @code
 [ZIKAnyServiceRoute
    makeRouteWithDestination:[LoginService class]
    makeDestination:^id<LoginServiceInput> _Nullable(ZIKPerformRouteConfig *config, __kindof ZIKRouter *router) {
        LoginService *destination = [[LoginService alloc] init];
        return destination;
 }]
 .prepareDestination(^(id<LoginServiceInput> destination, ZIKPerformRouteConfig *config, ZIKServiceRouter *router) {
    // Prepare the destination
 })
 .registerURLPattern(@"app://service/login/:uid")
 .processUserInfoFromURL(^(NSDictionary *userInfo, NSURL *url, ZIKPerformRouteConfig *config, ZIKServiceRouter *router) {
 
 })
 .performActionFromURL(^(NSString *action, NSDictionary *userInfo, NSURL *url, ZIKPerformRouteConfig *config, ZIKServiceRouter *router) {
 
 });
 @endcode
 */
@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^registerURLPattern)(NSString *pattern);

/// Process the user info from url. This method is called before `performWithConfiguration:`. You can config the configuration with the user info.
@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^processUserInfoFromURL)(void(^)(NSDictionary *userInfo, NSURL *url, RouteConfig config, ZIKServiceRouter *router));

/// Perform `action` from the url (app://loginView/?action=showAlert) after performing ended. You can store a completion handler in userInfo and give some data back to the caller.
@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^performActionFromURL)(void(^)(NSString *action, NSDictionary *userInfo, NSURL *url, RouteConfig config, ZIKServiceRouter *router));

/// Do actions before `-performWithConfiguration:` for URL route rule.
@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^beforePerformWithConfigurationFromURL)(void(^)(RouteConfig config, ZIKServiceRouter *router));

/// Do actions after `-notifySuccessWithAction:` for URL route rule. The routeAction is ZIKRouteActionPerformRoute or ZIKRouteActionRemoveRoute.
@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^afterSuccessActionFromURL)(void(^)(ZIKRouteAction routeAction, RouteConfig config, ZIKServiceRouter *router));
@end

#pragma mark Interceptor

@interface ZIKRouter (Interceptor)
/**
 Inject interceptor for all routers before performing. You can process the configuration when implementing your custom URL router. See +enableDefaultURLRouteRule and +beforePerformWithConfigurationFromURL.
 
 @param handler A block invoked before `performWithConfiguration:`
 */
+ (void)interceptBeforePerformWithConfiguration:(void(^)(ZIKRouter *router, ZIKPerformRouteConfiguration *configuration))handler;

/// Inject interceptor for all routers after performing. Use this if you need to add action after the destination is instantiated.
+ (void)interceptAfterPerformWithConfiguration:(void(^)(ZIKRouter *router, ZIKPerformRouteConfiguration *configuration))handler;

/**
 Inject interceptor for all routers after success performing or removing. You can do some addtion custom actions when implementing your custom URL router. See +enableDefaultURLRouteRule and +afterSuccessActionFromURL.
 
 @note
 Success action may be called asynchronously (view router is notified performing success action after the view did finish displaying).
 Use `interceptAfterPerformWithConfiguration` instead if you need to add action immediately after the destination is instantiated.
 
 @param handler A block invoked after success performing or removing. The action is ZIKRouteActionPerformRoute or ZIKRouteActionRemoveRoute.
 */
+ (void)interceptAfterSuccessAction:(void(^)(ZIKRouter *router, ZIKRouteAction action))handler;

/// Inject interceptor for all routers after performing failed.
+ (void)interceptAfterEndPerformWithError:(void(^)(ZIKRouter *router, NSError *error))handler;

@end

NS_ASSUME_NONNULL_END
