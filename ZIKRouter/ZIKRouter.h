//
//  ZIKRouter.h
//  ZIKRouter
//
//  Created by zuik on 2017/3/2.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ZIKRouteConfiguration;

///ZIKRouter的子类要实现的协议
@protocol ZIKRouterProtocol <NSObject>
@required
///生成目标对象，并传入初始化参数
- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration;
///在这里执行具体的路由逻辑
- (void)performRouteOnDestination:(id)destination fromSource:(id)source;
+ (__kindof ZIKRouteConfiguration *)defaultRouteConfiguration;

@optional
- (void)performWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration;
- (NSString *)errorDomain;

@end

///路由的基类，不能直接使用
@interface ZIKRouter : NSObject <ZIKRouterProtocol>
@property (nonatomic,readonly, strong) __kindof ZIKRouteConfiguration *configuration;

- (instancetype)initWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithConfigure:(void(^)(__kindof ZIKRouteConfiguration * configuration))configAction;
- (instancetype)init NS_UNAVAILABLE;

- (void)performRoute;

///当目标对象不需要初始化参数时，可以直接执行
+ (void)performWithSource:(id)source;
///传入目标对象需要的初始化参数后执行
+ (void)performWithConfigure:(void(^ NS_NOESCAPE)(__kindof ZIKRouteConfiguration *configuration))configAction;

@end

@interface ZIKRouter (SubClassPrivate)

+ (NSError *)errorWithCode:(NSInteger)code userInfo:(nullable NSDictionary *)userInfo;
+ (NSError *)errorWithCode:(NSInteger)code localizedDescription:(NSString *)description;
- (void)errorCallbackWithRouteAction:(SEL)routeAction error:(NSError *)error;

@end

///用于配置目标对象，传递需要的初始化参数
@interface ZIKRouteConfiguration : NSObject
///方法的调用者，可以在这里进行权限限制
@property (nonatomic, weak) id source;
@property (nonatomic, copy, nullable) void(^errorHandler)(SEL routeAction, NSError *error);
@end

NS_ASSUME_NONNULL_END
