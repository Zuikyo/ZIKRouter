//
//  ZIKRouteConfiguration.h
//  ZIKRouter
//
//  Created by zuik on 2017/10/13.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZIKRouterState) {
    ZIKRouterStateNotRoute  NS_ENUM_DEPRECATED_IOS(7.0, 7.0, "Use ZIKRouterStateUnrouted instead") = 0,
    /// Didn't perform any route yet.
    ZIKRouterStateUnrouted = 0,
    /// Performing a route.
    ZIKRouterStateRouting,
    /// Successfully performing a route.
    ZIKRouterStateRouted,
    /// Removing a performed route.
    ZIKRouterStateRemoving,
    /// The router was performed and removed, now it can perform again.
    ZIKRouterStateRemoved
};

/// Route action.
typedef NSString *ZIKRouteAction NS_EXTENSIBLE_STRING_ENUM;

/// Initialize router with configuration. See ZIKRouteErrorInvalidConfiguration, ZIKViewRouteErrorUnsupportType, ZIKViewRouteErrorInvalidSource, ZIKViewRouteErrorInvalidContainer.
FOUNDATION_EXTERN ZIKRouteAction const ZIKRouteActionInit;

/// Perform route. See ZIKRouteErrorActionFailed, ZIKRouteErrorOverRoute, ZIKViewRouteErrorUnbalancedTransition, ZIKViewRouteErrorSegueNotPerformed, ZIKRouteErrorInfiniteRecursion, ZIKRouteErrorInfiniteRecursion, ZIKRouteErrorDestinationUnavailable.
FOUNDATION_EXTERN ZIKRouteAction const ZIKRouteActionPerformRoute;

/// Remove route. See ZIKRouteErrorActionFailed.
FOUNDATION_EXTERN ZIKRouteAction const ZIKRouteActionRemoveRoute;

typedef void(^ZIKRouteErrorHandler)(ZIKRouteAction routeAction, NSError *error);
typedef void(^ZIKRouteStateNotifier)(ZIKRouterState oldState, ZIKRouterState newState);

/// Configuration for destination module. You can use a subclass or use category to add complex parameters for destination module.
@interface ZIKRouteConfiguration : NSObject <NSCopying>

/**
 Error handler for router's provider. Each time the router was performed or removed, error handler will be called when the operation fails.
 @note
 Use weakSelf in errorHandler to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) ZIKRouteErrorHandler errorHandler;

/// Error handler for current performing, will reset to nil after performed.
@property (nonatomic, copy, nullable) ZIKRouteErrorHandler performerErrorHandler;

/**
 Monitor state.
 @note
 Use weakSelf in stateNotifier to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) ZIKRouteStateNotifier stateNotifier;

/// Initialize properties in current configuration class from another configuration, the other configuration must be same class or subclass of self. This is a convenient method to initialize a copy from an existing configuration in -copyWithZone:.
- (BOOL)setPropertiesFromConfiguration:(ZIKRouteConfiguration *)configuration NS_SWIFT_UNAVAILABLE("Can't get properties for Swift");

@end

typedef void(^ZIKPerformRouteCompletion)(BOOL success, id _Nullable destination, ZIKRouteAction routeAction, NSError *_Nullable error);
@interface ZIKPerformRouteConfiguration : ZIKRouteConfiguration <NSCopying>

/**
 Prepare for performRoute, and config other dependency for destination here. Subclass can offer more specific info.
 
 @note
 Use weakSelf in prepareDestination to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^prepareDestination)(id destination);

/**
 Success handler for router's provider. Each time the router was performed, success handler will be called when the operation succeed.
 
 @note
 Use weakSelf in successHandler to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^successHandler)(id destination);

/// Success handler for current performing, will reset to nil after performed.
@property (nonatomic, copy, nullable) void(^performerSuccessHandler)(id destination);

@property (nonatomic, copy, nullable) void(^routeCompletion)(id destination) API_DEPRECATED_WITH_REPLACEMENT("successHandler", ios(7.0, 7.0));

/**
 Completion handler for performRoute.
 
 @note
 Use weakSelf in completion to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) ZIKPerformRouteCompletion completionHandler;

/// User info when handle route action from URL Scheme. Will reset to empty after router remove route.
@property (nonatomic, strong, readonly) NSDictionary<NSString *, id> *userInfo;

/**
 Add user info.
 
 @note
 You should only use user info when handle route action from URL Scheme, because it's not recommanded to passing parameters in dictionary. The compiler can't check parameters' type.
 */
