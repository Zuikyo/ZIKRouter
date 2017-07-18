//
//  ZIKRouter.m
//  ZIKRouter
//
//  Created by zuik on 2017/3/2.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKRouter.h"

NSString *kZIKRouterErrorDomain = @"kZIKRouterErrorDomain";

@interface ZIKRouter () <ZIKRouterProtocol>
@property (nonatomic, strong) ZIKRouteConfiguration *configuration;
@end

@implementation ZIKRouter

- (instancetype)initWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    NSParameterAssert(configuration.source);
    NSAssert([self conformsToProtocol:@protocol(ZIKRouterProtocol)], @"%@ 没有遵守ZIKRouterProtocol",[self class]);
    
    if (self = [super init]) {
        _configuration = configuration;
    }
    return self;
}

- (instancetype)initWithConfigure:(void(^)(__kindof ZIKRouteConfiguration * configuration))configAction {
    NSParameterAssert(configAction);
    ZIKRouteConfiguration *configuration = [[self class] defaultRouteConfiguration];
    if (configAction) {
        configAction(configuration);
    }
    return [self initWithConfiguration:configuration];
}

- (void)performRoute {
    NSAssert(self.configuration.source, @"执行路由时，必须有configuration");
    [self performWithConfiguration:self.configuration];
}

- (void)performWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    NSParameterAssert(configuration.source);
    
    id destination = [self destinationWithConfiguration:configuration];
    [self performRouteOnDestination:destination fromSource:configuration.source];
}

+ (void)performWithSource:(UIViewController *)source {
    NSParameterAssert([source isKindOfClass:[UIViewController class]]);
    
    [self performWithConfigure:^(__kindof ZIKRouteConfiguration * _Nonnull configuration) {
        configuration.source = source;
    }];
}

+ (void)performWithConfigure:(void(^ NS_NOESCAPE)(__kindof ZIKRouteConfiguration *configuration))configAction {
    NSParameterAssert(configAction);
    
    ZIKRouteConfiguration *configuration = [self defaultRouteConfiguration];
    if (configAction) {
        configAction(configuration);
    }
    ZIKRouter *route = [[self alloc] initWithConfiguration:configuration];
    [route performRoute];
}

#pragma mark ZIKRouterProtocol

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    NSAssert(NO, @"ZIKRouter的子类 %@ 没有实现ZIKRouterProtocol协议！",[self class]);
    return nil;
}

- (void)performRouteOnDestination:(id)destination fromSource:(id)source {
    NSAssert(NO, @"ZIKRouter的子类 %@ 没有实现ZIKRouterProtocol协议！",[self class]);
}

+ (ZIKRouteConfiguration *)defaultRouteConfiguration {
    NSAssert(NO, @"ZIKRouter的子类 %@ 没有实现ZIKRouterProtocol协议！",[self class]);
    return nil;
}

+ (NSString *)errorDomain {
    return kZIKRouterErrorDomain;
}

+ (NSError *)errorWithCode:(NSInteger)code userInfo:(nullable NSDictionary *)userInfo {
    return [NSError errorWithDomain:[self errorDomain] code:code userInfo:userInfo];
}

+ (NSError *)errorWithCode:(NSInteger)code localizedDescription:(NSString *)description {
    NSParameterAssert(description);
    return [NSError errorWithDomain:[self errorDomain] code:code userInfo:@{NSLocalizedDescriptionKey:description}];
}

- (void)errorCallbackWithRouteAction:(SEL)routeAction error:(NSError *)error {
    if (self.configuration.errorHandler) {
        self.configuration.errorHandler(routeAction, error);
    }
}

@end

@implementation ZIKRouteConfiguration

@end
