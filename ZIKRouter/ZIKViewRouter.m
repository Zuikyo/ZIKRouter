//
//  ZIKViewRouter.m
//  ZIKRouter
//
//  Created by zuik on 2017/3/2.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKViewRouter.h"
#import "ZIKRouter+Private.h"
#import "ZIKViewRouter+Private.h"
#import <objc/runtime.h>
#import "UIViewController+ZIKViewRouter.h"
#import "UIView+ZIKViewRouter.h"
#import "ZIKPresentationState.h"

#pragma mark Hook helper

@interface UIView ()
- (void)setZIK_routed:(BOOL)routed;
@end
@interface UIView (_ZIKViewRouter)
@end
@implementation UIView (_ZIKViewRouter)
///Temporary bind auto created router to a UIView when it's not addSubView: by router. Reset to nil when view is removed.
- (__kindof ZIKViewRouter *)ZIK_destinationViewRouter {
    return objc_getAssociatedObject(self, "ZIK_destinationViewRouter");
}
- (void)setZIK_destinationViewRouter:(nullable ZIKViewRouter *)viewRouter {
    objc_setAssociatedObject(self, "ZIK_destinationViewRouter", viewRouter, OBJC_ASSOCIATION_RETAIN);
}
///Route type when view is routed from a router, will reset to nil when view is removed
- (nullable NSNumber *)ZIK_routeTypeFromRouter {
    NSNumber *result = objc_getAssociatedObject(self, "ZIK_routeTypeFromRouter");
    return result;
}
- (void)setZIK_routeTypeFromRouter:(nullable NSNumber *)routeType {
    NSParameterAssert(!routeType ||
                      [routeType integerValue] <= ZIKViewRouteTypeGetDestination);
    objc_setAssociatedObject(self, "ZIK_routeTypeFromRouter", routeType, OBJC_ASSOCIATION_RETAIN);
}
@end

@interface UIViewController ()
- (void)setZIK_routed:(BOOL)routed;
- (void)setZIK_removing:(BOOL)removing;
@end

@interface UIViewController (_ZIKViewRouter)
@end
@implementation UIViewController (_ZIKViewRouter)
///Route type when view is routed from a router. Reset to nil when view is removed.
- (nullable NSNumber *)ZIK_routeTypeFromRouter {
    NSNumber *result = objc_getAssociatedObject(self, "ZIK_routeTypeFromRouter");
    return result;
}
- (void)setZIK_routeTypeFromRouter:(nullable NSNumber *)routeType {
    NSParameterAssert(!routeType ||
                      [routeType integerValue] <= ZIKViewRouteTypeGetDestination);
    objc_setAssociatedObject(self, "ZIK_routeTypeFromRouter", routeType, OBJC_ASSOCIATION_RETAIN);
}
///Temporary bind auto created routers to a segue destination for routable views in destination. Reset to nil when segue is performed.
- (nullable NSArray<ZIKViewRouter *> *)ZIK_destinationViewRouters {
    return objc_getAssociatedObject(self, "ZIK_destinationViewRouters");
}
- (void)setZIK_destinationViewRouters:(nullable NSArray<ZIKViewRouter *> *)viewRouters {
    NSParameterAssert(!viewRouters || [viewRouters isKindOfClass:[NSArray class]]);
    objc_setAssociatedObject(self, "ZIK_destinationViewRouters", viewRouters, OBJC_ASSOCIATION_RETAIN);
}
///Temporary bind a router to a UIViewController when performing segue from the router. Reset to nil when segue is performed.
- (__kindof ZIKViewRouter *)ZIK_sourceViewRouter {
    return objc_getAssociatedObject(self, "ZIK_sourceViewRouter");
}
- (void)setZIK_sourceViewRouter:(__kindof ZIKViewRouter *)viewRouter {
    objc_setAssociatedObject(self, "ZIK_sourceViewRouter", viewRouter, OBJC_ASSOCIATION_RETAIN);
}
- (nullable Class)ZIK_currentClassCallingPrepareForSegue {
    return objc_getAssociatedObject(self, "ZIK_CurrentClassCallingPrepareForSegue");
}
- (void)setZIK_currentClassCallingPrepareForSegue:(Class)vcClass {
    objc_setAssociatedObject(self, "ZIK_CurrentClassCallingPrepareForSegue", vcClass, OBJC_ASSOCIATION_RETAIN);
}
- (UIViewController *)ZIK_parentMovingTo {
    UIViewController *(^weakContainer)(void) = objc_getAssociatedObject(self, "ZIK_parentMovingTo");
    if (weakContainer) {
        return weakContainer();
    }
    return nil;
}
- (void)setZIK_parentMovingTo:(nullable UIViewController *)parentMovingTo {
    NSParameterAssert(!parentMovingTo || [parentMovingTo isKindOfClass:[UIViewController class]]);
    id object = nil;
    if (parentMovingTo) {
        __weak typeof(UIViewController *)weakParent = parentMovingTo;
        UIViewController *(^weakContainer)(void) = ^ {
            return weakParent;
        };
        object = weakContainer;
    }
    objc_setAssociatedObject(self, "ZIK_parentMovingTo", object, OBJC_ASSOCIATION_RETAIN);
}
- (nullable UIViewController *)ZIK_parentRemovingFrom {
    UIViewController *(^weakContainer)(void) = objc_getAssociatedObject(self, "ZIK_parentRemovingFrom");
    if (weakContainer) {
        return weakContainer();
    }
    return nil;
}
- (void)setZIK_parentRemovingFrom:(nullable UIViewController *)parentRemovingFrom {
    NSParameterAssert(!parentRemovingFrom || [parentRemovingFrom isKindOfClass:[UIViewController class]]);
    id object;
    if (parentRemovingFrom) {
        __weak typeof(UIViewController *)weakParent = parentRemovingFrom;
        UIViewController *(^weakContainer)(void) = ^ {
            return weakParent;
        };
        object = weakContainer;
    }
    objc_setAssociatedObject(self, "ZIK_parentRemovingFrom", object, OBJC_ASSOCIATION_RETAIN);
}
- (nullable id<UIViewControllerTransitionCoordinator>)ZIK_currentTransitionCoordinator {
    id<UIViewControllerTransitionCoordinator> transitionCoordinator = self.transitionCoordinator;
    if (!transitionCoordinator) {
        transitionCoordinator = self.navigationController.transitionCoordinator;
        if (!transitionCoordinator) {
            transitionCoordinator = self.presentingViewController.transitionCoordinator;
            if (!transitionCoordinator) {
                return [self.parentViewController ZIK_currentTransitionCoordinator];
            }
        }
    }
    return transitionCoordinator;
}
@end

@interface UIStoryboardSegue (_ZIKViewRouter)
@end
@implementation UIStoryboardSegue (_ZIKViewRouter)
- (nullable Class)ZIK_currentClassCallingPerform {
    return objc_getAssociatedObject(self, "ZIK_CurrentClassCallingPerform");
}
- (void)setZIK_currentClassCallingPerform:(Class)vcClass {
    objc_setAssociatedObject(self, "ZIK_CurrentClassCallingPerform", vcClass, OBJC_ASSOCIATION_RETAIN);
}
@end

#pragma mark Private Config

@interface ZIKViewRouteConfiguration ()
@property (nonatomic, assign) BOOL autoCreated;
@property (nonatomic, strong, nullable) ZIKViewRouteSegueConfiguration *segueConfiguration;
@property (nonatomic, strong, nullable) ZIKViewRoutePopoverConfiguration *popoverConfiguration;
@end

@interface ZIKViewRoutePopoverConfiguration ()
@property (nonatomic, assign) BOOL sourceRectConfiged;
@property (nonatomic, assign) BOOL popoverLayoutMarginsConfiged;
@end

@interface ZIKViewRouteSegueConfiguration ()
@property (nonatomic, weak, nullable) UIViewController *segueSource;
@property (nonatomic, weak, nullable) UIViewController *segueDestination;
@property (nonatomic, strong) ZIKPresentationState *destinationStateBeforeRoute;
@end

#pragma mark ----------ZIKViewRouter----------

NSArray<NSNumber *> *kDefaultRouteTypesForViewController;
NSArray<NSNumber *> *kDefaultRouteTypesForView;

NSString *const kZIKViewRouteWillPerformRouteNotification = @"kZIKViewRouteWillPerformRouteNotification";
NSString *const kZIKViewRouteDidPerformRouteNotification = @"kZIKViewRouteDidPerformRouteNotification";
NSString *const kZIKViewRouteWillRemoveRouteNotification = @"kZIKViewRouteWillRemoveRouteNotification";
NSString *const kZIKViewRouteDidRemoveRouteNotification = @"kZIKViewRouteDidRemoveRouteNotification";
NSString *const kZIKViewRouteRemoveRouteCanceledNotification = @"kZIKViewRouteRemoveRouteCanceledNotification";
NSString *const kZIKViewRouteErrorDomain = @"kZIKViewRouteErrorDomain";

static BOOL _assert_isLoadFinished = NO;
static CFMutableDictionaryRef g_viewProtocolToRouterMap;
static CFMutableDictionaryRef g_configProtocolToRouterMap;
static CFMutableDictionaryRef g_viewToRoutersMap;
static CFMutableDictionaryRef g_viewToDefaultRouterMap;
static CFMutableDictionaryRef g_viewToExclusiveRouterMap;
#if ZIKVIEWROUTER_CHECK
static CFMutableDictionaryRef _check_routerToViewsMap;
static NSArray<Class> *g_routableViews;
#endif

static ZIKViewRouteGlobalErrorHandler g_globalErrorHandler;
static dispatch_semaphore_t g_globalErrorSema;
static NSMutableArray *g_preparingUIViewRouters;

@interface ZIKViewRouter ()<ZIKRouterProtocol>
@property (nonatomic, assign) BOOL routingFromInternal;
@property (nonatomic, assign) ZIKViewRouteRealType realRouteType;
///Destination prepared. Only for UIView destination
@property (nonatomic, assign) BOOL prepared;
@property (nonatomic, strong, nullable) ZIKPresentationState *stateBeforeRoute;
@property (nonatomic, weak, nullable) UIViewController<ZIKViewRouteContainer> *container;
@property (nonatomic, strong, nullable) ZIKViewRouter *retainedSelf;
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation ZIKViewRouter

#pragma clang diagnostic pop

@dynamic configuration;
@dynamic _nocopy_configuration;
@dynamic _nocopy_removeConfiguration;

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZIKRouter_replaceMethodWithMethod([UIApplication class], @selector(setDelegate:),
                                          self, @selector(ZIKViewRouter_hook_setDelegate:));
        ZIKRouter_replaceMethodWithMethodType([UIStoryboard class], @selector(storyboardWithName:bundle:), true, self, @selector(ZIKViewRouter_hook_storyboardWithName:bundle:), true);
    });
}

+ (void)setup {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _initializeZIKViewRouter();
    });
}

+ (void)ZIKViewRouter_hook_setDelegate:(id<UIApplicationDelegate>)delegate {
    [ZIKViewRouter setup];
    [self ZIKViewRouter_hook_setDelegate:delegate];
}

+ (UIStoryboard *)ZIKViewRouter_hook_storyboardWithName:(NSString *)name bundle:(nullable NSBundle *)storyboardBundleOrNil {
    [ZIKViewRouter setup];
    return [self ZIKViewRouter_hook_storyboardWithName:name bundle:storyboardBundleOrNil];
}

static void _initializeZIKViewRouter(void) {
    if (!g_viewProtocolToRouterMap) {
        g_viewProtocolToRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    }
    if (!g_configProtocolToRouterMap) {
        g_configProtocolToRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    }
    kDefaultRouteTypesForViewController = @[
                                            @(ZIKViewRouteTypePush),
                                            @(ZIKViewRouteTypePresentModally),
                                            @(ZIKViewRouteTypePresentAsPopover),
                                            @(ZIKViewRouteTypePerformSegue),
                                            @(ZIKViewRouteTypeShow),
                                            @(ZIKViewRouteTypeShowDetail),
                                            @(ZIKViewRouteTypeAddAsChildViewController),
                                            @(ZIKViewRouteTypeGetDestination)
                                            ];
    kDefaultRouteTypesForView = @[
                                  @(ZIKViewRouteTypeAddAsSubview),
                                  @(ZIKViewRouteTypeGetDestination)
                                  ];
    g_globalErrorSema = dispatch_semaphore_create(1);
    
    g_preparingUIViewRouters = [NSMutableArray array];
#if ZIKVIEWROUTER_CHECK
    NSMutableArray *routableViews = [NSMutableArray array];
#endif
    
    Class ZIKViewRouterClass = [ZIKViewRouter class];
    Class UIResponderClass = [UIResponder class];
    Class UIViewControllerClass = [UIViewController class];
    Class UIStoryboardSegueClass = [UIStoryboardSegue class];
    
    ZIKRouter_replaceMethodWithMethod(UIViewControllerClass, @selector(willMoveToParentViewController:),
                                      ZIKViewRouterClass, @selector(ZIKViewRouter_hook_willMoveToParentViewController:));
    ZIKRouter_replaceMethodWithMethod(UIViewControllerClass, @selector(didMoveToParentViewController:),
                                      ZIKViewRouterClass, @selector(ZIKViewRouter_hook_didMoveToParentViewController:));
    ZIKRouter_replaceMethodWithMethod(UIViewControllerClass, @selector(viewWillAppear:),
                                      ZIKViewRouterClass, @selector(ZIKViewRouter_hook_viewWillAppear:));
    ZIKRouter_replaceMethodWithMethod(UIViewControllerClass, @selector(viewDidAppear:),
                                      ZIKViewRouterClass, @selector(ZIKViewRouter_hook_viewDidAppear:));
    ZIKRouter_replaceMethodWithMethod(UIViewControllerClass, @selector(viewWillDisappear:),
                                      ZIKViewRouterClass, @selector(ZIKViewRouter_hook_viewWillDisappear:));
    if (NSClassFromString(@"SLComposeServiceViewController")) {
        //fix SLComposeServiceViewController doesn't call -[super viewWillDisappear:]
        ZIKRouter_replaceMethodWithMethod(NSClassFromString(@"SLComposeServiceViewController"), @selector(viewWillDisappear:),
                                          ZIKViewRouterClass, @selector(ZIKViewRouter_hook_viewWillDisappear:));
    }
    ZIKRouter_replaceMethodWithMethod(UIViewControllerClass, @selector(viewDidDisappear:),
                                      ZIKViewRouterClass, @selector(ZIKViewRouter_hook_viewDidDisappear:));
    ZIKRouter_replaceMethodWithMethod(UIViewControllerClass, @selector(viewDidLoad),
                                      ZIKViewRouterClass, @selector(ZIKViewRouter_hook_viewDidLoad));
    
    ZIKRouter_replaceMethodWithMethod([UIView class], @selector(willMoveToSuperview:),
                                      ZIKViewRouterClass, @selector(ZIKViewRouter_hook_willMoveToSuperview:));
    ZIKRouter_replaceMethodWithMethod([UIView class], @selector(didMoveToSuperview),
                                      ZIKViewRouterClass, @selector(ZIKViewRouter_hook_didMoveToSuperview));
    ZIKRouter_replaceMethodWithMethod([UIView class], @selector(willMoveToWindow:),
                                      ZIKViewRouterClass, @selector(ZIKViewRouter_hook_willMoveToWindow:));
    ZIKRouter_replaceMethodWithMethod([UIView class], @selector(didMoveToWindow),
                                      ZIKViewRouterClass, @selector(ZIKViewRouter_hook_didMoveToWindow));
    
    ZIKRouter_replaceMethodWithMethod(UIViewControllerClass, @selector(prepareForSegue:sender:),
                                      ZIKViewRouterClass, @selector(ZIKViewRouter_hook_prepareForSegue:sender:));
    ZIKRouter_replaceMethodWithMethod(UIStoryboardSegueClass, @selector(perform),
                                      ZIKViewRouterClass, @selector(ZIKViewRouter_hook_seguePerform));
    
    ZIKRouter_enumerateClassList(^(__unsafe_unretained Class class) {
        if (ZIKRouter_classIsSubclassOfClass(class, UIResponderClass)) {
            if (class_conformsToProtocol(class, @protocol(ZIKRoutableView))) {
                NSCAssert([class isSubclassOfClass:[UIView class]] || [class isSubclassOfClass:UIViewControllerClass], @"ZIKRoutableView only suppourt UIView and UIViewController");
#if ZIKVIEWROUTER_CHECK
                [routableViews addObject:class];
#endif
            }
            if (ZIKRouter_classIsSubclassOfClass(class, UIViewControllerClass)) {
                //hook all UIViewController's -prepareForSegue:sender:
                ZIKRouter_replaceMethodWithMethod(class, @selector(prepareForSegue:sender:),
                                                  ZIKViewRouterClass, @selector(ZIKViewRouter_hook_prepareForSegue:sender:));
            }
        } else if (ZIKRouter_classIsSubclassOfClass(class,UIStoryboardSegueClass)) {//hook all UIStoryboardSegue's -perform
            ZIKRouter_replaceMethodWithMethod(class, @selector(perform),
                                              ZIKViewRouterClass, @selector(ZIKViewRouter_hook_seguePerform));
        } else if (ZIKRouter_classIsSubclassOfClass(class, ZIKViewRouterClass)) {
            IMP registerIMP = class_getMethodImplementation(objc_getMetaClass(class_getName(class)), @selector(registerRoutableDestination));
            NSCAssert2(registerIMP, @"Router(%@) must implement +registerRoutableDestination to register destination with %@",class,class);
            void(*registerFunc)(Class, SEL) = (void(*)(Class,SEL))registerIMP;
            if (registerFunc) {
                registerFunc(class,@selector(registerRoutableDestination));
            }
#if ZIKVIEWROUTER_CHECK
            CFMutableSetRef views = (CFMutableSetRef)CFDictionaryGetValue(_check_routerToViewsMap, (__bridge const void *)(class));
            NSSet *viewSet = (__bridge NSSet *)(views);
            NSCAssert2(viewSet.count > 0 || ZIKRouter_classIsSubclassOfClass(class, NSClassFromString(@"ZIKViewRouteAdapter")), @"This router class(%@) was not resgistered with any view class. Use ZIKViewRouter_registerView() to register view in Router(%@)'s +registerRoutableDestination.",class,class);
#endif
        }

    });
    
#if ZIKVIEWROUTER_CHECK
    g_routableViews = routableViews;
    ZIKRouter_enumerateProtocolList(^(Protocol *protocol) {
        if (protocol_conformsToProtocol(protocol, @protocol(ZIKViewRoutable)) &&
            protocol != @protocol(ZIKViewRoutable)) {
            Class routerClass = (Class)CFDictionaryGetValue(g_viewProtocolToRouterMap, (__bridge const void *)(protocol));
            NSCAssert1(routerClass, @"Declared view protocol(%@) is not registered with any router class!",NSStringFromProtocol(protocol));
            
            CFSetRef viewsRef = CFDictionaryGetValue(_check_routerToViewsMap, (__bridge const void *)(routerClass));
            NSSet *views = (__bridge NSSet *)(viewsRef);
            NSCAssert1(views.count > 0, @"Router(%@) didn't registered with any viewClass", routerClass);
            for (Class viewClass in views) {
                NSCAssert3([viewClass conformsToProtocol:protocol], @"Router(%@)'s viewClass(%@) should conform to registered protocol(%@)",routerClass, viewClass, NSStringFromProtocol(protocol));
            }
        } else if (protocol_conformsToProtocol(protocol, @protocol(ZIKViewConfigRoutable)) &&
                   protocol != @protocol(ZIKViewConfigRoutable)) {
            Class routerClass = (Class)CFDictionaryGetValue(g_configProtocolToRouterMap, (__bridge const void *)(protocol));
            NSCAssert1(routerClass, @"Declared routable config protocol(%@) is not registered with any router class!",NSStringFromProtocol(protocol));
            ZIKViewRouteConfiguration *config = [routerClass defaultRouteConfiguration];
            NSCAssert3([config conformsToProtocol:protocol], @"Router(%@)'s default ZIKViewRouteConfiguration(%@) should conform to registered config protocol(%@)",routerClass, [config class], NSStringFromProtocol(protocol));
        }
    });
#endif
    
    _assert_isLoadFinished = YES;
}

#pragma mark Dynamic Discover

void ZIKViewRouter_registerView(Class viewClass, Class routerClass) {
    NSCParameterAssert([viewClass isSubclassOfClass:[UIView class]] ||
                       [viewClass isSubclassOfClass:[UIViewController class]]);
    NSCParameterAssert([viewClass conformsToProtocol:@protocol(ZIKRoutableView)]);
    NSCParameterAssert([routerClass isSubclassOfClass:[ZIKViewRouter class]]);
    NSCAssert(!_assert_isLoadFinished, @"Only register in +registerRoutableDestination.");
    NSCAssert([NSThread isMainThread], @"Call in main thread for thread safety.");
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!g_viewToDefaultRouterMap) {
            g_viewToDefaultRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
        }
        if (!g_viewToRoutersMap) {
            g_viewToRoutersMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
        }
#if ZIKVIEWROUTER_CHECK
        if (!_check_routerToViewsMap) {
            _check_routerToViewsMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
        }
#endif
    });
    NSCAssert(!g_viewToExclusiveRouterMap ||
              (g_viewToExclusiveRouterMap && !CFDictionaryGetValue(g_viewToExclusiveRouterMap, (__bridge const void *)(viewClass))), @"There is a registered exclusive router, can't use another router for this viewClass.");
    
    if (!CFDictionaryContainsKey(g_viewToDefaultRouterMap, (__bridge const void *)(viewClass))) {
        CFDictionarySetValue(g_viewToDefaultRouterMap, (__bridge const void *)(viewClass), (__bridge const void *)(routerClass));
    }
    CFMutableSetRef routers = (CFMutableSetRef)CFDictionaryGetValue(g_viewToRoutersMap, (__bridge const void *)(viewClass));
    if (routers == NULL) {
        routers = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue(g_viewToRoutersMap, (__bridge const void *)(viewClass), routers);
    }
    CFSetAddValue(routers, (__bridge const void *)(routerClass));
    