- (void)addUserInfoForKey:(NSString *)key object:(nullable id)object;

/**
 Add user info.
 
 @note
 You should only use user info when handle route action from URL Scheme, because it's not recommanded to passing parameters in dictionary. The compiler can't check parameters' type.
 */
- (void)addUserInfo:(NSDictionary<NSString *, id> *)userInfo;

@end

typedef void(^ZIKRemoveRouteCompletion)(BOOL success, ZIKRouteAction routeAction, NSError *_Nullable error);
@interface ZIKRemoveRouteConfiguration : ZIKRouteConfiguration <NSCopying>

/**
 Prepare for removeRoute. Subclass can offer more specific info.
 
 @note
 Use weakSelf in prepareDestination to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^prepareDestination)(id destination);

/**
 Success handler for router's provider. Each time the router was removed, success handler will be called when the operation succeed.
 
 @note
 Use weakSelf in successHandler to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^successHandler)(void);

/**
 Completion handler for removeRoute.
 
 @note
 Use weakSelf in completion to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) ZIKRemoveRouteCompletion completionHandler;

/// Success handler for current removing, will reset to nil after removed.
@property (nonatomic, copy, nullable) void(^performerSuccessHandler)(void);

@end

#pragma mark Makeable

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"

/// For configuration that can make destination by its own, as a factory for the destination.
@protocol ZIKConfigurationMakeable
/// Make destination with block.
@property (nonatomic, copy, readonly, nullable) id _Nullable(^makeDestination)(void);
@end

typedef id _Nullable(^ZIKMakeBlock)();
/// For configuration that can pass parameters and make destination synchronously.
@protocol ZIKConfigurationSyncMakeable <ZIKConfigurationMakeable>
/// Factory method creating destination with parameters.
@property (nonatomic, copy, readonly) id _Nullable(^makeDestinationWith)();
/**
 Maked destination after calling `makeDestinationWith`.
 
 @note
 You should set makedDestination in `makeDestinationWith`, so the router won't make and prepare destination again when perform with this configuration. If router's configuration has makedDestination, then it won't call `destinationWithConfiguration:` and `prepareDestination:configuration:` and `configuration._prepareDestiantion` when performing.
 */
@property (nonatomic, strong, nullable) id makedDestination;
@end

typedef void(^ZIKConstructBlock)();
/// For configuration that can pass parameters and make destination asynchronously.
@protocol ZIKConfigurationAsyncMakeable <ZIKConfigurationMakeable>
/// Asynchronous factory method passing required parameters for initializing destination module, and get destination in `didMakeDestination`.
@property (nonatomic, copy, readonly) void(^constructDestination)();
/// Give the destination to the caller.
@property (nonatomic, copy, nullable) void(^didMakeDestination)(id destination) NS_REFINED_FOR_SWIFT;
@end

/**
 Configuration that can make destination without using configuration subclass. It's for simple module config protocol that passing a few parameters for initializing module.
 
 @note In Swift, it's preferred to use ServiceMakeableConfiguration or configuration subclass instead.
 */
@interface ZIKServiceMakeableConfiguration<__covariant Destination>: ZIKPerformRouteConfiguration<ZIKConfigurationAsyncMakeable, ZIKConfigurationSyncMakeable>

