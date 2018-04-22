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

@interface ZIKRouteConfiguration ()

@end

@implementation ZIKRouteConfiguration

- (instancetype)init {
    if (self = [super init]) {
        NSAssert1(ZIKRouter_classSelfImplementingMethod([self class], @selector(copyWithZone:), false), @"configuration (%@) must override -copyWithZone:, because it will be deep copied when router is initialized. You can use -setPropertiesFromConfiguration: to quickly set properties to copy object in Objective-C.",[self class]);
        
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    ZIKRouteConfiguration *config = [[self class] new];
    config.errorHandler = self.errorHandler;
    config.performerErrorHandler = self.performerErrorHandler;
    config.stateNotifier = self.stateNotifier;
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

@implementation ZIKPerformRouteConfiguration

- (void)setRouteCompletion:(void (^)(id _Nonnull))routeCompletion {
    self.successHandler = routeCompletion;
}

- (void (^)(id _Nonnull))routeCompletion {
    return self.successHandler;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    ZIKPerformRouteConfiguration *config = [super copyWithZone:zone];
    config.prepareDestination = self.prepareDestination;
    config.successHandler = self.successHandler;
    config.completionHandler = self.completionHandler;
    config.performerSuccessHandler = self.performerSuccessHandler;
    config.route = self.route;
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