#if ZIKVIEWROUTER_CHECK
    CFMutableSetRef views = (CFMutableSetRef)CFDictionaryGetValue(_check_routerToViewsMap, (__bridge const void *)(routerClass));
    if (views == NULL) {
        views = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue(_check_routerToViewsMap, (__bridge const void *)(routerClass), views);
    }
    CFSetAddValue(views, (__bridge const void *)(viewClass));
#endif
}

void ZIKViewRouter_registerViewProtocol(Protocol *viewProtocol, Class routerClass) {
    NSCParameterAssert([routerClass isSubclassOfClass:[ZIKViewRouter class]]);
    NSCAssert(!_assert_isLoadFinished, @"Only register in +registerRoutableDestination.");
    NSCAssert([NSThread isMainThread], @"Call in main thread for thread safety.");
#if ZIKVIEWROUTER_CHECK
    NSCAssert1(protocol_conformsToProtocol(viewProtocol, @protocol(ZIKViewRoutable)), @"%@ should conforms to ZIKViewRoutable in DEBUG mode for safety checking", NSStringFromProtocol(viewProtocol));
#endif
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!g_viewProtocolToRouterMap) {
            g_viewProtocolToRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
        }
    });
    NSCAssert(!CFDictionaryGetValue(g_viewProtocolToRouterMap, (__bridge const void *)(viewProtocol)) ||
              (Class)CFDictionaryGetValue(g_viewProtocolToRouterMap, (__bridge const void *)(viewProtocol)) == routerClass
              , @"Protocol already registered by another router, viewProtocol should only be used by this routerClass.");
    
    CFDictionarySetValue(g_viewProtocolToRouterMap, (__bridge const void *)(viewProtocol), (__bridge const void *)(routerClass));
}

void ZIKViewRouter_registerConfigProtocol(Protocol *configProtocol, Class routerClass) {
    NSCParameterAssert([routerClass isSubclassOfClass:[ZIKViewRouter class]]);
    NSCAssert([[routerClass defaultRouteConfiguration] conformsToProtocol:configProtocol], @"configProtocol should be conformed by this router's defaultRouteConfiguration.");
    NSCAssert(!_assert_isLoadFinished, @"Only register in +registerRoutableDestination.");
    NSCAssert([NSThread isMainThread], @"Call in main thread for thread safety.");
#if ZIKVIEWROUTER_CHECK
    NSCAssert1(protocol_conformsToProtocol(configProtocol, @protocol(ZIKViewConfigRoutable)), @"%@ should conforms to ZIKViewConfigRoutable in DEBUG mode for safety checking", NSStringFromProtocol(configProtocol));
#endif
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!g_configProtocolToRouterMap) {
            g_configProtocolToRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
        }
    });
    NSCAssert(!CFDictionaryGetValue(g_configProtocolToRouterMap, (__bridge const void *)(configProtocol)) ||
              (Class)CFDictionaryGetValue(g_configProtocolToRouterMap, (__bridge const void *)(configProtocol)) == routerClass
              , @"Protocol already registered by another router, configProtocol should only be used by this routerClass.");
    
    CFDictionarySetValue(g_configProtocolToRouterMap, (__bridge const void *)(configProtocol), (__bridge const void *)(routerClass));
}

void ZIKViewRouter_registerViewForExclusiveRouter(Class viewClass, Class routerClass) {
    NSCParameterAssert([viewClass isSubclassOfClass:[UIView class]] ||
                       [viewClass isSubclassOfClass:[UIViewController class]]);
    NSCParameterAssert([viewClass conformsToProtocol:@protocol(ZIKRoutableView)]);
    NSCParameterAssert([routerClass isSubclassOfClass:[ZIKViewRouter class]]);
    NSCAssert(!_assert_isLoadFinished, @"Only register in +registerRoutableDestination.");
    NSCAssert([NSThread isMainThread], @"Call in main thread for thread safety.");
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!g_viewToExclusiveRouterMap) {
            g_viewToExclusiveRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
        }
        if (!g_viewToDefaultRouterMap) {
            g_viewToDefaultRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
        }
        if (!g_viewToRoutersMap) {
            g_viewToRoutersMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
        }
#if ZIKVIEWROUTER_CHECK
        if (!_check_routerToViewsMap) {
            _check_routerToViewsMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
        }
#endif
    });
    NSCAssert(!CFDictionaryGetValue(g_viewToExclusiveRouterMap, (__bridge const void *)(viewClass)), @"There is already a registered exclusive router for this viewClass, you can only specific one exclusive router for each viewClass. Choose the one used inside view.");
    NSCAssert(!CFDictionaryGetValue(g_viewToDefaultRouterMap, (__bridge const void *)(viewClass)), @"ViewClass already registered with another router by ZIKViewRouter_registerView(), check and remove them. You shall only use the exclusive router for this viewClass.");
    NSCAssert(!CFDictionaryContainsKey(g_viewToRoutersMap, (__bridge const void *)(viewClass)) ||
              (CFDictionaryContainsKey(g_viewToRoutersMap, (__bridge const void *)(viewClass)) &&
               !CFSetContainsValue(
                                   (CFMutableSetRef)CFDictionaryGetValue(g_viewToRoutersMap, (__bridge const void *)(viewClass)),
                                   (__bridge const void *)(routerClass)
                                   ))
              , @"ViewClass already registered with another router, check and remove them. You shall only use the exclusive router for this viewClass.");
    
    CFDictionarySetValue(g_viewToExclusiveRouterMap, (__bridge const void *)(viewClass), (__bridge const void *)(routerClass));
    CFDictionarySetValue(g_viewToDefaultRouterMap, (__bridge const void *)(viewClass), (__bridge const void *)(routerClass));
    CFMutableSetRef routers = (CFMutableSetRef)CFDictionaryGetValue(g_viewToRoutersMap, (__bridge const void *)(viewClass));
    if (routers == NULL) {
        routers = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue(g_viewToRoutersMap, (__bridge const void *)(viewClass), routers);
    }
    CFSetAddValue(routers, (__bridge const void *)(routerClass));
    
#if ZIKVIEWROUTER_CHECK
    CFMutableSetRef views = (CFMutableSetRef)CFDictionaryGetValue(_check_routerToViewsMap, (__bridge const void *)(routerClass));
    if (views == NULL) {
        views = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue(_check_routerToViewsMap, (__bridge const void *)(routerClass), views);
    }
    CFSetAddValue(views, (__bridge const void *)(viewClass));
#endif
}

void EnumerateRoutersForViewClass(Class viewClass,void(^handler)(Class routerClass)) {
    NSCParameterAssert([viewClass conformsToProtocol:@protocol(ZIKRoutableView)]);
    NSCParameterAssert(handler);
    if (!viewClass) {
        return;
    }
    Class UIViewControllerSuperclass = [UIViewController superclass];
    while (viewClass != UIViewControllerSuperclass) {
        if (class_conformsToProtocol(viewClass, @protocol(ZIKRoutableView))) {
            CFMutableSetRef routers = (CFMutableSetRef)CFDictionaryGetValue(g_viewToRoutersMap, (__bridge const void *)(viewClass));
            NSSet *routerClasses = (__bridge NSSet *)(routers);
            for (Class class in routerClasses) {
                if (handler) {
                    handler(class);
                }
            }
        }
        viewClass = class_getSuperclass(viewClass);
    }
}

static _Nullable Class ZIKViewRouterForRegisteredView(Class viewClass) {
    NSCParameterAssert([viewClass isSubclassOfClass:[UIView class]] ||
                       [viewClass isSubclassOfClass:[UIViewController class]]);
    NSCParameterAssert([viewClass conformsToProtocol:@protocol(ZIKRoutableView)]);
    NSCAssert(_assert_isLoadFinished, @"Only get router after app did finish launch.");
    NSCAssert(g_viewToDefaultRouterMap, @"Didn't register any viewClass yet.");
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!g_viewToDefaultRouterMap) {
            g_viewToDefaultRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
        }
    });
    if (viewClass) {
        while (viewClass && !class_conformsToProtocol(viewClass, @protocol(ZIKRoutableView))) {
            viewClass = class_getSuperclass(viewClass);
        }
        Class routerClass = CFDictionaryGetValue(g_viewToDefaultRouterMap, (__bridge const void *)(viewClass));
        NSCAssert(!routerClass || [routerClass isSubclassOfClass:[ZIKViewRouter class]],@"routerClass should be ZIKViewRouter's subclass.");
        
        if (!routerClass) {
            //this protocol is not registered
            CFSetRef routers = CFDictionaryGetValue(g_viewToRoutersMap, (__bridge const void *)(viewClass));
            NSCAssert(routers, @"Didn't register any routerClass for viewClass.");
            NSCAssert(CFSetGetCount(routers) == 1, @"There are multi routers for this view class, you have to use ZIKViewRouterRegisterViewWithViewProtocol() to register different protocol for each router.");
            if (!routers) {
                return nil;
            }
            //Get random one, and add to default map
            routerClass = [(__bridge NSSet *)routers anyObject];
            NSCAssert(routerClass, @"Didn't register default routerClass and any other routerClass for viewClass.");
            NSCAssert([routerClass isSubclassOfClass:[ZIKViewRouter class]],@"routerClass should be ZIKViewRouter's subclass.");
            if (routerClass) {
                CFDictionarySetValue(g_viewToDefaultRouterMap, (__bridge const void *)(viewClass), (__bridge const void *)(routerClass));
                return routerClass;
            }
        }
        return routerClass;
    }
    return nil;
}

_Nullable Class ZIKViewRouterForView(Protocol<ZIKViewRoutable> *viewProtocol) {
    NSCParameterAssert(viewProtocol);
    NSCAssert(g_viewProtocolToRouterMap, @"Didn't register any protocol yet.");
    NSCAssert(_assert_isLoadFinished, @"Only get router after app did finish launch.");
#if ZIKVIEWROUTER_CHECK
    NSCAssert(g_routableViews, @"g_routableViews should be initialized.");
    NSCAssert(ZIKRouter_subclassesComformToProtocol(g_routableViews, viewProtocol).count <= 1, @"More than one view class conforms to this protocol, please use a unique protocol only conformed by the view class you want to fetch.");
#endif
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!g_viewProtocolToRouterMap) {
            g_viewProtocolToRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
        }
    });
    if (!viewProtocol) {
        [ZIKViewRouter _o_callbackError_invalidProtocolWithAction:@selector(init) errorDescription:@"ZIKViewRouterForView() viewProtocol is nil"];
        return nil;
    }
    
    Class routerClass = CFDictionaryGetValue(g_viewProtocolToRouterMap, (__bridge const void *)(viewProtocol));
    if (routerClass) {
        return routerClass;
    }
    [ZIKViewRouter _o_callbackError_invalidProtocolWithAction:@selector(init)
                                             errorDescription:@"Didn't find view router for view protocol: %@, this protocol was not registered.",viewProtocol];
    NSCAssert1(NO, @"Didn't find view router for view protocol: %@, this protocol was not registered.",viewProtocol);
    return nil;
}

_Nullable Class ZIKViewRouterForConfig(Protocol<ZIKViewConfigRoutable> *configProtocol) {
    NSCParameterAssert(configProtocol);
    NSCAssert(g_configProtocolToRouterMap, @"Didn't register any protocol yet.");
    NSCAssert(_assert_isLoadFinished, @"Only get router after app did finish launch.");
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!g_configProtocolToRouterMap) {
            g_configProtocolToRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
        }
    });
    if (!configProtocol) {
        [ZIKViewRouter _o_callbackError_invalidProtocolWithAction:@selector(init) errorDescription:@"ZIKViewRouterForConfig() configProtocol is nil"];
        return nil;
    }
    
    Class routerClass = CFDictionaryGetValue(g_configProtocolToRouterMap, (__bridge const void *)(configProtocol));
    if (routerClass) {
        return routerClass;
    }
    
    [ZIKViewRouter _o_callbackError_invalidProtocolWithAction:@selector(init)
                                             errorDescription:@"Didn't find view router for config protocol: %@, this protocol was not registered.",configProtocol];
    NSCAssert1(NO, @"Didn't find view router for config protocol: %@, this protocol was not registered.",configProtocol);
    return nil;
}

#pragma mark Initialize

- (nullable instancetype)initWithConfiguration:(__kindof ZIKViewRouteConfiguration *)configuration removeConfiguration:(nullable __kindof ZIKViewRemoveConfiguration *)removeConfiguration {
    NSParameterAssert([configuration isKindOfClass:[ZIKViewRouteConfiguration class]]);
    
    if (!removeConfiguration) {
        removeConfiguration = [[self class] defaultRemoveConfiguration];
    }
    if (self = [super initWithConfiguration:configuration removeConfiguration:removeConfiguration]) {
        if (![[self class] _o_validateRouteTypeInConfiguration:configuration]) {
            [self _o_callbackError_unsupportTypeWithAction:@selector(init)
                                          errorDescription:@"%@ doesn't support routeType:%ld, supported types: %@",[self class],configuration.routeType,[[self class] supportedRouteTypes]];
            NSAssert(NO, @"%@ doesn't support routeType:%ld, supported types: %@",[self class],(long)configuration.routeType,[[self class] supportedRouteTypes]);
            return nil;
        } else if (![[self class] _o_validateRouteSourceNotMissedInConfiguration:configuration] ||
                   ![[self class] _o_validateRouteSourceClassInConfiguration:configuration]) {
            [self _o_callbackError_invalidSourceWithAction:@selector(init)
                                          errorDescription:@"Source: (%@) is invalid for configuration: (%@)",configuration.source,configuration];
            NSAssert(NO, @"Source: (%@) is invalid for configuration: (%@)",configuration.source,configuration);
            return nil;
        } else {
            ZIKViewRouteType type = configuration.routeType;
            if (type == ZIKViewRouteTypePerformSegue) {
                if (![[self class] _o_validateSegueInConfiguration:configuration]) {
                    [self _o_callbackError_invalidConfigurationWithAction:@selector(performRoute)
                                                         errorDescription:@"SegueConfiguration : (%@) was invalid",configuration.segueConfiguration];
                    NSAssert(NO, @"SegueConfiguration : (%@) was invalid",configuration.segueConfiguration);
                    return nil;
                }
            } else if (type == ZIKViewRouteTypePresentAsPopover) {
                if (![[self class] _o_validatePopoverInConfiguration:configuration]) {
                    [self _o_callbackError_invalidConfigurationWithAction:@selector(performRoute)
                                                         errorDescription:@"PopoverConfiguration : (%@) was invalid",configuration.popoverConfiguration];
                    NSAssert(NO, @"PopoverConfiguration : (%@) was invalid",configuration.popoverConfiguration);
                    return nil;
                }
            } else if (type == ZIKViewRouteTypeCustom) {
                BOOL valid = YES;
                if ([[self class] respondsToSelector:@selector(validateCustomRouteConfiguration:removeConfiguration:)]) {
                    valid = [[self class] validateCustomRouteConfiguration:configuration removeConfiguration:removeConfiguration];
                }
                if (!valid) {
                    [self _o_callbackError_invalidConfigurationWithAction:@selector(performRoute)
                                                         errorDescription:@"Configuration : (%@) was invalid for ZIKViewRouteTypeCustom",configuration];
                    NSAssert(NO, @"Configuration : (%@) was invalid for ZIKViewRouteTypeCustom",configuration);
                    return nil;
                }
            }
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_o_handleWillPerformRouteNotification:) name:kZIKViewRouteWillPerformRouteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_o_handleDidPerformRouteNotification:) name:kZIKViewRouteDidPerformRouteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_o_handleWillRemoveRouteNotification:) name:kZIKViewRouteWillRemoveRouteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_o_handleDidRemoveRouteNotification:) name:kZIKViewRouteDidRemoveRouteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_o_handleRemoveRouteCanceledNotification:) name:kZIKViewRouteRemoveRouteCanceledNotification object:nil];
    }
    return self;
}

+ (instancetype)routerFromView:(UIView *)destination source:(UIView *)source {
    NSParameterAssert(destination);
    NSParameterAssert(source);
    if (!destination || !source) {
        return nil;
    }
    NSAssert([self _o_validateSupportedRouteTypesForUIView], @"Router for UIView only suppourts ZIKViewRouteTypeAddAsSubview, ZIKViewRouteTypeGetDestination and ZIKViewRouteTypeCustom, override +supportedRouteTypes in your router.");
    
    ZIKViewRouteConfiguration *configuration = [self defaultRouteConfiguration];
    configuration.autoCreated = YES;
    configuration.routeType = ZIKViewRouteTypeAddAsSubview;
    configuration.source = source;
    ZIKViewRouter *router = [[self alloc] initWithConfiguration:configuration removeConfiguration:nil];
    [router attachDestination:destination];
    
    return router;
}

+ (instancetype)routerFromSegueIdentifier:(NSString *)identifier sender:(nullable id)sender destination:(UIViewController *)destination source:(UIViewController *)source {
    NSParameterAssert([destination isKindOfClass:[UIViewController class]]);
    NSParameterAssert([source isKindOfClass:[UIViewController class]]);
    
    ZIKViewRouteConfiguration *configuration = [self defaultRouteConfiguration];
    configuration.autoCreated = YES;
    configuration.routeType = ZIKViewRouteTypePerformSegue;
    configuration.source = source;
    configuration.configureSegue(^(ZIKViewRouteSegueConfiguration * _Nonnull segueConfig) {
        segueConfig.identifier = identifier;
        segueConfig.sender = sender;
    });
    
    ZIKViewRouter *router = [[self alloc] initWithConfiguration:configuration removeConfiguration:nil];
    [router attachDestination:destination];
    return router;

}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark

- (void)notifyRouteState:(ZIKRouterState)state {
    if (state == ZIKRouterStateRemoved) {
        self.realRouteType = ZIKViewRouteRealTypeUnknown;
        self.prepared = NO;
    }
    [super notifyRouteState:state];
}

+ (BOOL)supportRouteType:(ZIKViewRouteType)type {
    NSArray<NSNumber *> *supportedRouteTypes = [self supportedRouteTypes];
    if ([supportedRouteTypes containsObject:@(type)]) {
        return YES;
    }
    return NO;
}

#pragma mark ZIKViewRouterProtocol

+ (void)registerRoutableDestination {
    NSAssert2(NO, @"subclass(%@) must implement +registerRoutableDestination to register destination with %@",self,self);
}

+ (NSArray<NSNumber *> *)supportedRouteTypes {
    return kDefaultRouteTypesForViewController;
}

- (id)destinationWithConfiguration:(__kindof ZIKViewRouteConfiguration *)configuration {
    NSAssert(NO, @"Router: %@ not conforms to ZIKViewRouterProtocol！",[self class]);
    return nil;
}

+ (BOOL)destinationPrepared:(id)destination {
    NSAssert(self != [ZIKViewRouter class], @"Check destination prepared with it's router.");
    return YES;
}

- (void)prepareDestination:(id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    NSAssert(self != [ZIKViewRouter class], @"Prepare destination with it's router.");
}

- (void)didFinishPrepareDestination:(id)destination configuration:(nonnull __kindof ZIKViewRouteConfiguration *)configuration {
    NSAssert([self class] != [ZIKViewRouter class] ||
             configuration.routeType == ZIKViewRouteTypePerformSegue,
             @"Only ZIKViewRouteTypePerformSegue can use ZIKViewRouter class to perform route, otherwise, use a subclass of ZIKViewRouter for destination.");
}

+ (ZIKViewRouteConfiguration *)defaultRouteConfiguration {
    return [ZIKViewRouteConfiguration new];
}

+ (__kindof ZIKViewRemoveConfiguration *)defaultRemoveConfiguration {
    return [ZIKViewRemoveConfiguration new];
}

+ (BOOL)completeSynchronously {
    return YES;
}

#pragma mark Perform Route

- (BOOL)canPerform {
    return [self _o_canPerformWithErrorMessage:NULL];
}

- (BOOL)canPerformCustomRoute {
    return NO;
}

- (BOOL)_o_canPerformWithErrorMessage:(NSString **)message {
    ZIKRouterState state = self.state;
    if (state == ZIKRouterStateRouting) {
        if (message) {
            *message = @"Router is routing.";
        }
        return NO;
    }
    if (state == ZIKRouterStateRemoving) {
        if (message) {
            *message = @"Router is removing.";
        }
        return NO;
    }
    if (state == ZIKRouterStateRouted) {
        if (message) {
            *message = @"Router is routed, can't perform route after remove.";
        }
        return NO;
    }
    
    ZIKViewRouteType type = self._nocopy_configuration.routeType;
    if (type == ZIKViewRouteTypeCustom) {
        BOOL canPerform = [self canPerformCustomRoute];
        if (canPerform && message) {
            *message = @"Can't perform custom route.";
        }
        return canPerform;
    }
    id source = self._nocopy_configuration.source;
    if (!source) {
        if (type != ZIKViewRouteTypeGetDestination) {
            if (message) {
                *message = @"Source was dealloced.";
            }
            return NO;
        }
    }
    
    id destination = self.destination;
    switch (type) {
        case ZIKViewRouteTypePush: {
            if (![[self class] _o_validateSourceInNavigationStack:source]) {
                if (message) {
                    *message = [NSString stringWithFormat:@"Source (%@) is not in any navigation stack now, can't push.",source];
                }
                return NO;
            }
            if (destination && ![[self class] _o_validateDestination:destination notInNavigationStackOfSource:source]) {
                if (message) {
                    *message = [NSString stringWithFormat:@"Destination (%@) is already in source (%@)'s navigation stack, can't push.",destination,source];
                }
                return NO;
            }
            break;
        }
            
        case ZIKViewRouteTypePresentModally:
        case ZIKViewRouteTypePresentAsPopover: {
            if (![[self class] _o_validateSourceNotPresentedAnyView:source]) {
                if (message) {
                    *message = [NSString stringWithFormat:@"Source (%@) presented another view controller (%@), can't present destination now.",source,[source presentedViewController]];
                }
                return NO;
            }
            break;
        }
        default:
            break;
    }
    return YES;
}

