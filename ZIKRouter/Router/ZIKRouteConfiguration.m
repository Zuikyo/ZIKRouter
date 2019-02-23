//
//  ZIKRouteConfiguration.m
//  ZIKRouter
//
//  Created by zuik on 2017/10/13.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKRouteConfiguration.h"
#import "ZIKRouteConfigurationPrivate.h"
#import <objc/runtime.h>
#import "ZIKRouterRuntime.h"
#import "ZIKRouterInternal.h"

@interface ZIKRouteConfiguration ()

@end

@implementation ZIKRouteConfiguration

- (id)copyWithZone:(nullable NSZone *)zone {
    ZIKRouteConfiguration *config = [[self class] new];
    config.errorHandler = self.errorHandler;
    config.performerErrorHandler = self.performerErrorHandler;
    config.stateNotifier = self.stateNotifier;
    config._prepareDestination = self._prepareDestination;
    return config;
}

- (BOOL)setPropertiesFromConfiguration:(ZIKRouteConfiguration *)configuration {
    if ([configuration isKindOfClass:[self class]] == NO) {
        NSAssert2(NO, @"Invalid configuration (%@) to copy property values to %@",[configuration class], [self class]);
        return NO;
    }
    NSMutableArray<NSString *> *keys = [NSMutableArray array];
    Class configClass = [self class];
    while (configClass && configClass != [ZIKRouteConfiguration class]) {
        unsigned int count = 0;
        objc_property_t *properties = class_copyPropertyList(configClass, &count);
        for (int i = 0; i < count; i++) {
            objc_property_t property = properties[i];
            if (property) {
                const char *readonly = property_copyAttributeValue(property, "R");
                if (readonly) {
                    continue;
                }
                const char *propertyName = property_getName(property);
                if (propertyName == NULL) {
                    continue;
                }
                NSString *name = [NSString stringWithUTF8String:propertyName];
                if (name == nil) {
                    continue;
                }
                [keys addObject:name];
            }
        }
        configClass = class_getSuperclass(configClass);
    }
    
    [self setValuesForKeysWithDictionary:[configuration dictionaryWithValuesForKeys:keys]];
    return YES;
}

@end

@interface ZIKPerformRouteConfiguration()
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *userInfo;
@end

@implementation ZIKPerformRouteConfiguration

- (void)setRouteCompletion:(void (^)(id _Nonnull))routeCompletion {
    self.successHandler = routeCompletion;
}

- (void (^)(id _Nonnull))routeCompletion {
    return self.successHandler;
}

- (NSMutableDictionary<NSString *, id> *)userInfo {
    if (_userInfo == nil) {
        _userInfo = [NSMutableDictionary dictionary];
    }
    return _userInfo;
}

- (void)addUserInfoForKey:(NSString *)key object:(id)object {
    if (key == nil) {
        return;
    }
    if (_userInfo == nil) {
        _userInfo = [NSMutableDictionary dictionary];
    }
    _userInfo[key] = object;
}

- (void)addUserInfo:(NSDictionary<NSString *, id> *)userInfo {
    if (userInfo == nil) {
        return;
    }
    if (_userInfo == nil) {
        _userInfo = [NSMutableDictionary dictionary];
    }
    [_userInfo addEntriesFromDictionary:userInfo];
}

- (void)removeUserInfo {
    if (_userInfo) {
        [_userInfo removeAllObjects];
    }
}

- (id)copyWithZone:(nullable NSZone *)zone {
    ZIKPerformRouteConfiguration *config = [super copyWithZone:zone];
    config.prepareDestination = self.prepareDestination;
    config.successHandler = self.successHandler;
    config.completionHandler = self.completionHandler;
    config.performerSuccessHandler = self.performerSuccessHandler;
    config.route = self.route;
    if (_userInfo) {
        config.userInfo = _userInfo;
    }
    return config;
}

@end

@interface ZIKServiceMakeableConfiguration ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *constructorContainer;
@end
@implementation ZIKServiceMakeableConfiguration
@dynamic _prepareDestination;

- (ZIKMakeBlock)makeDestinationWith {
    if (!_makeDestinationWith) {
        return ^id{
            NSAssert(NO, @"makeDestinationWith is not set");
            return nil;
        };
    }
    return _makeDestinationWith;
}

- (ZIKConstructBlock)constructDestination {
    if (!_constructDestination) {
        return ^{ NSAssert(NO, @"constructDestination is not set"); };
    }
    return _constructDestination;
}

- (NSMutableDictionary<NSString *, id> *)constructorContainer {
    if (!_constructorContainer) {
        _constructorContainer = [NSMutableDictionary dictionary];
    }
    return _constructorContainer;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    ZIKServiceMakeableConfiguration *config = [super copyWithZone:zone];
    config.makeDestination = self.makeDestination;
    config.makeDestinationWith = _makeDestinationWith;
    config.makedDestination = self.makedDestination;
    config.constructDestination = _constructDestination;
    config.didMakeDestination = self.didMakeDestination;
    config.constructorContainer = _constructorContainer;
    return config;
}

@end

@interface ZIKSwiftServiceMakeableConfiguration ()<ZIKConfigurationAsyncMakeable, ZIKConfigurationSyncMakeable>
@end
@implementation ZIKSwiftServiceMakeableConfiguration

- (ZIKMakeBlock)makeDestinationWith {
    if (!_makeDestinationWith) {
        return ^id{
            NSAssert(NO, @"makeDestinationWith is not set");
            return nil;
        };
    }
    return _makeDestinationWith;
}

