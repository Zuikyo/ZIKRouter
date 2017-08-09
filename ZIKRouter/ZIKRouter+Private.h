//
//  ZIKRouter_Private.h
//  ZIKRouter
//
//  Created by zuik on 2017/5/24.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKRouter.h"

NS_ASSUME_NONNULL_BEGIN

extern bool ZIKRouter_replaceMethodWithMethod(Class originalClass, SEL originalSelector, Class swizzledClass, SEL swizzledSelector);
extern IMP ZIKRouter_replaceMethodWithMethodAndGetOriginalImp(Class originalClass, SEL originalSelector, Class swizzledClass, SEL swizzledSelector);
extern void ZIKRouter_enumerateClassList(void(^handler)(Class class));
extern void ZIKRouter_enumerateProtocolList(void(^handler)(Protocol *protocol));
extern bool ZIKRouter_classIsSubclassOfClass(Class class, Class parentClass);
extern NSArray *ZIKRouter_subclassesComformToProtocol(NSArray<Class> *classes, Protocol *protocol);

///expost APIs to subclass
@interface ZIKRouter ()
@property (nonatomic, readonly, assign) ZIKRouterState preState;
///subclass can get the real configuration to avoid unnecessary copy
@property (nonatomic, readonly, copy) __kindof ZIKRouteConfiguration *_nocopy_configuration;
@property (nonatomic, readonly, copy) __kindof ZIKRouteConfiguration *_nocopy_removeConfiguration;
@property (nonatomic, readonly, weak) id destination;

//Attach a destination not created from router
- (void)attachDestination:(id)destination;

///If a router need to perform on a specific thread, override -performWithConfiguration: and call [super performWithConfiguration:configuration] in that thread
- (void)performWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration;

///Change state
- (void)notifyRouteState:(ZIKRouterState)state;

- (void)notifySuccessWithAction:(SEL)routeAction;

///Call providerErrorHandler and performerErrorHandler
- (void)notifyError:(NSError *)error routeAction:(SEL)routeAction;

+ (NSError *)errorWithCode:(NSInteger)code userInfo:(nullable NSDictionary *)userInfo;
+ (NSError *)errorWithCode:(NSInteger)code localizedDescription:(NSString *)description;
+ (NSError *)errorWithCode:(NSInteger)code localizedDescriptionFormat:(NSString *)format ,...;
@end

NS_ASSUME_NONNULL_END