///override superclass
- (void)performRouteWithSuccessHandler:(void(^)(void))performerSuccessHandler
                 performerErrorHandler:(void(^)(SEL routeAction, NSError *error))performerErrorHandler {
    ZIKRouterState state = self.state;
    if (state == ZIKRouterStateRouting) {
        [self _o_callbackError_errorCode:ZIKViewRouteErrorOverRoute
                            errorHandler:performerErrorHandler
                                  action:@selector(performRoute)
                        errorDescription:@"%@ is routing, can't perform route again",self];
        return;
    } else if (state == ZIKRouterStateRouted) {
        [self _o_callbackError_actionFailedWithAction:@selector(performRoute)
                                     errorDescription:@"%@ 's state is routed, can't perform route again",self];
        return;
    } else if (state == ZIKRouterStateRemoving) {
        [self _o_callbackError_errorCode:ZIKViewRouteErrorActionFailed
                            errorHandler:performerErrorHandler
                                  action:@selector(performRoute)
                        errorDescription:@"%@ 's state is removing, can't perform route again",self];
        return;
    }
    [super performRouteWithSuccessHandler:performerSuccessHandler performerErrorHandler:performerErrorHandler];
}

///override superclass
- (void)performWithConfiguration:(__kindof ZIKViewRouteConfiguration *)configuration {
    NSParameterAssert(configuration);
    NSAssert([[[self class] defaultRouteConfiguration] isKindOfClass:[configuration class]], @"When using custom configuration class，you must override +defaultRouteConfiguration to return your custom configuration instance.");
    
    if (configuration.routeType == ZIKViewRouteTypePerformSegue) {
        [self performRouteOnDestination:nil configuration:configuration];
        return;
    }
    
    if ([NSThread isMainThread]) {
        [super performWithConfiguration:configuration];
    } else {
        NSAssert(NO, @"%@ performRoute should only be called in main thread!",self);
        dispatch_async(dispatch_get_main_queue(), ^{
            [super performWithConfiguration:configuration];
        });
    }
}

+ (__kindof ZIKViewRouter *)performWithSource:(id)source routeType:(ZIKViewRouteType)routeType {
    return [self performWithConfigure:^(__kindof ZIKViewRouteConfiguration * _Nonnull config) {
        config.source = source;
        config.routeType = routeType;
    }];
}

+ (nullable __kindof ZIKViewRouter *)performOnDestination:(id)destination
                                                configure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder
                                          removeConfigure:(void(NS_NOESCAPE ^ _Nullable)( __kindof ZIKViewRemoveConfiguration *config))removeConfigBuilder {
    if (![destination conformsToProtocol:@protocol(ZIKRoutableView)]) {
        [[self class] _o_callbackGlobalErrorHandlerWithRouter:nil action:@selector(init) error:[[self class] errorWithCode:ZIKViewRouteErrorInvalidConfiguration localizedDescription:[NSString stringWithFormat:@"Perform route on invalid destination: (%@)",destination]]];
        NSAssert1(NO, @"Perform route on invalid destination: (%@)",destination);
        return nil;
    }
    CFMutableSetRef routers = (CFMutableSetRef)CFDictionaryGetValue(g_viewToRoutersMap, (__bridge const void *)([destination class]));
    BOOL valid = YES;
    if (!routers) {
        valid = NO;
    } else {
        NSSet *registeredRouters = (__bridge NSSet *)(routers);
        if (![registeredRouters containsObject:[self class]]) {
            valid = NO;
        }
    }
    if (!valid) {
        [[self class] _o_callbackGlobalErrorHandlerWithRouter:nil action:@selector(init) error:[[self class] errorWithCode:ZIKViewRouteErrorInvalidConfiguration localizedDescription:[NSString stringWithFormat:@"Perform route on invalid destination (%@), this view is not registered with this router (%@)",destination,self]]];
        NSAssert2(NO, @"Perform route on invalid destination (%@), this view is not registered with this router (%@)",destination,self);
        return nil;
    }
    ZIKViewRouter *router = [[self alloc] initWithConfigure:configBuilder removeConfigure:removeConfigBuilder];
    NSAssert(router._nocopy_configuration.routeType != ZIKViewRouteTypeGetDestination, @"It's meaningless to get destination when you already offer a prepared destination.");
    [router attachDestination:destination];
    [router performRouteOnDestination:destination configuration:router._nocopy_configuration];
    return router;
}

+ (nullable __kindof ZIKViewRouter *)performOnDestination:(id)destination
                                                configure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder {
    return [self performOnDestination:destination configure:configBuilder removeConfigure:nil];
}

+ (__kindof ZIKViewRouter *)performOnDestination:(id)destination source:(id<ZIKViewRouteSource>)source routeType:(ZIKViewRouteType)routeType {
    return [self performOnDestination:destination configure:^(__kindof ZIKViewRouteConfiguration * _Nonnull config) {
        config.source = source;
        config.routeType = routeType;
    } removeConfigure:nil];
}

+ (nullable __kindof ZIKViewRouter *)prepareDestination:(id)destination
                                              configure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder
                                        removeConfigure:(void(NS_NOESCAPE ^ _Nullable)( __kindof ZIKViewRemoveConfiguration *config))removeConfigBuilder {
    if (![destination conformsToProtocol:@protocol(ZIKRoutableView)]) {
        [[self class] _o_callbackGlobalErrorHandlerWithRouter:nil action:@selector(init) error:[[self class] errorWithCode:ZIKViewRouteErrorInvalidConfiguration localizedDescription:[NSString stringWithFormat:@"Prepare for invalid destination: (%@)",destination]]];
        NSAssert1(NO, @"Prepare for invalid destination: (%@)",destination);
        return nil;
    }
    CFMutableSetRef routers = (CFMutableSetRef)CFDictionaryGetValue(g_viewToRoutersMap, (__bridge const void *)([destination class]));
    BOOL valid = YES;
    if (!routers) {
        valid = NO;
    } else {
        NSSet *registeredRouters = (__bridge NSSet *)(routers);
        if (![registeredRouters containsObject:[self class]]) {
            valid = NO;
        }
    }
    if (!valid) {
        [[self class] _o_callbackGlobalErrorHandlerWithRouter:nil action:@selector(init) error:[[self class] errorWithCode:ZIKViewRouteErrorInvalidConfiguration localizedDescription:[NSString stringWithFormat:@"Prepare for invalid destination (%@), this view is not registered with this router (%@)",destination,self]]];
        NSAssert2(NO, @"Prepare for invalid destination (%@), this view is not registered with this router (%@)",destination,self);
        return nil;
    }
    ZIKViewRouter *router = [[self alloc] initWithConfigure:configBuilder removeConfigure:removeConfigBuilder];
    [router attachDestination:destination];
    [router prepareForPerformRouteOnDestination:destination];
    [(id)destination setZIK_routeTypeFromRouter:@(ZIKViewRouteTypeGetDestination)];
    return router;
}

+ (nullable __kindof ZIKViewRouter *)prepareDestination:(id)destination
                                              configure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder {
    return [self prepareDestination:destination configure:configBuilder removeConfigure:nil];
}

- (void)performRouteOnDestination:(nullable id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    NSAssert(!destination || ZIKViewRouterForRegisteredView([destination class])  == [self class], @"Bad impletmentation ,destination's class should be registered with this view router's class by macro RegisterRoutableView in it's router.");
    
    [self notifyRouteState:ZIKRouterStateRouting];
    
    if (!destination &&
        [[self class] _o_validateDestinationShouldExistInConfiguration:configuration]) {
        [self notifyRouteState:ZIKRouterStateRouteFailed];
        [self _o_callbackError_actionFailedWithAction:@selector(performRoute) errorDescription:@"-destinationWithConfiguration: of router: %@ return nil when performRoute, configuration may be invalid or router has bad impletmentation in -destinationWithConfiguration. Configuration: %@",[self class],configuration];
        return;
    } else if (![[self class] _o_validateDestinationClass:destination inConfiguration:configuration]) {
        [self notifyRouteState:ZIKRouterStateRouteFailed];
        [self _o_callbackError_actionFailedWithAction:@selector(performRoute) errorDescription:@"Bad impletment in destinationWithConfiguration: of router: %@, invalid destination: %@ !",[self class],destination];
        NSAssert(NO, @"Bad impletment in destinationWithConfiguration: of router: %@, invalid destination: %@ !",[self class],destination);
        return;
    }
    
    if (![[self class] _o_validateRouteSourceNotMissedInConfiguration:configuration]) {
        [self notifyRouteState:ZIKRouterStateRouteFailed];
        [self _o_callbackError_invalidSourceWithAction:@selector(performRoute)
                                      errorDescription:@"Source was dealloced when performRoute on (%@)",self];
        return;
    }
    
    id source = configuration.source;
    ZIKViewRouteType routeType = configuration.routeType;
    switch (routeType) {
        case ZIKViewRouteTypePush:
            [self _o_performPushOnDestination:destination fromSource:source];
            break;
            
        case ZIKViewRouteTypePresentModally:
            [self _o_performPresentModallyOnDestination:destination fromSource:source];
            break;
            
        case ZIKViewRouteTypePresentAsPopover:
            [self _o_performPresentAsPopoverOnDestination:destination fromSource:source popoverConfiguration:configuration.popoverConfiguration];
            break;
            
        case ZIKViewRouteTypeAddAsChildViewController:
            [self _o_performAddChildViewControllerOnDestination:destination fromSource:source];
            break;
            
        case ZIKViewRouteTypePerformSegue:
            [self _o_performSegueWithIdentifier:configuration.segueConfiguration.identifier fromSource:source sender:configuration.segueConfiguration.sender];
            break;
            
        case ZIKViewRouteTypeShow:
            [self _o_performShowOnDestination:destination fromSource:source];
            break;
            
        case ZIKViewRouteTypeShowDetail:
            [self _o_performShowDetailOnDestination:destination fromSource:source];
            break;
            
        case ZIKViewRouteTypeAddAsSubview:
            [self _o_performAddSubviewOnDestination:destination fromSource:source];
            break;
            
        case ZIKViewRouteTypeCustom:
            [self _o_performCustomOnDestination:destination fromSource:source];
            break;
            
        case ZIKViewRouteTypeGetDestination:
            [self _o_performGetDestination:destination fromSource:source];
            break;
    }
}

- (void)_o_performPushOnDestination:(UIViewController *)destination fromSource:(UIViewController *)source {
    NSParameterAssert([destination isKindOfClass:[UIViewController class]]);
    NSParameterAssert([source isKindOfClass:[UIViewController class]]);
    
    if (![[self class] _o_validateSourceInNavigationStack:source]) {
        [self notifyRouteState:ZIKRouterStateRouteFailed];
        [self _o_callbackError_invalidSourceWithAction:@selector(performRoute)
                                      errorDescription:@"Source: (%@) is not in any navigation stack when perform push.",source];
        return;
    }
    if (![[self class] _o_validateDestination:destination notInNavigationStackOfSource:source]) {
        [self notifyRouteState:ZIKRouterStateRouteFailed];
        [self _o_callbackError_overRouteWithAction:@selector(performRoute)
                                  errorDescription:@"Pushing the same view controller instance more than once is not supported. Source: (%@), destination: (%@), viewControllers in navigation stack: (%@)",source,destination,source.navigationController.viewControllers];
        return;
    }
    UIViewController *wrappedDestination = [self _o_wrappedDestination:destination];
    [self beginPerformRoute];
    [destination setZIK_routeTypeFromRouter:@(ZIKViewRouteTypePush)];
    self.realRouteType = ZIKViewRouteRealTypePush;
    [source.navigationController pushViewController:wrappedDestination animated:self._nocopy_configuration.animated];
    [ZIKViewRouter _o_completeWithtransitionCoordinator:source.navigationController.transitionCoordinator
                                   transitionCompletion:^{
        [self endPerformRouteWithSuccess];
    }];
}

- (void)_o_performPresentModallyOnDestination:(UIViewController *)destination fromSource:(UIViewController *)source {
    NSParameterAssert([destination isKindOfClass:[UIViewController class]]);
    NSParameterAssert([source isKindOfClass:[UIViewController class]]);
    
    if (![[self class] _o_validateSourceNotPresentedAnyView:source]) {
        [self notifyRouteState:ZIKRouterStateRouteFailed];
        [self _o_callbackError_invalidSourceWithAction:@selector(performRoute)
                                      errorDescription:@"Warning: Attempt to present %@ on %@ whose view is not in the window hierarchy! %@ already presented %@.",destination,source,source,source.presentedViewController];
        return;
    }
    if (![[self class] _o_validateSourceInWindowHierarchy:source]) {
        [self notifyRouteState:ZIKRouterStateRouteFailed];
        [self _o_callbackError_invalidSourceWithAction:@selector(performRoute)
                                      errorDescription:@"Warning: Attempt to present %@ on %@ whose view is not in the window hierarchy! %@ 's view not in any superview.",destination,source,source];
        return;
    }
    UIViewController *wrappedDestination = [self _o_wrappedDestination:destination];
    [self beginPerformRoute];
    [destination setZIK_routeTypeFromRouter:@(ZIKViewRouteTypePresentModally)];
    self.realRouteType = ZIKViewRouteRealTypePresentModally;
    [source presentViewController:wrappedDestination animated:self._nocopy_configuration.animated completion:^{
        [self endPerformRouteWithSuccess];
    }];
}

- (void)_o_performPresentAsPopoverOnDestination:(UIViewController *)destination fromSource:(UIViewController *)source popoverConfiguration:(ZIKViewRoutePopoverConfiguration *)popoverConfiguration {
    NSParameterAssert([destination isKindOfClass:[UIViewController class]]);
    NSParameterAssert([source isKindOfClass:[UIViewController class]]);
    
    if (!popoverConfiguration) {
        [self notifyRouteState:ZIKRouterStateRouteFailed];
        [self _o_callbackError_invalidConfigurationWithAction:@selector(performRoute)
                                             errorDescription:@"Miss popoverConfiguration when perform presentAsPopover on source: (%@), router: (%@).",source,self];
        return;
    }
    if (![[self class] _o_validateSourceNotPresentedAnyView:source]) {
        [self notifyRouteState:ZIKRouterStateRouteFailed];
        [self _o_callbackError_invalidSourceWithAction:@selector(performRoute)
                                      errorDescription:@"Warning: Attempt to present %@ on %@ whose view is not in the window hierarchy! %@ already presented %@.",destination,source,source,source.presentedViewController];
        return;
    }
    if (![[self class] _o_validateSourceInWindowHierarchy:source]) {
        [self notifyRouteState:ZIKRouterStateRouteFailed];
        [self _o_callbackError_invalidSourceWithAction:@selector(performRoute)
                                      errorDescription:@"Warning: Attempt to present %@ on %@ whose view is not in the window hierarchy! %@ 's view not in any superview.",destination,source,source];
        return;
    }
    
    ZIKViewRouteRealType realRouteType = ZIKViewRouteRealTypePresentAsPopover;
    ZIKViewRouteConfiguration *configuration = self._nocopy_configuration;
    
    if (NSClassFromString(@"UIPopoverPresentationController")) {
        destination.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *popoverPresentationController = destination.popoverPresentationController;
        
        if (popoverConfiguration.barButtonItem) {
            popoverPresentationController.barButtonItem = popoverConfiguration.barButtonItem;
        } else if (popoverConfiguration.sourceView) {
            popoverPresentationController.sourceView = popoverConfiguration.sourceView;
            if (popoverConfiguration.sourceRectConfiged) {
                popoverPresentationController.sourceRect = popoverConfiguration.sourceRect;
            }
        } else {
            [self notifyRouteState:ZIKRouterStateRouteFailed];
            [self _o_callbackError_invalidConfigurationWithAction:@selector(performRoute)
                                                 errorDescription:@"Invalid popoverConfiguration: (%@) when perform presentAsPopover on source: (%@), router: (%@).",popoverConfiguration,source,self];
            
            return;
        }
        if (popoverConfiguration.delegate) {
            NSAssert([popoverConfiguration.delegate conformsToProtocol:@protocol(UIPopoverPresentationControllerDelegate)], @"delegate should conforms to UIPopoverPresentationControllerDelegate");
            popoverPresentationController.delegate = popoverConfiguration.delegate;
        }
        if (popoverConfiguration.passthroughViews) {
            popoverPresentationController.passthroughViews = popoverConfiguration.passthroughViews;
        }
        if (popoverConfiguration.backgroundColor) {
            popoverPresentationController.backgroundColor = popoverConfiguration.backgroundColor;
        }
        if (popoverConfiguration.popoverLayoutMarginsConfiged) {
            popoverPresentationController.popoverLayoutMargins = popoverConfiguration.popoverLayoutMargins;
        }
        if (popoverConfiguration.popoverBackgroundViewClass) {
            popoverPresentationController.popoverBackgroundViewClass = popoverConfiguration.popoverBackgroundViewClass;
        }
        
        UIViewController *wrappedDestination = [self _o_wrappedDestination:destination];
        [self beginPerformRoute];
        self.realRouteType = realRouteType;
        [destination setZIK_routeTypeFromRouter:@(ZIKViewRouteTypePresentAsPopover)];
        [source presentViewController:wrappedDestination animated:configuration.animated completion:^{
            [self endPerformRouteWithSuccess];
        }];
        return;
    }
    
    //iOS7 iPad
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UIViewController *wrappedDestination = [self _o_wrappedDestination:destination];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
        UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:wrappedDestination];
#pragma clang diagnostic pop
        objc_setAssociatedObject(destination, "zikrouter_popover", popover, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        if (popoverConfiguration.delegate) {
            NSAssert([popoverConfiguration.delegate conformsToProtocol:@protocol(UIPopoverControllerDelegate)], @"delegate should conforms to UIPopoverControllerDelegate");
            popover.delegate = (id)popoverConfiguration.delegate;
        }
        
        if (popoverConfiguration.passthroughViews) {
            popover.passthroughViews = popoverConfiguration.passthroughViews;
        }
        if (popoverConfiguration.backgroundColor) {
            popover.backgroundColor = popoverConfiguration.backgroundColor;
        }
        if (popoverConfiguration.popoverLayoutMarginsConfiged) {
            popover.popoverLayoutMargins = popoverConfiguration.popoverLayoutMargins;
        }
        if (popoverConfiguration.popoverBackgroundViewClass) {
            popover.popoverBackgroundViewClass = popoverConfiguration.popoverBackgroundViewClass;
        }
        self.routingFromInternal = YES;
        [self prepareForPerformRouteOnDestination:destination];
        [destination setZIK_routeTypeFromRouter:@(ZIKViewRouteTypePresentAsPopover)];
        if (popoverConfiguration.barButtonItem) {
            self.realRouteType = realRouteType;
            [ZIKViewRouter AOP_notifyAll_router:self willPerformRouteOnDestination:destination fromSource:source];
            [popover presentPopoverFromBarButtonItem:popoverConfiguration.barButtonItem permittedArrowDirections:popoverConfiguration.permittedArrowDirections animated:configuration.animated];
        } else if (popoverConfiguration.sourceView) {
            self.realRouteType = realRouteType;
            [ZIKViewRouter AOP_notifyAll_router:self willPerformRouteOnDestination:destination fromSource:source];
            [popover presentPopoverFromRect:popoverConfiguration.sourceRect inView:popoverConfiguration.sourceView permittedArrowDirections:popoverConfiguration.permittedArrowDirections animated:configuration.animated];
        } else {
            [self notifyRouteState:ZIKRouterStateRouteFailed];
            [self _o_callbackError_invalidConfigurationWithAction:@selector(performRoute)
                                                 errorDescription:@"Invalid popoverConfiguration: (%@) when perform presentAsPopover on source: (%@), router: (%@).",popoverConfiguration,source,self];
            self.routingFromInternal = NO;
            return;
        }
        
        [ZIKViewRouter _o_completeWithtransitionCoordinator:popover.contentViewController.transitionCoordinator
                                       transitionCompletion:^{
            [self endPerformRouteWithSuccess];
        }];
        return;
    }
    
    //iOS7 iPhone
    UIViewController *wrappedDestination = [self _o_wrappedDestination:destination];
    [self beginPerformRoute];
    [destination setZIK_routeTypeFromRouter:@(ZIKViewRouteTypePresentAsPopover)];
    self.realRouteType = ZIKViewRouteRealTypePresentModally;
    [source presentViewController:wrappedDestination animated:configuration.animated completion:^{
        [self endPerformRouteWithSuccess];
    }];
}

- (void)_o_performSegueWithIdentifier:(NSString *)identifier fromSource:(UIViewController *)source sender:(nullable id)sender {
    
    ZIKViewRouteConfiguration *configuration = self._nocopy_configuration;
    ZIKViewRouteSegueConfiguration *segueConfig = configuration.segueConfiguration;
    segueConfig.segueSource = nil;
    segueConfig.segueDestination = nil;
    segueConfig.destinationStateBeforeRoute = nil;
    
    self.routingFromInternal = YES;
    //Set nil in -ZIKViewRouter_hook_prepareForSegue:sender:
    [source setZIK_sourceViewRouter:self];
    
    /*
     Hook UIViewController's -prepareForSegue:sender: and UIStoryboardSegue's -perform to prepare and complete
     Call -prepareForPerformRouteOnDestination in -ZIKViewRouter_hook_prepareForSegue:sender:
     Call +AOP_notifyAll_router:willPerformRouteOnDestination: in -ZIKViewRouter_hook_prepareForSegue:sender:
     Call -notifyRouteState:ZIKRouterStateRouted
          -notifyPerformRouteSuccessWithDestination:
          +AOP_notifyAll_router:didPerformRouteOnDestination:
     in -ZIKViewRouter_hook_seguePerform
     */
    [source performSegueWithIdentifier:identifier sender:sender];
    
    UIViewController *destination = segueConfig.segueDestination;//segueSource and segueDestination was set in -ZIKViewRouter_hook_prepareForSegue:sender:
    
    /*When perform a unwind segue, if destination's -canPerformUnwindSegueAction:fromViewController:withSender: return NO, here will be nil
     This inspection relies on synchronized call -prepareForSegue:sender: and -canPerformUnwindSegueAction:fromViewController:withSender: in -performSegueWithIdentifier:sender:
     */
    if (!destination) {
        [self notifyRouteState:ZIKRouterStateRouteFailed];
        [self _o_callbackError_segueNotPerformedWithAction:@selector(performRoute) errorDescription:@"destination can't perform segue identitier:%@ now",identifier];
        self.routingFromInternal = NO;
        return;
    }
    NSParameterAssert([destination isKindOfClass:[UIViewController class]]);
    NSParameterAssert([source isKindOfClass:[UIViewController class]]);
    NSAssert(![source ZIK_sourceViewRouter], @"Didn't set sourceViewRouter to nil in -ZIKViewRouter_hook_prepareForSegue:sender:, router will not be dealloced before source was dealloced");
}

