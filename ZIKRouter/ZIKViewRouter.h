//
//  ZIKViewRouter.h
//  ZIKRouter
//
//  Created by zuik on 2017/3/2.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKRouter.h"
NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger,ZIKViewRouteType) {
    ZIKViewRouteTypePush,
    ZIKViewRouteTypePresent,
    ZIKViewRouteTypeSubview,
    ZIKViewRouteTypeChildViewController
};

@class ZIKViewRouteConfiguration;

@protocol ZIKViewRouteSource <NSObject>

@optional

@property(nullable, nonatomic,readonly,strong) UINavigationController *navigationController;

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated: (BOOL)flag completion:(void (^ __nullable)(void))completion;

- (void)addChildViewController:(UIViewController *)childController;

- (void)addSubview:(UIView *)view;

@end

///ZIKViewRouter的子类要实现的协议
@protocol ZIKViewRouterProtocol <NSObject>
///用configuration初始化目的界面，返回类型为UIViewController或者UIView
- (id)destinationWithConfiguration:(__kindof ZIKViewRouteConfiguration *)configuration;
@optional
///可以在这里判断source，做调用权限限制
- (void)performRouteOnDestination:(UIViewController *)destination fromSource:(id<ZIKViewRouteSource>)source;

+ (__kindof ZIKViewRouteConfiguration *)defaultRouteConfiguration;

- (NSString *)errorDomain;

@end

///用于定义跳转到某个界面的路由
@interface ZIKViewRouter : ZIKRouter
- (__kindof ZIKViewRouteConfiguration *)configuration;

- (instancetype)initWithConfiguration:(__kindof ZIKViewRouteConfiguration *)configuration NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithConfigure:(void(^)(__kindof ZIKViewRouteConfiguration * configuration))configAction;

///当目的界面不需要初始化参数时，可以直接执行跳转，使用默认的跳转方式
+ (void)performWithSource:(id<ZIKViewRouteSource>)source;
+ (void)performWithConfigure:(void(^ NS_NOESCAPE)(__kindof ZIKViewRouteConfiguration *configuration))configAction;

@end

extern NSString *kZIKViewRouteErrorDomain;

typedef NS_ENUM(NSInteger, ZIKViewRouteError) {
    ZIKViewRouteErrorInvalidSource,
    ZIKViewRouteErrorUnsupportType
};

///用于配置跳转逻辑，例如跳转方式、动画等
@interface ZIKViewRouteConfiguration : ZIKRouteConfiguration
///跳转的源界面
@property (nonatomic, weak) id<ZIKViewRouteSource> source;
///跳转方式，默认为ZIKRouteTypePush
@property (nonatomic, assign) ZIKViewRouteType routeType;
///是否有跳转动画，默认为YES
@property (nonatomic, assign) BOOL animated;
///presentViewController:animated:completion:中的completion参数
@property (nonatomic, copy, nullable) void(^presentCompletion)(void);

@property (nonatomic, copy, nullable) void(^addChildCompletion)(UIViewController *viewController);

@property (nonatomic, copy, nullable) void(^addSubviewCompletion)(UIView *view);
@end

NS_ASSUME_NONNULL_END