- (ZIKConstructBlock)constructDestination {
    if (!_constructDestination) {
        return ^{ NSAssert(NO, @"constructDestination is not set"); };
    }
    return _constructDestination;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    ZIKSwiftServiceMakeableConfiguration *config = [super copyWithZone:zone];
    config.makeDestination = self.makeDestination;
    config.makeDestinationWith = self.makeDestinationWith;
    config.makedDestination = self.makedDestination;
    config.constructDestination = self.constructDestination;
    config.didMakeDestination = self.didMakeDestination;
    return config;
}

@end

@implementation ZIKRemoveRouteConfiguration

- (id)copyWithZone:(nullable NSZone *)zone {
    ZIKRemoveRouteConfiguration *config = [super copyWithZone:zone];
    config.prepareDestination = self.prepareDestination;
    config.successHandler = self.successHandler;
    config.completionHandler = self.completionHandler;
    config.performerSuccessHandler = self.performerSuccessHandler;
    return config;
}

@end

@implementation ZIKRouteStrictConfiguration
- (instancetype)initWithConfiguration:(ZIKPerformRouteConfiguration *)configuration {
    if (self = [super init]) {
        _configuration = configuration;
    }
    return self;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([super respondsToSelector:aSelector]) {
        return YES;
    }
    return [_configuration respondsToSelector:aSelector];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    if ([super conformsToProtocol:aProtocol]) {
        return YES;
    }
    return [_configuration conformsToProtocol:aProtocol];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    return _configuration;
}

- (ZIKRouteErrorHandler)errorHandler {
    return self.configuration.errorHandler;
}

- (void)setErrorHandler:(ZIKRouteErrorHandler)errorHandler {
    self.configuration.errorHandler = errorHandler;
}

- (ZIKRouteErrorHandler)performerErrorHandler {
    return self.configuration.errorHandler;
}

- (void)setPerformerErrorHandler:(ZIKRouteErrorHandler)performerErrorHandler {
    self.configuration.performerErrorHandler = performerErrorHandler;
}

- (ZIKRouteStateNotifier)stateNotifier {
    return self.configuration.stateNotifier;
}

- (void)setStateNotifier:(ZIKRouteStateNotifier)stateNotifier {
    self.configuration.stateNotifier = stateNotifier;
}

@end

@implementation ZIKPerformRouteStrictConfiguration
@dynamic configuration;
- (instancetype)initWithConfiguration:(ZIKPerformRouteConfiguration *)configuration {
    if (self = [super initWithConfiguration:configuration]) {
        NSCParameterAssert([configuration isKindOfClass:[ZIKPerformRouteConfiguration class]]);
    }
    return self;
}
- (void(^)(id))prepareDestination {
    return self.configuration.prepareDestination;
}
- (void)setPrepareDestination:(void (^)(id _Nonnull))prepareDestination {
    self.configuration.prepareDestination = prepareDestination;
}
- (void(^)(id))successHandler {
    return self.configuration.successHandler;
}
- (void)setSuccessHandler:(void (^)(id _Nonnull))successHandler {
    self.configuration.successHandler = successHandler;
}
- (void(^)(id))performerSuccessHandler {
    return self.configuration.performerSuccessHandler;
}
- (void)setPerformerSuccessHandler:(void (^)(id _Nonnull))performerSuccessHandler {
    self.configuration.performerSuccessHandler = performerSuccessHandler;
}
- (void(^)(BOOL success, id _Nullable, ZIKRouteAction, NSError *_Nullable))completionHandler {
    return self.configuration.completionHandler;
}
- (void)setCompletionHandler:(void (^)(BOOL, id _Nullable, ZIKRouteAction _Nonnull, NSError * _Nullable))completionHandler {
    self.configuration.completionHandler = completionHandler;
}

- (NSDictionary<NSString *, id> *)userInfo {
    return self.configuration.userInfo;
}

- (void)addUserInfoForKey:(NSString *)key object:(id)object {
    [self.configuration addUserInfoForKey:key object:object];
}

- (void)addUserInfo:(NSDictionary<NSString *,id> *)userInfo {
    [self.configuration addUserInfo:userInfo];
}

@end

@implementation ZIKRemoveRouteStrictConfiguration
@dynamic configuration;
- (instancetype)initWithConfiguration:(ZIKRemoveRouteConfiguration *)configuration {
    if (self = [super initWithConfiguration:configuration]) {
        NSCParameterAssert([configuration isKindOfClass:[ZIKRemoveRouteConfiguration class]]);
    }
    return self;
}

- (void(^)(id))prepareDestination {
    return self.configuration.prepareDestination;
}
- (void)setPrepareDestination:(void (^)(id _Nonnull))prepareDestination {
    self.configuration.prepareDestination = prepareDestination;
}
- (void (^)(void))successHandler {
    return self.configuration.successHandler;
}
- (void)setSuccessHandler:(void (^)(void))successHandler {
    self.configuration.successHandler = successHandler;
}
- (ZIKRemoveRouteCompletion)completionHandler {
    return self.configuration.completionHandler;
}
- (void)setCompletionHandler:(ZIKRemoveRouteCompletion)completionHandler {
    self.configuration.completionHandler = completionHandler;
}
- (void (^)(void))performerSuccessHandler {
    return self.configuration.performerSuccessHandler;
}
- (void)setPerformerSuccessHandler:(void (^)(void))performerSuccessHandler {
    self.configuration.performerSuccessHandler = performerSuccessHandler;
}
@end