- (void)_o_performShowOnDestination:(UIViewController *)destination fromSource:(UIViewController *)source {
    NSParameterAssert([destination isKindOfClass:[UIViewController class]]);
    NSParameterAssert([source isKindOfClass:[UIViewController class]]);
    [destination setZIK_routeTypeFromRouter:@(ZIKViewRouteTypeShow)];
    UIViewController *wrappedDestination = [self _o_wrappedDestination:destination];
    ZIKPresentationState *destinationStateBeforeRoute = [destination ZIK_presentationState];
    [self beginPerformRoute];
    
    [source showViewController:wrappedDestination sender:self._nocopy_configuration.sender];
    
    id<UIViewControllerTransitionCoordinator> transitionCoordinator = [source ZIK_currentTransitionCoordinator];
    if (!transitionCoordinator) {
        transitionCoordinator = [destination ZIK_currentTransitionCoordinator];
    }
    [ZIKViewRouter _o_completeRouter:self
      analyzeRouteTypeForDestination:destination
                              source:source
         destinationStateBeforeRoute:destinationStateBeforeRoute
               transitionCoordinator:transitionCoordinator
                          completion:^{
                              [self endPerformRouteWithSuccess];
                          }];
}

- (void)_o_performShowDetailOnDestination:(UIViewController *)destination fromSource:(UIViewController *)source {
    NSParameterAssert([destination isKindOfClass:[UIViewController class]]);
    NSParameterAssert([source isKindOfClass:[UIViewController class]]);
    [destination setZIK_routeTypeFromRouter:@(ZIKViewRouteTypeShowDetail)];
    UIViewController *wrappedDestination = [self _o_wrappedDestination:destination];
    ZIKPresentationState *destinationStateBeforeRoute = [destination ZIK_presentationState];
    [self beginPerformRoute];
    
    [source showDetailViewController:wrappedDestination sender:self._nocopy_configuration.sender];
    
    id<UIViewControllerTransitionCoordinator> transitionCoordinator = [source ZIK_currentTransitionCoordinator];
    if (!transitionCoordinator) {
        transitionCoordinator = [destination ZIK_currentTransitionCoordinator];
    }
    [ZIKViewRouter _o_completeRouter:self
      analyzeRouteTypeForDestination:destination
                              source:source
         destinationStateBeforeRoute:destinationStateBeforeRoute
               transitionCoordinator:transitionCoordinator
                          completion:^{
                              [self endPerformRouteWithSuccess];
                          }];
}

- (void)_o_performAddChildViewControllerOnDestination:(UIViewController *)destination fromSource:(UIViewController *)source {
    NSParameterAssert([destination isKindOfClass:[UIViewController class]]);
    NSParameterAssert([source isKindOfClass:[UIViewController class]]);
    UIViewController *wrappedDestination = [self _o_wrappedDestination:destination];
//    [self beginPerformRoute];
    self.routingFromInternal = YES;
    [self prepareForPerformRouteOnDestination:destination];
    [destination setZIK_routeTypeFromRouter:@(ZIKViewRouteTypeAddAsChildViewController)];
    [source addChildViewController:wrappedDestination];
    
//    self.realRouteType = ZIKViewRouteRealTypeAddAsChildViewController;
    self.realRouteType = ZIKViewRouteRealTypeUnknown;
//    [self endPerformRouteWithSuccess];
    [self notifyRouteState:ZIKRouterStateRouted];
    self.routingFromInternal = NO;
    [self notifyPerformRouteSuccessWithDestination:destination];
}

- (void)_o_performAddSubviewOnDestination:(UIView *)destination fromSource:(UIView *)source {
    NSParameterAssert([destination isKindOfClass:[UIView class]]);
    NSParameterAssert([source isKindOfClass:[UIView class]]);
    [self beginPerformRoute];
    [destination setZIK_routeTypeFromRouter:@(ZIKViewRouteTypeAddAsSubview)];
    
    [source addSubview:destination];
    
    self.realRouteType = ZIKViewRouteRealTypeAddAsSubview;
    [self endPerformRouteWithSuccess];
}

- (void)_o_performCustomOnDestination:(id)destination fromSource:(id)source {
    [destination setZIK_routeTypeFromRouter:@(ZIKViewRouteTypeCustom)];
    self.realRouteType = ZIKViewRouteRealTypeCustom;
    if ([self respondsToSelector:@selector(performCustomRouteOnDestination:fromSource:configuration:)]) {
        [self performCustomRouteOnDestination:destination fromSource:source configuration:self._nocopy_configuration];
    } else {
        [self notifyRouteState:ZIKRouterStateRouteFailed];
        [self _o_callbackError_actionFailedWithAction:@selector(performRoute) errorDescription:@"Perform custom route but router(%@) didn't implement -performCustomRouteOnDestination:fromSource:configuration:",[self class]];
        NSAssert(NO, @"Perform custom route but router(%@) didn't implement -performCustomRouteOnDestination:fromSource:configuration:",[self class]);
    }
}

- (void)_o_performGetDestination:(id)destination fromSource:(id)source {
    [destination setZIK_routeTypeFromRouter:@(ZIKViewRouteTypeGetDestination)];
    self.routingFromInternal = YES;
    [self prepareForPerformRouteOnDestination:destination];
    self.stateBeforeRoute = [destination ZIK_presentationState];
    self.realRouteType = ZIKViewRouteRealTypeUnknown;
    [self notifyRouteState:ZIKRouterStateRouted];
    self.routingFromInternal = NO;
    [self notifyPerformRouteSuccessWithDestination:destination];
}

- (UIViewController *)_o_wrappedDestination:(UIViewController *)destination {
    self.container = nil;
    ZIKViewRouteConfiguration *configuration = self._nocopy_configuration;
    if (!configuration.containerWrapper) {
        return destination;
    }
    UIViewController<ZIKViewRouteContainer> *container = configuration.containerWrapper(destination);
    
    NSString *errorDescription;
    if (!container) {
        errorDescription = @"container is nil";
    } else if ([container isKindOfClass:[UINavigationController class]]) {
        if (configuration.routeType == ZIKViewRouteTypePush) {
            errorDescription = [NSString stringWithFormat:@"navigationController:(%@) can't be pushed into another navigationController",container];
        } else if (configuration.routeType == ZIKViewRouteTypeShow
                   && [configuration.source isKindOfClass:[UIViewController class]]
                   && [(UIViewController *)configuration.source navigationController]) {
            errorDescription = [NSString stringWithFormat:@"navigationController:(%@) can't be pushed into another navigationController",container];
        } else if (configuration.routeType == ZIKViewRouteTypeShowDetail
                   && [configuration.source isKindOfClass:[UIViewController class]]
                   && [(UIViewController *)configuration.source splitViewController].isCollapsed &&
                   [[[(UIViewController *)configuration.source splitViewController].viewControllers firstObject] isKindOfClass:[UINavigationController class]]) {
            errorDescription = [NSString stringWithFormat:@"navigationController:(%@) can't be pushed into another navigationController",container];
        } else if ([[(UINavigationController *)container viewControllers] firstObject] != destination) {
            errorDescription = [NSString stringWithFormat:@"container:(%@) must set destination as root view controller, destination:(%@), container's viewcontrollers:(%@)",container,destination,[(UINavigationController *)container viewControllers]];
        }
    } else if ([container isKindOfClass:[UITabBarController class]]) {
        if (![[(UITabBarController *)container viewControllers] containsObject:destination]) {
            errorDescription = [NSString stringWithFormat:@"container:(%@) must contains destination in it's viewControllers, destination:(%@), container's viewcontrollers:(%@)",container,destination,[(UITabBarController *)container viewControllers]];
        }
    } else if ([container isKindOfClass:[UISplitViewController class]]) {
        if (configuration.routeType == ZIKViewRouteTypePush) {
            errorDescription = [NSString stringWithFormat:@"Split View Controllers cannot be pushed to a Navigation Controller %@",destination];
        } else if (configuration.routeType == ZIKViewRouteTypeShow
                   && [configuration.source isKindOfClass:[UIViewController class]]
                   && [(UIViewController *)configuration.source navigationController]) {
            errorDescription = [NSString stringWithFormat:@"Split View Controllers cannot be pushed to a Navigation Controller %@",destination];
        } else if (configuration.routeType == ZIKViewRouteTypeShowDetail
                   && [configuration.source isKindOfClass:[UIViewController class]]
                   && [(UIViewController *)configuration.source splitViewController].isCollapsed &&
                   [[[(UIViewController *)configuration.source splitViewController].viewControllers firstObject] isKindOfClass:[UINavigationController class]]) {
            errorDescription = [NSString stringWithFormat:@"Split View Controllers cannot be pushed to a Navigation Controller %@",destination];
        } else if (![[(UISplitViewController *)container viewControllers] containsObject:destination]) {
            errorDescription = [NSString stringWithFormat:@"container:(%@) must contains destination in it's viewControllers, destination:(%@), container's viewcontrollers:(%@)",container,destination,[(UITabBarController *)container viewControllers]];
        }
    }
    if (errorDescription) {
        [self _o_callbackError_invalidContainerWithAction:@selector(performRoute) errorDescription:@"containerWrapper returns invalid container: %@",errorDescription];
        NSAssert(NO, @"containerWrapper returns invalid container");
        return destination;
    }
    self.container = container;
    return container;
}

+ (void)_o_prepareForDestinationRoutingFromExternal:(id)destination router:(ZIKViewRouter *)router performer:(nullable id)performer {
    NSParameterAssert(destination);
    NSParameterAssert(router);
    
    if (![[router class] destinationPrepared:destination]) {
        if (!performer) {
            NSString *description = [NSString stringWithFormat:@"Can't find which custom UIView or UIViewController added destination:(%@) as subview, so we can't notify the performer to config the destination. You may add destination to a superview in code directly, and the superview is not a custom class. Please change your code and add subview by a custom view router with ZIKViewRouteTypeAddAsSubview. CallStack: %@",destination, [NSThread callStackSymbols]];
            [self _o_callbackError_invalidPerformerWithAction:@selector(performRoute) errorDescription:description];
            NSAssert(NO, description);
        }
        
        if ([performer respondsToSelector:@selector(prepareForDestinationRoutingFromExternal:configuration:)]) {
            ZIKViewRouteConfiguration *config = router._nocopy_configuration;
            id source = config.source;
            ZIKViewRouteType routeType = config.routeType;
            ZIKViewRouteSegueConfiguration *segueConfig = config.segueConfiguration;
            BOOL handleExternalRoute = config.handleExternalRoute;
            [performer prepareForDestinationRoutingFromExternal:destination configuration:config];
            if (config.source != source) {
                config.source = source;
            }
            if (config.routeType != routeType) {
                config.routeType = routeType;
            }
            if (segueConfig.identifier && ![config.segueConfiguration.identifier isEqualToString:segueConfig.identifier]) {
                config.segueConfiguration = segueConfig;
            }
            if (config.handleExternalRoute != handleExternalRoute) {
                config.handleExternalRoute = handleExternalRoute;
            }
        } else {
            [router _o_callbackError_invalidSourceWithAction:@selector(performRoute) errorDescription:@"Destination %@ 's performer :%@ missed -prepareForDestinationRoutingFromExternal:configuration: to config destination.",destination, performer];
            NSAssert(NO, @"Destination %@ 's performer :%@ missed -prepareForDestinationRoutingFromExternal:configuration: to config destination.",destination, performer);
        }
    }
    
    [router prepareForPerformRouteOnDestination:destination];
}

- (void)prepareForPerformRouteOnDestination:(id)destination {
    ZIKViewRouteConfiguration *configuration = self._nocopy_configuration;
    if (configuration.prepareForRoute) {
        configuration.prepareForRoute(destination);
    }
    if ([self respondsToSelector:@selector(prepareDestination:configuration:)]) {
        [self prepareDestination:destination configuration:configuration];
    }
    if ([self respondsToSelector:@selector(didFinishPrepareDestination:configuration:)]) {
        [self didFinishPrepareDestination:destination configuration:configuration];
    }
}

+ (void)_o_completeRouter:(ZIKViewRouter *)router
analyzeRouteTypeForDestination:(UIViewController *)destination
                   source:(UIViewController *)source
destinationStateBeforeRoute:(ZIKPresentationState *)destinationStateBeforeRoute
    transitionCoordinator:(nullable id <UIViewControllerTransitionCoordinator>)transitionCoordinator
               completion:(void(^)(void))completion {
    [ZIKViewRouter _o_completeWithtransitionCoordinator:transitionCoordinator transitionCompletion:^{
        ZIKPresentationState *destinationStateAfterRoute = [destination ZIK_presentationState];
        if ([destinationStateBeforeRoute isEqual:destinationStateAfterRoute]) {
            router.realRouteType = ZIKViewRouteRealTypeCustom;//maybe ZIKViewRouteRealTypeUnwind, but we just need to know this route can't be remove
            NSLog(@"⚠️Warning: segue(%@) 's destination(%@)'s state was not changed after perform route from source: %@. current state: %@. You may override %@'s -showViewController:sender:/-showDetailViewController:sender:/-presentViewController:animated:completion:/-pushViewController:animated: or use a custom segue, but didn't perform real presentation, or your presentation was async.",self,destination,source,destinationStateAfterRoute,source);
        } else {
            ZIKViewRouteDetailType routeType = [ZIKPresentationState detailRouteTypeFromStateBeforeRoute:destinationStateBeforeRoute stateAfterRoute:destinationStateAfterRoute];
            NSLog(@"Debug: detail route type from source:%@ to destination:%@ is %@",source,destination,[ZIKPresentationState descriptionOfType:routeType]);
            router.realRouteType = [[router class] _o_realRouteTypeFromDetailType:routeType];
        }
        if (completion) {
            completion();
        }
    }];
}

+ (void)_o_completeWithtransitionCoordinator:(nullable id <UIViewControllerTransitionCoordinator>)transitionCoordinator transitionCompletion:(void(^)(void))completion {
    NSParameterAssert(completion);
    //If user use a custom transition from source to destination, such as methods in UIView(UIViewAnimationWithBlocks) or UIView (UIViewKeyframeAnimations), the transitionCoordinator will be nil, route will complete before animation complete
    if (!transitionCoordinator) {
        completion();
        return;
    }
    [transitionCoordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        completion();
    }];
}

- (void)notifyPerformRouteSuccessWithDestination:(id)destination {
    ZIKViewRouteConfiguration *configuration = self._nocopy_configuration;
    if (configuration.routeCompletion) {
        configuration.routeCompletion(destination);
    }
    [super notifySuccessWithAction:@selector(performRoute)];
}

- (void)beginPerformRoute {
    NSAssert(self.state == ZIKRouterStateRouting, @"state should be routing when begin to route.");
    self.retainedSelf = self;
    self.routingFromInternal = YES;
    id destination = self.destination;
    id source = self._nocopy_configuration.source;
    [self prepareForPerformRouteOnDestination:destination];
    [ZIKViewRouter AOP_notifyAll_router:self willPerformRouteOnDestination:destination fromSource:source];
}

- (void)endPerformRouteWithSuccess {
    NSAssert(self.state == ZIKRouterStateRouting, @"state should be routing when end route.");
    id destination = self.destination;
    id source = self._nocopy_configuration.source;
    [self notifyRouteState:ZIKRouterStateRouted];
    [self notifyPerformRouteSuccessWithDestination:destination];
    [ZIKViewRouter AOP_notifyAll_router:self didPerformRouteOnDestination:destination fromSource:source];
    self.routingFromInternal = NO;
    self.retainedSelf = nil;
}

- (void)endPerformRouteWithError:(NSError *)error {
    NSParameterAssert(error);
    NSAssert(self.state == ZIKRouterStateRouting, @"state should be routing when end route.");
    [self notifyRouteState:ZIKRouterStateRouteFailed];
    [self _o_callbackErrorWithAction:@selector(performRoute) error:error];
    self.routingFromInternal = NO;
    self.retainedSelf = nil;
}

//+ (ZIKViewRouteRealType)_o_realRouteTypeForViewController:(UIViewController *)destination {
//    ZIKViewRouteType routeType = [destination ZIK_routeType];
//    return [self _o_realRouteTypeForRouteTypeFromViewController:routeType];
//}

///routeType must from -[viewController ZIK_routeType]
+ (ZIKViewRouteRealType)_o_realRouteTypeForRouteTypeFromViewController:(ZIKViewRouteType)routeType {
    ZIKViewRouteRealType realRouteType;
    switch (routeType) {
        case ZIKViewRouteTypePush:
            realRouteType = ZIKViewRouteRealTypePush;
            break;
            
        case ZIKViewRouteTypePresentModally:
            realRouteType = ZIKViewRouteRealTypePresentModally;
            break;
            
        case ZIKViewRouteTypePresentAsPopover:
            realRouteType = ZIKViewRouteRealTypePresentAsPopover;
            break;
            
        case ZIKViewRouteTypeAddAsChildViewController:
            realRouteType = ZIKViewRouteRealTypeAddAsChildViewController;
            break;
            
        case ZIKViewRouteTypeShow:
            realRouteType = ZIKViewRouteRealTypeCustom;
            break;
            
        case ZIKViewRouteTypeShowDetail:
            realRouteType = ZIKViewRouteRealTypeCustom;
            break;
            
        default:
            realRouteType = ZIKViewRouteRealTypeCustom;
            break;
    }
    return realRouteType;
}

+ (ZIKViewRouteRealType)_o_realRouteTypeFromDetailType:(ZIKViewRouteDetailType)detailType {
    ZIKViewRouteRealType realType;
    switch (detailType) {
        case ZIKViewRouteDetailTypePush:
        case ZIKViewRouteDetailTypeParentPushed:
            realType = ZIKViewRouteRealTypePush;
            break;
            
        case ZIKViewRouteDetailTypePresentModally:
            realType = ZIKViewRouteRealTypePresentModally;
            break;
            
        case ZIKViewRouteDetailTypePresentAsPopover:
            realType = ZIKViewRouteRealTypePresentAsPopover;
            break;
            
        case ZIKViewRouteDetailTypeAddAsChildViewController:
            realType = ZIKViewRouteRealTypeAddAsChildViewController;
            break;
            
        case ZIKViewRouteDetailTypeRemoveFromParentViewController:
        case ZIKViewRouteDetailTypeRemoveFromNavigationStack:
        case ZIKViewRouteDetailTypeDismissed:
        case ZIKViewRouteDetailTypeRemoveAsSplitMaster:
        case ZIKViewRouteDetailTypeRemoveAsSplitDetail:
            realType = ZIKViewRouteRealTypeUnwind;
            break;
            
        default:
            realType = ZIKViewRouteRealTypeCustom;
            break;
    }
    return realType;
}

#pragma mark Remove Route

- (BOOL)canRemove {
    NSAssert([NSThread isMainThread], @"Always check state in main thread, bacause state may change in main thread after you check the state in child thread.");
    return [self _o_canRemoveWithErrorMessage:NULL];
}

- (BOOL)canRemoveCustomRoute {
    return NO;
}

- (BOOL)_o_canRemoveWithErrorMessage:(NSString **)message {
    ZIKViewRouteConfiguration *configuration = self._nocopy_configuration;
    if (!configuration) {
        if (message) {
            *message = @"Configuration missed.";
        }
        return NO;
    }
    ZIKViewRouteType routeType = configuration.routeType;
    ZIKViewRouteRealType realRouteType = self.realRouteType;
    id destination = self.destination;
    
    if (self.state != ZIKRouterStateRouted) {
        if (message) {
            *message = [NSString stringWithFormat:@"Router can't remove, it's not performed, current state:%ld router:%@",(long)self.state,self];
        }
        return NO;
    }
    
    if (routeType == ZIKViewRouteTypeCustom) {
        return [self canRemoveCustomRoute];
    }
    
    if (!destination) {
        if (self.state != ZIKRouterStateRemoved) {
            [self notifyRouteState:ZIKRouterStateRemoved];
        }
        if (message) {
            *message = [NSString stringWithFormat:@"Router can't remove, destination is dealloced. router:%@",self];
        }
        return NO;
    }
    
    switch (realRouteType) {
        case ZIKViewRouteRealTypeUnknown:
        case ZIKViewRouteRealTypeUnwind:
        case ZIKViewRouteRealTypeCustom: {
            if (message) {
                *message = [NSString stringWithFormat:@"Router can't remove, realRouteType is %ld, doesn't support remove, router:%@",(long)realRouteType,self];
            }
            return NO;
            break;
        }
            
        case ZIKViewRouteRealTypePush: {
            if (![self _o_canPop]) {
                [self notifyRouteState:ZIKRouterStateRemoved];
                if (message) {
                    *message = [NSString stringWithFormat:@"Router can't remove, destination doesn't have navigationController when pop, router:%@",self];
                }
                return NO;
            }
            break;
        }
            
        case ZIKViewRouteRealTypePresentModally:
        case ZIKViewRouteRealTypePresentAsPopover: {
            if (![self _o_canDismiss]) {
                [self notifyRouteState:ZIKRouterStateRemoved];
                if (message) {
                    *message = [NSString stringWithFormat:@"Router can't remove, destination is not presented when dismiss. router:%@",self];
                }
                return NO;
            }
            break;
        }
          
        case ZIKViewRouteRealTypeAddAsChildViewController: {
            if (![self _o_canRemoveFromParentViewController]) {
                [self notifyRouteState:ZIKRouterStateRemoved];
                if (message) {
                    *message = [NSString stringWithFormat:@"Router can't remove, doesn't have parent view controller when remove from parent. router:%@",self];
                }
                return NO;
            }
            break;
        }
            
        case ZIKViewRouteRealTypeAddAsSubview: {
            if (![self _o_canRemoveFromSuperview]) {
                [self notifyRouteState:ZIKRouterStateRemoved];
                if (message) {
                    *message = [NSString stringWithFormat:@"Router can't remove, destination doesn't have superview when remove from superview. router:%@",self];
                }
                return NO;
            }
            break;
        }
    }
    return YES;
}