/**
 Make destination with block.
 @discussion
 Set this in makeDestinationWith or constructDestination block. It's for capturing parameters easily, so we don't need configuration subclass to hold parameters.
 @note
 When using configuration with `registerModuleProtocol:forMakingService:making:`, makeDestination is auto used for making destination.
 
 When using a router subclass with makeable configuration, the router subclass is responsible for check and use makeDestination in `-destinationWithConfiguration:`.
 */
@property (nonatomic, copy, nullable) Destination _Nullable(^makeDestination)(void);

/**
 Factory method passing required parameters and make destination. You should set makedDestination in makeDestinationWith.
 
 If a module need a few required parameters when creating destination, you can declare in module config protocol:
 @code
 @protocol LoginServiceModuleInput <ZIKServiceModuleRoutable>
 /// Pass required parameter and return destination with LoginServiceInput type.
 @property (nonatomic, copy, readonly) id<LoginServiceInput> _Nullable(^makeDestinationWith)(NSString *account);
 @end
 @endcode
 
 Then register module with module config factory block:
 @code
 // Let ZIKServiceMakeableConfiguration conform to LoginServiceModuleInput
 DeclareRoutableServiceModuleProtocol(LoginServiceModuleInput)
 
 // Register in some +registerRoutableDestination
 [ZIKModuleServiceRouter(LoginServiceModuleInput)
 registerModuleProtocol:ZIKRoutable(LoginServiceModuleInput)
 forMakingService:[LoginService class]
 making:^ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> * _Nonnull{
     ZIKServiceMakeableConfiguration *config = [ZIKServiceMakeableConfiguration new];
     __weak typeof(config) weakConfig = config;
     // User is responsible for calling makeDestinationWith and giving parameters
     config.makeDestinationWith = id^(NSString *account) {
 
         // Capture parameters in makeDestination, so we don't need configuration subclass to hold the parameters
         // MakeDestination will be used for creating destination instance
         weakConfig.makeDestination = ^LoginService * _Nullable{
             // Use custom initializer
             LoginService *destination = [LoginService alloc] initWithAccount:account];
             return destination;
         };
         // Set makedDestination, so the router won't make destination and prepare destination again when perform with this configuration
         weakConfig.makedDestination = weakConfig.makeDestination();
         return weakConfig.makedDestination;
     };
     return config;
 }];
 @endcode
 
 You can use this module with LoginServiceModuleInput:
 @code
 [ZIKRouterToServiceModule(LoginServiceModuleInput)
    makeDestinationWithConfiguring:^(ZIKPerformRouteConfiguration<LoginServiceModuleInput> *config) {
        // Give parameters and make destination
        id<LoginServiceInput> destination = config.makeDestinationWith(@"account");
 }];
 @endcode
 
 Or just:
 @code
 id<LoginServiceInput> destination = ZIKRouterToServiceModule(LoginServiceModuleInput).defaultRouteConfiguration.makeDestinationWith(@"account");
 @endcode
 */
@property (nonatomic, copy) Destination _Nullable(^makeDestinationWith)();

/**
 Maked destination after calling `makeDestinationWith`.
 
 @note
 You should set makedDestination in `makeDestinationWith`, so the router won't make and prepare destination again when perform with this configuration. If router's configuration has makedDestination, then it won't call `destinationWithConfiguration:` and `prepareDestination:configuration:` and `configuration._prepareDestiantion` when performing.
 */
@property (nonatomic, strong, nullable) Destination makedDestination;

