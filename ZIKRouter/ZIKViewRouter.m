//
//  ZIKViewRouter.m
//  ZIKRouter
//
//  Created by zuik on 2017/3/2.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKViewRouter.h"

NSString *kZIKViewRouteErrorDomain = @"kZIKViewRouteErrorDomain";

@interface ZIKViewRouter ()<ZIKRouterProtocol,ZIKViewRouterProtocol>

@end
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation ZIKViewRouter

#pragma clang diagnostic pop
@dynamic configuration;

- (instancetype)initWithConfiguration:(__kindof ZIKViewRouteConfiguration *)configuration {
    NSParameterAssert([configuration isKindOfClass:[ZIKViewRouteConfiguration class]]);
    NSAssert([self conformsToProtocol:@protocol(ZIKViewRouterProtocol)], @"%@ 没有遵守ZIKViewRouterProtocol",[self class]);
    
    if (self = [super initWithConfiguration:configuration]) {
        
    }
    return self;
}

- (void)performWithConfiguration:(__kindof ZIKViewRouteConfiguration *)configuration {
    NSParameterAssert(configuration);
    
    if ([NSThread isMainThread]) {
        [super performWithConfiguration:configuration];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [super performWithConfiguration:configuration];
        });
    }
}

#pragma mark ZIKRouterProtocol

- (void)performRouteOnDestination:(id)destination fromSource:(id<ZIKViewRouteSource>)source {
    NSParameterAssert([destination isKindOfClass:[UIViewController class]]);
    NSParameterAssert([source isKindOfClass:[UIViewController class]]);
    
    NSAssert(self.configuration, @"执行路由前必须设置configuration");
    
    ZIKViewRouteType routeType = self.configuration.routeType;
    
    switch (routeType) {
        case ZIKViewRouteTypePush:
            if (![source respondsToSelector:@selector(navigationController)]) {
                [self errorCallbackWithRouteAction:@selector(performWithConfigure:) error:[[self class] errorWithCode:ZIKViewRouteErrorInvalidSource localizedDescription:[NSString stringWithFormat:@"source：%@无效，navigationController为空，无法执行push",source]]];
                return;
            }
            [source.navigationController pushViewController:destination animated:self.configuration.animated];
            break;
            
        case ZIKViewRouteTypePresent:
            if (![source respondsToSelector:@selector(presentViewController:animated:completion:)]) {
                [self errorCallbackWithRouteAction:@selector(performWithConfigure:) error:[[self class] errorWithCode:ZIKViewRouteErrorInvalidSource localizedDescription:[NSString stringWithFormat:@"source：%@无效，没有实现presentViewController:animated:completion:，无法执行present",source]]];
                return;
            }
            [source presentViewController:destination animated:self.configuration.animated completion:self.configuration.presentCompletion];
            break;
            
        case ZIKViewRouteTypeChildViewController:
            if (![source respondsToSelector:@selector(addChildViewController:)]) {
                [self errorCallbackWithRouteAction:@selector(performWithConfigure:) error:[[self class] errorWithCode:ZIKViewRouteErrorInvalidSource localizedDescription:[NSString stringWithFormat:@"source：%@无效，没有实现addChildViewController:",source]]];
                return;
            }
            [source addChildViewController:destination];
            if (self.configuration.addChildCompletion) {
                self.configuration.addChildCompletion(destination);
            }
            break;
            
        case ZIKViewRouteTypeSubview:
            if (![source respondsToSelector:@selector(addSubview:)]) {
                [self errorCallbackWithRouteAction:@selector(performWithConfigure:) error:[[self class] errorWithCode:ZIKViewRouteErrorInvalidSource localizedDescription:[NSString stringWithFormat:@"source：%@无效，没有实现addSubview:",source]]];
                return;
            }
            UIView *view;
            if ([destination isKindOfClass:[UIViewController class]]) {
                view = [(UIViewController *)destination view];
            } else if ([destination isKindOfClass:[UIView class]]) {
                view = destination;
            } else {
                [[NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"%@ 的 destinationWithConfiguration: 实现错误，返回的destination必须是UIViewController或者UIView",[self class]] userInfo:nil] raise];
                return;
            }
            [source addSubview:view];
            if (self.configuration.addSubviewCompletion) {
                self.configuration.addSubviewCompletion(view);
            }
            
            break;
    }
}

- (id)destinationWithConfiguration:(__kindof ZIKViewRouteConfiguration *)configuration {
    NSParameterAssert([[[self class] defaultRouteConfiguration] isKindOfClass:[configuration class]]);
    NSAssert(NO, @"ZIKViewRouter的子类 %@ 没有实现ZIKRouterProtocol协议！",[self class]);
    return nil;
}

+ (ZIKViewRouteConfiguration *)defaultRouteConfiguration {
    return [[ZIKViewRouteConfiguration alloc] init];
}

+ (NSString *)errorDomain {
    return kZIKViewRouteErrorDomain;
}

@end

@implementation ZIKViewRouteConfiguration
@dynamic source;

- (instancetype)init {
    if (self = [super init]) {
        [self configDefaultValue];
    }
    return self;
}

- (void)configDefaultValue {
    _routeType = ZIKViewRouteTypePush;
    _animated = YES;
}

@end