- (BOOL)_o_canPop {
    UIViewController *destination = self.destination;
    if (!destination.navigationController) {
        return NO;
    }
    return YES;
}

- (BOOL)_o_canDismiss {
    UIViewController *destination = self.destination;
    if (!destination.presentingViewController && /*can dismiss destination itself*/
        !destination.presentedViewController /*can dismiss destination's presentedViewController*/
        ) {
        return NO;
    }
    return YES;
}

- (BOOL)_o_canRemoveFromParentViewController {
    UIViewController *destination = self.destination;
    if (!destination.parentViewController) {
        return NO;
    }
    return YES;
}

- (BOOL)_o_canRemoveFromSuperview {
    UIView *destination = self.destination;
    if (!destination.superview) {
        return NO;
    }
    return YES;
}

- (void)removeRouteWithSuccessHandler:(void(^)(void))performerSuccessHandler
                   performerErrorHandler:(void(^)(SEL routeAction, NSError *error))performerErrorHandler {
    void(^doRemoveRoute)() = ^ {
        if (self.state != ZIKRouterStateRouted || !self._nocopy_configuration) {
            [self _o_callbackError_errorCode:ZIKViewRouteErrorActionFailed
                                errorHandler:performerErrorHandler
                                      action:@selector(removeRoute)
                            errorDescription:@"State should be ZIKRouterStateRouted when removeRoute, current state:%ld, configuration:%@",self.state,self._nocopy_configuration];
            return;
        }
        NSString *errorMessage;
        if (![self _o_canRemoveWithErrorMessage:&errorMessage]) {
            NSString *description = [NSString stringWithFormat:@"%@, configuration:%@",errorMessage,self._nocopy_configuration];
            [self _o_callbackError_actionFailedWithAction:@selector(removeRoute)
                                         errorDescription:description];
            if (performerErrorHandler) {
                performerErrorHandler(@selector(removeRoute),[[self class] errorWithCode:ZIKViewRouteErrorActionFailed localizedDescription:description]);
            }
            return;
        }
        
        [super removeRouteWithSuccessHandler:performerSuccessHandler performerErrorHandler:performerErrorHandler];
    };
    
    if ([NSThread isMainThread]) {
        doRemoveRoute();
    } else {
        NSAssert(NO, @"%@ removeRoute should only be called in main thread!",self);
        dispatch_async(dispatch_get_main_queue(), ^{
            doRemoveRoute();
        });
    }
}

- (void)removeDestination:(id)destination removeConfiguration:(__kindof ZIKRouteConfiguration *)removeConfiguration {
    [self notifyRouteState:ZIKRouterStateRemoving];
    if (!destination) {
        [self notifyRouteState:ZIKRouterStateRemoveFailed];
        [self _o_callbackError_actionFailedWithAction:@selector(removeRoute)
                                     errorDescription:@"Destination was deallced when removeRoute, router:%@",self];
        return;
    }
    
    ZIKViewRouteConfiguration *configuration = self._nocopy_configuration;
    if (configuration.routeType == ZIKViewRouteTypeCustom) {
        if ([self respondsToSelector:@selector(removeCustomRouteOnDestination:fromSource:removeConfiguration:configuration:)]) {
            [self removeCustomRouteOnDestination:destination
                                      fromSource:self._nocopy_configuration.source
                             removeConfiguration:self._nocopy_removeConfiguration
                                   configuration:configuration];
        } else {
            [self notifyRouteState:ZIKRouterStateRemoveFailed];
            [self _o_callbackError_actionFailedWithAction:@selector(performRoute) errorDescription:@"Remove custom route but router(%@) didn't implement -removeCustomRouteOnDestination:fromSource:removeConfiguration:configuration:",[self class]];
            NSAssert(NO, @"Remove custom route but router(%@) didn't implement -removeCustomRouteOnDestination:fromSource:removeConfiguration:configuration:",[self class]);
        }
        return;
    }
    ZIKViewRouteRealType realRouteType = self.realRouteType;
    NSString *errorDescription;
    
    switch (realRouteType) {
        case ZIKViewRouteRealTypePush:
            [self _o_popOnDestination:destination];
            break;
            
        case ZIKViewRouteRealTypePresentModally:
            [self _o_dismissOnDestination:destination];
            break;
            
        case ZIKViewRouteRealTypePresentAsPopover:
            [self _o_dismissPopoverOnDestination:destination];
            break;
            
        case ZIKViewRouteRealTypeAddAsChildViewController:
            [self _o_removeFromParentViewControllerOnDestination:destination];
            break;
            
        case ZIKViewRouteRealTypeAddAsSubview:
            [self _o_removeFromSuperviewOnDestination:destination];
            break;
            
        case ZIKViewRouteRealTypeUnknown:
            errorDescription = @"RouteType(Unknown) can't removeRoute";
            break;
            
        case ZIKViewRouteRealTypeUnwind:
            errorDescription = @"RouteType(Unwind) can't removeRoute";
            break;
            
        case ZIKViewRouteRealTypeCustom:
            errorDescription = @"RouteType(Custom) can't removeRoute";
            break;
    }
    if (errorDescription) {
        [self notifyRouteState:ZIKRouterStateRemoveFailed];
        [self _o_callbackError_actionFailedWithAction:@selector(removeRoute)
                                     errorDescription:errorDescription];
    }
}