/**
 Asynchronous factory method passing required parameters for initializing destination module, and get destination in `didMakeDestination`.
 
 If a module need a few required parameters when creating destination, you can declare in module config protocol:
 @code
 @protocol LoginServiceModuleInput <ZIKServiceModuleRoutable>
 /// Pass required parameter for initializing destination.
 @property (nonatomic, copy, readonly) void(^constructDestination)(NSString *account);
 /// Designate destination type.
 @property (nonatomic, copy, nullable) void(^didMakeDestination)(id<LoginServiceInput> destination);
 @end
 @endcode
 
 Then register module with module config factory block:
 @code
 // Let ZIKServiceMakeableConfiguration conform to LoginServiceModuleInput
 DeclareRoutableServiceModuleProtocol(LoginServiceModuleInput)
 
 // Register in some +registerRoutableDestination
 [ZIKModuleServiceRouter(LoginServiceModuleInput)
    registerModuleProtocol:ZIKRoutable(LoginServiceModuleInput)
    forMakingService:[LoginService class]
    making:^ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> * _Nonnull{
        ZIKServiceMakeableConfiguration<LoginService *> *config = [ZIKServiceMakeableConfiguration new];
        __weak typeof(config) weakConfig = config;
 
        // User is responsible for calling constructDestination and giving parameters
        config.constructDestination = ^(NSString *account) {
            // Capture parameters in makeDestination, so we don't need configuration subclass to hold the parameters
            // MakeDestination will be used for creating destination instance
            weakConfig.makeDestination = ^LoginService * _Nullable{
                // Use custom initializer
                LoginService *destination = [LoginService alloc] initWithAccount:account];
                return destination;
            };
        };
        return config;
 }];
 @endcode
 
 You can use this module with LoginServiceModuleInput:
 @code
 [ZIKRouterToServiceModule(LoginServiceModuleInput)
    makeDestinationWithConfiguring:^(ZIKPerformRouteConfiguration<LoginServiceModuleInput> *config) {
        // Give parameters for making destination
        config.constructDestination(@"account");
        config.didMakeDestination = ^(id<LoginServiceInput> destination) {
            // Did get the destination
        };
 }];
 @endcode
 */
@property (nonatomic, copy) void(^constructDestination)();

/// Give the destination with specfic type to the caller. This is auto called and reset to nil after `didFinishPrepareDestination:configuration:`.
@property (nonatomic, copy, nullable) void(^didMakeDestination)(Destination destination) NS_REFINED_FOR_SWIFT;

/**
 Container to hold custom `makeDestinationWith` and `constructDestination` block. If the destination has multi custom initializers, you can add new constructor and store them in the container.
 
 @code
 @protocol LoginServiceModuleInput <ZIKServiceModuleRoutable>
 @property (nonatomic, copy, readonly) id<LoginServiceInput> _Nullable(^makeDestinationWith)(NSString *account);
 
 // The second constructor
 @property (nonatomic, copy, readonly) id<LoginServiceInput> _Nullable(^makeDestinationForNewAccountWith)(NSString *account);
 @end
 
 @interface ZIKSwiftServiceMakeableConfiguration (LoginServiceModuleInput) <LoginServiceModuleInput>
 @end
 @implementation ZIKSwiftServiceMakeableConfiguration
 - (ZIKMakeBlock)makeDestinationForNewAccountWith {
     return self.constructorContainer[@"makeDestinationForNewAccountWith"];
 }
 - (void)setMakeDestinationForNewAccountWith:(ZIKMakeBlock)block {
     self.constructorContainer[@"makeDestinationForNewAccountWith"] = block;
 }
 @end
 @endcode
 */
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, id> *constructorContainer;

@end

@interface ZIKSwiftServiceMakeableConfiguration : ZIKPerformRouteConfiguration /**<ZIKConfigurationAsyncMakeable, ZIKConfigurationSyncMakeable>**/
@property (nonatomic, copy, nullable) id _Nullable(^makeDestination)(void) NS_REFINED_FOR_SWIFT;
@property (nonatomic, copy) id _Nullable(^makeDestinationWith)() NS_REFINED_FOR_SWIFT;

/**
 Maked destination after calling `makeDestinationWith`.
 
 @note
 You should set makedDestination in `makeDestinationWith`, so the router won't make and prepare destination again when perform with this configuration. If router's configuration has makedDestination, then it won't call `destinationWithConfiguration:` and `prepareDestination:configuration:` and `configuration._prepareDestiantion` when performing.
 */
@property (nonatomic, strong, nullable) id makedDestination;
@property (nonatomic, copy) void(^constructDestination)() NS_REFINED_FOR_SWIFT;
@property (nonatomic, copy, nullable) void(^didMakeDestination)(id destination) NS_REFINED_FOR_SWIFT;
@end

