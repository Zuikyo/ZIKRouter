//
//  ZIKRouter+URLRouter.h
//  ZIKRouterDemo
//
//  Created by zuik on 2019/4/19.
//  Copyright © 2019 zuik. All rights reserved.
//

#import <ZIKRouter/ZIKServiceRouterType.h>

NS_ASSUME_NONNULL_BEGIN

/// Key for data in router.configuration.userInfo
typedef NSString *ZIKURLRouteKey NS_EXTENSIBLE_STRING_ENUM;

/// Default is @"origin-url". You can change this key like: ZIKURLRouteKeyOriginURL = @"originURL"
FOUNDATION_EXTERN ZIKURLRouteKey ZIKURLRouteKeyOriginURL;
/// Default is @"action". You can change this key like: ZIKURLRouteKeyAction = @"action-name"
FOUNDATION_EXTERN ZIKURLRouteKey ZIKURLRouteKeyAction;

/**
 This provides basic URL router features. Call +enableDefaultURLRouteRule if you want to use this URL router.
 
 You can implement your custom URL rules by intercepting or hooking ZIKRouter's state control methods, or creating a parent URL router class overriding these methods for custom rules.
 
 This uses the standard URL format: scheme://host/path/?query
 
 Features of this URL router:
 
 1. Save origin url to router.configuration.userInfo: userInfo = @{ZIKURLRouteKeyOriginURL: url}
 
 2. Use url host as identifier to fetch destination router with `toIdentifier`. In url `app://loginView`, the identifier is `loginView`
 
 2. Get parameters from url to router.configuration.userInfo: app://loginView/?account=abc&pwd=123  => @{@"account": @"abc", @"pwd": @"123"}
 
 3. Process the userInfo before performing
 
 4. Perform action from the url after performing: app://loginView/?action=showAlert
 */
@interface ZIKRouter (URLRouter)

/// Enable default URL router. You can implement your rules.
+ (void)enableDefaultURLRouteRule;

/// Get identifier from url for fetching its router. The default implementation is using url host as identifier.
+ (NSString *)routerIdentifierFromURL:(NSURL *)url;

/// Get user info from URL. Subclass can override and process the url.
+ (NSDictionary *)userInfoFromURL:(NSURL *)url;

# pragma mark Subclass Override

/// Process the user info from url. This method is called before `performWithConfiguration:`. You can config the configuration with the user info.
- (void)processUserInfo:(NSDictionary *)userInfo fromURL:(NSURL *)url;

/// Perform action after performing ended when the url has `action` param.
- (void)performAction:(NSString *)action userInfo:(NSDictionary *)userInfo fromURL:(NSURL *)url;

/// Default actions before `-performWithConfiguration:` for default URL route rule.
- (void)URLRouter_beforePerformWithConfiguration:(ZIKPerformRouteConfiguration *)configuration;

/// Default actions after `-notifySuccessWithAction:` for default URL route rule. The routeAction is ZIKRouteActionPerformRoute or ZIKRouteActionRemoveRoute.
- (void)URLRouter_afterSuccessAction:(ZIKRouteAction)routeAction;

@end

#pragma mark Interceptor

@interface ZIKRouter (Interceptor)
/**
 Inject interceptor for all routers before performing. You can process the configuration for your URL router.
 
 @code
 @implementation ZIKRouter (URLRouter)
 
 + (void)enableDefaultURLRouteRule {
     [ZIKRouter interceptBeforePerformWithConfiguration:^(ZIKRouter *router, ZIKPerformRouteConfiguration *configuration) {
        [router URLRouter_beforePerformWithConfiguration:configuration];
     }];
 }
 
 - (void)URLRouter_beforePerformWithConfiguration:(ZIKPerformRouteConfiguration *)configuration {
     NSDictionary *userInfo = [self.configuration valueForKey:@"_userInfo"];
     if (!userInfo) {
        return;
     }
     NSURL *url = userInfo[ZIKURLRouteKeyOriginURL];
     if (!url || ![url isKindOfClass:[NSURL class]]) {
        return;
     }
     [self processUserInfo:userInfo fromURL:url];
 }
 
 // Subclass can override
 - (void)processUserInfo:(NSDictionary *)userInfo fromURL:(NSURL *)url {
 
 }
 
 @end
 @endcode
 
 @param handler A block invoked before `performWithConfiguration:`
 */