- (void)_o_popOnDestination:(UIViewController *)destination {
    [destination setZIK_routeTypeFromRouter:@(ZIKViewRouteTypePush)];
    UIViewController *source = destination.navigationController.visibleViewController;
    [self beginRemoveRouteFromSource:source];
    
    UINavigationController *navigationController;
    if (self.container.navigationController) {
        navigationController = self.container.navigationController;
    } else {
        navigationController = destination.navigationController;
    }
    UIViewController *popTo = (UIViewController *)self._nocopy_configuration.source;
    
    if ([navigationController.viewControllers containsObject:popTo]) {
        [navigationController popToViewController:popTo animated:self._nocopy_removeConfiguration.animated];
    } else {
        NSAssert(NO, @"navigationController doesn't contains original source when pop destination.");
        [destination.navigationController popViewControllerAnimated:self._nocopy_removeConfiguration.animated];
    }
    [ZIKViewRouter _o_completeWithtransitionCoordinator:destination.navigationController.transitionCoordinator
                                   transitionCompletion:^{
        [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
    }];
}

- (void)_o_dismissOnDestination:(UIViewController *)destination {
    [destination setZIK_routeTypeFromRouter:@(ZIKViewRouteTypePresentModally)];
    UIViewController *source = destination.presentingViewController;
    [self beginRemoveRouteFromSource:source];
    
    [destination dismissViewControllerAnimated:self._nocopy_removeConfiguration.animated completion:^{
        [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
    }];
}

- (void)_o_dismissPopoverOnDestination:(UIViewController *)destination {
    [destination setZIK_routeTypeFromRouter:@(ZIKViewRouteTypePresentAsPopover)];
    UIViewController *source = destination.presentingViewController;
    [self beginRemoveRouteFromSource:source];
    
    if (NSClassFromString(@"UIPopoverPresentationController") ||
        [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) {
        [destination dismissViewControllerAnimated:self._nocopy_removeConfiguration.animated completion:^{
            [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
        }];
        return;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    UIPopoverController *popover = objc_getAssociatedObject(destination, "zikrouter_popover");
#pragma clang diagnostic pop
    if (!popover) {
        NSAssert(NO, @"Didn't set UIPopoverController to destination in -_o_performPresentAsPopoverOnDestination:fromSource:popoverConfiguration:");
        [destination dismissViewControllerAnimated:self._nocopy_removeConfiguration.animated completion:^{
            [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
        }];
        return;
    }
    [popover dismissPopoverAnimated:self._nocopy_removeConfiguration.animated];
    [ZIKViewRouter _o_completeWithtransitionCoordinator:destination.transitionCoordinator
                                   transitionCompletion:^{
        [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
    }];
}

- (void)_o_removeFromParentViewControllerOnDestination:(UIViewController *)destination {
    [destination setZIK_routeTypeFromRouter:@(ZIKViewRouteTypeAddAsChildViewController)];
    
    UIViewController *wrappedDestination = self.container;
    if (!wrappedDestination) {
        wrappedDestination = destination;
    }
    UIViewController *source = wrappedDestination.parentViewController;
    [self beginRemoveRouteFromSource:source];
    
    [wrappedDestination willMoveToParentViewController:nil];
    BOOL isViewLoaded = wrappedDestination.isViewLoaded;
    if (isViewLoaded) {
        [wrappedDestination.view removeFromSuperview];//If do removeFromSuperview before removeFromParentViewController, -didMoveToParentViewController:nil in destination may be called twice
    }
    [wrappedDestination removeFromParentViewController];
    
    [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
    if (!isViewLoaded) {
        [destination setZIK_routeTypeFromRouter:nil];
    }
}

- (void)_o_removeFromSuperviewOnDestination:(UIView *)destination {
    NSAssert(destination.superview, @"Destination doesn't have superview when remove from superview.");
    [destination setZIK_routeTypeFromRouter:@(ZIKViewRouteTypeAddAsSubview)];
    UIView *source = destination.superview;
    [self beginRemoveRouteFromSource:source];
    
    [destination removeFromSuperview];
    
    [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
}

- (void)notifyRemoveRouteSuccess {
    ZIKViewRemoveConfiguration *configuration = self._nocopy_removeConfiguration;
    if (configuration.removeCompletion) {
        configuration.removeCompletion();
    }
    [super notifySuccessWithAction:@selector(removeRoute)];
}

- (void)beginRemoveRouteFromSource:(id)source {
    NSAssert(self.destination, @"Destination is not exist when remove route.");
    NSAssert(self.state == ZIKRouterStateRemoving, @"state should be removing when begin to remove.");
    self.retainedSelf = self;
    self.routingFromInternal = YES;
    id destination = self.destination;
    if ([destination conformsToProtocol:@protocol(ZIKRoutableView)]) {
        [ZIKViewRouter AOP_notifyAll_router:self willRemoveRouteOnDestination:destination fromSource:source];
    } else {
        NSAssert([self isMemberOfClass:[ZIKViewRouter class]] && self._nocopy_configuration.routeType == ZIKViewRouteTypePerformSegue, @"Only ZIKViewRouteTypePerformSegue's destination can not conform to ZIKRoutableView");
    }
}

- (void)endRemoveRouteWithSuccessOnDestination:(id)destination fromSource:(id)source {
    NSParameterAssert(destination);
    NSAssert(self.state == ZIKRouterStateRemoving, @"state should be removing when end remove.");
    [self notifyRouteState:ZIKRouterStateRemoved];
    [self notifyRemoveRouteSuccess];
    if ([destination conformsToProtocol:@protocol(ZIKRoutableView)]) {
        [ZIKViewRouter AOP_notifyAll_router:self didRemoveRouteOnDestination:destination fromSource:source];
    } else {
        NSAssert([self isMemberOfClass:[ZIKViewRouter class]] && self._nocopy_configuration.routeType == ZIKViewRouteTypePerformSegue, @"Only ZIKViewRouteTypePerformSegue's destination can not conform to ZIKRoutableView");
    }
    self.routingFromInternal = NO;
    self.container = nil;
    self.retainedSelf = nil;
}

- (void)endRemoveRouteWithError:(NSError *)error {
    NSParameterAssert(error);
    NSAssert(self.state == ZIKRouterStateRemoving, @"state should be removing when end remove.");
    [self notifyRouteState:ZIKRouterStateRemoveFailed];
    [self _o_callbackErrorWithAction:@selector(removeRoute) error:error];
    self.routingFromInternal = NO;
    self.retainedSelf = nil;
}

#pragma mark AOP

+ (void)AOP_notifyAll_router:(nullable ZIKViewRouter *)router willPerformRouteOnDestination:(id)destination fromSource:(id)source {
    NSParameterAssert([destination conformsToProtocol:@protocol(ZIKRoutableView)]);
    EnumerateRoutersForViewClass([destination class], ^(__unsafe_unretained Class routerClass) {
        if ([routerClass respondsToSelector:@selector(router:willPerformRouteOnDestination:fromSource:)]) {
            [routerClass router:router willPerformRouteOnDestination:destination fromSource:source];
        }
    });
}

+ (void)AOP_notifyAll_router:(nullable ZIKViewRouter *)router didPerformRouteOnDestination:(id)destination fromSource:(id)source {
    NSParameterAssert([destination conformsToProtocol:@protocol(ZIKRoutableView)]);
    EnumerateRoutersForViewClass([destination class], ^(__unsafe_unretained Class routerClass) {
        if ([routerClass respondsToSelector:@selector(router:didPerformRouteOnDestination:fromSource:)]) {
            [routerClass router:router didPerformRouteOnDestination:destination fromSource:source];
        }
    });
}

+ (void)AOP_notifyAll_router:(nullable ZIKViewRouter *)router willRemoveRouteOnDestination:(id)destination fromSource:(id)source {
    NSParameterAssert([destination conformsToProtocol:@protocol(ZIKRoutableView)]);
    EnumerateRoutersForViewClass([destination class], ^(__unsafe_unretained Class routerClass) {
        if ([routerClass respondsToSelector:@selector(router:willRemoveRouteOnDestination:fromSource:)]) {
            [routerClass router:router willRemoveRouteOnDestination:destination fromSource:(id)source];
        }
    });
}

+ (void)AOP_notifyAll_router:(nullable ZIKViewRouter *)router didRemoveRouteOnDestination:(id)destination fromSource:(id)source {
    NSParameterAssert([destination conformsToProtocol:@protocol(ZIKRoutableView)]);
    EnumerateRoutersForViewClass([destination class], ^(__unsafe_unretained Class routerClass) {
        if ([routerClass respondsToSelector:@selector(router:didRemoveRouteOnDestination:fromSource:)]) {
            [routerClass router:router didRemoveRouteOnDestination:destination fromSource:(id)source];
        }
    });
}

#pragma mark Hook System Navigation

///Update state when route action is not performed from router
- (void)_o_handleWillPerformRouteNotification:(NSNotification *)note {
    id destination = note.object;
    if (!self.destination || self.destination != destination) {
        return;
    }
    ZIKRouterState state = self.state;
    if (!self.routingFromInternal && state != ZIKRouterStateRouting) {
        ZIKViewRouteConfiguration *configuration = self._nocopy_configuration;
        BOOL isFromAddAsChild = (configuration.routeType == ZIKViewRouteTypeAddAsChildViewController);
        if (state != ZIKRouterStateRouted ||
            (self.stateBeforeRoute &&
             configuration.routeType == ZIKViewRouteTypeGetDestination) ||
            (isFromAddAsChild &&
             self.realRouteType == ZIKViewRouteRealTypeUnknown)) {
                if (isFromAddAsChild) {
                    self.realRouteType = ZIKViewRouteRealTypeAddAsChildViewController;
                }
            [self notifyRouteState:ZIKRouterStateRouting];//not performed from router (dealed by system, or your code)
            if (configuration.handleExternalRoute) {
                [self prepareForPerformRouteOnDestination:destination];
            } else {
                [self prepareDestination:destination configuration:configuration];
                [self didFinishPrepareDestination:destination configuration:configuration];
            }
        }
    }
}

- (void)_o_handleDidPerformRouteNotification:(NSNotification *)note {
    id destination = note.object;
    if (!self.destination || self.destination != destination) {
        return;
    }
    if (self.stateBeforeRoute &&
        self._nocopy_configuration.routeType == ZIKViewRouteTypeGetDestination) {
        NSAssert(self.realRouteType == ZIKViewRouteRealTypeUnknown, @"real route type is unknown before destination is real routed");
        ZIKPresentationState *stateBeforeRoute = self.stateBeforeRoute;
        ZIKViewRouteDetailType detailRouteType = [ZIKPresentationState detailRouteTypeFromStateBeforeRoute:stateBeforeRoute stateAfterRoute:[destination ZIK_presentationState]];
        self.realRouteType = [ZIKViewRouter _o_realRouteTypeFromDetailType:detailRouteType];
        self.stateBeforeRoute = nil;
    }
    if (!self.routingFromInternal &&
        self.state != ZIKRouterStateRouted) {
        [self notifyRouteState:ZIKRouterStateRouted];//not performed from router (dealed by system, or your code)
        if (self._nocopy_configuration.handleExternalRoute) {
            [self notifyPerformRouteSuccessWithDestination:destination];
        }
    }
}

- (void)_o_handleWillRemoveRouteNotification:(NSNotification *)note {
    id destination = note.object;
    if (!self.destination || self.destination != destination) {
        return;
    }
    ZIKRouterState state = self.state;
    if (!self.routingFromInternal && state != ZIKRouterStateRemoving) {
        if (state != ZIKRouterStateRemoved ||
            (self.stateBeforeRoute &&
             self._nocopy_configuration.routeType == ZIKViewRouteTypeGetDestination)) {
                [self notifyRouteState:ZIKRouterStateRemoving];//not performed from router (dealed by system, or your code)
            }
    }
    if (state == ZIKRouterStateRouting) {
        [self _o_callbackError_unbalancedTransitionWithAction:@selector(removeRoute) errorDescription:@"Unbalanced calls to begin/end appearance transitions for destination. This error occurs when you try and display a view controller before the current view controller is finished displaying. This may cause the UIViewController skips or messes up the order calling -viewWillAppear:, -viewDidAppear:, -viewWillDisAppear: and -viewDidDisappear:, and messes up the route state. Current error reason is trying to remove route on destination when destination is routing, router:(%@), callStack:%@",self,[NSThread callStackSymbols]];
    }
}

- (void)_o_handleDidRemoveRouteNotification:(NSNotification *)note {
    id destination = note.object;
    if (!self.destination || self.destination != destination) {
        return;
    }
    if (self.stateBeforeRoute &&
        self._nocopy_configuration.routeType == ZIKViewRouteTypeGetDestination) {
        NSAssert(self.realRouteType == ZIKViewRouteRealTypeUnknown, @"real route type is unknown before destination is real routed");
        ZIKPresentationState *stateBeforeRoute = self.stateBeforeRoute;
        ZIKViewRouteDetailType detailRouteType = [ZIKPresentationState detailRouteTypeFromStateBeforeRoute:stateBeforeRoute stateAfterRoute:[destination ZIK_presentationState]];
        self.realRouteType = [ZIKViewRouter _o_realRouteTypeFromDetailType:detailRouteType];
        self.stateBeforeRoute = nil;
    }
    if (!self.routingFromInternal &&
        self.state != ZIKRouterStateRemoved) {
        [self notifyRouteState:ZIKRouterStateRemoved];//not performed from router (dealed by system, or your code)
        if (self._nocopy_removeConfiguration.handleExternalRoute) {
            [self notifyRemoveRouteSuccess];
        }
    }
}

- (void)_o_handleRemoveRouteCanceledNotification:(NSNotification *)note {
    id destination = note.object;
    if (!self.destination || self.destination != destination) {
        return;
    }
    if (!self.routingFromInternal &&
        self.state == ZIKRouterStateRemoving) {
        ZIKRouterState preState = self.preState;
        [self notifyRouteState:preState];//not performed from router (dealed by system, or your code)
    }
}

- (void)ZIKViewRouter_hook_willMoveToParentViewController:(UIViewController *)parent {
    [self ZIKViewRouter_hook_willMoveToParentViewController:parent];
    if (parent) {
        [(UIViewController *)self setZIK_parentMovingTo:parent];
    } else {
        UIViewController *currentParent = [(UIViewController *)self parentViewController];
        NSAssert(currentParent, @"currentParent shouldn't be nil when removing from parent");
        [(UIViewController *)self setZIK_parentRemovingFrom:currentParent];
    }
}

- (void)ZIKViewRouter_hook_didMoveToParentViewController:(UIViewController *)parent {
    [self ZIKViewRouter_hook_didMoveToParentViewController:parent];
    if (parent) {
        NSAssert([(UIViewController *)self parentViewController], @"currentParent shouldn't be nil when didMoved to parent");
//        NSAssert([(UIViewController *)self ZIK_parentMovingTo] ||
//                 [(UIViewController *)self ZIK_isRootViewControllerInContainer], @"parentMovingTo should be set in -ZIKViewRouter_hook_willMoveToParentViewController:. But if a container is from storyboard, it's not created with initWithRootViewController:, so rootViewController may won't call willMoveToParentViewController: before didMoveToParentViewController:.");
        
        [(UIViewController *)self setZIK_parentMovingTo:nil];
    } else {
        NSAssert([(UIViewController *)self parentViewController] == nil, @"currentParent should be nil when removed from parent");
        //If you do removeFromSuperview before removeFromParentViewController, -didMoveToParentViewController:nil in child view controller may be called twice.
        //        NSAssert([(UIViewController *)self ZIK_parentRemovingFrom], @"RemovingFrom should be set in -ZIKViewRouter_hook_willMoveToParentViewController.");
        
        [(UIViewController *)self setZIK_parentRemovingFrom:nil];
    }
}

- (void)ZIKViewRouter_hook_viewWillAppear:(BOOL)animated {
    UIViewController *destination = (UIViewController *)self;
    BOOL removing = destination.ZIK_removing;
    BOOL isRoutableView = ([self conformsToProtocol:@protocol(ZIKRoutableView)] == YES);
    if (removing) {
        [destination setZIK_removing:NO];
        if (isRoutableView) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteRemoveRouteCanceledNotification object:destination];
        }
    }
    if (isRoutableView) {
        BOOL routed = [(UIViewController *)self ZIK_routed];
        if (!routed) {
            NSAssert(removing == NO, @"removing a not routed view is unexpected");
            UIViewController *parentMovingTo = [(UIViewController *)self ZIK_parentMovingTo];
            [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteWillPerformRouteNotification object:destination];
            NSNumber *routeTypeFromRouter = [destination ZIK_routeTypeFromRouter];
            if (!routeTypeFromRouter ||
                [routeTypeFromRouter integerValue] == ZIKViewRouteTypeGetDestination ||
                [routeTypeFromRouter integerValue] == ZIKViewRouteTypeAddAsChildViewController) {
                UIViewController *source = parentMovingTo;
                if (!source) {
                    UIViewController *node = destination;
                    while (node) {
                        if (node.isBeingPresented) {
                            source = node.presentingViewController;
                            break;
                        } else {
                            node = node.parentViewController;
                        }
                    }
                }
                [ZIKViewRouter AOP_notifyAll_router:nil willPerformRouteOnDestination:destination fromSource:source];
            }
        }
    }
    
    [self ZIKViewRouter_hook_viewWillAppear:animated];
}

- (void)ZIKViewRouter_hook_viewDidAppear:(BOOL)animated {
    BOOL routed = [(UIViewController *)self ZIK_routed];
    UIViewController *parentMovingTo = [(UIViewController *)self ZIK_parentMovingTo];
    if (!routed &&
        [self conformsToProtocol:@protocol(ZIKRoutableView)]) {
        UIViewController *destination = (UIViewController *)self;
        [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteDidPerformRouteNotification object:destination];
        NSNumber *routeTypeFromRouter = [destination ZIK_routeTypeFromRouter];//This destination is routing from router
        if (!routeTypeFromRouter ||
            [routeTypeFromRouter integerValue] == ZIKViewRouteTypeGetDestination ||
            [routeTypeFromRouter integerValue] == ZIKViewRouteTypeAddAsChildViewController) {
            UIViewController *source = parentMovingTo;
            if (!source) {
                UIViewController *node = destination;
                while (node) {
                    if (node.isBeingPresented) {
                        source = node.presentingViewController;
                        break;
                    } else if (node.isMovingToParentViewController) {
                        source = node.parentViewController;
                        break;
                    } else {
                        node = node.parentViewController;
                    }
                }
            }
            [ZIKViewRouter AOP_notifyAll_router:nil didPerformRouteOnDestination:destination fromSource:source];
        }
        if (routeTypeFromRouter) {
            [destination setZIK_routeTypeFromRouter:nil];
        }
    }
    
    [self ZIKViewRouter_hook_viewDidAppear:animated];
    if (!routed) {
        [(UIViewController *)self setZIK_routed:YES];
    }
}

- (void)ZIKViewRouter_hook_viewWillDisappear:(BOOL)animated {
    UIViewController *destination = (UIViewController *)self;
    if (destination.ZIK_removing == NO) {
        UIViewController *node = destination;
        while (node) {
            UIViewController *parentRemovingFrom = node.ZIK_parentRemovingFrom;
            UIViewController *source;
            if (parentRemovingFrom || //removing from navigation / willMoveToParentViewController:nil, removeFromParentViewController
                node.isMovingFromParentViewController || //removed from splite
                (!node.parentViewController && !node.presentingViewController && ![node ZIK_isAppRootViewController])) {
                source = parentRemovingFrom;
            } else if (node.isBeingDismissed) {
                source = node.presentingViewController;
            } else {
                node = node.parentViewController;
                continue;
            }
            if ([self conformsToProtocol:@protocol(ZIKRoutableView)]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteWillRemoveRouteNotification object:destination];
                NSNumber *routeTypeFromRouter = [destination ZIK_routeTypeFromRouter];
                if (!routeTypeFromRouter ||
                    [routeTypeFromRouter integerValue] == ZIKViewRouteTypeGetDestination) {
                    [ZIKViewRouter AOP_notifyAll_router:nil willRemoveRouteOnDestination:destination fromSource:source];
                }
            }
            [destination setZIK_parentRemovingFrom:source];
            [destination setZIK_removing:YES];
            break;
        }
    }
    
    [self ZIKViewRouter_hook_viewWillDisappear:animated];
}

- (void)ZIKViewRouter_hook_viewDidDisappear:(BOOL)animated {
    UIViewController *destination = (UIViewController *)self;
    BOOL removing = destination.ZIK_removing;
    if ([self conformsToProtocol:@protocol(ZIKRoutableView)]) {
        if (removing) {
            UIViewController *source = destination.ZIK_parentRemovingFrom;
            [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteDidRemoveRouteNotification object:destination];
            NSNumber *routeTypeFromRouter = [destination ZIK_routeTypeFromRouter];
            if (!routeTypeFromRouter ||
                [routeTypeFromRouter integerValue] == ZIKViewRouteTypeGetDestination) {
                [ZIKViewRouter AOP_notifyAll_router:nil didRemoveRouteOnDestination:destination fromSource:source];
            }
            if (routeTypeFromRouter) {
                [destination setZIK_routeTypeFromRouter:nil];
            }
        }
    }
    if (removing) {
        [destination setZIK_removing:NO];
        [destination setZIK_routed:NO];
    } else if (ZIKClassIsCustomClass([destination class])) {
        //Check unbalanced calls to begin/end appearance transitions
        UIViewController *node = destination;
        while (node) {
            UIViewController *parentRemovingFrom = node.ZIK_parentRemovingFrom;
            UIViewController *source;
            if (parentRemovingFrom ||
                node.isMovingFromParentViewController ||
                (!node.parentViewController && !node.presentingViewController && ![node ZIK_isAppRootViewController])) {
                source = parentRemovingFrom;
            } else if (node.isBeingDismissed) {
                source = node.presentingViewController;
            } else {
                node = node.parentViewController;
                continue;
            }
            
            [destination setZIK_parentRemovingFrom:source];
            [ZIKViewRouter _o_callbackGlobalErrorHandlerWithRouter:nil action:@selector(removeRoute) error:[ZIKViewRouter errorWithCode:ZIKViewRouteErrorUnbalancedTransition localizedDescriptionFormat:@"Unbalanced calls to begin/end appearance transitions for destination. This error occurs when you try and display a view controller before the current view controller is finished displaying. This may cause the UIViewController skips or messes up the order calling -viewWillAppear:, -viewDidAppear:, -viewWillDisAppear: and -viewDidDisappear:, and messes up the route state. Current error reason is already removed destination but destination appears again before -viewDidDisappear:, router:(%@), callStack:%@",self,[NSThread callStackSymbols]]];
            NSAssert(NO, @"Unbalanced calls to begin/end appearance transitions for destination. This error may from your custom transition.");
            break;
        }
    }
    
    [self ZIKViewRouter_hook_viewDidDisappear:animated];
}

/**
 Note: in -viewWillAppear:, if the view controller contains sub routable UIView added from external (addSubview:, storyboard or xib), the subview may not be ready yet. The UIView has to search the performer with -nextResponder to prepare itself, nextResponder can only be gained after -viewDidLoad or -willMoveToWindow:. But -willMoveToWindow: may not be called yet in -viewWillAppear:. If the subview is not ready, config the subview in -handleViewReady may fail.
 So we have to make sure routable UIView is prepared before -viewDidLoad if it's added to the superview when superview is not on screen yet.
 */
- (void)ZIKViewRouter_hook_viewDidLoad {
    NSAssert([NSThread isMainThread], @"UI thread must be main thread.");
    [self ZIKViewRouter_hook_viewDidLoad];
    
    //Find performer and prepare for destination added to a superview not on screen in -ZIKViewRouter_hook_willMoveToSuperview
    NSMutableArray *preparingRouters = g_preparingUIViewRouters;
    
    NSMutableArray *preparedRouters;
    if (preparingRouters.count > 0) {
        for (ZIKViewRouter *router in preparingRouters) {
            UIView *destination = router.destination;
            NSAssert([destination isKindOfClass:[UIView class]], @"Only UIView destination need fix.");
            id performer = [destination ZIK_routePerformer];
            if (performer) {
                [ZIKViewRouter _o_prepareForDestinationRoutingFromExternal:destination router:router performer:performer];
                router.prepared = YES;
                if (!preparedRouters) {
                    preparedRouters = [NSMutableArray array];
                }
                [preparedRouters addObject:router];
            }
        }
        if (preparedRouters.count > 0) {
            [preparingRouters removeObjectsInArray:preparedRouters];
        }
    }
}

///Add subview by code or storyboard will auto create a corresponding router. We assume it's superview's view controller as the performer. If your custom class view use a routable view as it's part, the custom view should use a router to add and prepare the routable view, then the routable view don't need to search performer.

/**
 When a routable view is added from storyboard or xib
 Invoking order in subview when subview needs prepare:
 1.willMoveToSuperview: (can't find performer until -viewDidLoad, add to preparing list)
 2.didMoveToSuperview
 3.ZIKViewRouter_hook_viewDidLoad
    4.didFinishPrepareDestination:configuration:
    5.viewDidLoad
 6.willMoveToWindow:
    7.router:willPerformRouteOnDestination:fromSource:
 8.didMoveToWindow
    9.router:didPerformRouteOnDestination:fromSource:
 
 Invoking order in subview when subview doesn't need prepare:
 1.willMoveToSuperview: (don't need to find performer, so finish directly)
    2.didFinishPrepareDestination:configuration:
 3.didMoveToSuperview
 4.willMoveToWindow:
    5.router:willPerformRouteOnDestination:fromSource:
 6.didMoveToWindow
    7.router:didPerformRouteOnDestination:fromSource:
 */

/**
 Directly add a routable subview to a visible UIView in view controller.
 Invoking order in subview:
 1.willMoveToWindow:
 2.willMoveToSuperview: (superview is already in a view controller, so can find performer now)
    3.didFinishPrepareDestination:configuration:
    4.router:willPerformRouteOnDestination:fromSource:
 5.didMoveToWindow
    6.router:didPerformRouteOnDestination:fromSource:
 7.didMoveToSuperview
 */

/**
 Directly add a routable subview to an invisible UIView in view controller.
 Invoking order in subview:
 1.willMoveToSuperview: (superview is already in a view controller, so can find performer now)
    2.didFinishPrepareDestination:configuration:
 3.didMoveToSuperview
 4.willMoveToWindow: (when superview is visible)
    5.router:willPerformRouteOnDestination:fromSource:
 6.didMoveToWindow
    7.router:didPerformRouteOnDestination:fromSource:
 */

/**
 Add a routable subview to a superview, then add the superview to a UIView in view controller.
 Invoking order in subview when subview needs prepare:
 1.willMoveToSuperview: (add to prepare list if it's superview chain is not in window)
 2.didMoveToSuperview
 3.willMoveToWindow: (still in preparing list, if destination is already on screen, search performer fail, else search in didMoveToWindow)
 4.didMoveToWindow
    5.didFinishPrepareDestination:configuration:
    6.router:willPerformRouteOnDestination:fromSource:
 
 Invoking order in subview when subview doesn't need prepare:
 1.willMoveToSuperview: (don't need to find performer, so finish directly)
    2.didFinishPrepareDestination:configuration:
 3.didMoveToSuperview
 4.willMoveToWindow:
    5.router:willPerformRouteOnDestination:fromSource:
 6.didMoveToWindow
    7.router:didPerformRouteOnDestination:fromSource:
 */

/**
 Add a routable subview to a superviw, but the superview was never added to any view controller. This should get an assert failure when subview needs prepare.
 Invoking order in subview when subview needs prepare:
 1.willMoveToSuperview:newSuperview (add to preparing list, prepare until )
 2.didMoveToSuperview
 3.willMoveToSuperview:nil
    4.when detected that router is still in prepareing list, means last preparation is not finished, assert fail, route fail with a invalid performer error.
    5.router:willRemoveRouteOnDestination:fromSource:
 6.didMoveToSuperview
    7.router:didRemoveRouteOnDestination:fromSource:
 
 Invoking order in subview when subview don't need prepare:
 1.willMoveToSuperview:newSuperview
    2.didFinishPrepareDestination:configuration:
 3.didMoveToSuperview
 4.willMoveToSuperview:nil
    5.router:willPerformRouteOnDestination:fromSource:
    6.router:didPerformRouteOnDestination:fromSource: (the view was never displayed after added, so willMoveToWindow: is never be invoked, so router needs to end the perform route action here.)
    7.router:willRemoveRouteOnDestination:fromSource:
 8.didMoveToSuperview
    9.router:didRemoveRouteOnDestination:fromSource:
 */

/**
 Add a routable subview to a UIWindow. This should get an assert failure when subview needs prepare.
 Invoking order in subview when subview needs prepare:
 1.willMoveToWindow:newWindow
 2.willMoveToSuperview:newSuperview
    3.when detected that newSuperview is already on screen, but can't find the performer, assert fail, get a global invalid performer error
    4.router:willPerformRouteOnDestination:fromSource: (if no assert fail, route will continue)
 5.didMoveToWindow
    6.router:didPerformRouteOnDestination:fromSource:
 7.didMoveToSuperview
 
 Invoking order in subview when subview doesn't need prepare:
 1.willMoveToWindow:newWindow
 2.willMoveToSuperview:newSuperview
    3.didFinishPrepareDestination:configuration:
    4.router:willPerformRouteOnDestination:fromSource:
 5.didMoveToWindow
    6.router:didPerformRouteOnDestination:fromSource:
 7.didMoveToSuperview
 */

- (void)ZIKViewRouter_hook_willMoveToSuperview:(nullable UIView *)newSuperview {
    UIView *destination = (UIView *)self;
    if ([self conformsToProtocol:@protocol(ZIKRoutableView)]) {
        if (!newSuperview) {
            //Removing from superview
            ZIKViewRouter *destinationRouter = [destination ZIK_destinationViewRouter];
            if (destinationRouter) {
                //This is routing from router
                if ([g_preparingUIViewRouters containsObject:destinationRouter]) {
                    //Didn't fine the performer of UIView until it's removing from superview, maybe it's superview was never added to any view controller
                    [g_preparingUIViewRouters removeObject:destinationRouter];
                    NSString *description = [NSString stringWithFormat:@"Didn't fine the performer of UIView until it's removing from superview, maybe it's superview was never added to any view controller. Can't find which custom UIView or UIViewController added destination:(%@) as subview, so we can't notify the performer to config the destination. You may add destination to a UIWindow in code directly, and the UIWindow is not a custom class. Please change your code and add subview by a custom view router with ZIKViewRouteTypeAddAsSubview. Destination superview: (%@).",destination, newSuperview];
                    [destinationRouter endPerformRouteWithError:[ZIKViewRouter errorWithCode:ZIKViewRouteErrorInvalidPerformer localizedDescription:description]];
                    NSAssert(NO, description);
                }
                //Destination don't need prepare, but it's superview never be added to a view controller, so destination is never on a window
                if (destinationRouter.state == ZIKRouterStateRouting &&
                    ![destination ZIK_firstAvailableUIViewController]) {
                    //end perform
                    [ZIKViewRouter AOP_notifyAll_router:destinationRouter willPerformRouteOnDestination:destination fromSource:destination.superview];
                    [destinationRouter endPerformRouteWithSuccess];
                }
                [destination setZIK_destinationViewRouter:nil];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteWillRemoveRouteNotification object:destination];
            NSNumber *routeTypeFromRouter = [destination ZIK_routeTypeFromRouter];
            if (!routeTypeFromRouter ||
                [routeTypeFromRouter integerValue] == ZIKViewRouteTypeGetDestination) {
                [ZIKViewRouter AOP_notifyAll_router:nil willRemoveRouteOnDestination:destination fromSource:destination.superview];
            }
        } else if (!destination.ZIK_routed) {
            //Adding to a superview
            ZIKViewRouter *router;
            NSNumber *routeTypeFromRouter = [destination ZIK_routeTypeFromRouter];
            if (!routeTypeFromRouter) {
                //Not routing from router
                Class routerClass = ZIKViewRouterForRegisteredView([destination class]);
                NSAssert([routerClass isSubclassOfClass:[ZIKViewRouter class]], @"Use macro RegisterRoutableView to register destination in it's router, router should be subclass of ZIKViewRouter.");
                NSAssert([routerClass _o_validateSupportedRouteTypesForUIView], @"Router for UIView only suppourts ZIKViewRouteTypeAddAsSubview, ZIKViewRouteTypeGetDestination and ZIKViewRouteTypeCustom, override +supportedRouteTypes in your router.");
                
                id performer = nil;
                BOOL needPrepare = NO;
                if (![routerClass destinationPrepared:destination]) {
                    needPrepare = YES;
                    if (destination.nextResponder) {
                        performer = [destination ZIK_routePerformer];
                    } else if (newSuperview.nextResponder) {
                        performer = [newSuperview ZIK_routePerformer];
                    }
                    //Adding to a superview on screen.
                    if (!performer && (newSuperview.window || [newSuperview isKindOfClass:[UIWindow class]])) {
                        NSString *description = [NSString stringWithFormat:@"Adding to a superview on screen. Can't find which custom UIView or UIViewController added destination:(%@) as subview, so we can't notify the performer to config the destination. You may add destination to a UIWindow in code directly. Please change your code and add subview by a custom view router with ZIKViewRouteTypeAddAsSubview. Destination superview: (%@).",destination, newSuperview];
                        [ZIKViewRouter _o_callbackError_invalidPerformerWithAction:@selector(performRoute) errorDescription:description];
                        NSAssert(NO, description);
                    }
                }
                
                ZIKViewRouter *destinationRouter = [routerClass routerFromView:destination source:newSuperview];
                destinationRouter.routingFromInternal = YES;
                [destinationRouter notifyRouteState:ZIKRouterStateRouting];
                [destination setZIK_destinationViewRouter:destinationRouter];
                if (needPrepare) {
                    if (performer) {
                        [ZIKViewRouter _o_prepareForDestinationRoutingFromExternal:destination router:destinationRouter performer:performer];
                        destinationRouter.prepared = YES;
                    } else {
                        if (!newSuperview.window && ![newSuperview isKindOfClass:[UIWindow class]]) {
                            //Adding to a superview not on screen, can't search performer before -viewDidLoad. willMoveToSuperview: is called before willMoveToWindow:. Find performer and prepare in -ZIKViewRouter_hook_viewDidLoad, do willPerformRoute AOP in -ZIKViewRouter_hook_willMoveToWindow:
                            [g_preparingUIViewRouters addObject:destinationRouter];
                        }
                        NSAssert(!newSuperview.window && ![newSuperview isKindOfClass:[UIWindow class]], @"When new superview is already on screen, performer should not be nil.");
                    }
                } else {
                    [destinationRouter prepareDestination:destination configuration:destinationRouter._nocopy_configuration];
                    [destinationRouter didFinishPrepareDestination:destination configuration:destinationRouter._nocopy_configuration];
                    destinationRouter.prepared = YES;
                }
                router = destinationRouter;
                
                //Adding to a superview on screen.
                if (newSuperview.window || [newSuperview isKindOfClass:[UIWindow class]]) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteWillPerformRouteNotification object:destination];
                    NSNumber *routeTypeFromRouter = [destination ZIK_routeTypeFromRouter];
                    if (!routeTypeFromRouter ||
                        [routeTypeFromRouter integerValue] == ZIKViewRouteTypeGetDestination) {
                        [ZIKViewRouter AOP_notifyAll_router:router willPerformRouteOnDestination:destination fromSource:newSuperview];
                    }
                }
            }
        }
    }
    if (!newSuperview) {
//        NSAssert(destination.ZIK_routed == YES, @"ZIK_routed should be YES before remove");
        [destination setZIK_routed:NO];
    }
    [self ZIKViewRouter_hook_willMoveToSuperview:newSuperview];
}

- (void)ZIKViewRouter_hook_didMoveToSuperview {
    UIView *destination = (UIView *)self;
    UIView *superview = destination.superview;
    if ([self conformsToProtocol:@protocol(ZIKRoutableView)]) {
        if (!superview) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteDidRemoveRouteNotification object:destination];
            NSNumber *routeTypeFromRouter = [destination ZIK_routeTypeFromRouter];
            if (!routeTypeFromRouter ||
                [routeTypeFromRouter integerValue] == ZIKViewRouteTypeGetDestination) {
                [ZIKViewRouter AOP_notifyAll_router:nil didRemoveRouteOnDestination:destination fromSource:nil];//Can't get source, source may already be dealloced here or is in dealloc
            }
            if (routeTypeFromRouter) {
                [destination setZIK_routeTypeFromRouter:nil];
            }
        }
    }
    
    [self ZIKViewRouter_hook_didMoveToSuperview];
}

- (void)ZIKViewRouter_hook_willMoveToWindow:(nullable UIWindow *)newWindow {
    UIView *destination = (UIView *)self;
    BOOL routed = destination.ZIK_routed;
    if ([self conformsToProtocol:@protocol(ZIKRoutableView)]) {
        if (!routed) {
            ZIKViewRouter *router;
            UIView *source;
            NSNumber *routeTypeFromRouter = [destination ZIK_routeTypeFromRouter];
            BOOL searchPerformerInDidMoveToWindow = NO;
            if (!routeTypeFromRouter) {
                ZIKViewRouter *destinationRouter = [destination ZIK_destinationViewRouter];
                NSString *failedToPrepareDescription;
                if (destinationRouter) {
                    if ([g_preparingUIViewRouters containsObject:destinationRouter]) {
                        //Didn't fine the performer of UIView route  before it's displayed on screen. But maybe can find in -didMoveToWindow.
                        [g_preparingUIViewRouters removeObject:destinationRouter];
                        failedToPrepareDescription = [NSString stringWithFormat:@"Didn't fine the performer of UIView route before it's displayed on screen. Can't find which custom UIView or UIViewController added destination:(%@) as subview, so we can't notify the performer to config the destination. You may add destination to a UIWindow in code directly, and the UIWindow is not a custom class. Please change your code and add subview by a custom view router with ZIKViewRouteTypeAddAsSubview. Destination superview: %@.",destination, destination.superview];
                    }
                }
                
                //Was added to a superview when superview was not on screen, and it's displayed now.
                if (destination.superview) {
                    Class routerClass = ZIKViewRouterForRegisteredView([destination class]);
                    NSAssert([routerClass isSubclassOfClass:[ZIKViewRouter class]], @"Use macro RegisterRoutableView to register destination in it's router, router should be subclass of ZIKViewRouter.");
                    NSAssert([routerClass _o_validateSupportedRouteTypesForUIView], @"Router for UIView only suppourts ZIKViewRouteTypeAddAsSubview, ZIKViewRouteTypeGetDestination and ZIKViewRouteTypeCustom, override +supportedRouteTypes in your router.");
                    
                    source = destination.superview;
                    
                    if (!destinationRouter) {
                        destinationRouter = [routerClass routerFromView:destination source:source];
                        destinationRouter.routingFromInternal = YES;
                        [destinationRouter notifyRouteState:ZIKRouterStateRouting];
                        [destination setZIK_destinationViewRouter:destinationRouter];
                    }
                    
                    if (!destinationRouter.prepared) {
                        id performer = nil;
                        BOOL needPrepare = NO;
                        BOOL onScreen = NO;
                        if (![routerClass destinationPrepared:destination]) {
                            needPrepare = YES;
                            onScreen = ([destination ZIK_firstAvailableUIViewController] != nil);
                            
                            if (onScreen) {
                                performer = [destination ZIK_routePerformer];
                            }
                            
                            if (onScreen) {
                                if (!performer) {
                                    NSString *description;
                                    if (failedToPrepareDescription) {
                                        description = failedToPrepareDescription;
                                    } else {
                                        description = [NSString stringWithFormat:@"Can't find which custom UIView or UIViewController added destination:(%@) as subview, so we can't notify the performer to config the destination. You may add destination to a UIWindow in code directly, and the UIWindow is not a custom class. Please change your code and add subview by a custom view router with ZIKViewRouteTypeAddAsSubview. Destination superview: %@.",destination, destination.superview];
                                    }
                                    [ZIKViewRouter _o_callbackError_invalidPerformerWithAction:@selector(performRoute) errorDescription:description];
                                    NSAssert(NO, description);
                                }
                                NSAssert(ZIKClassIsCustomClass(performer), @"performer should be a subclass of UIViewController in your project.");
                            }
                        }
                        if (onScreen) {
                            if (needPrepare) {
                                [ZIKViewRouter _o_prepareForDestinationRoutingFromExternal:destination router:destinationRouter performer:performer];
                            } else {
                                [destinationRouter prepareDestination:destination configuration:destinationRouter._nocopy_configuration];
                                [destinationRouter didFinishPrepareDestination:destination configuration:destinationRouter._nocopy_configuration];
                            }
                        } else {
                            searchPerformerInDidMoveToWindow = YES;
                            [g_preparingUIViewRouters addObject:destinationRouter];
                        }
                    }
                    
                    router = destinationRouter;
                }
            }
            
            //Was added to a superview when superview was not on screen, and it's displayed now.
            if (!routed && destination.superview && !searchPerformerInDidMoveToWindow) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteWillPerformRouteNotification object:destination];
                if (!routeTypeFromRouter ||
                    [routeTypeFromRouter integerValue] == ZIKViewRouteTypeGetDestination) {
                    [ZIKViewRouter AOP_notifyAll_router:router willPerformRouteOnDestination:destination fromSource:source];
                }
            }
        }
    }
    
    [self ZIKViewRouter_hook_willMoveToWindow:newWindow];
}