#pragma clang diagnostic pop

#pragma mark Strict Configuration

/// Proxy of ZIKRouteConfiguration to handle configuration in a type safe way.
@interface ZIKRouteStrictConfiguration<__covariant Destination> : NSObject
@property (nonatomic, strong, readonly) ZIKRouteConfiguration *configuration;

- (instancetype)initWithConfiguration:(ZIKRouteConfiguration *)configuration NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
/**
 Error handler for router's provider. Each time the router was performed or removed, error handler will be called when the operation fails.
 
 @note
 Use weakSelf in errorHandler to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) ZIKRouteErrorHandler errorHandler;

/// Error handler for current performing, will reset to nil after performed.
@property (nonatomic, copy, nullable) ZIKRouteErrorHandler performerErrorHandler;

/**
 Monitor state.
 
 @note
 Use weakSelf in stateNotifier to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) ZIKRouteStateNotifier stateNotifier;

@end

/// Proxy of ZIKPerformRouteConfiguration to handle configuration in a type safe way.
@interface ZIKPerformRouteStrictConfiguration<__covariant Destination> : ZIKRouteStrictConfiguration<Destination>
@property (nonatomic, strong, readonly) ZIKPerformRouteConfiguration *configuration;
- (instancetype)initWithConfiguration:(ZIKPerformRouteConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

/**
 Prepare for performRoute, and config other dependency for destination here. Subclass can offer more specific info.
 
 @note
 Use weakSelf in prepareDestination to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^prepareDestination)(Destination destination);

/**
 Success handler for router's provider. Each time the router was performed, success handler will be called when the operation succeed.
 
 @note
 Use weakSelf in successHandler to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^successHandler)(Destination destination);

/// Success handler for current performing, will reset to nil after performed.
@property (nonatomic, copy, nullable) void(^performerSuccessHandler)(Destination destination);

/**
 Completion handler for performRoute.
 
 @note
 Use weakSelf in completion to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^completionHandler)(BOOL success, Destination _Nullable destination, ZIKRouteAction routeAction, NSError *_Nullable error);

/// User info when handle route action from URL Scheme.
@property (nonatomic, strong, readonly) NSDictionary<NSString *, id> *userInfo;

/**
 Add user info.
 
 @note
 You should only use user info when handle route action from URL Scheme, because it's not recommanded to passing parameters in dictionary. The compiler can't check parameters' type.
 */
- (void)addUserInfoForKey:(NSString *)key object:(nullable id)object;

/**
 Add user info.
 
 @note
 You should only use user info when handle route action from URL Scheme, because it's not recommanded to passing parameters in dictionary. The compiler can't check parameters' type.
 */
- (void)addUserInfo:(NSDictionary<NSString *, id> *)userInfo;

@end

/// Proxy of ZIKRemoveRouteConfiguration to handle configuration in a type safe way.
@interface ZIKRemoveRouteStrictConfiguration<__covariant Destination> : ZIKRouteStrictConfiguration<Destination>
@property (nonatomic, strong, readonly) ZIKRemoveRouteConfiguration *configuration;
- (instancetype)initWithConfiguration:(ZIKRemoveRouteConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

/**
 Prepare for removeRoute. Subclass can offer more specific info.
 
 @note
 Use weakSelf in prepareDestination to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^prepareDestination)(Destination destination);

/**
 Success handler for router's provider. Each time the router was removed, success handler will be called when the operation succeed.
 
 @note
 Use weakSelf in successHandler to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^successHandler)(void);

/**
 Completion handler for removeRoute.
 
 @note
 Use weakSelf in completion to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) ZIKRemoveRouteCompletion completionHandler;

/// Success handler for current removing, will reset to nil after removed.
@property (nonatomic, copy, nullable) void(^performerSuccessHandler)(void);

@end

NS_ASSUME_NONNULL_END