+ (void)interceptBeforePerformWithConfiguration:(void(^)(ZIKRouter *router, ZIKPerformRouteConfiguration *configuration))handler;

/// Inject interceptor for all routers after performing. Use this if you need to add action after the destination is instantiated.
+ (void)interceptAfterPerformWithConfiguration:(void(^)(ZIKRouter *router, ZIKPerformRouteConfiguration *configuration))handler;

/**
 Inject interceptor for all routers after success performing or removing. You can do some addtion custom actions.
 
 @note
 Success action may be called asynchronously (view router is notified performing success action after the view did finish displaying).
 Use `interceptAfterPerformWithConfiguration` instead if you need to add action immediately after the destination is instantiated.
 
 @code
 @implementation ZIKRouter (URLRouter)
 
 + (void)enableDefaultURLRouteRule {
     [ZIKRouter interceptAfterSuccessAction:^(ZIKRouter * _Nonnull router, ZIKRouteAction  _Nonnull routeAction) {
        [router URLRouter_afterSuccessAction:routeAction];
     }];
 }
 
 - (void)URLRouter_afterSuccessAction:(ZIKRouteAction)routeAction {
     // Only handle perform route acation
     if (![routeAction isEqualToString:ZIKRouteActionPerformRoute]) {
        return;
     }
     NSDictionary *userInfo = [self.configuration valueForKey:@"_userInfo"];
     if (!userInfo) {
        return;
     }
     NSURL *url = userInfo[@"origin-url"];
     if (!url || ![url isKindOfClass:[NSURL class]]) {
        return;
     }
     NSString *action = userInfo[ZIKURLRouteKeyAction];
     if (action && [action isKindOfClass:[NSString class]]) {
        [self performAction:action userInfo:userInfo fromURL:url];
     }
 }
 
 - (void)performAction:(NSString *)action userInfo:(NSDictionary *)userInfo fromURL:(NSURL *)url {
    // Perform action from URL, such as get data and give it back to html5
 }
 
 @end
 @endcode
 
 @param handler A block invoked after success performing or removing. The action is ZIKRouteActionPerformRoute or ZIKRouteActionRemoveRoute.
 */
+ (void)interceptAfterSuccessAction:(void(^)(ZIKRouter *router, ZIKRouteAction action))handler;

/// Inject interceptor for all routers after performing failed.
+ (void)interceptAfterEndPerformWithError:(void(^)(ZIKRouter *router, NSError *error))handler;

@end

/**
 URL router to search and call service from url.
 
 It's easy to add other custom features with a custom URL router parent class, such as:
 
 1. Call any methods of destination via url. the URL router can get parameters and call methods with OC runtime: router://loginService/?action=callMethod&method=fillAccount&account=abc
 
 2. Automatically give data back to h5 after performing action. If you are using JavaScriptBridge, the you can pass the `responseCallback` to router's userInfo and call it after performing action.
 
 You can implement these features by yourself if needed.
 */
@interface ZIKServiceRouter<__covariant Destination, __covariant RouteConfig: ZIKPerformRouteConfiguration *> (URLRouter)

/// Perform route for the url. It will search router with `+routerForURL:`, get userInfo with `+userInfoFromURL:` then perform route.
+ (nullable ZIKServiceRouter<Destination, RouteConfig> *)performURL:(NSURL *)url;

/// Get router for identifier from URL.
+ (nullable ZIKServiceRouterType<Destination, RouteConfig> *)routerForURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