- (void)ZIKViewRouter_hook_didMoveToWindow {
    UIView *destination = (UIView *)self;
    UIWindow *window = destination.window;
    UIView *superview = destination.superview;
    BOOL routed = destination.ZIK_routed;
    if ([self conformsToProtocol:@protocol(ZIKRoutableView)]) {
        if (!routed) {
            ZIKViewRouter *router;
            NSNumber *routeTypeFromRouter = [destination ZIK_routeTypeFromRouter];
            if (!routeTypeFromRouter) {
                ZIKViewRouter *destinationRouter = destination.ZIK_destinationViewRouter;
                NSAssert(destinationRouter, @"destinationRouter should be set in -ZIKViewRouter_hook_willMoveToSuperview:");
                router = destinationRouter;
                
                //Find performer and prepare for destination added to a superview not on screen in -ZIKViewRouter_hook_willMoveToSuperview
                if (g_preparingUIViewRouters.count > 0) {
                    if ([g_preparingUIViewRouters containsObject:destinationRouter]) {
                        [g_preparingUIViewRouters removeObject:destinationRouter];
                        id performer = [destination ZIK_routePerformer];
                        if (performer) {
                            [ZIKViewRouter _o_prepareForDestinationRoutingFromExternal:destination router:destinationRouter performer:performer];
                            router.prepared = YES;
                            
                        } else {
                            NSString *description = [NSString stringWithFormat:@"Didn't find performer when UIView is already on screen. Can't find which custom UIView or UIViewController added destination:(%@) as subview, so we can't notify the performer to config the destination. You may add destination to a UIWindow in code directly, and the UIWindow is not a custom class. Please change your code and add subview by a custom view router with ZIKViewRouteTypeAddAsSubview. Destination superview: %@.",destination, destination.superview];
                            [ZIKViewRouter _o_callbackError_invalidPerformerWithAction:@selector(performRoute) errorDescription:description];
                            NSAssert(NO, description);
                        }
                        [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteWillPerformRouteNotification object:destination];
                        if (!routeTypeFromRouter ||
                            [routeTypeFromRouter integerValue] == ZIKViewRouteTypeGetDestination) {
                            [ZIKViewRouter AOP_notifyAll_router:router willPerformRouteOnDestination:destination fromSource:superview];
                        }
                    }
                }
                //end perform
                [destinationRouter notifyRouteState:ZIKRouterStateRouted];
                [destinationRouter notifyPerformRouteSuccessWithDestination:destination];
                [destination setZIK_destinationViewRouter:nil];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteDidPerformRouteNotification object:destination];
            if (!routeTypeFromRouter ||
                [routeTypeFromRouter integerValue] == ZIKViewRouteTypeGetDestination) {
                [ZIKViewRouter AOP_notifyAll_router:router didPerformRouteOnDestination:destination fromSource:superview];
            }
            router.routingFromInternal = NO;
            if (routeTypeFromRouter) {
                [destination setZIK_routeTypeFromRouter:nil];
            }
        }
    }
    
    [self ZIKViewRouter_hook_didMoveToWindow];
    if (!routed && window) {
        [destination setZIK_routed:YES];
    }
}

- (void)ZIKViewRouter_hook_prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    /**
     We hooked every UIViewController and subclasses in +load, because a vc may override -prepareForSegue:sender: and not call [super prepareForSegue:sender:].
     If subclass vc call [super prepareForSegue:sender:] in it's -prepareForSegue:sender:, because it's superclass's -prepareForSegue:sender: was alse hooked, we will enter -ZIKViewRouter_hook_prepareForSegue:sender: for superclass. But we can't invoke superclass's original implementation by [self ZIKViewRouter_hook_prepareForSegue:sender:], it will call current class's original implementation, then there is an endless loop.
     To sovle this, we use a 'currentClassCalling' variable to mark the next class which calling -prepareForSegue:sender:, if -prepareForSegue:sender: was called again in a same call stack, fetch the original implementation in 'currentClassCalling', and just call original implementation, don't enter -ZIKViewRouter_hook_prepareForSegue:sender: again.
     
     Something else: this solution relies on correct use of [super prepareForSegue:sender:]. Every time -prepareForSegue:sender: was invoked, the 'currentClassCalling' will be updated as 'currentClassCalling = [currentClassCalling superclass]'.So these codes will lead to bug:
     1. - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     [super prepareForSegue:segue sender:sender];
     [super prepareForSegue:segue sender:sender];
     }
     1. - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     dispatch_async(dispatch_get_main_queue(), ^{
     [super prepareForSegue:segue sender:sender];
     });
     }
     These bad implementations should never exist in your code, so we ignore these situations.
     */
    Class currentClassCalling = [(UIViewController *)self ZIK_currentClassCallingPrepareForSegue];
    if (!currentClassCalling) {
        currentClassCalling = [self class];
    }
    [(UIViewController *)self setZIK_currentClassCallingPrepareForSegue:[currentClassCalling superclass]];
    
    if (currentClassCalling != [self class]) {
        //Call [super prepareForSegue:segue sender:sender]
        Method superMethod = class_getInstanceMethod(currentClassCalling, @selector(ZIKViewRouter_hook_prepareForSegue:sender:));
        IMP superImp = method_getImplementation(superMethod);
        NSAssert(superMethod && superImp, @"ZIKViewRouter_hook_prepareForSegue:sender: should exist in super");
        if (superImp) {
            ((void(*)(id, SEL, UIStoryboardSegue *, id))superImp)(self, @selector(prepareForSegue:sender:), segue, sender);
        }
        return;
    }
    
    UIViewController *source = segue.sourceViewController;
    UIViewController *destination = segue.destinationViewController;
    
    BOOL isUnwindSegue = YES;
    if (![destination isViewLoaded] ||
        (!destination.parentViewController &&
         !destination.presentingViewController)) {
            isUnwindSegue = NO;
        }
    
    ZIKViewRouter *sourceRouter = [(UIViewController *)self ZIK_sourceViewRouter];
    if (sourceRouter) {
        //This segue is performed from router, see -_o_performSegueWithIdentifier:fromSource:sender:
        ZIKViewRouteSegueConfiguration *configuration = sourceRouter._nocopy_configuration.segueConfiguration;
        if (!configuration.segueSource) {
            NSAssert([segue.identifier isEqualToString:configuration.identifier], @"should be same identifier");
            [sourceRouter attachDestination:destination];
            configuration.segueSource = source;
            configuration.segueDestination = destination;
            configuration.destinationStateBeforeRoute = [destination ZIK_presentationState];
            if (isUnwindSegue) {
                sourceRouter.realRouteType = ZIKViewRouteRealTypeUnwind;
            }
        }
        
        [(UIViewController *)self setZIK_sourceViewRouter:nil];
        [source setZIK_sourceViewRouter:sourceRouter];//Set nil in -ZIKViewRouter_hook_seguePerform
        [destination setZIK_sourceViewRouter:sourceRouter];
    }
    
    NSMutableArray<ZIKViewRouter *> *destinationRouters;//routers for child view controllers conform to ZIKRoutableView in destination
    NSMutableArray<UIViewController *> *routableViews;
    
    if (!isUnwindSegue) {
        destinationRouters = [NSMutableArray array];
        if ([destination conformsToProtocol:@protocol(ZIKRoutableView)]) {//if destination is ZIKRoutableView, create router for it
            if (sourceRouter && sourceRouter._nocopy_configuration.segueConfiguration.segueDestination == destination) {
                [destinationRouters addObject:sourceRouter];//If this segue is performed from router, don't auto create router again
            } else {
                routableViews = [NSMutableArray array];
                [routableViews addObject:destination];
            }
        }
        
        NSArray<UIViewController *> *subRoutableViews = [ZIKViewRouter routableViewsInContainerViewController:destination];//Search child view controllers conform to ZIKRoutableView in destination
        if (subRoutableViews.count > 0) {
            if (!routableViews) {
                routableViews = [NSMutableArray array];
            }
            [routableViews addObjectsFromArray:subRoutableViews];
        }
        
        //Generate router for each routable view
        if (routableViews.count > 0) {
            for (UIViewController *routableView in routableViews) {
                Class routerClass = ZIKViewRouterForRegisteredView([routableView class]);
                NSAssert([routerClass isSubclassOfClass:[ZIKViewRouter class]], @"Destination's view router should be subclass of ZIKViewRouter");
                ZIKViewRouter *destinationRouter = [routerClass routerFromSegueIdentifier:segue.identifier sender:sender destination:routableView source:(UIViewController *)self];
                destinationRouter.routingFromInternal = YES;
                ZIKViewRouteSegueConfiguration *segueConfig = destinationRouter._nocopy_configuration.segueConfiguration;
                NSAssert(destinationRouter && segueConfig, @"Failed to create router.");
                segueConfig.destinationStateBeforeRoute = [routableView ZIK_presentationState];
                if (destinationRouter) {
                    [destinationRouters addObject:destinationRouter];
                }
            }
        }
        if (destinationRouters.count > 0) {
            [destination setZIK_destinationViewRouters:destinationRouters];//Get and set nil in -ZIKViewRouter_hook_seguePerform
        }
    }
    
    //Call original implementation of current class
    [self ZIKViewRouter_hook_prepareForSegue:segue sender:sender];
    [(UIViewController *)self setZIK_currentClassCallingPrepareForSegue:nil];
    
    void(^prepareForRouteInSourceRouter)(id destination);
    if (sourceRouter) {
        prepareForRouteInSourceRouter = sourceRouter._nocopy_configuration.prepareForRoute;
    }
    
    //Prepare for unwind destination or unroutable views
    if (sourceRouter && sourceRouter._nocopy_configuration.segueConfiguration.segueDestination == destination) {
        if (isUnwindSegue) {
            if (prepareForRouteInSourceRouter) {
                prepareForRouteInSourceRouter(destination);
            }
            return;
        }
        if (![destination conformsToProtocol:@protocol(ZIKRoutableView)]) {
            if (prepareForRouteInSourceRouter) {
                prepareForRouteInSourceRouter(destination);
            }
        }
    }
    //Prepare routable views
    for (NSInteger idx = 0; idx < destinationRouters.count; idx++) {
        ZIKViewRouter *router = [destinationRouters objectAtIndex:idx];
        UIViewController * routableView = router.destination;
        NSAssert(routableView, @"Destination wasn't set when create destinationRouters");
        [routableView setZIK_routeTypeFromRouter:@(ZIKViewRouteTypePerformSegue)];
        [router notifyRouteState:ZIKRouterStateRouting];
        if (sourceRouter) {
            //Segue is performed from a router
            if (prepareForRouteInSourceRouter) {
                prepareForRouteInSourceRouter(routableView);
            }
            [router prepareForPerformRouteOnDestination:routableView];
        } else {
            //View controller is from storyboard, need to notify the performer of segue to config the destination
            [ZIKViewRouter _o_prepareForDestinationRoutingFromExternal:routableView router:router performer:(UIViewController *)self];
        }
        [ZIKViewRouter AOP_notifyAll_router:router willPerformRouteOnDestination:routableView fromSource:source];
    }
}

- (void)ZIKViewRouter_hook_seguePerform {
    Class currentClassCalling = [(UIStoryboardSegue *)self ZIK_currentClassCallingPerform];
    if (!currentClassCalling) {
        currentClassCalling = [self class];
    }
    [(UIStoryboardSegue *)self setZIK_currentClassCallingPerform:[currentClassCalling superclass]];
    
    if (currentClassCalling != [self class]) {
        //[super perform]
        Method superMethod = class_getInstanceMethod(currentClassCalling, @selector(ZIKViewRouter_hook_seguePerform));
        IMP superImp = method_getImplementation(superMethod);
        NSAssert(superMethod && superImp, @"ZIKViewRouter_hook_seguePerform should exist in super");
        if (superImp) {
            ((void(*)(id, SEL))superImp)(self, @selector(perform));
        }
        return;
    }
    
    UIViewController *destination = [(UIStoryboardSegue *)self destinationViewController];
    UIViewController *source = [(UIStoryboardSegue *)self sourceViewController];
    ZIKViewRouter *sourceRouter = [source ZIK_sourceViewRouter];//Set in -ZIKViewRouter_hook_prepareForSegue:sender:
    NSArray<ZIKViewRouter *> *destinationRouters = [destination ZIK_destinationViewRouters];
    
    //Call original implementation of current class
    [self ZIKViewRouter_hook_seguePerform];
    [(UIStoryboardSegue *)self setZIK_currentClassCallingPerform:nil];
    
    //If this is not a unwind route, and destination contains routable views (see ZIKViewRouter_hook_prepareForSegue:sender:)
    if (destinationRouters.count > 0) {
        [destination setZIK_destinationViewRouters:nil];
    }
    if (sourceRouter) {
        [source setZIK_sourceViewRouter:nil];
        [destination setZIK_sourceViewRouter:nil];
    }
    
    id <UIViewControllerTransitionCoordinator> transitionCoordinator = [source ZIK_currentTransitionCoordinator];
    if (!transitionCoordinator) {
        transitionCoordinator = [destination ZIK_currentTransitionCoordinator];
    }
    void(^routeCompletionInSourceRouter)(id destination);
    if (sourceRouter) {
        //Complete unwind route. Unwind route doesn't need to config destination
        if (sourceRouter.realRouteType == ZIKViewRouteRealTypeUnwind &&
            sourceRouter._nocopy_configuration.segueConfiguration.segueDestination == destination) {
            [ZIKViewRouter _o_completeWithtransitionCoordinator:transitionCoordinator transitionCompletion:^{
                [sourceRouter notifyRouteState:ZIKRouterStateRouted];
                [sourceRouter notifyPerformRouteSuccessWithDestination:destination];
                sourceRouter.routingFromInternal = NO;
            }];
            return;
        }
        routeCompletionInSourceRouter = sourceRouter._nocopy_configuration.routeCompletion;
    }
    
    //Complete routable views
    for (NSInteger idx = destinationRouters.count - 1; idx >= 0; idx--) {
        ZIKViewRouter *router = [destinationRouters objectAtIndex:idx];
        UIViewController *routableView = router.destination;
        ZIKPresentationState *destinationStateBeforeRoute = router._nocopy_configuration.segueConfiguration.destinationStateBeforeRoute;
        NSAssert(destinationStateBeforeRoute, @"Didn't set state in -ZIKViewRouter_hook_prepareForSegue:sender:");
        [ZIKViewRouter _o_completeRouter:router
          analyzeRouteTypeForDestination:routableView
                                  source:source
             destinationStateBeforeRoute:destinationStateBeforeRoute
                   transitionCoordinator:transitionCoordinator
                              completion:^{
                                  NSAssert(router.state == ZIKRouterStateRouting, @"state should be routing when end route");
                                  [router notifyRouteState:ZIKRouterStateRouted];
                                  [router notifyPerformRouteSuccessWithDestination:routableView];
                                  if (sourceRouter) {
                                      if (routableView == sourceRouter.destination) {
                                          NSAssert(idx == 0, @"If destination is in destinationRouters, it should be at index 0.");
                                          NSAssert(router == sourceRouter, nil);
                                      } else if (routeCompletionInSourceRouter) {
                                          //Let performer prepare each routable views
                                          routeCompletionInSourceRouter(routableView);
                                      }
                                  }
                                  [ZIKViewRouter AOP_notifyAll_router:router didPerformRouteOnDestination:routableView fromSource:source];
                                  router.routingFromInternal = NO;
                              }];
    }
    //Complete unroutable view
    if (sourceRouter && sourceRouter._nocopy_configuration.segueConfiguration.segueDestination == destination && ![destination conformsToProtocol:@protocol(ZIKRoutableView)]) {
        ZIKPresentationState *destinationStateBeforeRoute = sourceRouter._nocopy_configuration.segueConfiguration.destinationStateBeforeRoute;
        NSAssert(destinationStateBeforeRoute, @"Didn't set state in -ZIKViewRouter_hook_prepareForSegue:sender:");
        [ZIKViewRouter _o_completeRouter:sourceRouter
          analyzeRouteTypeForDestination:destination
                                  source:source
             destinationStateBeforeRoute:destinationStateBeforeRoute
                   transitionCoordinator:transitionCoordinator
                              completion:^{
                                  [sourceRouter notifyRouteState:ZIKRouterStateRouted];
                                  [sourceRouter notifyPerformRouteSuccessWithDestination:destination];
                                  sourceRouter.routingFromInternal = NO;
                              }];
    }
}

+ (nullable NSArray<UIViewController *> *)routableViewsInContainerViewController:(UIViewController *)vc {
    NSMutableArray *routableViews;
    NSArray<__kindof UIViewController *> *childViewControllers = vc.childViewControllers;
    if (childViewControllers.count == 0) {
        return routableViews;
    }
    
    BOOL isContainerVC = NO;
    BOOL isSystemViewController = NO;
    NSArray<UIViewController *> *rootVCs;
    if ([vc isKindOfClass:[UINavigationController class]]) {
        isContainerVC = YES;
        if ([(UINavigationController *)vc viewControllers].count > 0) {
            UIViewController *rootViewController = [[(UINavigationController *)vc viewControllers] firstObject];
            if (rootViewController) {
                rootVCs = @[rootViewController];
            } else {
                rootVCs = @[];
            }
        }
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        isContainerVC = YES;
        rootVCs = [(UITabBarController *)vc viewControllers];
    } else if ([vc isKindOfClass:[UISplitViewController class]]) {
        isContainerVC = YES;
        rootVCs = [(UISplitViewController *)vc viewControllers];
    }
    
    if (ZIKClassIsCustomClass([vc class]) == NO) {
        isSystemViewController = YES;
    }
    if (isContainerVC) {
        if (!routableViews) {
            routableViews = [NSMutableArray array];
        }
        for (UIViewController *child in rootVCs) {
            if ([child conformsToProtocol:@protocol(ZIKRoutableView)]) {
                [routableViews addObject:child];
            } else {
                NSArray<UIViewController *> *routableViewsInChild = [self routableViewsInContainerViewController:child];
                if (routableViewsInChild.count > 0) {
                    [routableViews addObjectsFromArray:routableViewsInChild];
                }
            }
        }
    }
    if (isSystemViewController) {
        if (!routableViews) {
            routableViews = [NSMutableArray array];
        }
        for (UIViewController *child in vc.childViewControllers) {
            if (rootVCs && [rootVCs containsObject:child]) {
                continue;
            }
            if ([child conformsToProtocol:@protocol(ZIKRoutableView)]) {
                [routableViews addObject:child];
            } else {
                NSArray<UIViewController *> *routableViewsInChild = [self routableViewsInContainerViewController:child];
                if (routableViewsInChild.count > 0) {
                    [routableViews addObjectsFromArray:routableViewsInChild];
                }
            }
        }
    }
    return routableViews;
}

#pragma mark Validate

+ (BOOL)_o_validateRouteTypeInConfiguration:(ZIKViewRouteConfiguration *)configuration {
    if (![self supportRouteType:configuration.routeType]) {
        return NO;
    }
    return YES;
}

+ (BOOL)_o_validateRouteSourceNotMissedInConfiguration:(ZIKViewRouteConfiguration *)configuration {
    if (!configuration.source) {
        if (configuration.routeType != ZIKViewRouteTypeCustom && configuration.routeType != ZIKViewRouteTypeGetDestination) {
            NSLog(@"");
        }
    }
    if (!configuration.source &&
        (configuration.routeType != ZIKViewRouteTypeCustom &&
        configuration.routeType != ZIKViewRouteTypeGetDestination)) {
        return NO;
    }
    return YES;
}

+ (BOOL)_o_validateRouteSourceClassInConfiguration:(ZIKViewRouteConfiguration *)configuration {
    if (!configuration.source &&
        (configuration.routeType != ZIKViewRouteTypeCustom &&
         configuration.routeType != ZIKViewRouteTypeGetDestination)) {
        return NO;
    }
    id source = configuration.source;
    switch (configuration.routeType) {
        case ZIKViewRouteTypeAddAsSubview:
            if (![source isKindOfClass:[UIView class]]) {
                return NO;
            }
            break;
            
        case ZIKViewRouteTypePerformSegue:
            break;
            
        case ZIKViewRouteTypeCustom:
        case ZIKViewRouteTypeGetDestination:
            break;
        default:
            if (![source isKindOfClass:[UIViewController class]]) {
                return NO;
            }
            break;
    }
    return YES;
}

+ (BOOL)_o_validateSegueInConfiguration:(ZIKViewRouteConfiguration *)configuration {
    if (!configuration.segueConfiguration.identifier && !configuration.autoCreated) {
        return NO;
    }
    return YES;
}

+ (BOOL)_o_validatePopoverInConfiguration:(ZIKViewRouteConfiguration *)configuration {
    ZIKViewRoutePopoverConfiguration *popoverConfig = configuration.popoverConfiguration;
    if (!popoverConfig ||
        (!popoverConfig.barButtonItem && !popoverConfig.sourceView)) {
        return NO;
    }
    return YES;
}

+ (BOOL)_o_validateDestinationShouldExistInConfiguration:(ZIKViewRouteConfiguration *)configuration {
    if (configuration.routeType == ZIKViewRouteTypePerformSegue) {
        return NO;
    }
    return YES;
}

+ (BOOL)_o_validateDestinationClass:(nullable id)destination inConfiguration:(ZIKViewRouteConfiguration *)configuration {
    NSAssert(!destination || [destination conformsToProtocol:@protocol(ZIKRoutableView)], @"Destination must conforms to ZIKRoutableView. Use macro RegisterRoutableView to quick config in it's custom router. It's used to config view not created from router.");
    
    switch (configuration.routeType) {
        case ZIKViewRouteTypeAddAsSubview:
            if ([destination isKindOfClass:[UIView class]]) {
                NSAssert([[self class] _o_validateSupportedRouteTypesForUIView], @"%@ 's +supportedRouteTypes returns error types, if destination is a UIView, %@ only support ZIKViewRouteTypeAddAsSubview and ZIKViewRouteTypeCustom",[self class], [self class]);
                return YES;
            }
            break;
        case ZIKViewRouteTypeCustom:
            if ([destination isKindOfClass:[UIView class]]) {
                NSAssert([[self class] _o_validateSupportedRouteTypesForUIView], @"%@ 's +supportedRouteTypes returns error types, if destination is a UIView, %@ only support ZIKViewRouteTypeAddAsSubview and ZIKViewRouteTypeCustom, if use ZIKViewRouteTypeCustom, router must implement -performCustomRouteOnDestination:fromSource:configuration:.",[self class], [self class]);
                return YES;
            } else if ([destination isKindOfClass:[UIViewController class]]) {
                NSAssert([[self class] _o_validateSupportedRouteTypesForUIViewController], @"%@ 's +supportedRouteTypes returns error types, if destination is a UIViewController, %@ can't support ZIKViewRouteTypeAddAsSubview, if use ZIKViewRouteTypeCustom, router must implement -performCustomRouteOnDestination:fromSource:configuration:.",[self class], [self class]);
                return YES;
            }
            break;
            
        case ZIKViewRouteTypePerformSegue:
            NSAssert(!destination, @"ZIKViewRouteTypePerformSegue's destination should be created by UIKit automatically");
            return YES;
            break;
            
        default:
            if ([destination isKindOfClass:[UIViewController class]]) {
                NSAssert([[self class] _o_validateSupportedRouteTypesForUIViewController], @"%@ 's +supportedRouteTypes returns error types, if destination is a UIViewController, %@ can't support ZIKViewRouteTypeAddAsSubview",[self class], [self class]);
                return YES;
            }
            break;
    }
    return NO;
}

+ (BOOL)_o_validateSourceInNavigationStack:(UIViewController *)source {
    BOOL canPerformPush = [source respondsToSelector:@selector(navigationController)];
    if (!canPerformPush ||
        (canPerformPush && !source.navigationController)) {
        return NO;
    }
    return YES;
}

+ (BOOL)_o_validateDestination:(UIViewController *)destination notInNavigationStackOfSource:(UIViewController *)source {
    NSArray<UIViewController *> *viewControllersInStack = source.navigationController.viewControllers;
    if ([viewControllersInStack containsObject:destination]) {
        return NO;
    }
    return YES;
}

+ (BOOL)_o_validateSourceNotPresentedAnyView:(UIViewController *)source {
    if (source.presentedViewController) {
        return NO;
    }
    return YES;
}

+ (BOOL)_o_validateSourceInWindowHierarchy:(UIViewController *)source {
    if (!source.isViewLoaded) {
        return NO;
    }
    if (!source.view.superview) {
        return NO;
    }
    if (!source.view.window) {
        return NO;
    }
    return YES;
}

+ (BOOL)_o_validateSupportedRouteTypesForUIView {
    NSMutableArray<NSNumber *> *supportedRouteTypes = [[self supportedRouteTypes] mutableCopy];
    if (supportedRouteTypes.count == 0) {
        return NO;
    }
    if ([supportedRouteTypes containsObject:@(ZIKViewRouteTypeCustom)]) {
        if (![self instancesRespondToSelector:@selector(performCustomRouteOnDestination:fromSource:configuration:)]) {
            return NO;
        }
    }
    [supportedRouteTypes removeObject:@(ZIKViewRouteTypeAddAsSubview)];
    [supportedRouteTypes removeObject:@(ZIKViewRouteTypeGetDestination)];
    [supportedRouteTypes removeObject:@(ZIKViewRouteTypeCustom)];
    if (supportedRouteTypes.count > 0) {
        return NO;
    }
    return YES;
}

+ (BOOL)_o_validateSupportedRouteTypesForUIViewController {
    NSArray<NSNumber *> *supportedRouteTypes = [self supportedRouteTypes];
    if (supportedRouteTypes.count == 0) {
        return NO;
    }
    if ([supportedRouteTypes containsObject:@(ZIKViewRouteTypeCustom)]) {
        if (![self instancesRespondToSelector:@selector(performCustomRouteOnDestination:fromSource:configuration:)]) {
            return NO;
        }
    }
    if ([supportedRouteTypes containsObject:@(ZIKViewRouteTypeAddAsSubview)]) {
        return NO;
    }
    return YES;
}

#pragma mark Error Handle

+ (NSString *)errorDomain {
    return kZIKViewRouteErrorDomain;
}

+ (void)setGlobalErrorHandler:(ZIKViewRouteGlobalErrorHandler)globalErrorHandler {
    dispatch_semaphore_wait(g_globalErrorSema, DISPATCH_TIME_FOREVER);
    
    g_globalErrorHandler = globalErrorHandler;
    
    dispatch_semaphore_signal(g_globalErrorSema);
}

- (void)_o_callbackErrorWithAction:(SEL)routeAction error:(NSError *)error {
    [[self class] _o_callbackGlobalErrorHandlerWithRouter:self action:routeAction error:error];
    [super notifyError:error routeAction:routeAction];
}

+ (void)_o_callbackGlobalErrorHandlerWithRouter:(__kindof ZIKViewRouter *)router action:(SEL)action error:(NSError *)error {
    dispatch_semaphore_wait(g_globalErrorSema, DISPATCH_TIME_FOREVER);
    
    ZIKViewRouteGlobalErrorHandler errorHandler = g_globalErrorHandler;
    if (errorHandler) {
        errorHandler(router, action, error);
    } else {
#ifdef DEBUG
        NSLog(@"❌ZIKViewRouter Error: router's action (%@) catch error: (%@),\nrouter:(%@)", NSStringFromSelector(action), error,router);
#endif
    }
    
    dispatch_semaphore_signal(g_globalErrorSema);
}

//Call your errorHandler and globalErrorHandler, use this if you don't want to affect the routing
- (void)_o_callbackError_errorCode:(ZIKViewRouteError)code
                      errorHandler:(void(^)(SEL routeAction, NSError *error))errorHandler
                            action:(SEL)action
                  errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    
    NSError *error = [[self class] errorWithCode:code localizedDescription:description];
    [[self class] _o_callbackGlobalErrorHandlerWithRouter:self action:action error:error];
    if (errorHandler) {
        errorHandler(action,error);
    }
}

+ (void)_o_callbackError_invalidPerformerWithAction:(SEL)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self _o_callbackGlobalErrorHandlerWithRouter:nil action:action error:[[self class] errorWithCode:ZIKViewRouteErrorInvalidPerformer localizedDescription:description]];
}

+ (void)_o_callbackError_invalidProtocolWithAction:(SEL)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [[self class] _o_callbackGlobalErrorHandlerWithRouter:nil action:action error:[[self class] errorWithCode:ZIKViewRouteErrorInvalidProtocol localizedDescription:description]];
    NSAssert(NO, @"Error when get router for viewProtocol: %@",description);
}

- (void)_o_callbackError_invalidConfigurationWithAction:(SEL)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self _o_callbackErrorWithAction:action error:[[self class] errorWithCode:ZIKViewRouteErrorInvalidConfiguration localizedDescription:description]];
}

- (void)_o_callbackError_unsupportTypeWithAction:(SEL)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self _o_callbackErrorWithAction:action error:[[self class] errorWithCode:ZIKViewRouteErrorUnsupportType localizedDescription:description]];
}

- (void)_o_callbackError_unbalancedTransitionWithAction:(SEL)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [[self class] _o_callbackGlobalErrorHandlerWithRouter:self action:action error:[[self class] errorWithCode:ZIKViewRouteErrorUnbalancedTransition localizedDescription:description]];
    NSAssert(NO, @"Unbalanced calls to begin/end appearance transitions for destination. This error occurs when you try and display a view controller before the current view controller is finished displaying. This may cause the UIViewController skips or messes up the order calling -viewWillAppear:, -viewDidAppear:, -viewWillDisAppear: and -viewDidDisappear:, and messes up the route state.");
}

- (void)_o_callbackError_invalidSourceWithAction:(SEL)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self _o_callbackErrorWithAction:action error:[[self class] errorWithCode:ZIKViewRouteErrorInvalidSource localizedDescription:description]];
}

- (void)_o_callbackError_invalidContainerWithAction:(SEL)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self _o_callbackErrorWithAction:action error:[[self class] errorWithCode:ZIKViewRouteErrorInvalidContainer localizedDescription:description]];
}

- (void)_o_callbackError_actionFailedWithAction:(SEL)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self _o_callbackErrorWithAction:action error:[[self class] errorWithCode:ZIKViewRouteErrorActionFailed localizedDescription:description]];
}

- (void)_o_callbackError_segueNotPerformedWithAction:(SEL)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self _o_callbackErrorWithAction:action error:[[self class] errorWithCode:ZIKViewRouteErrorSegueNotPerformed localizedDescription:description]];
}

- (void)_o_callbackError_overRouteWithAction:(SEL)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self _o_callbackErrorWithAction:action error:[[self class] errorWithCode:ZIKViewRouteErrorOverRoute localizedDescription:description]];
}

#pragma mark Getter/Setter

- (BOOL)autoCreated {
    return self._nocopy_configuration.autoCreated;
}

#pragma mark Debug

+ (NSString *)descriptionOfRouteType:(ZIKViewRouteType)routeType {
    NSString *description;
    switch (routeType) {
        case ZIKViewRouteTypePush:
            description = @"Push";
            break;
        case ZIKViewRouteTypePresentModally:
            description = @"PresentModally";
            break;
        case ZIKViewRouteTypePresentAsPopover:
            description = @"PresentAsPopover";
            break;
        case ZIKViewRouteTypePerformSegue:
            description = @"PerformSegue";
            break;
        case ZIKViewRouteTypeShow:
            description = @"Show";
            break;
        case ZIKViewRouteTypeShowDetail:
            description = @"ShowDetail";
            break;
        case ZIKViewRouteTypeAddAsChildViewController:
            description = @"AddAsChildViewController";
            break;
        case ZIKViewRouteTypeAddAsSubview:
            description = @"AddAsSubview";
            break;
        case ZIKViewRouteTypeCustom:
            description = @"Custom";
            break;
        case ZIKViewRouteTypeGetDestination:
            description = @"GetDestination";
            break;
    }
    return description;
}

+ (NSString *)descriptionOfRealRouteType:(ZIKViewRouteRealType)routeType {
    NSString *description;
    switch (routeType) {
        case ZIKViewRouteRealTypeUnknown:
            description = @"Unknown";
            break;
        case ZIKViewRouteRealTypePush:
            description = @"Push";
            break;
        case ZIKViewRouteRealTypePresentModally:
            description = @"PresentModally";
            break;
        case ZIKViewRouteRealTypePresentAsPopover:
            description = @"PresentAsPopover";
            break;
        case ZIKViewRouteRealTypeAddAsChildViewController:
            description = @"AddAsChildViewController";
            break;
        case ZIKViewRouteRealTypeAddAsSubview:
            description = @"AddAsSubview";
            break;
        case ZIKViewRouteRealTypeUnwind:
            description = @"Unwind";
            break;
        case ZIKViewRouteRealTypeCustom:
            description = @"Custom";
            break;
    }
    return description;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, realRouteType:%@, autoCreated:%d",[super description],[[self class] descriptionOfRealRouteType:self.realRouteType],self.autoCreated];
}

@end

#pragma mark Config for Route

@implementation ZIKViewRouteConfiguration

- (instancetype)init {
    if (self = [super init]) {
        [self configDefaultValue];
    }
    return self;
}

- (void)configDefaultValue {
    _routeType = ZIKViewRouteTypePresentModally;
    _animated = YES;
}

- (void)configureSegue:(ZIKViewRouteSegueConfigure)configure {
    NSParameterAssert(configure);
    NSAssert(!self.segueConfiguration, @"should only configure once");
    ZIKViewRouteSegueConfiguration *config = [ZIKViewRouteSegueConfiguration new];
    configure(config);
    self.segueConfiguration = config;
}

- (ZIKViewRouteSegueConfiger)configureSegue {
    __weak typeof(self) weakSelf = self;
    return ^(ZIKViewRouteSegueConfigure configure) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (strongSelf.segueConfiguration) {
            [ZIKViewRouter _o_callbackGlobalErrorHandlerWithRouter:nil
                                                            action:@selector(configureSegue)
                                                             error:[ZIKViewRouter errorWithCode:ZIKViewRouteErrorInvalidConfiguration
                                                                     localizedDescriptionFormat:@"segueConfiguration for configuration: %@ should only configure once",self]];
            NSAssert(NO, @"segueConfiguration for configuration: %@ should only configure once",self);
        }
        ZIKViewRouteSegueConfiguration *segueConfiguration = [ZIKViewRouteSegueConfiguration new];
        if (configure) {
            configure(segueConfiguration);
        } else {
            [ZIKViewRouter _o_callbackGlobalErrorHandlerWithRouter:nil
                                                            action:@selector(configureSegue)
                                                             error:[ZIKViewRouter errorWithCode:ZIKViewRouteErrorInvalidConfiguration
                                                                     localizedDescriptionFormat:@"When configureSegue for configuration : %@, configure block should not be nil !",self]];
            NSAssert(NO, @"When configureSegue for configuration : %@, configure block should not be nil !",self);
        }
        if (!segueConfiguration.identifier && !strongSelf.autoCreated) {
            [ZIKViewRouter _o_callbackGlobalErrorHandlerWithRouter:nil
                                                            action:@selector(configureSegue)
                                                             error:[ZIKViewRouter errorWithCode:ZIKViewRouteErrorInvalidConfiguration
                                                                     localizedDescriptionFormat:@"configureSegue didn't assign segue identifier for configuration: %@", self]];
            NSAssert(NO, @"configureSegue didn't assign segue identifier for configuration: %@", self);
        }
        strongSelf.segueConfiguration = segueConfiguration;
    };
}

- (ZIKViewRoutePopoverConfiger)configurePopover {
    __weak typeof(self) weakSelf = self;
    return ^(ZIKViewRoutePopoverConfigure configure) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (strongSelf.popoverConfiguration) {
            [ZIKViewRouter _o_callbackGlobalErrorHandlerWithRouter:nil
                                                            action:@selector(configureSegue)
                                                             error:[ZIKViewRouter errorWithCode:ZIKViewRouteErrorInvalidConfiguration
                                                                     localizedDescriptionFormat:@"popoverConfiguration for configuration: %@ should only configure once",self]];
            NSAssert(NO, @"popoverConfiguration for configuration: %@ should only configure once",self);
        }
        ZIKViewRoutePopoverConfiguration *popoverConfiguration = [ZIKViewRoutePopoverConfiguration new];
        if (configure) {
            configure(popoverConfiguration);
        } else {
            [ZIKViewRouter _o_callbackGlobalErrorHandlerWithRouter:nil
                                                            action:@selector(configureSegue)
                                                             error:[ZIKViewRouter errorWithCode:ZIKViewRouteErrorInvalidConfiguration
                                                                     localizedDescriptionFormat:@"When configurePopover for configuration : %@, configure should not be nil !",self]];
            NSAssert(NO, @"When configurePopover for configuration : %@, configure should not be nil !",self);
        }
        if (!popoverConfiguration.sourceView && !popoverConfiguration.barButtonItem) {
            [ZIKViewRouter _o_callbackGlobalErrorHandlerWithRouter:nil
                                                            action:@selector(configureSegue)
                                                             error:[ZIKViewRouter errorWithCode:ZIKViewRouteErrorInvalidConfiguration
                                                                     localizedDescriptionFormat:@"configurePopover didn't assign sourceView or barButtonItem for configuration: %@", self]];
            NSAssert(NO, @"configurePopover didn't assign sourceView or barButtonItem for configuration: %@", self);
        }
        strongSelf.popoverConfiguration = popoverConfiguration;
    };
}

- (id)copyWithZone:(nullable NSZone *)zone {
    ZIKViewRouteConfiguration *config = [super copyWithZone:zone];
    config.source = self.source;
    config.routeType = self.routeType;
    config.animated = self.animated;
    config.autoCreated = self.autoCreated;
    config.containerWrapper = self.containerWrapper;
    config.sender = self.sender;
    config.popoverConfiguration = [self.popoverConfiguration copy];
    config.segueConfiguration = [self.segueConfiguration copy];
    config.prepareForRoute = self.prepareForRoute;
    config.routeCompletion = self.routeCompletion;
    config.handleExternalRoute = self.handleExternalRoute;
    return config;
}

- (NSString *)description {
    NSString *description = [NSString stringWithFormat:@"source:%@, routeType:%@, animated:%d, handleExternalRoute:%d",self.source,[ZIKViewRouter descriptionOfRouteType:self.routeType],self.animated,self.handleExternalRoute];
    if (self.segueConfiguration) {
        description = [description stringByAppendingFormat:@",segue config:(%@)",self.segueConfiguration.description];
    }
    if (self.popoverConfiguration) {
        description = [description stringByAppendingFormat:@",popover config:(%@)",self.popoverConfiguration.description];
    }
    return description;
}

@end

@implementation ZIKViewRoutePopoverConfiguration

- (instancetype)init {
    if (self = [super init]) {
        [self configDefaultValue];
    }
    return self;
}

- (void)configDefaultValue {
    _permittedArrowDirections = UIPopoverArrowDirectionAny;
}

- (void)setSourceRect:(CGRect)sourceRect {
    self.sourceRectConfiged = YES;
    _sourceRect = sourceRect;
}

- (void)setPopoverLayoutMargins:(UIEdgeInsets)popoverLayoutMargins {
    self.popoverLayoutMarginsConfiged = YES;
    _popoverLayoutMargins = popoverLayoutMargins;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    ZIKViewRoutePopoverConfiguration *config = [super copyWithZone:zone];
    config.delegate = self.delegate;
    config.barButtonItem = self.barButtonItem;
    config.sourceRectConfiged = self.sourceRectConfiged;
    config->_sourceRect = self.sourceRect;
    config.sourceView = self.sourceView;
    config.permittedArrowDirections = self.permittedArrowDirections;
    config.passthroughViews = self.passthroughViews;
    config.backgroundColor = self.backgroundColor;
    config.popoverLayoutMarginsConfiged = self.popoverLayoutMarginsConfiged;
    config->_popoverLayoutMargins = self.popoverLayoutMargins;
    config.popoverBackgroundViewClass = self.popoverBackgroundViewClass;
    return config;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"barButtonItem:%@, sourceView:%@, sourceRect:%@", self.barButtonItem,self.sourceView,NSStringFromCGRect(self.sourceRect)];
}

@end

@implementation ZIKViewRouteSegueConfiguration

- (id)copyWithZone:(nullable NSZone *)zone {
    ZIKViewRouteSegueConfiguration *config = [super copyWithZone:zone];
    config.identifier = self.identifier;
    config.sender = self.sender;
    config.segueSource = self.segueSource;
    config.segueDestination = self.segueDestination;
    return config;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"identifier:%@, sender:%@",self.identifier,self.sender];
}

@end

@implementation ZIKViewRemoveConfiguration

- (instancetype)init {
    if (self = [super init]) {
        [self configDefaultValue];
    }
    return self;
}

- (void)configDefaultValue {
    _animated = YES;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    ZIKViewRemoveConfiguration *config = [super copyWithZone:zone];
    config.animated = self.animated;
    config.removeCompletion = self.removeCompletion;
    config.handleExternalRoute = self.handleExternalRoute;
    return config;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"animated:%d,handleExternalRoute:%d",self.animated,self.handleExternalRoute];
}

@end
