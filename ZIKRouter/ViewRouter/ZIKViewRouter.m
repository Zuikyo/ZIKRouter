//
//  ZIKViewRouter.m
//  ZIKRouter
//
//  Created by zuik on 2017/3/2.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKViewRouter.h"
#import "ZIKRouterInternal.h"
#import "ZIKRouterPrivate.h"
#import "ZIKViewRouterInternal.h"
#import "ZIKViewRouterPrivate.h"
#import "ZIKViewRouteRegistry.h"
#import "ZIKRouteRegistryInternal.h"
#import "ZIKViewRouteRegistryPrivate.h"
#import "ZIKViewRoute.h"
#import "ZIKViewRouteError.h"
#import <objc/runtime.h>
#import "ZIKRouterRuntime.h"
#import "ZIKRouterRuntimeDebug.h"
#import "UIViewController+ZIKViewRouter.h"
#import "UIView+ZIKViewRouter.h"
#import "ZIKPresentationState.h"
#import "UIView+ZIKViewRouterPrivate.h"
#import "UIViewController+ZIKViewRouterPrivate.h"
#import "UIStoryboardSegue+ZIKViewRouterPrivate.h"
#import "ZIKRouteConfigurationPrivate.h"
#import "ZIKViewRouteConfigurationPrivate.h"
#import "ZIKViewRouterTypePrivate.h"

/// Notifications to notify all routers that state of its destination is changed
NSNotificationName kZIKViewRouteWillPerformRouteNotification = @"kZIKViewRouteWillPerformRouteNotification";
NSNotificationName kZIKViewRouteDidPerformRouteNotification = @"kZIKViewRouteDidPerformRouteNotification";
NSNotificationName kZIKViewRouteWillRemoveRouteNotification = @"kZIKViewRouteWillRemoveRouteNotification";
NSNotificationName kZIKViewRouteDidRemoveRouteNotification = @"kZIKViewRouteDidRemoveRouteNotification";
NSNotificationName kZIKViewRouteRemoveRouteCancelledNotification = @"kZIKViewRouteRemoveRouteCancelledNotification";

static ZIKViewRouteGlobalErrorHandler g_globalErrorHandler;
static dispatch_semaphore_t g_globalErrorSema;
/// Auto created UIView routers waiting to find performer and prepare
static NSMutableSet *g_preparingXXViewRouters;
/// Auto created UIView routers waiting to finish
static NSMutableSet *g_finishingXXViewRouters;

@interface ZIKViewRouter ()
@property (nonatomic, assign) BOOL routingFromInternal;
@property (nonatomic, assign) ZIKViewRouteRealType realRouteType;
/// Destination prepared. Only for UIView destination
@property (nonatomic, assign) BOOL prepared;
#if ZIK_HAS_UIKIT
@property (nonatomic, strong, nullable) ZIKPresentationState *stateBeforeRoute;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
@property (nonatomic, strong, nullable) UIPopoverController *popover;
#pragma clang diagnostic pop
#endif
@property (nonatomic, weak, nullable) XXViewController<ZIKViewRouteContainer> *container;
@property (nonatomic, strong, nullable) ZIKViewRouter *retainedSelf;
@end

@implementation ZIKViewRouter
@dynamic configuration;
@dynamic original_configuration;
@dynamic original_removeConfiguration;

+ (void)load {
    [ZIKRouteRegistry addRegistry:[ZIKViewRouteRegistry class]];
    g_globalErrorSema = dispatch_semaphore_create(1);
    g_preparingXXViewRouters = [NSMutableSet set];
    g_finishingXXViewRouters = [NSMutableSet set];
    
    Class ZIKViewRouterClass = [ZIKViewRouter class];
    Class XXViewControllerClass = [XXViewController class];
    Class XXStoryboardSegueClass = [XXStoryboardSegue class];
    
#if ZIK_HAS_UIKIT
    zix_replaceMethodWithMethod(XXViewControllerClass, @selector(willMoveToParentViewController:),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_willMoveToParentViewController:));
    zix_replaceMethodWithMethod(XXViewControllerClass, @selector(didMoveToParentViewController:),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_didMoveToParentViewController:));
    zix_replaceMethodWithMethod(XXViewControllerClass, @selector(viewWillAppear:),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_viewWillAppear:));
    zix_replaceMethodWithMethod(XXViewControllerClass, @selector(viewDidAppear:),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_viewDidAppear:));
    zix_replaceMethodWithMethod(XXViewControllerClass, @selector(viewWillDisappear:),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_viewWillDisappear:));
    if (NSClassFromString(@"SLComposeServiceViewController")) {
        //fix SLComposeServiceViewController doesn't call -[super viewWillDisappear:]
        zix_replaceMethodWithMethod(NSClassFromString(@"SLComposeServiceViewController"), @selector(viewWillDisappear:),
                                    ZIKViewRouterClass, @selector(ZIKViewRouter_hook_viewWillDisappear:));
    }
    zix_replaceMethodWithMethod(XXViewControllerClass, @selector(viewDidDisappear:),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_viewDidDisappear:));
    
    zix_replaceMethodWithMethod([XXView class], @selector(willMoveToSuperview:),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_willMoveToSuperview:));
    zix_replaceMethodWithMethod([XXView class], @selector(didMoveToSuperview),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_didMoveToSuperview));
    zix_replaceMethodWithMethod([XXView class], @selector(willMoveToWindow:),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_willMoveToWindow:));
    zix_replaceMethodWithMethod([XXView class], @selector(didMoveToWindow),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_didMoveToWindow));
#else
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [ZIKViewRouter handleWindowWillCloseNotification:note];
    }];
    zix_replaceMethodWithMethod(XXViewControllerClass, @selector(presentViewController:animator:),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_presentViewController:animator:));
    zix_replaceMethodWithMethod([NSWindow class], @selector(setContentViewController:),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_setContentViewController:));
    zix_replaceMethodWithMethod(XXViewControllerClass, @selector(viewWillAppear),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_viewWillAppear));
    zix_replaceMethodWithMethod(XXViewControllerClass, @selector(viewDidAppear),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_viewDidAppear));
    zix_replaceMethodWithMethod(XXViewControllerClass, @selector(viewWillDisappear),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_viewWillDisappear));
    zix_replaceMethodWithMethod(XXViewControllerClass, @selector(viewDidDisappear),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_viewDidDisappear));
    
    zix_replaceMethodWithMethod([XXView class], @selector(viewWillMoveToSuperview:),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_willMoveToSuperview:));
    zix_replaceMethodWithMethod([XXView class], @selector(viewDidMoveToSuperview),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_didMoveToSuperview));
    zix_replaceMethodWithMethod([XXView class], @selector(viewWillMoveToWindow:),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_willMoveToWindow:));
    zix_replaceMethodWithMethod([XXView class], @selector(viewDidMoveToWindow),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_didMoveToWindow));
#endif
    zix_replaceMethodWithMethod(XXViewControllerClass, @selector(viewDidLoad),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_viewDidLoad));
    zix_replaceMethodWithMethod(XXViewControllerClass, @selector(prepareForSegue:sender:),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_prepareForSegue:sender:));
    zix_replaceMethodWithMethod(XXStoryboardSegueClass, @selector(perform),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_seguePerform));
#if ZIK_HAS_UIKIT
    zix_replaceMethodWithMethod([UIStoryboard class], @selector(instantiateInitialViewController),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_instantiateInitialViewController));
#else
    zix_replaceMethodWithMethod([NSStoryboard class], @selector(instantiateInitialController),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_instantiateInitialViewController));
#endif
}

+ (void)_didFinishRegistration {
    
}

#pragma mark Initialize

- (nullable instancetype)initWithConfiguration:(__kindof ZIKViewRouteConfiguration *)configuration removeConfiguration:(nullable __kindof ZIKViewRemoveConfiguration *)removeConfiguration {
    NSParameterAssert([configuration isKindOfClass:[ZIKViewRouteConfiguration class]]);
    
    if (self = [super initWithConfiguration:configuration removeConfiguration:removeConfiguration]) {
        if (![[self class] _validateRouteTypeInConfiguration:configuration]) {
            [self notifyError_unsupportTypeWithAction:ZIKRouteActionInit
                                     errorDescription:@"%@ doesn't support routeType:%ld, supported types: %ld",[self class],configuration.routeType,[[self class] supportedRouteTypes]];
            return nil;
        } else if (![[self class] _validateRouteSourceNotMissedInConfiguration:configuration] ||
                   ![[self class] _validateRouteSourceClassInConfiguration:configuration]) {
            [self notifyError_invalidSourceWithAction:ZIKRouteActionInit
                                     errorDescription:@"Source: (%@) is invalid for configuration: (%@)",configuration.source,configuration];
            return nil;
        } else {
            ZIKViewRouteType type = configuration.routeType;
            if (type == ZIKViewRouteTypePerformSegue) {
                if (![[self class] _validateSegueInConfiguration:configuration]) {
                    [self notifyError_invalidConfigurationWithAction:ZIKRouteActionInit
                                                    errorDescription:@"SegueConfiguration : (%@) was invalid",configuration.segueConfiguration];
                    return nil;
                }
            } else if (type == ZIKViewRouteTypePresentAsPopover) {
                if (![[self class] _validatePopoverInConfiguration:configuration]) {
                    [self notifyError_invalidConfigurationWithAction:ZIKRouteActionInit
                                                    errorDescription:@"PopoverConfiguration : (%@) was invalid",configuration.popoverConfiguration];
                    return nil;
                }
            } else if (type == ZIKViewRouteTypeCustom) {
                if (![[self class] validateCustomRouteConfiguration:configuration removeConfiguration:self.original_removeConfiguration]) {
                    [self notifyError_invalidConfigurationWithAction:ZIKRouteActionInit
                                                    errorDescription:@"Configuration : (%@) was invalid for ZIKViewRouteTypeCustom",configuration];
                    return nil;
                }
            }
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleWillPerformRouteNotification:) name:kZIKViewRouteWillPerformRouteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleDidPerformRouteNotification:) name:kZIKViewRouteDidPerformRouteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleWillRemoveRouteNotification:) name:kZIKViewRouteWillRemoveRouteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleDidRemoveRouteNotification:) name:kZIKViewRouteDidRemoveRouteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleRemoveRouteCancelledNotification:) name:kZIKViewRouteRemoveRouteCancelledNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Override

- (void)notifyRouteState:(ZIKRouterState)state {
    if (state == ZIKRouterStateRemoved) {
        self.realRouteType = ZIKViewRouteRealTypeUnknown;
        self.prepared = NO;
    }
    [super notifyRouteState:state];
}


+ (ZIKViewRouteConfiguration *)defaultRouteConfiguration {
    return [ZIKViewRouteConfiguration new];
}

+ (__kindof ZIKViewRemoveConfiguration *)defaultRemoveConfiguration {
    return [ZIKViewRemoveConfiguration new];
}

+ (ZIKViewRouteStrictConfiguration *)defaultRouteStrictConfigurationFor:(ZIKViewRouteConfiguration *)configuration {
    return [[ZIKViewRouteStrictConfiguration alloc] initWithConfiguration:configuration];
}

+ (ZIKViewRemoveStrictConfiguration *)defaultRemoveStrictConfigurationFor:(ZIKViewRemoveConfiguration *)configuration {
    return [[ZIKViewRemoveStrictConfiguration alloc] initWithConfiguration:configuration];
}

+ (BOOL)canMakeDestinationSynchronously {
    return YES;
}

- (void)performWithConfiguration:(__kindof ZIKViewRouteConfiguration *)configuration {
    NSParameterAssert(configuration);
    if (configuration.routeType == ZIKViewRouteTypePerformSegue) {
        [self performRouteOnDestination:nil configuration:configuration];
        return;
    }
    
    if ([NSThread isMainThread]) {
        [super performWithConfiguration:configuration];
    } else {
        NSAssert(NO, @"%@ performRoute should only be called in main thread!",self);
        dispatch_sync(dispatch_get_main_queue(), ^{
            [super performWithConfiguration:configuration];
        });
    }
}

- (void)attachDestination:(id)destination {
    NSAssert2(destination == nil || [[self class] isAbstractRouter] || self.original_configuration.routeType == ZIKViewRouteTypePerformSegue || [ZIKViewRouteRegistry isDestinationClass:[destination class] registeredWithRouter:[self class]], @"Destination (%@) attached to router (%@) is not registered with the router.", [destination class], [self class]);
#if ZIKROUTER_CHECK
    if (destination && self.original_configuration.routeType != ZIKViewRouteTypePerformSegue) {
        [self _validateDestinationConformance:destination];
    }
#endif
    [super attachDestination:destination];
}

- (void)removeRouteWithSuccessHandler:(void(^)(void))performerSuccessHandler
                         errorHandler:(void(^)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler {
    if ([NSThread isMainThread]) {
        [super removeRouteWithSuccessHandler:performerSuccessHandler errorHandler:performerErrorHandler];
    } else {
        NSAssert(NO, @"%@ removeRoute should only be called in main thread!",self);
        dispatch_async(dispatch_get_main_queue(), ^{
            [super removeRouteWithSuccessHandler:performerSuccessHandler errorHandler:performerErrorHandler];
        });
    }
}

- (void)removeRouteWithConfiguring:(void(NS_NOESCAPE ^)(ZIKRemoveRouteConfiguration *config))removeConfigBuilder {
    if ([NSThread isMainThread]) {
        [super removeRouteWithConfiguring:removeConfigBuilder];
    } else {
        NSAssert(NO, @"%@ removeRoute should only be called in main thread!",self);
        dispatch_async(dispatch_get_main_queue(), ^{
            [super removeRouteWithConfiguring:removeConfigBuilder];
        });
    }
}

- (void)removeRouteWithStrictConfiguring:(void (NS_NOESCAPE ^)(ZIKRemoveRouteStrictConfiguration<id> * _Nonnull))removeConfigBuilder {
    if ([NSThread isMainThread]) {
        [super removeRouteWithStrictConfiguring:removeConfigBuilder];
    } else {
        NSAssert(NO, @"%@ removeRoute should only be called in main thread!",self);
        dispatch_async(dispatch_get_main_queue(), ^{
            [super removeRouteWithStrictConfiguring:removeConfigBuilder];
        });
    }
}

+ (BOOL)canMakeDestination {
    if (![super canMakeDestination]) {
        return NO;
    }
    return [self supportRouteType:ZIKViewRouteTypeMakeDestination];
}

+ (nullable id)makeDestinationWithPreparation:(void(^ _Nullable)(id destination))prepare {
    return [self makeDestinationWithConfiguring:^(ZIKPerformRouteConfiguration * _Nonnull config) {
        if (prepare) {
            config.prepareDestination = prepare;
        }
    }];
}

+ (nullable id)makeDestinationWithConfiguring:(void(NS_NOESCAPE ^ _Nullable)(ZIKPerformRouteConfiguration *config))configBuilder {
    NSAssert(self != [ZIKViewRouter class], @"Only get destination from router subclass");
    return [super makeDestinationWithConfiguring:^(ZIKPerformRouteConfiguration * _Nonnull config) {
        ZIKViewRouteConfiguration *configuration = (ZIKViewRouteConfiguration *)config;
        configuration.routeType = ZIKViewRouteTypeMakeDestination;
        if (configBuilder) {
            configBuilder(config);
        }
        if (configuration.injected) {
            configuration = (ZIKViewRouteConfiguration *)configuration.injected;
        }
        configuration.routeType = ZIKViewRouteTypeMakeDestination;
    }];
}

+ (nullable id)makeDestinationWithStrictConfiguring:(void (NS_NOESCAPE ^)(ZIKPerformRouteStrictConfiguration<id> * _Nonnull, ZIKPerformRouteConfiguration * _Nonnull))configBuilder {
    return [super makeDestinationWithStrictConfiguring:^(ZIKPerformRouteStrictConfiguration<id> * strictConfig, ZIKPerformRouteConfiguration *config) {
        ZIKViewRouteConfiguration *configuration = (ZIKViewRouteConfiguration *)config;
        configuration.routeType = ZIKViewRouteTypeMakeDestination;
        if (configBuilder) {
            configBuilder(strictConfig, config);
        }
        if (configuration.injected) {
            configuration = (ZIKViewRouteConfiguration *)configuration.injected;
        }
        configuration.routeType = ZIKViewRouteTypeMakeDestination;
    }];
}

+ (BOOL)isAbstractRouter {
    return self == [ZIKViewRouter class];
}

#pragma mark ZIKViewRouterSubclass

+ (void)registerRoutableDestination {
    NSAssert1([self isAbstractRouter], @"Subclass(%@) must override +registerRoutableDestination to register destination.",self);
}

- (id)destinationWithConfiguration:(__kindof ZIKViewRouteConfiguration *)configuration {
    NSAssert(NO, @"Router: %@ must override -destinationWithConfiguration: to return the destination！",[self class]);
    return nil;
}

+ (BOOL)shouldAutoCreateForDestination:(id)destination fromSource:(nullable id)source {
    return YES;
}

+ (ZIKViewRouteTypeMask)supportedRouteTypes {
    return ZIKViewRouteTypeMaskViewControllerDefault;
}

+ (BOOL)destinationPrepared:(id)destination {
    NSAssert(self != [ZIKViewRouter class], @"Check destination prepared with its router.");
    return YES;
}

#pragma clang diagnostics push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (BOOL)destinationFromExternalPrepared:(id)destination {
    NSAssert(self != [ZIKViewRouter class], @"Check destination prepared with its router.");
    return [[self class] destinationPrepared:destination];
}

#pragma clang diagnostics pop

- (void)prepareDestination:(id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    NSAssert([self class] != [ZIKViewRouter class] ||
             configuration.routeType == ZIKViewRouteTypePerformSegue, @"Prepare destination with its router.");
}

- (void)didFinishPrepareDestination:(id)destination configuration:(nonnull __kindof ZIKViewRouteConfiguration *)configuration {
    NSAssert([self class] != [ZIKViewRouter class] ||
             configuration.routeType == ZIKViewRouteTypePerformSegue,
             @"Only ZIKViewRouteTypePerformSegue can use ZIKViewRouter class to perform route, otherwise, use a subclass of ZIKViewRouter for destination.");
}

#pragma mark Perform Route

- (BOOL)canPerformCustomRoute {
    return NO;
}

- (BOOL)_canPerformPush {
    XXViewController *source = (XXViewController *)self.original_configuration.source;
    if (!source) {
        return NO;
    }
    if ([source isKindOfClass:[XXViewController class]] == NO) {
        return NO;
    }
#if ZIK_HAS_UIKIT
    if ([[self class] _validateSourceInNavigationStack:source] == NO) {
        return NO;
    }
#else
    return NO;
#endif
    return YES;
}

- (BOOL)_canPerformPresent {
    XXViewController *source = (XXViewController *)self.original_configuration.source;
    if (!source) {
        return NO;
    }
    if ([source isKindOfClass:[XXViewController class]] == NO) {
        return NO;
    }
#if ZIK_HAS_UIKIT
    if ([[self class] _validateSourceNotPresentedAnyView:source] == NO) {
        return NO;
    }
#endif
    if ([[self class] _validateSourceInWindowHierarchy:source] == NO) {
        return NO;
    }
    return YES;
}

- (BOOL)_canPerformWithErrorMessage:(NSString **)message {
    ZIKRouterState state = self.state;
    if (state == ZIKRouterStateRouting) {
        if (message) {
            *message = @"Router is routing.";
        }
        return NO;
    } else if (state == ZIKRouterStateRemoving) {
        if (message) {
            *message = @"Router is removing.";
        }
        return NO;
    } else if (state == ZIKRouterStateRouted && self.destination != nil && [self shouldRemoveBeforePerform]) {
        if (message) {
            *message = @"Router is routed, can't perform route after remove.";
        }
        return NO;
    }
    
    ZIKViewRouteType type = self.original_configuration.routeType;
    if (type == ZIKViewRouteTypeCustom) {
        BOOL canPerform = [self canPerformCustomRoute];
        if (canPerform && message) {
            *message = @"Can't perform custom route.";
        }
        return canPerform;
    }
    id source = self.original_configuration.source;
    if (!source) {
        if (type != ZIKViewRouteTypeMakeDestination) {
            if (message) {
                *message = @"Source was dealloced.";
            }
            return NO;
        }
    }
    
    switch (type) {
            
#if ZIK_HAS_UIKIT
        case ZIKViewRouteTypePush: {
            id destination = self.destination;
            if (![[self class] _validateSourceInNavigationStack:source]) {
                if (message) {
                    *message = [NSString stringWithFormat:@"Source (%@) is not in any navigation stack now, can't push.",source];
                }
                return NO;
            }
            if (destination && ![[self class] _validateDestination:destination notInNavigationStackOfSource:source]) {
                if (message) {
                    *message = [NSString stringWithFormat:@"Destination (%@) is already in source (%@)'s navigation stack, can't push.",destination,source];
                }
                return NO;
            }
            break;
        }
#endif
            
        case ZIKViewRouteTypePresentModally:
#if ZIK_HAS_UIKIT
        case ZIKViewRouteTypePresentAsPopover: {
            if (![[self class] _validateSourceNotPresentedAnyView:source]) {
                if (message) {
                    *message = [NSString stringWithFormat:@"Source (%@) presented another view controller (%@), can't present destination now.",source,[source presentedViewController]];
                }
                return NO;
            }
            break;
        }
#endif
        default:
            break;
    }
    if (message) {
        *message = nil;
    }
    return YES;
}

- (void)performRouteOnDestination:(nullable id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    if (!destination &&
        [[self class] _validateDestinationShouldExistInConfiguration:configuration]) {
        [self notifyRouteState:self.preState];
        [self notifyError_actionFailedWithAction:ZIKRouteActionPerformRoute errorDescription:@"-destinationWithConfiguration: of router: %@ return nil when performRoute, configuration may be invalid or router has bad impletmentation in -destinationWithConfiguration. Configuration: %@",[self class],configuration];
        return;
    } else if (![[self class] _validateDestinationClass:destination inConfiguration:configuration]) {
        [self notifyRouteState:self.preState];
        [self notifyError_actionFailedWithAction:ZIKRouteActionPerformRoute errorDescription:@"Bad impletment in destinationWithConfiguration: of router: %@, invalid destination (%@) for configuration (%@) !",[self class],destination,configuration];
        return;
    }
#if ZIKROUTER_CHECK
    if ([[self class] _validateDestinationShouldExistInConfiguration:configuration]) {
        [self _validateDestinationConformance:destination];
    }
#endif
    if (![[self class] _validateRouteSourceNotMissedInConfiguration:configuration]) {
        [self notifyRouteState:self.preState];
        [self notifyError_invalidSourceWithAction:ZIKRouteActionPerformRoute
                                 errorDescription:@"Source was dealloced when performRoute on (%@)",self];
        return;
    }
    
    id source = configuration.source;
    ZIKViewRouteType routeType = configuration.routeType;
    switch (routeType) {
            
#if ZIK_HAS_UIKIT
        case ZIKViewRouteTypePush:
            [self _performPushOnDestination:destination fromSource:source];
            break;
#endif
            
        case ZIKViewRouteTypePresentModally:
            [self _performPresentModallyOnDestination:destination fromSource:source];
            break;
            
        case ZIKViewRouteTypePresentAsPopover:
            [self _performPresentAsPopoverOnDestination:destination fromSource:source popoverConfiguration:configuration.popoverConfiguration];
            break;
            
#if !ZIK_HAS_UIKIT
        case ZIKViewRouteTypePresentAsSheet:
            [self _performPresentAsSheetOnDestination:destination fromSource:source];
            break;
            
        case ZIKViewRouteTypePresentWithAnimator:
            [self _performPresentWithAnimatorOnDestination:destination fromSource:source];
            break;
#endif
            
        case ZIKViewRouteTypeAddAsChildViewController:
            [self _performAddChildViewControllerOnDestination:destination fromSource:source];
            break;
            
        case ZIKViewRouteTypePerformSegue:
            [self _performSegueWithIdentifier:configuration.segueConfiguration.identifier fromSource:source sender:configuration.segueConfiguration.sender];
            break;
            
        case ZIKViewRouteTypeShow:
            [self _performShowOnDestination:destination fromSource:source];
            break;
            
#if ZIK_HAS_UIKIT
        case ZIKViewRouteTypeShowDetail:
            [self _performShowDetailOnDestination:destination fromSource:source];
            break;
#endif
            
        case ZIKViewRouteTypeAddAsSubview:
            [self _performAddSubviewOnDestination:destination fromSource:source];
            break;
            
        case ZIKViewRouteTypeCustom:
            [self _performCustomOnDestination:destination fromSource:source];
            break;
            
        case ZIKViewRouteTypeMakeDestination:
            [self _performMakeDestination:destination fromSource:source];
            break;
    }
}

#if ZIK_HAS_UIKIT
- (void)_performPushOnDestination:(XXViewController *)destination fromSource:(XXViewController *)source {
    NSParameterAssert([destination isKindOfClass:[XXViewController class]]);
    NSParameterAssert([source isKindOfClass:[XXViewController class]]);
    
    if (![[self class] _validateSourceInNavigationStack:source]) {
        [self notifyRouteState:self.preState];
        [self notifyError_invalidSourceWithAction:ZIKRouteActionPerformRoute
                                 errorDescription:@"Source: (%@) is not in any navigation stack when perform push.",source];
        return;
    }
    if (![[self class] _validateDestination:destination notInNavigationStackOfSource:source]) {
        [self notifyRouteState:self.preState];
        [self notifyError_overRouteWithAction:ZIKRouteActionPerformRoute
                             errorDescription:@"Pushing the same view controller instance more than once is not supported. Source: (%@), destination: (%@), viewControllers in navigation stack: (%@)",source,destination,source.navigationController.viewControllers];
        return;
    }
    XXViewController *wrappedDestination = [self _wrappedDestination:destination];
    [self beginPerformRoute];
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypePush)];
    self.realRouteType = ZIKViewRouteRealTypePush;
    [source.navigationController pushViewController:wrappedDestination animated:self.original_configuration.animated];
    [ZIKViewRouter _completeWithtransitionCoordinator:source.navigationController.transitionCoordinator
                                 transitionCompletion:^{
        [self endPerformRouteWithSuccess];
    }];
}
#endif

- (void)_performPresentModallyOnDestination:(XXViewController *)destination fromSource:(XXViewController *)source {
    NSParameterAssert([destination isKindOfClass:[XXViewController class]]);
    NSParameterAssert([source isKindOfClass:[XXViewController class]]);
    
#if ZIK_HAS_UIKIT
    if (![[self class] _validateSourceNotPresentedAnyView:source]) {
        [self notifyRouteState:self.preState];
        [self notifyError_invalidSourceWithAction:ZIKRouteActionPerformRoute
                                 errorDescription:@"Warning: Attempt to present %@ on %@ whose view is not in the window hierarchy! %@ already presented %@.",destination,source,source,source.presentedViewController];
        return;
    }
#endif
    if (![[self class] _validateSourceInWindowHierarchy:source]) {
        [self notifyRouteState:self.preState];
        [self notifyError_invalidSourceWithAction:ZIKRouteActionPerformRoute
                                 errorDescription:@"Warning: Attempt to present %@ on %@ whose view is not in the window hierarchy! %@ 's view not in any superview.",destination,source,source];
        return;
    }
    if (source == destination) {
        [self notifyRouteState:self.preState];
        [self notifyError_invalidSourceWithAction:ZIKRouteActionPerformRoute
                                 errorDescription:@"Application tried to present modally an active controller %@, destination: %@",source, destination];
        return;
    }
    
    XXViewController *wrappedDestination = [self _wrappedDestination:destination];
    [self beginPerformRoute];
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypePresentModally)];
#if ZIK_HAS_UIKIT
    self.realRouteType = ZIKViewRouteRealTypePresentModally;
    [source presentViewController:wrappedDestination animated:self.original_configuration.animated completion:^{
        [self endPerformRouteWithSuccess];
    }];
#else
    self.realRouteType = ZIKViewRouteRealTypePresentModally;
    [source presentViewControllerAsModalWindow:wrappedDestination];
    [ZIKViewRouter _completeWithMacTransitionCompletion:^{
        [self endPerformRouteWithSuccess];
    }];
#endif
}

- (void)_performPresentAsPopoverOnDestination:(XXViewController *)destination fromSource:(XXViewController *)source popoverConfiguration:(ZIKViewRoutePopoverConfiguration *)popoverConfiguration {
    NSParameterAssert([destination isKindOfClass:[XXViewController class]]);
    NSParameterAssert([source isKindOfClass:[XXViewController class]]);
    
    if (!popoverConfiguration) {
        [self notifyRouteState:self.preState];
        [self notifyError_invalidConfigurationWithAction:ZIKRouteActionPerformRoute
                                        errorDescription:@"Miss popoverConfiguration when perform presentAsPopover on source: (%@), router: (%@).",source,self];
        return;
    }
#if ZIK_HAS_UIKIT
    if (![[self class] _validateSourceNotPresentedAnyView:source]) {
        [self notifyRouteState:self.preState];
        [self notifyError_invalidSourceWithAction:ZIKRouteActionPerformRoute
                                 errorDescription:@"Warning: Attempt to present %@ on %@ whose view is not in the window hierarchy! %@ already presented %@.",destination,source,source,source.presentedViewController];
        return;
    }
#endif
    if (![[self class] _validateSourceInWindowHierarchy:source]) {
        [self notifyRouteState:self.preState];
        [self notifyError_invalidSourceWithAction:ZIKRouteActionPerformRoute
                                 errorDescription:@"Warning: Attempt to present %@ on %@ whose view is not in the window hierarchy! %@ 's view not in any superview.",destination,source,source];
        return;
    }
    if (source == destination) {
        [self notifyRouteState:self.preState];
        [self notifyError_invalidSourceWithAction:ZIKRouteActionPerformRoute
                                 errorDescription:@"Application tried to present modally an active controller %@, destination: %@",source, destination];
        return;
    }
    
#if ZIK_HAS_UIKIT
    ZIKViewRouteConfiguration *configuration = self.original_configuration;
#if !TARGET_OS_TV
    if (NSClassFromString(@"UIPopoverPresentationController")) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
        destination.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *popoverPresentationController = destination.popoverPresentationController;
#pragma clang diagnostic pop
        if (popoverConfiguration.barButtonItem) {
            popoverPresentationController.barButtonItem = popoverConfiguration.barButtonItem;
        } else if (popoverConfiguration.sourceView) {
            popoverPresentationController.sourceView = popoverConfiguration.sourceView;
            if (popoverConfiguration.sourceRectConfiged) {
                popoverPresentationController.sourceRect = popoverConfiguration.sourceRect;
            }
        } else {
            [self notifyRouteState:self.preState];
            [self notifyError_invalidConfigurationWithAction:ZIKRouteActionPerformRoute
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
        
        XXViewController *wrappedDestination = [self _wrappedDestination:destination];
        [self beginPerformRoute];
        self.realRouteType = ZIKViewRouteRealTypePresentAsPopover;
        [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypePresentAsPopover)];
        [source presentViewController:wrappedDestination animated:configuration.animated completion:^{
            [self endPerformRouteWithSuccess];
        }];
        return;
    }
#endif
    
    //iOS7 iPad, or TV
    BOOL shouldPopover = NO;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        shouldPopover = YES;
    }
    if (@available(iOS 9.0, *)) {
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomTV) {
            shouldPopover = YES;
        }
    }
    if (shouldPopover) {
        XXViewController *wrappedDestination = [self _wrappedDestination:destination];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
        UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:wrappedDestination];
        self.popover = popover;
#pragma clang diagnostic pop
        
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
        [self prepareDestinationForPerforming];
        [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypePresentAsPopover)];
        if (popoverConfiguration.barButtonItem) {
            self.realRouteType = ZIKViewRouteRealTypePresentAsPopover;
            [ZIKViewRouter AOP_notifyAll_router:self willPerformRouteOnDestination:destination fromSource:source];
            [popover presentPopoverFromBarButtonItem:popoverConfiguration.barButtonItem permittedArrowDirections:popoverConfiguration.permittedArrowDirections animated:configuration.animated];
        } else if (popoverConfiguration.sourceView) {
            self.realRouteType = ZIKViewRouteRealTypePresentAsPopover;
            [ZIKViewRouter AOP_notifyAll_router:self willPerformRouteOnDestination:destination fromSource:source];
            [popover presentPopoverFromRect:popoverConfiguration.sourceRect inView:popoverConfiguration.sourceView permittedArrowDirections:popoverConfiguration.permittedArrowDirections animated:configuration.animated];
        } else {
            self.popover = nil;
            ZIKRouterState preState = self.preState;
            [self notifyRouteState:preState];
            [self notifyError_invalidConfigurationWithAction:ZIKRouteActionPerformRoute
                                            errorDescription:@"Invalid popoverConfiguration: (%@) when perform presentAsPopover on source: (%@), router: (%@).",popoverConfiguration,source,self];
            if (self.state == preState) {
                self.routingFromInternal = NO;
            }
            return;
        }
        
        [ZIKViewRouter _completeWithtransitionCoordinator:popover.contentViewController.transitionCoordinator
                                     transitionCompletion:^{
            [self endPerformRouteWithSuccess];
        }];
        return;
    }
    
    //iOS7 iPhone
    XXViewController *wrappedDestination = [self _wrappedDestination:destination];
    [self beginPerformRoute];
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypePresentAsPopover)];
    self.realRouteType = ZIKViewRouteRealTypePresentModally;
    [source presentViewController:wrappedDestination animated:configuration.animated completion:^{
        [self endPerformRouteWithSuccess];
    }];
#else
    XXViewController *wrappedDestination = [self _wrappedDestination:destination];
    [self beginPerformRoute];
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypePresentAsPopover)];
    self.realRouteType = ZIKViewRouteRealTypePresentAsPopover;
    [source presentViewController:wrappedDestination asPopoverRelativeToRect:popoverConfiguration.sourceRect ofView:popoverConfiguration.sourceView preferredEdge:popoverConfiguration.preferredEdge behavior:popoverConfiguration.behavior];
    [ZIKViewRouter _completeWithMacTransitionCompletion:^{
        [self endPerformRouteWithSuccess];
    }];
#endif
}

#if !ZIK_HAS_UIKIT
- (void)_performPresentAsSheetOnDestination:(XXViewController *)destination fromSource:(XXViewController *)source {
    NSParameterAssert([destination isKindOfClass:[XXViewController class]]);
    NSParameterAssert([source isKindOfClass:[XXViewController class]]);
    if (![[self class] _validateSourceInWindowHierarchy:source]) {
        [self notifyRouteState:self.preState];
        [self notifyError_invalidSourceWithAction:ZIKRouteActionPerformRoute
                                 errorDescription:@"Warning: Attempt to present %@ on %@ whose view is not in the window hierarchy! %@ 's view not in any superview.",destination,source,source];
        return;
    }
    if (source == destination) {
        [self notifyRouteState:self.preState];
        [self notifyError_invalidSourceWithAction:ZIKRouteActionPerformRoute
                                 errorDescription:@"Application tried to present an active controller %@, destination: %@",source, destination];
        return;
    }
    
    XXViewController *wrappedDestination = [self _wrappedDestination:destination];
    [self beginPerformRoute];
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypePresentAsSheet)];
    self.realRouteType = ZIKViewRouteRealTypePresentAsSheet;
    [source presentViewControllerAsSheet:wrappedDestination];
    [ZIKViewRouter _completeWithMacTransitionCompletion:^{
        [self endPerformRouteWithSuccess];
    }];
}

- (void)_performPresentWithAnimatorOnDestination:(XXViewController *)destination fromSource:(XXViewController *)source {
    NSParameterAssert([destination isKindOfClass:[XXViewController class]]);
    NSParameterAssert([source isKindOfClass:[XXViewController class]]);
    if (![[self class] _validateSourceInWindowHierarchy:source]) {
        [self notifyRouteState:self.preState];
        [self notifyError_invalidSourceWithAction:ZIKRouteActionPerformRoute
                                 errorDescription:@"Warning: Attempt to present %@ on %@ whose view is not in the window hierarchy! %@ 's view not in any superview.",destination,source,source];
        return;
    }
    if (source == destination) {
        [self notifyRouteState:self.preState];
        [self notifyError_invalidSourceWithAction:ZIKRouteActionPerformRoute
                                 errorDescription:@"Application tried to present an active controller %@, destination: %@",source, destination];
        return;
    }
    
    id<NSViewControllerPresentationAnimator> animator = self.original_configuration.animator;
    if (animator == nil) {
        [self _performPresentModallyOnDestination:destination fromSource:source];
        return;
    }
    XXViewController *wrappedDestination = [self _wrappedDestination:destination];
    [self beginPerformRoute];
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypePresentWithAnimator)];
    self.realRouteType = ZIKViewRouteRealTypePresentWithAnimator;
    [source presentViewController:wrappedDestination animator:animator];
    [ZIKViewRouter _completeWithMacTransitionCompletion:^{
        [self endPerformRouteWithSuccess];
    }];
}
#endif

- (void)_performSegueWithIdentifier:(NSString *)identifier fromSource:(XXViewController *)source sender:(nullable id)sender {
    
    ZIKViewRouteConfiguration *configuration = self.original_configuration;
    ZIKViewRouteSegueConfiguration *segueConfig = configuration.segueConfiguration;
    segueConfig.segueSource = nil;
    segueConfig.segueDestination = nil;
#if ZIK_HAS_UIKIT
    segueConfig.destinationStateBeforeRoute = nil;
#endif
    
    self.routingFromInternal = YES;
    //Set nil in -ZIKViewRouter_hook_prepareForSegue:sender:
    [source setZix_sourceViewRouter:self];
    
    /*
     Hook UIViewController's -prepareForSegue:sender: and UIStoryboardSegue's -perform to prepare and complete
     Call -prepareDestinationForPerforming in -ZIKViewRouter_hook_prepareForSegue:sender:
     Call +AOP_notifyAll_router:willPerformRouteOnDestination: in -ZIKViewRouter_hook_prepareForSegue:sender:
     Call -notifyRouteState:ZIKRouterStateRouted
          -notifyPerformRouteSuccessWithDestination:
          +AOP_notifyAll_router:didPerformRouteOnDestination:
     in -ZIKViewRouter_hook_seguePerform
     */
    [source performSegueWithIdentifier:identifier sender:sender];
    
    XXViewController *destination = segueConfig.segueDestination;//segueSource and segueDestination was set in -ZIKViewRouter_hook_prepareForSegue:sender:
    
    /*When perform a unwind segue, if destination's -canPerformUnwindSegueAction:fromViewController:withSender: return NO, here will be nil
     This inspection relies on synchronized call -prepareForSegue:sender: and -canPerformUnwindSegueAction:fromViewController:withSender: in -performSegueWithIdentifier:sender:
     */
    if (!destination) {
        ZIKRouterState preState = self.preState;
        [self notifyRouteState:preState];
        [self notifyError_segueNotPerformedWithAction:ZIKRouteActionPerformRoute errorDescription:@"destination can't perform segue identitier:%@ now",identifier];
        if (self.state == preState) {
            self.routingFromInternal = NO;
        }
        return;
    }
#if ZIKROUTER_CHECK
    if ([self class] != [ZIKViewRouter class]) {
        [self _validateDestinationConformance:destination];
    }
#endif
    NSParameterAssert([destination isKindOfClass:[XXViewController class]]);
    NSParameterAssert([source isKindOfClass:[XXViewController class]]);
    NSAssert(![source zix_sourceViewRouter], @"Didn't set sourceViewRouter to nil in -ZIKViewRouter_hook_prepareForSegue:sender:, router will not be dealloced before source was dealloced");
}

- (void)_performShowOnDestination:(XXViewController *)destination fromSource:(XXViewController *)source {
    NSParameterAssert([destination isKindOfClass:[XXViewController class]]);
#if ZIK_HAS_UIKIT
    NSParameterAssert([source isKindOfClass:[XXViewController class]]);
    if ([source respondsToSelector:@selector(showViewController:sender:)] == NO) {
        if ([source isKindOfClass:[UINavigationController class]]) {
            [self _performPushOnDestination:destination fromSource:source];
        } else if ([source isKindOfClass:[UISplitViewController class]]) {
            if (![destination isKindOfClass:[UINavigationController class]]) {
                for (UIViewController *vc in [(UISplitViewController *)source viewControllers]) {
                    if ([vc isKindOfClass:[UINavigationController class]]) {
                        [self _performPushOnDestination:destination fromSource:vc];
                        return;
                    }
                }
            }            
            [self _performPresentModallyOnDestination:destination fromSource:source];
        } else {
            [self _performPresentModallyOnDestination:destination fromSource:source];
        }
        return;
    }
#endif
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypeShow)];
    XXViewController *wrappedDestination = [self _wrappedDestination:destination];
#if ZIK_HAS_UIKIT
    ZIKPresentationState *destinationStateBeforeRoute = [destination zix_presentationState];
#endif
    [self beginPerformRoute];
#if ZIK_HAS_UIKIT
    [source showViewController:wrappedDestination sender:self.original_configuration.sender];

#pragma clang diagnostic pop
    id<UIViewControllerTransitionCoordinator> transitionCoordinator = [source zix_currentTransitionCoordinator];
    if (!transitionCoordinator) {
        transitionCoordinator = [destination zix_currentTransitionCoordinator];
    }
    [ZIKViewRouter _completeRouter:self
    analyzeRouteTypeForDestination:destination
                            source:source
       destinationStateBeforeRoute:destinationStateBeforeRoute
             transitionCoordinator:transitionCoordinator
                        completion:^{
                            [self endPerformRouteWithSuccess];
                        }];
#else
    self.realRouteType = ZIKViewRouteRealTypeShowWindow;
    NSWindow *window = [NSWindow windowWithContentViewController:wrappedDestination];
    NSWindowController *windowController = [[NSWindowController alloc] initWithWindow:window];
    [windowController showWindow:self.original_configuration.sender];
    [ZIKViewRouter _completeWithMacTransitionCompletion:^{
        [self endPerformRouteWithSuccess];
    }];
#endif
}

#if ZIK_HAS_UIKIT
- (void)_performShowDetailOnDestination:(XXViewController *)destination fromSource:(XXViewController *)source {
    NSParameterAssert([destination isKindOfClass:[XXViewController class]]);
    NSParameterAssert([source isKindOfClass:[XXViewController class]]);
    if ([source respondsToSelector:@selector(showDetailViewController:sender:)] == NO) {
        [self _performPresentModallyOnDestination:destination fromSource:source];
        return;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypeShowDetail)];
    XXViewController *wrappedDestination = [self _wrappedDestination:destination];
    ZIKPresentationState *destinationStateBeforeRoute = [destination zix_presentationState];
    [self beginPerformRoute];
    
    [source showDetailViewController:wrappedDestination sender:self.original_configuration.sender];
    
#pragma clang diagnostic pop
    id<UIViewControllerTransitionCoordinator> transitionCoordinator = [source zix_currentTransitionCoordinator];
    if (!transitionCoordinator) {
        transitionCoordinator = [destination zix_currentTransitionCoordinator];
    }
    [ZIKViewRouter _completeRouter:self
    analyzeRouteTypeForDestination:destination
                            source:source
       destinationStateBeforeRoute:destinationStateBeforeRoute
             transitionCoordinator:transitionCoordinator
                        completion:^{
                            [self endPerformRouteWithSuccess];
                        }];
}
#endif

- (void)_performAddChildViewControllerOnDestination:(XXViewController *)destination fromSource:(XXViewController *)source {
    NSParameterAssert([destination isKindOfClass:[XXViewController class]]);
    NSParameterAssert([source isKindOfClass:[XXViewController class]]);
    XXViewController *wrappedDestination = [self _wrappedDestination:destination];
//    [self beginPerformRoute];
    /// Call AOP in -viewWillAppear: and -viewDidAppear:
    self.routingFromInternal = YES;
    [self prepareDestinationForPerforming];
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypeAddAsChildViewController)];
    [source addChildViewController:wrappedDestination];
    
    self.realRouteType = ZIKViewRouteRealTypeUnknown;
    void(^addingChildViewHandler)(XXViewController *, void(^)(void)) = self.original_configuration.addingChildViewHandler;
    void(^completion)(void) = ^{
#if ZIK_HAS_UIKIT
        [wrappedDestination didMoveToParentViewController:source];
#endif
        self.realRouteType = ZIKViewRouteRealTypeAddAsChildViewController;
        [self endPerformRouteWithSuccessWithAOP:NO];
    };
    if (addingChildViewHandler) {
        addingChildViewHandler(wrappedDestination, completion);
        return;
    } else {
        [source.view addSubview:destination.view];
        //    [self endPerformRouteWithSuccess];
        completion();
    }
}

- (void)_performAddSubviewOnDestination:(XXView *)destination fromSource:(XXView *)source {
    NSParameterAssert([destination isKindOfClass:[XXView class]]);
    NSParameterAssert([source isKindOfClass:[XXView class]]);
    [self beginPerformRoute];
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypeAddAsSubview)];
    
    [source addSubview:destination];
    
    self.realRouteType = ZIKViewRouteRealTypeAddAsSubview;
    
    // UIKit will call -willMoveToSuperview:, -didMoveToSuperview, -willMoveToWindow:, -didMoveToWindow asynchronously.
    // AppKit will call them synchronously in -addSubview:
#if !ZIK_HAS_UIKIT
    if (destination.zix_routed) {
        [destination setZix_routeTypeFromRouter:nil];
    }
#endif
    
    [self endPerformRouteWithSuccess];
}

- (void)_performCustomOnDestination:(id)destination fromSource:(nullable id)source {
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypeCustom)];
    self.realRouteType = ZIKViewRouteRealTypeCustom;
    [self performCustomRouteOnDestination:destination fromSource:source configuration:self.original_configuration];
}

- (void)_performMakeDestination:(id)destination fromSource:(nullable id)source {
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypeMakeDestination)];
    self.routingFromInternal = YES;
    [self prepareDestinationForPerforming];
#if ZIK_HAS_UIKIT
    if ([destination respondsToSelector:@selector(zix_presentationState)]) {
        self.stateBeforeRoute = [destination zix_presentationState];
    }
#endif
    self.realRouteType = ZIKViewRouteRealTypeUnknown;
    [self endPerformRouteWithSuccessWithAOP:NO];
}

- (void)performCustomRouteOnDestination:(id)destination fromSource:(nullable id)source configuration:(ZIKViewRouteConfiguration *)configuration {
    [self beginPerformRoute];
    [self endPerformRouteWithError:[ZIKViewRouter viewRouteErrorWithCode:ZIKViewRouteErrorUnsupportType localizedDescriptionFormat:@"Subclass (%@) must override -performCustomRouteOnDestination:fromSource:configuration: to support custom route", [self class]]];
    NSAssert(NO, @"Subclass (%@) must override -performCustomRouteOnDestination:fromSource:configuration: to support custom route", [self class]);
}

- (XXViewController *)_wrappedDestination:(XXViewController *)destination {
    self.container = nil;
    ZIKViewRouteConfiguration *configuration = self.original_configuration;
    if (!configuration.containerWrapper) {
        return destination;
    }
    XXViewController<ZIKViewRouteContainer> *container = configuration.containerWrapper(destination);
    
    NSString *errorDescription;
    if (!container) {
        errorDescription = @"container is nil";
    }
#if ZIK_HAS_UIKIT
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
    else if ([container isKindOfClass:[UINavigationController class]]) {
        if (configuration.routeType == ZIKViewRouteTypePush) {
            errorDescription = [NSString stringWithFormat:@"navigationController:(%@) can't be pushed into another navigationController",container];
        } else if (configuration.routeType == ZIKViewRouteTypeShow
                   && [configuration.source isKindOfClass:[XXViewController class]]
                   && [(XXViewController *)configuration.source navigationController]) {
            errorDescription = [NSString stringWithFormat:@"navigationController:(%@) can't be pushed into another navigationController",container];
        } else if (configuration.routeType == ZIKViewRouteTypeShowDetail
                   && [configuration.source isKindOfClass:[XXViewController class]]
                   && [[(XXViewController *)configuration.source splitViewController] respondsToSelector:@selector(isCancelled)]
                   && [(XXViewController *)configuration.source splitViewController].isCollapsed &&
                   [[[(XXViewController *)configuration.source splitViewController].viewControllers firstObject] isKindOfClass:[UINavigationController class]]) {
            errorDescription = [NSString stringWithFormat:@"navigationController:(%@) can't be pushed into another navigationController",container];
        } else if ([[(UINavigationController *)container viewControllers] firstObject] != destination) {
            errorDescription = [NSString stringWithFormat:@"container:(%@) must set destination as root view controller, destination:(%@), container's viewcontrollers:(%@)",container,destination,[(UINavigationController *)container viewControllers]];
        }
    } else if ([container isKindOfClass:[XXTabBarController class]]) {
        if (![[(XXTabBarController *)container viewControllers] containsObject:destination]) {
            errorDescription = [NSString stringWithFormat:@"container:(%@) must contains destination in its viewControllers, destination:(%@), container's viewcontrollers:(%@)",container,destination,[(UITabBarController *)container viewControllers]];
        }
    } else if ([container isKindOfClass:[XXSplitViewController class]]) {
        if (configuration.routeType == ZIKViewRouteTypePush) {
            errorDescription = [NSString stringWithFormat:@"Split View Controllers cannot be pushed to a Navigation Controller %@",destination];
        } else if (configuration.routeType == ZIKViewRouteTypeShow
                   && [configuration.source isKindOfClass:[XXViewController class]]
                   && [(XXViewController *)configuration.source navigationController]) {
            errorDescription = [NSString stringWithFormat:@"Split View Controllers cannot be pushed to a Navigation Controller %@",destination];
        } else if (configuration.routeType == ZIKViewRouteTypeShowDetail
                   && [configuration.source isKindOfClass:[XXViewController class]]
                   && [[(XXViewController *)configuration.source splitViewController] respondsToSelector:@selector(isCancelled)]
                   && [(XXViewController *)configuration.source splitViewController].isCollapsed &&
                   [[[(XXViewController *)configuration.source splitViewController].viewControllers firstObject] isKindOfClass:[UINavigationController class]]) {
            errorDescription = [NSString stringWithFormat:@"Split View Controllers cannot be pushed to a Navigation Controller %@",destination];
        } else if (![[(XXSplitViewController *)container viewControllers] containsObject:destination]) {
            errorDescription = [NSString stringWithFormat:@"container:(%@) must contains destination in its viewControllers, destination:(%@), container's viewcontrollers:(%@)",container,destination,[(UITabBarController *)container viewControllers]];
        }
    }
#pragma clang diagnostic pop
#endif
    if (errorDescription) {
        [self notifyError_invalidContainerWithAction:ZIKRouteActionPerformRoute errorDescription:@"containerWrapper returns invalid container: %@",errorDescription];
        return destination;
    }
    self.container = container;
    return container;
}

+ (void)_prepareDestinationFromExternal:(id)destination router:(ZIKViewRouter *)router performer:(nullable id)performer {
    NSParameterAssert(destination);
    NSParameterAssert(router);
    
    if (![router destinationFromExternalPrepared:destination]) {
        if (!performer) {
            NSString *description = [NSString stringWithFormat:@"Can't find which custom UIView or UIViewController added destination:(%@) as subview, so we can't notify the performer to config the destination. You may add destination to a superview in code directly, and the superview is not a custom class. Please change your code and add subview by a custom view router with ZIKViewRouteTypeAddAsSubview. CallStack: %@",destination, [NSThread callStackSymbols]];
            [self notifyError_invalidPerformerWithAction:ZIKRouteActionPerformRoute errorDescription:description];
        }
        
        if ([performer respondsToSelector:@selector(prepareDestinationFromExternal:configuration:)]) {
            ZIKViewRouteConfiguration *config = router.original_configuration;
            id source = config.source;
            ZIKViewRouteType routeType = config.routeType;
            ZIKViewRouteSegueConfiguration *segueConfig = config.segueConfiguration;
            BOOL handleExternalRoute = config.handleExternalRoute;
            [performer prepareDestinationFromExternal:destination configuration:config];
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
            [router notifyError_invalidSourceWithAction:ZIKRouteActionPerformRoute errorDescription:@"Destination %@ 's performer :%@ missed -prepareDestinationFromExternal:configuration: to config destination.",destination, performer];
        }
    }
    
    [router prepareDestinationForPerforming];
}

#if ZIK_HAS_UIKIT
+ (void)_completeRouter:(ZIKViewRouter *)router
analyzeRouteTypeForDestination:(UIViewController *)destination
                   source:(UIViewController *)source
destinationStateBeforeRoute:(ZIKPresentationState *)destinationStateBeforeRoute
    transitionCoordinator:(nullable id <UIViewControllerTransitionCoordinator>)transitionCoordinator
               completion:(void(^)(void))completion {
    [ZIKViewRouter _completeWithtransitionCoordinator:transitionCoordinator transitionCompletion:^{
        ZIKPresentationState *destinationStateAfterRoute = [destination zix_presentationState];
        if ([destinationStateBeforeRoute isEqual:destinationStateAfterRoute]) {
            router.realRouteType = ZIKViewRouteRealTypeCustom;//maybe ZIKViewRouteRealTypeUnwind, but we just need to know this route can't be remove
#if DEBUG
            NSLog(@"⚠️Warning: destination(%@)'s state was not changed after perform route from source: (%@). current state: (%@).\nYou may begin another transition without animation when the source is still in a transition without animation, or you may override source's -showViewController:sender:/-showDetailViewController:sender:/-presentViewController:animated:completion:/-pushViewController:animated: or use a custom segue, but didn't perform real presentation, or your presentation was async.",destination,source,destinationStateAfterRoute);
#endif
        } else {
            ZIKViewRouteDetailType routeType = [ZIKPresentationState detailRouteTypeFromStateBeforeRoute:destinationStateBeforeRoute stateAfterRoute:destinationStateAfterRoute];
            router.realRouteType = [[router class] _realRouteTypeFromDetailType:routeType];
        }
        if (completion) {
            completion();
        }
    }];
}

+ (void)_completeWithtransitionCoordinator:(nullable id <UIViewControllerTransitionCoordinator>)transitionCoordinator transitionCompletion:(void(^)(void))completion {
    NSParameterAssert(completion);
    //If user use a custom transition from source to destination, such as methods in UIView(UIViewAnimationWithBlocks) or UIView (UIViewKeyframeAnimations), the transitionCoordinator will be nil, route will complete before animation complete
    if (!transitionCoordinator) {
        //If the source view controlelr is still in transition, begin another transition in completion may fail. So complete in next runloop (or next viewDidAppear: / viewDidDisappear:).
        dispatch_async(dispatch_get_main_queue(), ^{
            completion();
        });
        return;
    }
    [transitionCoordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        completion();
    }];
}
#else

+ (void)_completeWithMacTransitionCompletion:(void(^)(void))completion {
    NSAnimationContext *context = [NSAnimationContext currentContext];
    if (context == nil) {
        if (completion) {
            completion();
        }
        return;
    }
    context.completionHandler = ^{
        if (completion) {
            completion();
        }
    };
}
#endif

- (void)notifyPerformRouteSuccessWithDestination:(id)destination {
    [super notifySuccessWithAction:ZIKRouteActionPerformRoute];
}

- (void)beginPerformRoute {
    NSAssert(self.state == ZIKRouterStateRouting, @"state should be routing when begin to route.");
    self.retainedSelf = self;
    self.routingFromInternal = YES;
    id destination = self.destination;
    id source = self.original_configuration.source;
    [self prepareDestinationForPerforming];
    [ZIKViewRouter AOP_notifyAll_router:self willPerformRouteOnDestination:destination fromSource:source];
}

- (void)endPerformRouteWithSuccess {
    NSAssert(self.state == ZIKRouterStateRouting, @"state should be routing when end route.");
    NSAssert(self.destination, @"Destination should not be nil when perform with success.");
    [self endPerformRouteWithSuccessWithAOP:YES];
}

- (void)endPerformRouteWithSuccessWithAOP:(BOOL)notifyAOP {
    [self notifyRouteState:ZIKRouterStateRouted];
    if (notifyAOP) {
        id destination = self.destination;
        id source = self.original_configuration.source;
        [ZIKViewRouter AOP_notifyAll_router:self didPerformRouteOnDestination:destination fromSource:source];
    }
    [self notifySuccessWithAction:ZIKRouteActionPerformRoute];
    if (self.state == ZIKRouterStateRouted) {
        self.routingFromInternal = NO;
        self.retainedSelf = nil;
    }
#if DEBUG
    if ([self.destination isKindOfClass:[XXView class]]) {
        XXView *view = self.destination;
        if ([view zix_isRootView]) {
            if (!zix_classSelfImplementingMethod([self class], @selector(shouldAutoCreateForDestination:fromSource:), YES)) {
                NSLog(@"\nZIKViewRouter Warning:⚠️ the routable UIView (%@) is the root view of a view controller (%@), the UIKit system may implicitly remove and add the UIView during some animation. You should check and avoid those unnecessary auto creating in +shouldAutoCreateForDestination:fromSource:.", view, [view nextResponder]);
            }
        }
    }
#endif
}

- (void)endPerformRouteWithError:(NSError *)error {
    NSParameterAssert(error);
    NSAssert(self.state == ZIKRouterStateRouting, @"state should be routing when end route.");
    ZIKRouterState preState = self.preState;
    [super endPerformRouteWithError:error];
    if (self.state == preState) {
        self.routingFromInternal = NO;
        self.retainedSelf = nil;
    }
}

#if ZIK_HAS_UIKIT
+ (ZIKViewRouteRealType)_realRouteTypeFromDetailType:(ZIKViewRouteDetailType)detailType {
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
#endif

#pragma mark Remove Route

- (BOOL)shouldRemoveBeforePerform {
    ZIKViewRouteType routeType = self.original_configuration.routeType;
    if (routeType == ZIKViewRouteTypeMakeDestination) {
        return NO;
    }
    if (self.destination == nil) {
        return NO;
    }
    return YES;
}

- (BOOL)canRemove {
    NSAssert([NSThread isMainThread], @"Always check state in main thread, bacause state may change in main thread after you check the state in child thread.");
    return [self checkCanRemove] == nil;
}

- (BOOL)canRemoveCustomRoute {
    return NO;
}

- (NSString *)checkCanRemove {
    NSString *errorMessage = [super checkCanRemove];
    if (errorMessage) {
        return errorMessage;
    }
    ZIKViewRouteConfiguration *configuration = self.original_configuration;
    if (!configuration) {
        return @"Configuration missed.";
    }
    ZIKViewRouteType routeType = configuration.routeType;
    ZIKViewRouteRealType realRouteType = self.realRouteType;
    
    if (routeType == ZIKViewRouteTypeCustom) {
        if (![self canRemoveCustomRoute]) {
            return @"canRemoveCustomRoute return NO";
        } else {
            return nil;
        }
    }
    
    switch (realRouteType) {
        case ZIKViewRouteRealTypeUnknown:
            if ([self _guessCanRemove]) {
                return nil;
            }
            return [NSString stringWithFormat:@"Router can't remove, realRouteType is ZIKViewRouteRealTypeUnknown, doesn't support remove, router:%@",self];
            break;
        case ZIKViewRouteRealTypeUnwind:
        case ZIKViewRouteRealTypeCustom: {
            return [NSString stringWithFormat:@"Router can't remove, realRouteType is %ld, doesn't support remove, router:%@",(long)realRouteType,self];
            break;
        }
#if ZIK_HAS_UIKIT
        case ZIKViewRouteRealTypePush: {
            if (![self _canPop]) {
                return [NSString stringWithFormat:@"Router can't remove, destination doesn't have navigationController when pop, router:%@",self];
            }
            break;
        }
#endif
            
        case ZIKViewRouteRealTypePresentModally:
        case ZIKViewRouteRealTypePresentAsPopover:
#if !ZIK_HAS_UIKIT
        case ZIKViewRouteRealTypePresentAsSheet:
        case ZIKViewRouteRealTypePresentWithAnimator:
#endif
        {
            if (![self _canDismiss]) {
                return [NSString stringWithFormat:@"Router can't remove, destination is not presented when dismiss. router:%@", self];
            }
            break;
        }
#if !ZIK_HAS_UIKIT
        case ZIKViewRouteRealTypeShowWindow:
            if (![self _canCloseWindow]) {
                return [NSString stringWithFormat:@"Router can't remove, destination is not in any window, router:%@", self];
            }
            break;
#endif
        case ZIKViewRouteRealTypeAddAsChildViewController: {
            if (![self _canRemoveFromParentViewController]) {
                return [NSString stringWithFormat:@"Router can't remove, doesn't have parent view controller when remove from parent. router:%@", self];
            }
            break;
        }
            
        case ZIKViewRouteRealTypeAddAsSubview: {
            if (![self _canRemoveFromSuperview]) {
                return [NSString stringWithFormat:@"Router can't remove, destination doesn't have superview when remove from superview. router:%@",self];
            }
            break;
        }
    }
    return nil;
}

#if ZIK_HAS_UIKIT
- (BOOL)_canPop {
    XXViewController *destination = self.destination;
    if ([destination isKindOfClass:[XXViewController class]] == NO) {
        return NO;
    }
    if (!destination.navigationController) {
        return NO;
    }
    if ([destination.navigationController.viewControllers firstObject] == destination) {
        return NO;
    }
    return YES;
}
#endif

- (BOOL)_canDismiss {
    XXViewController *destination = self.destination;
    if ([destination isKindOfClass:[XXViewController class]] == NO) {
        return NO;
    }
#if ZIK_HAS_UIKIT
    if (!destination.presentingViewController && /*can dismiss destination itself*/
        !destination.presentedViewController /*can dismiss destination's presentedViewController*/
        ) {
        return NO;
    }
#else
    if (@available(macOS 10.10, *)) {
        if (!destination.presentingViewController &&
            !destination.presentedViewControllers) {
            return NO;
        }
    }
    if (!destination.view) {
        return NO;
    }
    if (!destination.view.superview) {
        return NO;
    }
#endif
    return YES;
}

#if !ZIK_HAS_UIKIT
- (BOOL)_canCloseWindow {
    XXViewController *destination = self.destination;
    if ([destination isKindOfClass:[XXViewController class]] == NO) {
        return NO;
    }
    if (destination.isViewLoaded == NO) {
        return NO;
    }
    if (destination.view.window == nil) {
        return NO;
    }
    return YES;
}
#endif

- (BOOL)_canRemoveFromParentViewController {
    XXViewController *destination = self.destination;
    if ([destination isKindOfClass:[XXViewController class]] == NO) {
        return NO;
    }
    if (!destination.parentViewController) {
        return NO;
    }
    return YES;
}

- (BOOL)_canRemoveFromSuperview {
    XXView *destination = self.destination;
    if ([destination isKindOfClass:[XXView class]] == NO) {
        return NO;
    }
    if (!destination.superview) {
        return NO;
    }
    return YES;
}

- (BOOL)_guessCanRemove {
#if ZIK_HAS_UIKIT
    if ([self _canPop]) {
        return YES;
    }
#endif
    if ([self _canDismiss]) {
        return YES;
    }
    if (self.original_configuration.routeType == ZIKViewRouteTypeAddAsChildViewController &&
        [self _canRemoveFromParentViewController]) {
        return YES;
    }
    if ([self _canRemoveFromSuperview]) {
        return YES;
    }
    return NO;
}

- (void)removeDestination:(id)destination removeConfiguration:(__kindof ZIKRemoveRouteConfiguration *)removeConfiguration {
    if (!destination) {
        [self notifyRouteState:self.preState];
        [self notifyError_actionFailedWithAction:ZIKRouteActionRemoveRoute
                                errorDescription:@"Destination was deallced when removeRoute, router:%@",self];
        return;
    }
    [self prepareDestinationForRemoving];
    ZIKViewRouteConfiguration *configuration = self.original_configuration;
    if (configuration.routeType == ZIKViewRouteTypeCustom) {
        [self _removeCustomOnDestination:destination fromSource:configuration.source];
        return;
    }
    ZIKViewRouteRealType realRouteType = self.realRouteType;
    NSString *errorDescription;
    
    switch (realRouteType) {
            
#if ZIK_HAS_UIKIT
        case ZIKViewRouteRealTypePush:
            [self _popOnDestination:destination];
            break;
#endif
            
        case ZIKViewRouteRealTypePresentModally:
            [self _dismissOnDestination:destination];
            break;
            
        case ZIKViewRouteRealTypePresentAsPopover:
            [self _dismissPopoverOnDestination:destination];
            break;
#if !ZIK_HAS_UIKIT
        case ZIKViewRouteRealTypePresentAsSheet:
        case ZIKViewRouteRealTypePresentWithAnimator:
            [self _dismissOnDestination:destination];
            break;
            
        case ZIKViewRouteRealTypeShowWindow:
            [self _closeWindowOnDestination:destination];
            break;
#endif
        case ZIKViewRouteRealTypeAddAsChildViewController:
            [self _removeFromParentViewControllerOnDestination:destination];
            break;
            
        case ZIKViewRouteRealTypeAddAsSubview:
            [self _removeFromSuperviewOnDestination:destination];
            break;
            
        case ZIKViewRouteRealTypeUnknown:
            if ([self _guessToRemoveDestination:destination] == NO) {
                errorDescription = @"RouteType(Unknown) can't removeRoute";
            }
            break;
            
        case ZIKViewRouteRealTypeUnwind:
            errorDescription = @"RouteType(Unwind) can't removeRoute";
            break;
            
        case ZIKViewRouteRealTypeCustom:
            errorDescription = @"RouteType(Custom) can't removeRoute";
            break;
    }
    if (errorDescription) {
        [self notifyRouteState:self.preState];
        [self notifyError_actionFailedWithAction:ZIKRouteActionRemoveRoute
                                errorDescription:errorDescription];
    }
}

- (BOOL)_guessToRemoveDestination:(id)destination {
    if ([destination isKindOfClass:[XXViewController class]]) {
#if ZIK_HAS_UIKIT
        ZIKViewRouteType routeType = self.original_configuration.routeType;
        BOOL preferDismiss = YES;
        if (routeType == ZIKViewRouteTypePush) {
            preferDismiss = NO;
        }
        if (@available(iOS 8, *)) {
            if (routeType == ZIKViewRouteTypeShow) {
                preferDismiss = NO;
            }
        }
        if (preferDismiss == NO && [self _canPop]) {
            [self _popOnDestination:destination];
            return YES;
        }
#endif
        if ([self _canDismiss]) {
            [self _dismissOnDestination:destination];
            return YES;
        }
#if ZIK_HAS_UIKIT
        if (preferDismiss == YES && [self _canPop]) {
            [self _popOnDestination:destination];
            return YES;
        }
#endif
        if (self.original_configuration.routeType == ZIKViewRouteTypeAddAsChildViewController) {
            if ([self _canRemoveFromParentViewController]) {
                [self _removeFromParentViewControllerOnDestination:destination];
                return YES;
            }
        }
    } else if ([destination isKindOfClass:[XXView class]]) {
        if ([self _canRemoveFromSuperview]) {
            [self _removeFromSuperviewOnDestination:destination];
            return YES;
        }
    }
    return NO;
}

#if ZIK_HAS_UIKIT
- (void)_popOnDestination:(XXViewController *)destination {
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypePush)];
    XXViewController *source = destination.navigationController.visibleViewController;
    [self beginRemoveRouteFromSource:source];
    
    UINavigationController *navigationController;
    if (self.container.navigationController) {
        navigationController = self.container.navigationController;
    } else {
        navigationController = destination.navigationController;
    }
    XXViewController *popTo = (XXViewController *)self.original_configuration.source;
    
    if ([navigationController.viewControllers containsObject:popTo]) {
        [navigationController popToViewController:popTo animated:self.original_removeConfiguration.animated];
    } else {
        NSAssert(NO, @"navigationController doesn't contains original source when pop destination.");
        [destination.navigationController popViewControllerAnimated:self.original_removeConfiguration.animated];
    }
    [ZIKViewRouter _completeWithtransitionCoordinator:destination.navigationController.transitionCoordinator
                                 transitionCompletion:^{
        [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
    }];
}
#endif

- (void)_dismissOnDestination:(XXViewController *)destination {
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypePresentModally)];
    XXViewController *source = destination.presentingViewController;
    [self beginRemoveRouteFromSource:source];
#if ZIK_HAS_UIKIT
    [destination dismissViewControllerAnimated:self.original_removeConfiguration.animated completion:^{
        [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
    }];
#else
    if (@available(macOS 10.10, *)) {
        [destination dismissController:nil];
    } else {
        [destination.view removeFromSuperview];
    }
    [ZIKViewRouter _completeWithMacTransitionCompletion:^{
        [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
    }];
#endif
}

#if !ZIK_HAS_UIKIT
- (void)_closeWindowOnDestination:(XXViewController *)destination {
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypeShow)];
    [self beginRemoveRouteFromSource:nil];
    [destination.view.window close];
    [ZIKViewRouter _completeWithMacTransitionCompletion:^{
        [self endRemoveRouteWithSuccessOnDestination:destination fromSource:nil];
    }];
}
#endif

- (void)_dismissPopoverOnDestination:(XXViewController *)destination {
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypePresentAsPopover)];
    XXViewController *source = destination.presentingViewController;
    [self beginRemoveRouteFromSource:source];
    
#if ZIK_HAS_UIKIT
    if (NSClassFromString(@"UIPopoverPresentationController") ||
        [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) {
        [destination dismissViewControllerAnimated:self.original_removeConfiguration.animated completion:^{
            [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
        }];
        return;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    UIPopoverController *popover = self.popover;
#pragma clang diagnostic pop
    if (!popover) {
        [destination dismissViewControllerAnimated:self.original_removeConfiguration.animated completion:^{
            [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
        }];
        return;
    }
    [popover dismissPopoverAnimated:self.original_removeConfiguration.animated];
    self.popover = nil;
    [ZIKViewRouter _completeWithtransitionCoordinator:destination.transitionCoordinator
                                 transitionCompletion:^{
        [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
    }];
#else
    [destination dismissController:nil];
    [ZIKViewRouter _completeWithMacTransitionCompletion:^{
        [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
    }];
#endif
}

- (void)_removeFromParentViewControllerOnDestination:(XXViewController *)destination {
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypeAddAsChildViewController)];
    
    XXViewController *wrappedDestination = self.container;
    if (!wrappedDestination) {
        wrappedDestination = destination;
    }
    XXViewController *source = wrappedDestination.parentViewController;
    [self beginRemoveRouteFromSource:source];
    
#if ZIK_HAS_UIKIT
    [wrappedDestination willMoveToParentViewController:nil];
#endif
    void(^completion)(void) = ^{
        [wrappedDestination removeFromParentViewController];
        [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
        if (!wrappedDestination.isViewLoaded) {
            [destination setZix_routeTypeFromRouter:nil];
        }
    };
    
    void(^removingChildViewHandler)(XXViewController *destination, void(^completion)(void)) = self.original_removeConfiguration.removingChildViewHandler;
    if (removingChildViewHandler) {
#if ZIK_HAS_UIKIT
        [wrappedDestination willMoveToParentViewController:nil];
#endif
        removingChildViewHandler(wrappedDestination, completion);
        return;
    }
    BOOL isViewLoaded = wrappedDestination.isViewLoaded;
    if (isViewLoaded) {
        [wrappedDestination.view removeFromSuperview];//If do removeFromSuperview before removeFromParentViewController, -didMoveToParentViewController:nil in destination may be called twice
    }
    [wrappedDestination removeFromParentViewController];
    
    [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
    if (!isViewLoaded) {
        [destination setZix_routeTypeFromRouter:nil];
    }
}

- (void)_removeFromSuperviewOnDestination:(XXView *)destination {
    NSAssert(destination.superview, @"Destination doesn't have superview when remove from superview.");
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypeAddAsSubview)];
    XXView *source = destination.superview;
    [self beginRemoveRouteFromSource:source];
    
    [destination removeFromSuperview];
    
    // UIKit will call -willMoveToSuperview:, -didMoveToSuperview, -willMoveToWindow:, -didMoveToWindow asynchronously.
    // AppKit will call them synchronously in -removeFromSuperview
#if !ZIK_HAS_UIKIT
    if (destination.zix_routed == NO) {
        [destination setZix_routeTypeFromRouter:nil];
    }
#endif
    
    [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
}

- (void)_removeCustomOnDestination:(id)destination fromSource:(nullable id)source {
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypeCustom)];
    [self removeCustomRouteOnDestination:destination
                              fromSource:source
                     removeConfiguration:self.original_removeConfiguration
                           configuration:self.original_configuration];
}

- (void)removeCustomRouteOnDestination:(id)destination fromSource:(nullable id)source removeConfiguration:(ZIKViewRemoveConfiguration *)removeConfiguration configuration:(ZIKViewRouteConfiguration *)configuration {
    [self beginRemoveRouteFromSource:source];
    [self endRemoveRouteWithError:[ZIKViewRouter viewRouteErrorWithCode:ZIKViewRouteErrorUnsupportType localizedDescriptionFormat:@"Subclass (%@) must override -removeCustomRouteOnDestination:fromSource:configuration: to support removing custom route.",[self class]]];
    NSAssert(NO, @"Subclass (%@) must override -removeCustomRouteOnDestination:fromSource:configuration: to support removing custom route.",[self class]);
}

- (void)beginRemoveRouteFromSource:(nullable id)source {
    NSAssert(self.destination, @"Destination is not exist when remove route.");
    NSAssert(self.state == ZIKRouterStateRemoving, @"state should be removing when begin to remove.");
    self.retainedSelf = self;
    self.routingFromInternal = YES;
    id destination = self.destination;
    if ([destination conformsToProtocol:@protocol(ZIKRoutableView)]) {
        [ZIKViewRouter AOP_notifyAll_router:self willRemoveRouteOnDestination:destination fromSource:source];
    } else {
        NSAssert([self isMemberOfClass:[ZIKViewRouter class]] && self.original_configuration.routeType == ZIKViewRouteTypePerformSegue, @"Only ZIKViewRouteTypePerformSegue's destination can not conform to ZIKRoutableView");
    }
}

- (void)endRemoveRouteWithSuccessOnDestination:(id)destination fromSource:(nullable id)source {
    NSParameterAssert(destination);
    NSAssert(self.state == ZIKRouterStateRemoving || !self.routingFromInternal, @"State should be removing when end remove.");
    [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source notifyAOP:YES];
}

- (void)endRemoveRouteWithSuccessOnDestination:(id)destination fromSource:(nullable id)source notifyAOP:(BOOL)notifyAOP {
    NSParameterAssert(destination);
    [self notifyRouteState:ZIKRouterStateRemoved];
    if (notifyAOP) {
        if ([destination conformsToProtocol:@protocol(ZIKRoutableView)]) {
            [ZIKViewRouter AOP_notifyAll_router:self didRemoveRouteOnDestination:destination fromSource:source];
        } else {
            NSAssert([self isMemberOfClass:[ZIKViewRouter class]] && self.original_configuration.routeType == ZIKViewRouteTypePerformSegue, @"Only ZIKViewRouteTypePerformSegue's destination can not conform to ZIKRoutableView");
        }
    }
    [self notifySuccessWithAction:ZIKRouteActionRemoveRoute];
    if (self.state == ZIKRouterStateRemoved) {
        self.routingFromInternal = NO;
        self.container = nil;
        self.retainedSelf = nil;
    }
}

- (void)endRemoveRouteWithError:(NSError *)error {
    NSParameterAssert(error);
    NSAssert(self.state == ZIKRouterStateRemoving, @"state should be removing when end remove.");
    ZIKRouterState preState = self.preState;
    [super endRemoveRouteWithError:error];
    if (self.state == preState) {
        self.routingFromInternal = NO;
        self.retainedSelf = nil;
    }
}

#pragma mark AOP

+ (void)AOP_notifyAll_router:(nullable ZIKViewRouter *)router willPerformRouteOnDestination:(id)destination fromSource:(nullable id)source {
    NSParameterAssert([destination conformsToProtocol:@protocol(ZIKRoutableView)]);
    [ZIKViewRouteRegistry enumerateRoutersForDestinationClass:[destination class] handler:^(ZIKRouterType * _Nonnull route) {
        ZIKViewRouterType *r = (ZIKViewRouterType *)route;
        [r router:router willPerformRouteOnDestination:destination fromSource:source];
    }];
}

+ (void)AOP_notifyAll_router:(nullable ZIKViewRouter *)router didPerformRouteOnDestination:(id)destination fromSource:(nullable id)source {
    NSParameterAssert([destination conformsToProtocol:@protocol(ZIKRoutableView)]);
    [ZIKViewRouteRegistry enumerateRoutersForDestinationClass:[destination class] handler:^(ZIKRouterType * _Nonnull route) {
        ZIKViewRouterType *r = (ZIKViewRouterType *)route;
        [r router:router didPerformRouteOnDestination:destination fromSource:source];
    }];
}

+ (void)AOP_notifyAll_router:(nullable ZIKViewRouter *)router willRemoveRouteOnDestination:(id)destination fromSource:(nullable id)source {
    NSParameterAssert([destination conformsToProtocol:@protocol(ZIKRoutableView)]);
    [ZIKViewRouteRegistry enumerateRoutersForDestinationClass:[destination class] handler:^(ZIKRouterType * _Nonnull route) {
        ZIKViewRouterType *r = (ZIKViewRouterType *)route;
        [r router:router willRemoveRouteOnDestination:destination fromSource:(id)source];
    }];
}

+ (void)AOP_notifyAll_router:(nullable ZIKViewRouter *)router didRemoveRouteOnDestination:(id)destination fromSource:(nullable id)source {
    NSParameterAssert([destination conformsToProtocol:@protocol(ZIKRoutableView)]);
#if DEBUG
    __block BOOL shouldDetectMemoryLeak = NO;
#endif
    [ZIKViewRouteRegistry enumerateRoutersForDestinationClass:[destination class] handler:^(ZIKRouterType * _Nonnull route) {
        ZIKViewRouterType *r = (ZIKViewRouterType *)route;
        [r router:router didRemoveRouteOnDestination:destination fromSource:(id)source];
#if DEBUG
        if (!r.routerClass || [r.routerClass shouldDetectMemoryLeak]) {
            if (!shouldDetectMemoryLeak) {
                shouldDetectMemoryLeak = YES;
            }
        }
#endif
    }];
#if DEBUG
    if (shouldDetectMemoryLeak) {
        zix_checkMemoryLeak(destination, [self detectMemoryLeakDelay], [self didDetectLeakingHandler]);
    }    
#endif
}

+ (void)router:(nullable ZIKViewRouter *)router willPerformRouteOnDestination:(id)destination fromSource:(nullable id)source {
    
}

+ (void)router:(nullable ZIKViewRouter *)router didPerformRouteOnDestination:(id)destination fromSource:(nullable id)source {
    
}

+ (void)router:(nullable ZIKViewRouter *)router willRemoveRouteOnDestination:(id)destination fromSource:(nullable id)source {
    
}

+ (void)router:(nullable ZIKViewRouter *)router didRemoveRouteOnDestination:(id)destination fromSource:(nullable id)source {
    
}

#pragma mark Hook System Navigation
/*
 What did ZIKViewRouter hooked:
 -willMoveToParentViewController:
 -didMoveToParentViewController:
 -viewWillAppear:
 -viewDidAppear:
 -viewWillDisappear:
 -viewDidDisappear:
 -viewDidLoad
 -willMoveToSuperview:
 -didMoveToSuperview
 -willMoveToWindow:
 -didMoveToWindow
 all UIViewControllers' -prepareForSegue:sender:
 all UIStoryboardSegues' -perform
 -instantiateInitialViewController
 
 ZIKViewRouter hooks these methods for AOP and storyboard. In -willMoveToSuperview, -willMoveToWindow:, -prepareForSegue:sender:, it detects if the view is registered with a router, and auto create a router if it's not routed from its router.
 */

/// Update state when route action is not performed from router
- (void)_handleWillPerformRouteNotification:(NSNotification *)note {
    id destination = note.object;
    if (!self.destination || self.destination != destination) {
        return;
    }
    ZIKRouterState state = self.state;
    if (!self.routingFromInternal && state != ZIKRouterStateRouting) {
        ZIKViewRouteConfiguration *configuration = self.original_configuration;
        BOOL isFromAddAsChild = (configuration.routeType == ZIKViewRouteTypeAddAsChildViewController);
        if (isFromAddAsChild && self.realRouteType == ZIKViewRouteRealTypeUnknown) {
            self.realRouteType = ZIKViewRouteRealTypeAddAsChildViewController;
            return;
        }
        if (state != ZIKRouterStateRouted || (
#if ZIK_HAS_UIKIT
                self.stateBeforeRoute &&
#endif
                configuration.routeType == ZIKViewRouteTypeMakeDestination
                )) {
            [self notifyRouteState:ZIKRouterStateRouting];//not performed from router (dealed by system, or your code)
            if (configuration.handleExternalRoute) {
                [self prepareDestinationForPerforming];
            } else {
                if (configuration._prepareDestination) {
                    configuration._prepareDestination(destination);
                }
                [self prepareDestination:destination configuration:configuration];
                [self didFinishPrepareDestination:destination configuration:configuration];
            }
        }
    }
}

- (void)_handleDidPerformRouteNotification:(NSNotification *)note {
    id destination = note.object;
    if (!self.destination || self.destination != destination) {
        return;
    }
#if ZIK_HAS_UIKIT
    if (self.stateBeforeRoute &&
        self.original_configuration.routeType == ZIKViewRouteTypeMakeDestination) {
        NSAssert(self.realRouteType == ZIKViewRouteRealTypeUnknown, @"real route type is unknown before destination is real routed");
        ZIKPresentationState *stateBeforeRoute = self.stateBeforeRoute;
        if (stateBeforeRoute && [destination respondsToSelector:@selector(zix_presentationState)]) {
            ZIKViewRouteDetailType detailRouteType = [ZIKPresentationState detailRouteTypeFromStateBeforeRoute:stateBeforeRoute stateAfterRoute:[destination zix_presentationState]];
            self.realRouteType = [ZIKViewRouter _realRouteTypeFromDetailType:detailRouteType];
            self.stateBeforeRoute = nil;
        }
    }
#endif
    if (!self.routingFromInternal &&
        self.state != ZIKRouterStateRouted) {
        [self notifyRouteState:ZIKRouterStateRouted];//not performed from router (dealed by system, or your code)
        if (self.original_configuration.handleExternalRoute) {
            [self notifyPerformRouteSuccessWithDestination:destination];
        }
    }
}

- (void)_handleWillRemoveRouteNotification:(NSNotification *)note {
    id destination = note.object;
    if (!self.destination || self.destination != destination) {
        return;
    }
    ZIKRouterState state = self.state;
    if (!self.routingFromInternal && state != ZIKRouterStateRemoving) {
        if (state != ZIKRouterStateRemoved || (
#if ZIK_HAS_UIKIT
                self.stateBeforeRoute &&
#endif
                self.original_configuration.routeType == ZIKViewRouteTypeMakeDestination)) {
                [self notifyRouteState:ZIKRouterStateRemoving];//not performed from router (dealed by system, or your code)
            }
    }
    if (state == ZIKRouterStateRouting) {
        [self notifyError_unbalancedTransitionWithAction:ZIKRouteActionPerformRoute errorDescription:@"Unbalanced calls to begin/end appearance transitions for destination. This error occurs when you try and display a view controller before the current view controller is finished displaying. This may cause the UIViewController skips or messes up the order calling -viewWillAppear:, -viewDidAppear:, -viewWillDisAppear: and -viewDidDisappear:, and messes up the route state. Current error reason is trying to remove route on destination when destination is routing, router:(%@), callStack:%@",self,[NSThread callStackSymbols]];
    }
}

- (void)_handleDidRemoveRouteNotification:(NSNotification *)note {
    id destination = note.object;
    if (!self.destination || self.destination != destination) {
        return;
    }
#if ZIK_HAS_UIKIT
    if (self.stateBeforeRoute &&
        self.original_configuration.routeType == ZIKViewRouteTypeMakeDestination) {
        NSAssert(self.realRouteType == ZIKViewRouteRealTypeUnknown, @"real route type is unknown before destination is real routed");
        ZIKPresentationState *stateBeforeRoute = self.stateBeforeRoute;
        if (stateBeforeRoute && [destination respondsToSelector:@selector(zix_presentationState)]) {
            ZIKViewRouteDetailType detailRouteType = [ZIKPresentationState detailRouteTypeFromStateBeforeRoute:stateBeforeRoute stateAfterRoute:[destination zix_presentationState]];
            self.realRouteType = [ZIKViewRouter _realRouteTypeFromDetailType:detailRouteType];
            self.stateBeforeRoute = nil;
        }
    }
#endif
    if (!self.routingFromInternal &&
        self.state != ZIKRouterStateRemoved) {
        [self notifyRouteState:ZIKRouterStateRemoved];//not performed from router (dealed by system, or your code)
        if (self.original_removeConfiguration.handleExternalRoute) {
            [self notifySuccessWithAction:ZIKRouteActionRemoveRoute];
        }
    }
}

- (void)_handleRemoveRouteCancelledNotification:(NSNotification *)note {
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

static  ZIKViewRouterType *_Nullable _routerTypeToRegisteredView(Class viewClass) {
    ZIKRouterType *route = [ZIKViewRouteRegistry routerToRegisteredDestinationClass:viewClass];
    if ([route isKindOfClass:[ZIKViewRouterType class]]) {
        return (ZIKViewRouterType *)route;
    }
#if DEBUG
    if (ZIKRouteRegistry.registrationFinished) {
        NSCAssert1(NO, @"Didn't register any routerClass for viewClass (%@).",NSStringFromClass(viewClass));
    } else {
        NSCAssert1(NO, @"❌❌❌❌warning: failed to get router for view (%@), because manually registration is not finished yet! If there're modules running before registration is finished, and modules require some routers before you register them, then you should register those required routers earlier.",NSStringFromClass(viewClass));
    }
#endif
    
    return nil;
}

#if ZIK_HAS_UIKIT

- (void)ZIKViewRouter_hook_willMoveToParentViewController:(UIViewController *)parent {
    [self ZIKViewRouter_hook_willMoveToParentViewController:parent];
    if (parent) {
        [(XXViewController *)self setZix_parentMovingTo:parent];
    } else {
        XXViewController *currentParent = [(XXViewController *)self parentViewController];
        NSAssert(currentParent, @"currentParent shouldn't be nil when removing from parent");
        [(XXViewController *)self setZix_parentRemovingFrom:currentParent];
    }
}

- (void)ZIKViewRouter_hook_didMoveToParentViewController:(UIViewController *)parent {
    [self ZIKViewRouter_hook_didMoveToParentViewController:parent];
    if (parent) {
        [(XXViewController *)self setZix_parentMovingTo:nil];
    } else {
        //If you do removeFromSuperview before removeFromParentViewController, -didMoveToParentViewController:nil in child view controller may be called twice.        
        [(XXViewController *)self setZix_parentRemovingFrom:nil];
    }
}

- (void)ZIKViewRouter_hook_viewWillAppear:(BOOL)animated {
    [ZIKViewRouter tryToFinishWaitingViewRouters:NO];
    UIViewController *destination = (UIViewController *)self;
    BOOL removing = destination.zix_removing;
    BOOL isRoutableView = ([self conformsToProtocol:@protocol(ZIKRoutableView)] == YES);
    if (removing) {
        [destination setZix_removing:NO];
        if (isRoutableView) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteRemoveRouteCancelledNotification object:destination];
        }
    }
    if (isRoutableView) {
        BOOL routed = [(UIViewController *)self zix_routed];
        if (!routed) {
            UIViewController *parentMovingTo = [(UIViewController *)self zix_parentMovingTo];
            [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteWillPerformRouteNotification object:destination];
            NSNumber *routeTypeFromRouter = [destination zix_routeTypeFromRouter];
            if (!routeTypeFromRouter ||
                [routeTypeFromRouter integerValue] == ZIKViewRouteTypeMakeDestination ||
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
    [ZIKViewRouter tryToFinishWaitingViewRouters:YES];
    BOOL routed = [(UIViewController *)self zix_routed];
    UIViewController *parentMovingTo = [(UIViewController *)self zix_parentMovingTo];
    if (!routed &&
        [self conformsToProtocol:@protocol(ZIKRoutableView)]) {
        UIViewController *destination = (UIViewController *)self;
        [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteDidPerformRouteNotification object:destination];
        NSNumber *routeTypeFromRouter = [destination zix_routeTypeFromRouter];//This destination is routing from router
        if (!routeTypeFromRouter ||
            [routeTypeFromRouter integerValue] == ZIKViewRouteTypeMakeDestination ||
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
            [destination setZix_routeTypeFromRouter:nil];
        }
    }
    
    [self ZIKViewRouter_hook_viewDidAppear:animated];
    if (!routed) {
        [(UIViewController *)self setZix_routed:YES];
    }
}

- (void)ZIKViewRouter_hook_viewWillDisappear:(BOOL)animated {
    UIViewController *destination = (UIViewController *)self;
    if (destination.zix_removing == NO) {
        UIViewController *node = destination;
        while (node) {
            UIViewController *parentRemovingFrom = node.zix_parentRemovingFrom;
            UIViewController *source;
            if (parentRemovingFrom || //removing from navigation / willMoveToParentViewController:nil, removeFromParentViewController
                node.isMovingFromParentViewController || //removed from splite
                (!node.parentViewController && !node.presentingViewController && ![node zix_isAppRootViewController])) {
                source = parentRemovingFrom;
            } else if (node.isBeingDismissed) {
                source = node.presentingViewController;
            } else {
                node = node.parentViewController;
                continue;
            }
            if ([self conformsToProtocol:@protocol(ZIKRoutableView)]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteWillRemoveRouteNotification object:destination];
                NSNumber *routeTypeFromRouter = [destination zix_routeTypeFromRouter];
                if (!routeTypeFromRouter ||
                    [routeTypeFromRouter integerValue] == ZIKViewRouteTypeMakeDestination) {
                    [ZIKViewRouter AOP_notifyAll_router:nil willRemoveRouteOnDestination:destination fromSource:source];
                }
            }
            [destination setZix_parentRemovingFrom:source];
            [destination setZix_removing:YES];
            break;
        }
    }
    
    [self ZIKViewRouter_hook_viewWillDisappear:animated];
}

- (void)ZIKViewRouter_hook_viewDidDisappear:(BOOL)animated {
    UIViewController *destination = (UIViewController *)self;
    BOOL removing = destination.zix_removing;
    if ([self conformsToProtocol:@protocol(ZIKRoutableView)]) {
        if (removing) {
            UIViewController *source = destination.zix_parentRemovingFrom;
            [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteDidRemoveRouteNotification object:destination];
            NSNumber *routeTypeFromRouter = [destination zix_routeTypeFromRouter];
            if (!routeTypeFromRouter ||
                [routeTypeFromRouter integerValue] == ZIKViewRouteTypeMakeDestination) {
                [ZIKViewRouter AOP_notifyAll_router:nil didRemoveRouteOnDestination:destination fromSource:source];
            }
            if (routeTypeFromRouter) {
                [destination setZix_routeTypeFromRouter:nil];
            }
        }
    }
    if (removing) {
        [destination setZix_removing:NO];
        [destination setZix_routed:NO];
    } else if (zix_classIsCustomClass([destination class])) {
        //Check unbalanced calls to begin/end appearance transitions
        UIViewController *node = destination;
        while (node) {
            UIViewController *parentRemovingFrom = node.zix_parentRemovingFrom;
            UIViewController *source;
            if (parentRemovingFrom ||
                node.isMovingFromParentViewController ||
                (!node.parentViewController && !node.presentingViewController && ![node zix_isAppRootViewController])) {
                source = parentRemovingFrom;
            } else if (node.isBeingDismissed) {
                source = node.presentingViewController;
            } else {
                node = node.parentViewController;
                continue;
            }
            
            [destination setZix_parentRemovingFrom:source];
            [ZIKViewRouter notifyGlobalErrorWithRouter:nil action:ZIKRouteActionPerformRoute error:[ZIKViewRouter errorWithCode:ZIKViewRouteErrorUnbalancedTransition localizedDescriptionFormat:@"Unbalanced calls to begin/end appearance transitions for %@. This error occurs when you try and display a view controller before the current view controller is finished displaying. This may cause the UIViewController skips or messes up the order calling -viewWillAppear:, -viewDidAppear:, -viewWillDisAppear: and -viewDidDisappear:, and messes up the route state. Current error reason is already removed destination but destination appears again before -viewDidDisappear:, callStack:%@",self,[NSThread callStackSymbols]]];
            break;
        }
    }
    
    [self ZIKViewRouter_hook_viewDidDisappear:animated];
}

#else

// Transition methods for Mac OS

- (void)ZIKViewRouter_hook_presentViewController:(NSViewController *)viewController animator:(id <NSViewControllerPresentationAnimator>)animator {
    zix_replaceMethodWithMethod([animator class], @selector(animatePresentationOfViewController:fromViewController:), [ZIKViewRouter class], @selector(ZIKViewRouter_hook_animatePresentationOfViewController:fromViewController:));
    zix_replaceMethodWithMethod([animator class], @selector(animateDismissalOfViewController:fromViewController:), [ZIKViewRouter class], @selector(ZIKViewRouter_hook_animateDismissalOfViewController:fromViewController:));
    [self ZIKViewRouter_hook_presentViewController:viewController animator:animator];
}

- (void)ZIKViewRouter_hook_animatePresentationOfViewController:(NSViewController *)viewController fromViewController:(NSViewController *)fromViewController {
    NSArray<ZIKViewRouter *> *destinationViewRouters = viewController.zix_destinationViewRouters;
    if (destinationViewRouters) {
        //Auto created routers
        for (ZIKViewRouter *router in destinationViewRouters) {
            if (router.destination == viewController) {
                router.realRouteType = ZIKViewRouteRealTypePresentWithAnimator;
            }
        }
    }
    [viewController setZix_parentMovingTo:fromViewController];
    [self ZIKViewRouter_hook_animatePresentationOfViewController:viewController fromViewController:fromViewController];
}
- (void)ZIKViewRouter_hook_animateDismissalOfViewController:(NSViewController *)viewController fromViewController:(NSViewController *)fromViewController {
    [viewController setZix_parentRemovingFrom:fromViewController];
    [self ZIKViewRouter_hook_animateDismissalOfViewController:viewController fromViewController:fromViewController];
}

- (void)ZIKViewRouter_hook_setContentViewController:(NSViewController *)contentViewController {
    if (contentViewController) {
        NSArray<ZIKViewRouter *> *destinationViewRouters = contentViewController.zix_destinationViewRouters;
        if (destinationViewRouters) {
            //Auto created routers
            for (ZIKViewRouter *router in destinationViewRouters) {
                if (router.destination == contentViewController) {
                    router.realRouteType = ZIKViewRouteRealTypeShowWindow;
                }
            }
        }
        
        NSWindow *window = (NSWindow *)self;
        id parent = window.windowController;
        if (parent == nil) {
            parent = window;
        }
        if (contentViewController.zix_parentMovingTo == nil) {
            [contentViewController setZix_parentMovingTo:parent];
        }
    }
    [self ZIKViewRouter_hook_setContentViewController:contentViewController];
}

+ (void)handleWindowWillCloseNotification:(NSNotification *)notification {
    NSWindow *window = (NSWindow *)notification.object;
    NSViewController *contentViewController = window.contentViewController;
    if (contentViewController == nil) {
        return;
    }
    id parent = window.windowController;
    if (parent == nil) {
        parent = window;
    }
    if (contentViewController.zix_parentRemovingFrom == nil) {
        [contentViewController setZix_parentRemovingFrom:parent];
    }
}

- (void)ZIKViewRouter_hook_viewWillAppear {
    [ZIKViewRouter tryToFinishWaitingViewRouters:NO];
    XXViewController *destination = (XXViewController *)self;
    BOOL removing = destination.zix_removing;
    BOOL isRoutableView = ([self conformsToProtocol:@protocol(ZIKRoutableView)] == YES);
    if (removing) {
        [destination setZix_removing:NO];
        if (isRoutableView) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteRemoveRouteCancelledNotification object:destination];
        }
    }
    if (isRoutableView) {
        BOOL routed = [(XXViewController *)self zix_routed];
        if (!routed) {
            id parentMovingTo = [(XXViewController *)self zix_parentMovingTo];
            [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteWillPerformRouteNotification object:destination];
            NSNumber *routeTypeFromRouter = [destination zix_routeTypeFromRouter];
            if (!routeTypeFromRouter ||
                [routeTypeFromRouter integerValue] == ZIKViewRouteTypeMakeDestination ||
                [routeTypeFromRouter integerValue] == ZIKViewRouteTypeAddAsChildViewController) {
                id source = parentMovingTo;
                [ZIKViewRouter AOP_notifyAll_router:nil willPerformRouteOnDestination:destination fromSource:source];
            }
        }
    }
    
    [self ZIKViewRouter_hook_viewWillAppear];
}

- (void)ZIKViewRouter_hook_viewDidAppear {
    [ZIKViewRouter tryToFinishWaitingViewRouters:YES];
    BOOL routed = [(XXViewController *)self zix_routed];
    id parentMovingTo = [(XXViewController *)self zix_parentMovingTo];
    if (!routed &&
        [self conformsToProtocol:@protocol(ZIKRoutableView)]) {
        XXViewController *destination = (XXViewController *)self;
        [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteDidPerformRouteNotification object:destination];
        NSNumber *routeTypeFromRouter = [destination zix_routeTypeFromRouter];//This destination is routing from router
        if (!routeTypeFromRouter ||
            [routeTypeFromRouter integerValue] == ZIKViewRouteTypeMakeDestination ||
            [routeTypeFromRouter integerValue] == ZIKViewRouteTypeAddAsChildViewController) {
            id source = parentMovingTo;
            [ZIKViewRouter AOP_notifyAll_router:nil didPerformRouteOnDestination:destination fromSource:source];
        }
        if (routeTypeFromRouter) {
            [destination setZix_routeTypeFromRouter:nil];
        }
    }
    
    [self ZIKViewRouter_hook_viewDidAppear];
    if (!routed) {
        [(XXViewController *)self setZix_parentMovingTo:nil];
        [(XXViewController *)self setZix_routed:YES];
    }
}

- (void)ZIKViewRouter_hook_viewWillDisappear {
    XXViewController *destination = (XXViewController *)self;
    if (destination.zix_removing == NO) {
        XXViewController *node = destination;
        while (node) {
            id parentRemovingFrom = node.zix_parentRemovingFrom;
            id source;
            if (parentRemovingFrom ||
                (!node.parentViewController && !node.presentingViewController && ![node zix_isAppRootViewController])) {
                source = parentRemovingFrom;
            } else {
                node = node.parentViewController;
                continue;
            }
            if ([self conformsToProtocol:@protocol(ZIKRoutableView)]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteWillRemoveRouteNotification object:destination];
                NSNumber *routeTypeFromRouter = [destination zix_routeTypeFromRouter];
                if (!routeTypeFromRouter ||
                    [routeTypeFromRouter integerValue] == ZIKViewRouteTypeMakeDestination) {
                    [ZIKViewRouter AOP_notifyAll_router:nil willRemoveRouteOnDestination:destination fromSource:source];
                }
            }
            [destination setZix_parentRemovingFrom:source];
            [destination setZix_removing:YES];
            break;
        }
    }
    
    [self ZIKViewRouter_hook_viewWillDisappear];
}

- (void)ZIKViewRouter_hook_viewDidDisappear {
    XXViewController *destination = (XXViewController *)self;
    BOOL removing = destination.zix_removing;
    if ([self conformsToProtocol:@protocol(ZIKRoutableView)]) {
        if (removing) {
            id source = destination.zix_parentRemovingFrom;
            [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteDidRemoveRouteNotification object:destination];
            NSNumber *routeTypeFromRouter = [destination zix_routeTypeFromRouter];
            if (!routeTypeFromRouter ||
                [routeTypeFromRouter integerValue] == ZIKViewRouteTypeMakeDestination) {
                [ZIKViewRouter AOP_notifyAll_router:nil didRemoveRouteOnDestination:destination fromSource:source];
            }
            if (routeTypeFromRouter) {
                [destination setZix_routeTypeFromRouter:nil];
            }
        }
    }
    if (removing) {
        [destination setZix_parentRemovingFrom:nil];
        [destination setZix_removing:NO];
        [destination setZix_routed:NO];
    } else if (zix_classIsCustomClass([destination class])) {
        //Check unbalanced calls to begin/end appearance transitions
        XXViewController *node = destination;
        while (node) {
            id parentRemovingFrom = node.zix_parentRemovingFrom;
            id source;
            if (parentRemovingFrom ||
                (!node.parentViewController && !node.presentingViewController && ![node zix_isAppRootViewController])) {
                source = parentRemovingFrom;
            } else {
                node = node.parentViewController;
                continue;
            }
            
            [destination setZix_parentRemovingFrom:source];
            [ZIKViewRouter notifyGlobalErrorWithRouter:nil action:ZIKRouteActionPerformRoute error:[ZIKViewRouter errorWithCode:ZIKViewRouteErrorUnbalancedTransition localizedDescriptionFormat:@"Unbalanced calls to begin/end appearance transitions for %@. This error occurs when you try and display a view controller before the current view controller is finished displaying. This may cause the UIViewController skips or messes up the order calling -viewWillAppear:, -viewDidAppear:, -viewWillDisAppear: and -viewDidDisappear:, and messes up the route state. Current error reason is already removed destination but destination appears again before -viewDidDisappear:, callStack:%@",self,[NSThread callStackSymbols]]];
            break;
        }
    }
    
    [self ZIKViewRouter_hook_viewDidDisappear];
}

#endif

/**
 Note: in -viewWillAppear:, if the view controller contains sub routable UIView added from external (addSubview:, storyboard or xib), the subview may not be ready yet. The UIView has to search the performer with -nextResponder to prepare itself, nextResponder can only be gained after -viewDidLoad or -willMoveToWindow:. But -willMoveToWindow: may not be called yet in -viewWillAppear:. If the subview is not ready, config the subview in -handleViewReady may fail.
 So we have to make sure routable UIView is prepared before -viewDidLoad if it's added to the superview when superview is not on screen yet.
 */
- (void)ZIKViewRouter_hook_viewDidLoad {
    NSAssert([NSThread isMainThread], @"UI thread must be main thread.");
    [self ZIKViewRouter_hook_viewDidLoad];
    
    [ZIKViewRouter tryToPrepareWaitingViewRouters];
}

+ (void)tryToPrepareWaitingViewRouters {
    //Find performer and prepare for destination added to a superview not on screen in -ZIKViewRouter_hook_willMoveToSuperview
    NSMutableSet *preparingRouters = g_preparingXXViewRouters;
    
    __block NSMutableSet *preparedRouters;
    if (preparingRouters.count > 0) {
        [preparingRouters enumerateObjectsUsingBlock:^(ZIKViewRouter *router, BOOL * _Nonnull stop) {
            XXView *destination = router.destination;
            NSAssert([destination isKindOfClass:[XXView class]], @"Only UIView destination need fix.");
            id performer = [destination zix_routePerformer];
            if (performer) {
                [ZIKViewRouter _prepareDestinationFromExternal:destination router:router performer:performer];
                router.prepared = YES;
                if ([destination respondsToSelector:@selector(zix_routeTypeFromRouter)]) {
                    NSNumber *routeTypeFromRouter = destination.zix_routeTypeFromRouter;
                    [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteWillPerformRouteNotification object:destination];
                    if (!routeTypeFromRouter ||
                        [routeTypeFromRouter integerValue] == ZIKViewRouteTypeMakeDestination) {
                        [ZIKViewRouter AOP_notifyAll_router:router willPerformRouteOnDestination:destination fromSource:router.original_configuration.source];
                    }
                }
                
                if (!preparedRouters) {
                    preparedRouters = [NSMutableSet set];
                }
                [preparedRouters addObject:router];
            }
        }];
        if (preparedRouters.count > 0) {
            [preparingRouters minusSet:preparedRouters];
        }
    }
}

// Some private system view won't call -willMoveToWindow: and -didMoveToWindow. Finish them with this.
+ (void)tryToFinishWaitingViewRouters:(BOOL)finishWhenHasWindow {
    NSMutableSet *finishingRouters = g_finishingXXViewRouters;
    __block NSMutableSet *finishedRouters;
    if (finishingRouters.count > 0) {
        [finishingRouters enumerateObjectsUsingBlock:^(ZIKViewRouter *router, BOOL * _Nonnull stop) {
            XXView *destination = router.destination;
            if (router.prepared == NO) {
                return;
            }
            if (!destination.window) {
                if (!finishWhenHasWindow) {
                    return;
                }
            }
            ZIKViewRouter *destinationViewRouter = destination.zix_destinationViewRouter;
            if (destinationViewRouter == router) {
                destination.zix_destinationViewRouter = nil;
            }
            if (!finishedRouters) {
                finishedRouters = [NSMutableSet set];
            }
            ZIKRouterState state = router.state;
            if (state == ZIKRouterStateRouted || state == ZIKRouterStateRemoved) {
                [finishedRouters addObject:router];
                return;
            }
            if (state == ZIKRouterStateRouting) {
                [finishedRouters addObject:router];
                if (destination == nil) {
                    [router endPerformRouteWithError:[ZIKViewRouter routeErrorWithCode:ZIKRouteErrorActionFailed localizedDescription:@"Destination was dealloced when performing route."]];
                    return;
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteDidPerformRouteNotification object:destination];
                [router endPerformRouteWithSuccess];
                return;
            }
            if (state == ZIKRouterStateRemoving) {
                [finishedRouters addObject:router];
                if (destination == nil) {
                    [router endRemoveRouteWithError:[ZIKViewRouter routeErrorWithCode:ZIKRouteErrorActionFailed localizedDescription:@"Destination was dealloced when removing route."]];
                    return;
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteDidRemoveRouteNotification object:destination];
                [router endRemoveRouteWithSuccessOnDestination:destination fromSource:destination.superview];
                return;
            }
        }];
        if (finishedRouters.count > 0) {
            [finishingRouters minusSet:finishedRouters];
        }
    }
}

/// Add subview by code or storyboard will auto create a corresponding router. We assume its superview's view controller is the performer. If your custom class view uses a routable view as its part, the custom view should use a router to add and prepare the routable view, then the routable view doesn't need to search performer.

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
 Add a routable subview to a superview, then add the superview to an UIView in view controller.
 Invoking order in subview when subview needs prepare:
 1.willMoveToSuperview: (add to prepare list if its superview chain is not in window)
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
 Add a routable subview to a superviw, but the superview was never added to any view controller. This should get an error when subview needs prepare.
 Invoking order in subview when subview needs prepare:
 1.willMoveToSuperview:newSuperview (add to preparing list, prepare until )
 2.didMoveToSuperview
 3.willMoveToSuperview:nil
    4.when detected that router is still in prepareing list, means last preparation is not finished, get invalid performer error.
    5.router:willRemoveRouteOnDestination:fromSource:
 6.didMoveToSuperview
    7.router:didRemoveRouteOnDestination:fromSource:
 
 Invoking order in subview when subview doesn't need prepare:
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
 Add a routable subview to an UIWindow. This should get an error when subview needs prepare.
 Invoking order in subview when subview needs prepare:
 1.willMoveToWindow:newWindow
 2.willMoveToSuperview:newSuperview
    3.when detected that newSuperview is already on screen, but can't find the performer, get invalid performer error
    4.router:willPerformRouteOnDestination:fromSource:
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

#if ZIK_HAS_UIKIT
- (void)ZIKViewRouter_hook_willMoveToSuperview:(nullable UIView *)newSuperview
#else
- (void)ZIKViewRouter_hook_willMoveToSuperview:(nullable NSView *)newSuperview
#endif
{
    XXView *destination = (XXView *)self;
    if (!newSuperview) {
        destination.zix_removing = YES;
    }
    if ([self conformsToProtocol:@protocol(ZIKRoutableView)]) {
        if (!newSuperview) {
            //Removing from superview
            NSNumber *routeTypeFromRouter = [destination zix_routeTypeFromRouter];
            ZIKViewRouter *destinationRouter = [destination zix_destinationViewRouter];
            BOOL alreadyRemoved = NO;
            BOOL shouldNotifyWillRemove = YES;
            if (!routeTypeFromRouter && destinationRouter) {
                //Destination's superview never be added to a view controller, so destination is never on a window
                if (destinationRouter.state == ZIKRouterStateRouting) {
                    [g_finishingXXViewRouters removeObject:destinationRouter];
                    if (destinationRouter.prepared == NO) {
                        shouldNotifyWillRemove = NO;
                        [destinationRouter prepareDestinationForPerforming];
                        destinationRouter.prepared = YES;
                        //Didn't find the performer of UIView until it's removing from superview, maybe its superview was never added to any view controller
                        NSString *description = [NSString stringWithFormat:@"Didn't find the performer of UIView until it's removing from superview, maybe its superview was never added to any view controller. Can't find which custom UIView or UIViewController added destination:(%@) as subview, so we can't notify the performer to config the destination. You may add destination to an UIWindow in code directly, and the UIWindow is not a custom class. Please change your code and add subview by a custom view router with ZIKViewRouteTypeAddAsSubview. Destination superview: (%@).",destination, newSuperview];
                        [destinationRouter endPerformRouteWithError:[ZIKViewRouter errorWithCode:ZIKViewRouteErrorInvalidPerformer localizedDescription:description]];
                        [g_preparingXXViewRouters removeObject:destinationRouter];
                    } else {
                        //end perform
                        [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteDidPerformRouteNotification object:destination];
                        [destinationRouter endPerformRouteWithSuccess];
                    }
                } else if (destinationRouter.state == ZIKRouterStateRemoved) {
                    // Already finish removing in +tryToFinishWaitingViewRouters
                    alreadyRemoved = YES;
                    destination.zix_destinationViewRouter = nil;
                }
            }
            if (!alreadyRemoved && (routeTypeFromRouter || shouldNotifyWillRemove)) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteWillRemoveRouteNotification object:destination];
                if (!routeTypeFromRouter ||
                    [routeTypeFromRouter integerValue] == ZIKViewRouteTypeMakeDestination) {
                    [ZIKViewRouter AOP_notifyAll_router:destinationRouter willRemoveRouteOnDestination:destination fromSource:destination.superview];
                }
            }
            
        } else if (!destination.zix_routed) {
            // First time adding to a superview
            ZIKViewRouter *router;
            BOOL alreadyPerformed = NO;
            BOOL shouldNotifyWillPerform = NO;
            NSNumber *routeTypeFromRouter = [destination zix_routeTypeFromRouter];
            if (!routeTypeFromRouter) {
                //Not routing from router
                ZIKViewRouter *destinationRouter = [destination zix_destinationViewRouter];
                if (destinationRouter && destinationRouter.state == ZIKRouterStateRouted) {
                    // Already finish performing in +tryToFinishWaitingViewRouters
                    alreadyPerformed = YES;
                }
                if (!destinationRouter) {
                    // Auto create its router
                    ZIKViewRouterType *routerType = _routerTypeToRegisteredView([destination class]);
                    NSAssert([routerType _validateSupportedRouteTypesForXXView], @"Router for UIView only supports ZIKViewRouteTypeAddAsSubview, ZIKViewRouteTypeMakeDestination and ZIKViewRouteTypeCustom, override +supportedRouteTypes in your router.");
                    shouldNotifyWillPerform = YES;
                    if ([routerType shouldAutoCreateForDestination:destination fromSource:newSuperview]) {
                        destinationRouter = [routerType routerFromView:destination source:newSuperview];
                        if (destinationRouter) {
                            destinationRouter.routingFromInternal = YES;
                            [destinationRouter notifyRouteState:ZIKRouterStateRouting];
                            [destination setZix_destinationViewRouter:destinationRouter];
                            [g_finishingXXViewRouters addObject:destinationRouter];// Finish in didMoveToWindow or view did appear
                        }
                    }
                }
                if (destinationRouter && destinationRouter.prepared == NO) {
                    shouldNotifyWillPerform = YES;
                    if (![destinationRouter destinationFromExternalPrepared:destination]) {
                        id performer;
                        if (destination.nextResponder) {
                            performer = [destination zix_routePerformer];
                        } else if (newSuperview.nextResponder) {
                            performer = [newSuperview zix_routePerformer];
                        }
                        
                        if (performer) {
                            //Adding to a superview on screen.
                            [ZIKViewRouter _prepareDestinationFromExternal:destination router:destinationRouter performer:performer];
                            destinationRouter.prepared = YES;
                        } else {
                            shouldNotifyWillPerform = NO;
                            //Adding to a superview on screen.
                            if (newSuperview.window || [newSuperview isKindOfClass:[XXWindow class]]) {
                                NSString *description = [NSString stringWithFormat:@"Adding to a superview on screen. Can't find which custom UIView or UIViewController added destination:(%@) as subview, so we can't notify the performer to config the destination. You may add destination to an UIWindow in code directly. Please fix your code and add subview by a custom view router with ZIKViewRouteTypeAddAsSubview. Destination superview: (%@).",destination, newSuperview];
                                [ZIKViewRouter notifyError_invalidPerformerWithAction:ZIKRouteActionPerformRoute errorDescription:description];
                            }
                        }
                    } else {
                        [destinationRouter prepareDestinationForPerforming];
                        destinationRouter.prepared = YES;
                    }
                }
                router = destinationRouter;
            }
            
            if (!alreadyPerformed && (routeTypeFromRouter || shouldNotifyWillPerform)) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteWillPerformRouteNotification object:destination];
                NSNumber *routeTypeFromRouter = [destination zix_routeTypeFromRouter];
                if (!routeTypeFromRouter ||
                    [routeTypeFromRouter integerValue] == ZIKViewRouteTypeMakeDestination) {
                    [ZIKViewRouter AOP_notifyAll_router:router willPerformRouteOnDestination:destination fromSource:newSuperview];
                }
            }
        }
    }
    
    if (!newSuperview) {
        destination.zix_routed = NO;
    }
    
    [self ZIKViewRouter_hook_willMoveToSuperview:newSuperview];
}

- (void)ZIKViewRouter_hook_didMoveToSuperview {
    XXView *destination = (XXView *)self;
    XXView *superview = destination.superview;
    if ([self conformsToProtocol:@protocol(ZIKRoutableView)]) {
        NSNumber *routeTypeFromRouter = [destination zix_routeTypeFromRouter];
        if (!superview) {
            BOOL alreadyRemoved = NO;
            ZIKViewRouter *destinationRouter = destination.zix_destinationViewRouter;
            if (destinationRouter) {
                [g_finishingXXViewRouters removeObject:destinationRouter];
                destination.zix_destinationViewRouter = nil;
                if (destinationRouter.state == ZIKRouterStateRemoved) {
                    // Already finish removing in +tryToFinishWaitingViewRouters
                    alreadyRemoved = YES;
                }
            }
            
#if ZIK_HAS_UIKIT
            if (routeTypeFromRouter) {
                [destination setZix_routeTypeFromRouter:nil];
            }
#endif
            if (!alreadyRemoved) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteDidRemoveRouteNotification object:destination];
                if (!routeTypeFromRouter ||
                    [routeTypeFromRouter integerValue] == ZIKViewRouteTypeMakeDestination) {
                    
                }
                BOOL notifyAOP = NO;
                if (!routeTypeFromRouter ||
                    [routeTypeFromRouter integerValue] == ZIKViewRouteTypeMakeDestination) {
                    notifyAOP = YES;
                }
                if (destinationRouter) {
                    // end remove
                    if (notifyAOP) {
                        [destinationRouter endRemoveRouteWithSuccessOnDestination:destination fromSource:nil];
                    } else {
                        [destinationRouter endRemoveRouteWithSuccessOnDestination:destination fromSource:nil notifyAOP:NO];
                    }
                } else if (notifyAOP) {
                    //Can't get source, source may already be dealloced here or is in dealloc
                    [ZIKViewRouter AOP_notifyAll_router:destinationRouter didRemoveRouteOnDestination:destination fromSource:nil];
                }
            }
        }
    }
    if (!superview) {
        destination.zix_removing = NO;
    }
    
    [self ZIKViewRouter_hook_didMoveToSuperview];
}

#if ZIK_HAS_UIKIT
- (void)ZIKViewRouter_hook_willMoveToWindow:(nullable UIWindow *)newWindow
#else
- (void)ZIKViewRouter_hook_willMoveToWindow:(nullable NSWindow *)newWindow
#endif
{
    XXView *destination = (XXView *)self;
    BOOL routed = destination.zix_routed;
    BOOL removing = destination.zix_removing;
    if ([self conformsToProtocol:@protocol(ZIKRoutableView)]) {
        if (!routed && !removing) {
            ZIKViewRouter *router;
            XXView *source;
            NSNumber *routeTypeFromRouter = [destination zix_routeTypeFromRouter];
            BOOL alreadyPerformed = NO;
            BOOL shouldNotifyWillPerform = NO;
            if (!routeTypeFromRouter) {
                // Not performed from router
                ZIKViewRouter *destinationRouter = [destination zix_destinationViewRouter];
                if (destinationRouter && destinationRouter.state == ZIKRouterStateRouted) {
                    // Already finish performing in +tryToFinishWaitingViewRouters
                    alreadyPerformed = YES;
                }
                // Was added to a superview when superview was not on screen, and it's displayed now.
                if (destination.superview) {
                    source = destination.superview;
                    
                    if (!destinationRouter) {
                        
                        ZIKViewRouterType *routerType = _routerTypeToRegisteredView([destination class]);
                        if (routerType) {
                            NSAssert([routerType _validateSupportedRouteTypesForXXView], @"Router for UIView only supports ZIKViewRouteTypeAddAsSubview, ZIKViewRouteTypeMakeDestination and ZIKViewRouteTypeCustom, override +supportedRouteTypes in your router.");
                            if ([routerType shouldAutoCreateForDestination:destination fromSource:source]) {
                                shouldNotifyWillPerform = YES;
                                destinationRouter = [routerType routerFromView:destination source:source];
                                if (destinationRouter) {
                                    destinationRouter.routingFromInternal = YES;
                                    [destinationRouter notifyRouteState:ZIKRouterStateRouting];
                                    [destination setZix_destinationViewRouter:destinationRouter];
                                    [g_finishingXXViewRouters addObject:destinationRouter];// Finish in didMoveToWindow or view did appear
                                }
                            }
                        }
                    }
                    
                    if (destinationRouter && destinationRouter.prepared == NO) {
                        shouldNotifyWillPerform = YES;
                        if (![destinationRouter destinationFromExternalPrepared:destination]) {
                            BOOL onScreen = ([destination zix_firstAvailableViewController] != nil);
                            if (onScreen) {
                                id performer = [destination zix_routePerformer];
                                if (performer) {
                                    NSAssert(zix_classIsCustomClass(performer), @"performer should be a subclass of UIViewController in your project.");
                                    [ZIKViewRouter _prepareDestinationFromExternal:destination router:destinationRouter performer:performer];
                                    destinationRouter.prepared = YES;
                                    [g_preparingXXViewRouters removeObject:destinationRouter];
                                } else {
                                    shouldNotifyWillPerform = NO;
                                }
                            } else {
                                shouldNotifyWillPerform = NO;
                            }
                        } else {
                            [destinationRouter prepareDestinationForPerforming];
                            destinationRouter.prepared = YES;
                            shouldNotifyWillPerform = YES;
                            [g_preparingXXViewRouters removeObject:destinationRouter];
                        }
                    }
                    router = destinationRouter;
                }
            }
            
            //Was added to a superview when superview was not on screen, and it's displayed now.
            if (!routed && source && !alreadyPerformed && shouldNotifyWillPerform) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteWillPerformRouteNotification object:destination];
                if (!routeTypeFromRouter ||
                    [routeTypeFromRouter integerValue] == ZIKViewRouteTypeMakeDestination) {
                    [ZIKViewRouter AOP_notifyAll_router:router willPerformRouteOnDestination:destination fromSource:source];
                }
            }
        }
    }
    
    [self ZIKViewRouter_hook_willMoveToWindow:newWindow];
}

- (void)ZIKViewRouter_hook_didMoveToWindow {
    XXView *destination = (XXView *)self;
    XXWindow *window = destination.window;
    BOOL routed = destination.zix_routed;
    BOOL removing = destination.zix_removing;
    if ([self conformsToProtocol:@protocol(ZIKRoutableView)]) {
        if (!routed && !removing) {
            ZIKViewRouter *router;
            BOOL alreadyPerformed = NO;
            NSNumber *routeTypeFromRouter = [destination zix_routeTypeFromRouter];
            if (!routeTypeFromRouter) {
                // Not from router
                BOOL shouldNotifyWillPerform = NO;
                id source = destination.superview;
                if (source == nil) {
                    source = destination.window;
                }
                if (source == nil) {
                    id nextResponder = destination.nextResponder;
                    if (nextResponder && ([nextResponder isKindOfClass:[XXView class]] || [nextResponder isKindOfClass:[XXWindow class]])) {
                        source = nextResponder;
                    }
                }
                ZIKViewRouter *destinationRouter = destination.zix_destinationViewRouter;
                if (destinationRouter && destinationRouter.state == ZIKRouterStateRouted) {
                    // Already finish performing in +tryToFinishWaitingViewRouters
                    alreadyPerformed = YES;
                }
                if (!destinationRouter) {
                    // Auto create its router
                    
                    if (source) {
                        ZIKViewRouterType *routerType = _routerTypeToRegisteredView([destination class]);
                        if (routerType) {
                            NSAssert([routerType _validateSupportedRouteTypesForXXView], @"Router for UIView only supports ZIKViewRouteTypeAddAsSubview, ZIKViewRouteTypeMakeDestination and ZIKViewRouteTypeCustom, override +supportedRouteTypes in your router.");
                            if ([routerType shouldAutoCreateForDestination:destination fromSource:source]) {
                                shouldNotifyWillPerform = YES;
                                destinationRouter = [routerType routerFromView:destination source:source];
                                if (destinationRouter) {
                                    destinationRouter.routingFromInternal = YES;
                                    [destinationRouter notifyRouteState:ZIKRouterStateRouting];
                                    [destination setZix_destinationViewRouter:destinationRouter];
                                    [g_finishingXXViewRouters addObject:destinationRouter];
                                }
                            }
                        }
                    }
                }
                router = destinationRouter;
                //Find performer and prepare for destination added to a superview not on screen in -ZIKViewRouter_hook_willMoveToSuperview
                if (destinationRouter && destinationRouter.prepared == NO) {
                    shouldNotifyWillPerform = YES;
                    if (![destinationRouter destinationFromExternalPrepared:destination]) {
                        BOOL onScreen = ([destination zix_firstAvailableViewController] != nil);
                        if (onScreen) {
                            id performer = [destination zix_routePerformer];
                            if (performer) {
                                NSAssert(zix_classIsCustomClass(performer), @"performer should be a subclass of UIViewController in your project.");
                                [ZIKViewRouter _prepareDestinationFromExternal:destination router:destinationRouter performer:performer];
                                destinationRouter.prepared = YES;
                            } else {
                                NSString *description = [NSString stringWithFormat:@"Can't find which custom UIView or UIViewController added destination:(%@) as subview, so we can't notify the performer to config the destination. You may add destination to an UIWindow in code directly, and the UIWindow is not a custom class. Please change your code and add subview by a custom view router with ZIKViewRouteTypeAddAsSubview. Destination superview: %@.",destination, destination.superview];
                                [ZIKViewRouter notifyError_invalidPerformerWithAction:ZIKRouteActionPerformRoute errorDescription:description];
                            }
                        } else {
                            // Can't find view controller to prepare
                            [destinationRouter prepareDestinationForPerforming];
                            destinationRouter.prepared = YES;
                        }
                    } else {
                        [destinationRouter prepareDestinationForPerforming];
                        destinationRouter.prepared = YES;
                    }
                    [g_preparingXXViewRouters removeObject:destinationRouter];
                }
                
                if (!alreadyPerformed && shouldNotifyWillPerform) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteWillPerformRouteNotification object:destination];
                    if (!routeTypeFromRouter ||
                        [routeTypeFromRouter integerValue] == ZIKViewRouteTypeMakeDestination) {
                        [ZIKViewRouter AOP_notifyAll_router:router willPerformRouteOnDestination:destination fromSource:source];
                    }
                }
            }
            
            if (router) {
                [g_finishingXXViewRouters removeObject:router];
            }
            if (!alreadyPerformed) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteDidPerformRouteNotification object:destination];
                BOOL notifyAOP = NO;
                if (!routeTypeFromRouter ||
                    [routeTypeFromRouter integerValue] == ZIKViewRouteTypeMakeDestination) {
                    notifyAOP = YES;
                }
                //end perform
                if (router) {
                    if (notifyAOP) {
                        [router endPerformRouteWithSuccess];
                    } else {
                        [router endPerformRouteWithSuccessWithAOP:NO];
                    }
                    destination.zix_destinationViewRouter = nil;
                } else if (notifyAOP) {
                    [ZIKViewRouter AOP_notifyAll_router:nil didPerformRouteOnDestination:destination fromSource:destination.superview];
                }
            }
            
#if ZIK_HAS_UIKIT
            if (routeTypeFromRouter) {
                [destination setZix_routeTypeFromRouter:nil];
            }
#endif
        }
    }
    
    [self ZIKViewRouter_hook_didMoveToWindow];
    if (!routed && window) {
        destination.zix_routed = YES;
    }
}

/// Auto prepare storyboard's routable initial view controller or it's routable child view controllers
#if ZIK_HAS_UIKIT
- (nullable __kindof UIViewController *)ZIKViewRouter_hook_instantiateInitialViewController
#else
- (nullable __kindof NSViewController *)ZIKViewRouter_hook_instantiateInitialViewController
#endif
{
    id initialViewController = [self ZIKViewRouter_hook_instantiateInitialViewController];
    XXViewController *parentViewController = initialViewController;
    NSMutableArray<XXViewController *> *routableViews;
#if !ZIK_HAS_UIKIT
    if ([parentViewController isKindOfClass:[NSWindowController class]]) {
        parentViewController = [(NSWindowController *)parentViewController contentViewController];
    }
#endif
    if ([parentViewController conformsToProtocol:@protocol(ZIKRoutableView)]) {
        routableViews = [NSMutableArray arrayWithObject:parentViewController];
    }
    NSArray<XXViewController *> *childViews = [ZIKViewRouter routableViewsInParentViewController:parentViewController];
    if (childViews.count > 0) {
        if (routableViews == nil) {
            routableViews = [NSMutableArray array];
        }
        [routableViews addObjectsFromArray:childViews];
    }
    for (XXViewController *destination in routableViews) {
        ZIKViewRouterType *routerType = _routerTypeToRegisteredView([destination class]);
        if (routerType) {
            if (destination != parentViewController && ![routerType shouldAutoCreateForDestination:destination fromSource:parentViewController]) {
                continue;
            }
            [routerType prepareDestination:destination configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                
            }];
        }
    }
    return initialViewController;
}

#if ZIK_HAS_UIKIT
- (void)ZIKViewRouter_hook_prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
#else
- (void)ZIKViewRouter_hook_prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender
#endif
{
    /**
     We hooked every UIViewController and subclasses in +load, because a vc may override -prepareForSegue:sender: and not call [super prepareForSegue:sender:].
     If subclass vc call [super prepareForSegue:sender:] in its -prepareForSegue:sender:, because its superclass's -prepareForSegue:sender: was alse hooked, we will enter -ZIKViewRouter_hook_prepareForSegue:sender: for superclass. But we can't invoke superclass's original implementation by [self ZIKViewRouter_hook_prepareForSegue:sender:], it will call current class's original implementation, then there is an endless loop.
     To sovle this, we use a 'currentClassCalling' variable to mark the next class which calling -prepareForSegue:sender:, if -prepareForSegue:sender: was called again in a same call stack, fetch the original implementation in 'currentClassCalling', and just call original implementation, don't enter -ZIKViewRouter_hook_prepareForSegue:sender: again.
     
     Something else: this solution relies on correct use of [super prepareForSegue:sender:]. Every time -prepareForSegue:sender: was invoked, the 'currentClassCalling' will be updated as 'currentClassCalling = [currentClassCalling superclass]'.So these codes will lead to bug:
     1.
     - (void)prepareForSegue:(XXStoryboardSegue *)segue sender:(id)sender {
         [super prepareForSegue:segue sender:sender];
         [super prepareForSegue:segue sender:sender];
     }
     2.
     - (void)prepareForSegue:(XXStoryboardSegue *)segue sender:(id)sender {
         dispatch_async(dispatch_get_main_queue(), ^{
             [super prepareForSegue:segue sender:sender];
         });
     }
     These bad implementations should never exist in your code, so we ignore these situations.
     */
    Class currentClassCalling = [(XXViewController *)self zix_currentClassCallingPrepareForSegue];
    if (!currentClassCalling) {
        currentClassCalling = [self class];
    }
    [(XXViewController *)self setZix_currentClassCallingPrepareForSegue:[currentClassCalling superclass]];
    
    if (currentClassCalling != [self class]) {
        //Call [super prepareForSegue:segue sender:sender]
        Method superMethod = class_getInstanceMethod(currentClassCalling, @selector(ZIKViewRouter_hook_prepareForSegue:sender:));
        IMP superImp = method_getImplementation(superMethod);
        NSAssert(superMethod && superImp, @"ZIKViewRouter_hook_prepareForSegue:sender: should exist in super");
        if (superImp) {
            ((void(*)(id, SEL, XXStoryboardSegue *, id))superImp)(self, @selector(prepareForSegue:sender:), segue, sender);
        }
        return;
    }
#if ZIK_HAS_UIKIT
    XXViewController *source = segue.sourceViewController;
    XXViewController *destination = segue.destinationViewController;
    
    BOOL isUnwindSegue = YES;
    if (![destination isViewLoaded] ||
        (!destination.parentViewController &&
         !destination.presentingViewController)) {
            isUnwindSegue = NO;
        }
#else
    BOOL isUnwindSegue = NO;
    id source = segue.sourceController;
    id destination = segue.destinationController;
#endif
    
    //The router performing route for this view controller
    ZIKViewRouter *sourceRouter = [(XXViewController *)self zix_sourceViewRouter];
    if (sourceRouter) {
        //This segue is performed from router, see -_performSegueWithIdentifier:fromSource:sender:
        ZIKViewRouteSegueConfiguration *configuration = [(ZIKViewRouteConfiguration *)sourceRouter.original_configuration segueConfiguration];
        if (!configuration.segueSource) {
            NSAssert([segue.identifier isEqualToString:configuration.identifier], @"should be same identifier");
            [sourceRouter attachDestination:destination];
            configuration.segueSource = source;
            configuration.segueDestination = destination;
#if ZIK_HAS_UIKIT
            configuration.destinationStateBeforeRoute = [destination zix_presentationState];
            if (isUnwindSegue) {
                sourceRouter.realRouteType = ZIKViewRouteRealTypeUnwind;
            }
#endif
        }
        
        [(XXViewController *)self setZix_sourceViewRouter:nil];
        [source setZix_sourceViewRouter:sourceRouter];//Set nil in -ZIKViewRouter_hook_seguePerform
    }
    
    //The sourceRouter and routers for child view controllers conform to ZIKRoutableView in destination
    NSMutableArray<ZIKViewRouter *> *destinationRouters;
    NSMutableArray<XXViewController *> *routableViews;
    
    if (!isUnwindSegue) {
        destinationRouters = [NSMutableArray array];
        XXViewController *parentViewController = destination;
#if !ZIK_HAS_UIKIT
        //NSWindowController is not supported by ZIKViewRouter
        if ([parentViewController isKindOfClass:[NSWindowController class]]) {
            parentViewController = [(NSWindowController *)parentViewController contentViewController];
        }
#endif
        if ([parentViewController conformsToProtocol:@protocol(ZIKRoutableView)]) {//if destination is ZIKRoutableView, create router for it
            if (sourceRouter && [(ZIKViewRouteConfiguration *)sourceRouter.original_configuration segueConfiguration].segueDestination == parentViewController) {
                [destinationRouters addObject:sourceRouter];//If this segue is performed from router, don't auto create router again
            } else {
                routableViews = [NSMutableArray array];
                [routableViews addObject:parentViewController];
            }
        }

        NSArray<XXViewController *> *subRoutableViews = [ZIKViewRouter routableViewsInParentViewController:parentViewController];//Search child view controllers conform to ZIKRoutableView in destination
        if (subRoutableViews.count > 0) {
            if (!routableViews) {
                routableViews = [NSMutableArray array];
            }
            [routableViews addObjectsFromArray:subRoutableViews];
        }
        
        //Generate router for each routable view
        if (routableViews.count > 0) {
            for (XXViewController *routableView in routableViews) {
                ZIKViewRouterType *routerType = _routerTypeToRegisteredView([routableView class]);
                if (routerType == nil) {
                    continue;
                }
                ZIKViewRouter *destinationRouter = [routerType routerFromSegueIdentifier:segue.identifier sender:sender destination:routableView source:(XXViewController *)self];
                destinationRouter.routingFromInternal = YES;
#if ZIK_HAS_UIKIT
                ZIKViewRouteSegueConfiguration *segueConfig = [(ZIKViewRouteConfiguration *)destinationRouter.original_configuration segueConfiguration];
                NSAssert(destinationRouter && segueConfig, @"Failed to create router.");

                segueConfig.destinationStateBeforeRoute = [routableView zix_presentationState];
#endif
                if (destinationRouter) {
                    [destinationRouters addObject:destinationRouter];
                }
            }
        }
        if (destinationRouters.count > 0) {
            [destination setZix_destinationViewRouters:destinationRouters];//Get and set nil in -ZIKViewRouter_hook_seguePerform
        }
    }
    
    //Call original implementation of current class
    [self ZIKViewRouter_hook_prepareForSegue:segue sender:sender];
    [(XXViewController *)self setZix_currentClassCallingPrepareForSegue:nil];
    
    //Prepare for unwind destination or unroutable views
    if (sourceRouter && [(ZIKViewRouteConfiguration *)sourceRouter.original_configuration segueConfiguration].segueDestination == destination) {
        void(^prepareDestinationInSourceRouter)(id destination);
        if (sourceRouter) {
            prepareDestinationInSourceRouter = [(ZIKViewRouteConfiguration *)sourceRouter.original_configuration prepareDestination];
        }
        if (isUnwindSegue) {
            if (prepareDestinationInSourceRouter) {
                prepareDestinationInSourceRouter(destination);
            }
            return;
        }
        if (![destination conformsToProtocol:@protocol(ZIKRoutableView)]) {
            if (prepareDestinationInSourceRouter) {
                prepareDestinationInSourceRouter(destination);
            }
        }
    }
    //Prepare routable views
    for (NSInteger idx = 0; idx < destinationRouters.count; idx++) {
        ZIKViewRouter *router = [destinationRouters objectAtIndex:idx];
        XXViewController * routableView = router.destination;
        NSAssert(routableView, @"Destination wasn't set when create destinationRouters");
        [routableView setZix_routeTypeFromRouter:@(ZIKViewRouteTypePerformSegue)];
        if (router != sourceRouter) {
            [router notifyRouteState:ZIKRouterStateRouting];
        }
        if (sourceRouter) {
            //Segue is performed from a router
            [router prepareDestinationForPerforming];
        } else {
            //View controller is from storyboard, need to notify the performer of segue to config the destination
            [ZIKViewRouter _prepareDestinationFromExternal:routableView router:router performer:(XXViewController *)self];
        }
        [ZIKViewRouter AOP_notifyAll_router:router willPerformRouteOnDestination:routableView fromSource:source];
    }
}

- (void)ZIKViewRouter_hook_seguePerform {
    Class currentClassCalling = [(XXStoryboardSegue *)self zix_currentClassCallingPerform];
    if (!currentClassCalling) {
        currentClassCalling = [self class];
    }
    [(XXStoryboardSegue *)self setZix_currentClassCallingPerform:[currentClassCalling superclass]];
    
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
    
#if ZIK_HAS_UIKIT
    XXViewController *destination = [(XXStoryboardSegue *)self destinationViewController];
    XXViewController *source = [(XXStoryboardSegue *)self sourceViewController];
#else
    id source = [(XXStoryboardSegue *)self sourceController];
    id destination = [(XXStoryboardSegue *)self destinationController];
#endif
    
    ZIKViewRouter *sourceRouter = [source zix_sourceViewRouter];//Was set in -ZIKViewRouter_hook_prepareForSegue:sender:
    NSArray<ZIKViewRouter *> *destinationRouters = [destination zix_destinationViewRouters];
    
    //Call original implementation of current class
    [self ZIKViewRouter_hook_seguePerform];
    [(XXStoryboardSegue *)self setZix_currentClassCallingPerform:nil];
    
    if (destinationRouters.count > 0) {
        [destination setZix_destinationViewRouters:nil];
    }
    if (sourceRouter) {
        [source setZix_sourceViewRouter:nil];
    }
    
#if ZIK_HAS_UIKIT
    id <UIViewControllerTransitionCoordinator> transitionCoordinator = [source zix_currentTransitionCoordinator];
    if (!transitionCoordinator) {
        transitionCoordinator = [destination zix_currentTransitionCoordinator];
    }
    if (sourceRouter) {
        //Complete unwind route. Unwind route doesn't need to config destination
        if (sourceRouter.realRouteType == ZIKViewRouteRealTypeUnwind &&
            [(ZIKViewRouteConfiguration *)sourceRouter.original_configuration segueConfiguration].segueDestination == destination) {
            [ZIKViewRouter _completeWithtransitionCoordinator:transitionCoordinator transitionCompletion:^{
                [sourceRouter endPerformRouteWithSuccessWithAOP:NO];
            }];
            return;
        }
    }
#endif
    
    //Complete routable views
    for (NSInteger idx = 0; idx < destinationRouters.count; idx++) {
        ZIKViewRouter *router = [destinationRouters objectAtIndex:idx];
        XXViewController *routableView = router.destination;
        void(^transitionCompletion)(void) = ^{
            NSAssert(router.state == ZIKRouterStateRouting, @"state should be routing when end route");
            if (sourceRouter) {
                if (routableView == sourceRouter.destination) {
                    NSAssert(idx == 0, @"If destination is in destinationRouters, it should be at index 0.");
                    NSAssert(router == sourceRouter, nil);
                }
            }
            [router endPerformRouteWithSuccess];
        };
#if ZIK_HAS_UIKIT
        ZIKPresentationState *destinationStateBeforeRoute = [(ZIKViewRouteConfiguration *)router.original_configuration segueConfiguration].destinationStateBeforeRoute;
        NSAssert(destinationStateBeforeRoute, @"Didn't set state in -ZIKViewRouter_hook_prepareForSegue:sender:");
        [ZIKViewRouter _completeRouter:router
        analyzeRouteTypeForDestination:routableView
                                source:source
           destinationStateBeforeRoute:destinationStateBeforeRoute
                 transitionCoordinator:transitionCoordinator
                            completion:transitionCompletion];
#else
        [ZIKViewRouter _completeWithMacTransitionCompletion:transitionCompletion];
#endif
    }
    //Complete unroutable view
    if (sourceRouter && [(ZIKViewRouteConfiguration *)sourceRouter.original_configuration segueConfiguration].segueDestination == destination && ![destination conformsToProtocol:@protocol(ZIKRoutableView)]) {
        void(^transitionCompletion)(void) = ^{
            [sourceRouter endPerformRouteWithSuccessWithAOP:NO];
        };
#if ZIK_HAS_UIKIT
        ZIKPresentationState *destinationStateBeforeRoute = [(ZIKViewRouteConfiguration *)sourceRouter.original_configuration segueConfiguration].destinationStateBeforeRoute;
        NSAssert(destinationStateBeforeRoute, @"Didn't set state in -ZIKViewRouter_hook_prepareForSegue:sender:");
        [ZIKViewRouter _completeRouter:sourceRouter
        analyzeRouteTypeForDestination:destination
                                source:source
           destinationStateBeforeRoute:destinationStateBeforeRoute
                 transitionCoordinator:transitionCoordinator
                            completion:transitionCompletion];
#else
        [ZIKViewRouter _completeWithMacTransitionCompletion:transitionCompletion];
#endif
    }
}

/// Search child view controllers conforming to ZIKRoutableView in vc
+ (nullable NSArray<XXViewController *> *)routableViewsInParentViewController:(XXViewController *)vc {
    NSMutableArray *routableViews;
    NSArray<__kindof XXViewController *> *childViewControllers = vc.childViewControllers;
    if (childViewControllers.count == 0) {
        return routableViews;
    }
    
    BOOL isContainerVC = NO;
    BOOL isSystemViewController = NO;
    NSArray<XXViewController *> *containedVCs;
#if ZIK_HAS_UIKIT
    if ([vc isKindOfClass:[UINavigationController class]]) {
        isContainerVC = YES;
        if ([(UINavigationController *)vc viewControllers].count > 0) {
            XXViewController *rootViewController = [[(UINavigationController *)vc viewControllers] firstObject];
            if (rootViewController) {
                containedVCs = @[rootViewController];
            } else {
                containedVCs = @[];
            }
        }
    } else
#endif
    if ([vc isKindOfClass:[XXTabBarController class]]) {
        isContainerVC = YES;
#if ZIK_HAS_UIKIT
        containedVCs = [(XXTabBarController *)vc viewControllers];
#else
        NSMutableArray<XXViewController *> *VCs = [NSMutableArray array];
        for (NSTabViewItem *item in [(XXTabBarController *)vc tabViewItems]) {
            if (item.viewController) {
                [VCs addObject:item.viewController];
            }
        }
        containedVCs = VCs;
#endif
    } else if ([vc isKindOfClass:[XXSplitViewController class]]) {
        isContainerVC = YES;
#if ZIK_HAS_UIKIT
        containedVCs = [(XXSplitViewController *)vc viewControllers];
#else
        NSMutableArray<XXViewController *> *VCs = [NSMutableArray array];
        for (NSSplitViewItem *item in [(XXSplitViewController *)vc splitViewItems]) {
            if (item.viewController) {
                [VCs addObject:item.viewController];
            }
        }
        containedVCs = VCs;
#endif
    } else if ([vc isKindOfClass:[XXPageViewController class]]) {
        isContainerVC = YES;
#if ZIK_HAS_UIKIT
        containedVCs = [(XXPageViewController *)vc viewControllers];
#else
        NSViewController *selectedViewController = [(XXPageViewController *)vc selectedViewController];
        if (selectedViewController) {
            containedVCs = @[selectedViewController];
        }
#endif
    }
    
    if (zix_classIsCustomClass([vc class]) == NO) {
        isSystemViewController = YES;
    }
    // Find in container's childs
    if (isContainerVC) {
        if (!routableViews) {
            routableViews = [NSMutableArray array];
        }
        for (XXViewController *child in containedVCs) {
            if ([child conformsToProtocol:@protocol(ZIKRoutableView)]) {
                [routableViews addObject:child];
            }
            NSArray<XXViewController *> *routableViewsInChild = [self routableViewsInParentViewController:child];
            if (routableViewsInChild.count > 0) {
                [routableViews addObjectsFromArray:routableViewsInChild];
            }
        }
    }
    // Find in childViewControllers
    if (isSystemViewController) {
        if (!routableViews) {
            routableViews = [NSMutableArray array];
        }
        for (XXViewController *child in vc.childViewControllers) {
            if (containedVCs && [containedVCs containsObject:child]) {
                continue;
            }
            if ([child conformsToProtocol:@protocol(ZIKRoutableView)]) {
                [routableViews addObject:child];
            }
            NSArray<XXViewController *> *routableViewsInChild = [self routableViewsInParentViewController:child];
            if (routableViewsInChild.count > 0) {
                [routableViews addObjectsFromArray:routableViewsInChild];
            }
        }
    }
    return routableViews;
}

#pragma mark Validate

+ (BOOL)validateCustomRouteConfiguration:(ZIKViewRouteConfiguration *)configuration removeConfiguration:(ZIKViewRemoveConfiguration *)removeConfiguration {
    return YES;
}

+ (BOOL)_validateRouteTypeInConfiguration:(ZIKViewRouteConfiguration *)configuration {
    if (![self supportRouteType:configuration.routeType]) {
        return NO;
    }
    return YES;
}

+ (BOOL)_validateRouteSourceNotMissedInConfiguration:(ZIKViewRouteConfiguration *)configuration {
    if (!configuration.source &&
        (
#if !ZIK_HAS_UIKIT
         configuration.routeType != ZIKViewRouteTypeShow &&
#endif
         configuration.routeType != ZIKViewRouteTypeCustom &&
         configuration.routeType != ZIKViewRouteTypeMakeDestination)) {
        return NO;
    }
    return YES;
}

+ (BOOL)_validateRouteSourceClassInConfiguration:(ZIKViewRouteConfiguration *)configuration {
    if (!configuration.source &&
        (
#if !ZIK_HAS_UIKIT
         configuration.routeType != ZIKViewRouteTypeShow &&
#endif
         configuration.routeType != ZIKViewRouteTypeCustom &&
         configuration.routeType != ZIKViewRouteTypeMakeDestination)) {
        return NO;
    }
    id source = configuration.source;
    switch (configuration.routeType) {
        case ZIKViewRouteTypeAddAsSubview:
            if (![source isKindOfClass:[XXView class]]) {
                return NO;
            }
            break;
            
        case ZIKViewRouteTypePerformSegue:
            break;
            
#if !ZIK_HAS_UIKIT
        case ZIKViewRouteTypeShow:
#endif
        case ZIKViewRouteTypeCustom:
        case ZIKViewRouteTypeMakeDestination:
            break;
        default:
            if (![source isKindOfClass:[XXViewController class]]) {
                return NO;
            }
            break;
    }
    return YES;
}

- (void)_validateDestinationConformance:(id)destination {
#if ZIKROUTER_CHECK
    Protocol *destinationProtocol;
    BOOL result = [ZIKViewRouteRegistry validateDestinationConformance:[destination class] forRouter:self protocol:&destinationProtocol];
    NSAssert(result,@"Bad implementation in router (%@)'s -destinationWithConfiguration:, or you use an invalid destination for -performOnDestination:. The destination (%@) doesn't conforms to registered view protocol (%@).",self, destination, NSStringFromProtocol(destinationProtocol));
#endif
}

+ (BOOL)_validateSegueInConfiguration:(ZIKViewRouteConfiguration *)configuration {
    if (!configuration.segueConfiguration.identifier && !configuration.autoCreated) {
        return NO;
    }
    return YES;
}

+ (BOOL)_validatePopoverInConfiguration:(ZIKViewRouteConfiguration *)configuration {
    ZIKViewRoutePopoverConfiguration *popoverConfig = configuration.popoverConfiguration;
    if (!popoverConfig ||
        (
#if ZIK_HAS_UIKIT
         !popoverConfig.barButtonItem &&
#endif
         !popoverConfig.sourceView
         )) {
        return NO;
    }
    return YES;
}

+ (BOOL)_validateDestinationShouldExistInConfiguration:(ZIKViewRouteConfiguration *)configuration {
    if (configuration.routeType == ZIKViewRouteTypePerformSegue) {
        return NO;
    }
    return YES;
}

+ (BOOL)_validateDestinationClass:(nullable id)destination inConfiguration:(ZIKViewRouteConfiguration *)configuration {
    NSAssert(!destination || [destination conformsToProtocol:@protocol(ZIKRoutableView)], @"Destination must conforms to ZIKRoutableView. It's used to config view not created from router.");
    
    switch (configuration.routeType) {
        case ZIKViewRouteTypeAddAsSubview:
            if ([destination isKindOfClass:[XXView class]]) {
                NSAssert([[self class] _validateSupportedRouteTypesForXXView], @"%@ 's +supportedRouteTypes returns error types, if destination is an UIView, %@ should support ZIKViewRouteTypeAddAsSubview or ZIKViewRouteTypeCustom",[self class], [self class]);
                return YES;
            }
            break;
        case ZIKViewRouteTypeCustom:
            if ([destination isKindOfClass:[XXView class]]) {
                NSAssert([[self class] _validateSupportedRouteTypesForXXView], @"%@ 's +supportedRouteTypes returns error types, if destination is an UIView, %@ should support ZIKViewRouteTypeAddAsSubview or ZIKViewRouteTypeCustom, if use ZIKViewRouteTypeCustom, router must implement -performCustomRouteOnDestination:fromSource:configuration:.",[self class], [self class]);
                return YES;
            } else if ([destination isKindOfClass:[XXViewController class]]) {
                NSAssert([[self class] _validateSupportedRouteTypesForXXViewController], @"%@ 's +supportedRouteTypes returns error types, if destination is an UIViewController, %@ can't only support ZIKViewRouteTypeAddAsSubview, if use ZIKViewRouteTypeCustom, router must implement -performCustomRouteOnDestination:fromSource:configuration:.",[self class], [self class]);
                return YES;
            }
            break;
            
        case ZIKViewRouteTypePerformSegue:
            NSAssert(!destination, @"ZIKViewRouteTypePerformSegue's destination should be created by UIKit automatically");
            return YES;
            break;
        
        case ZIKViewRouteTypeMakeDestination:
            if ([destination isKindOfClass:[XXViewController class]] || [destination isKindOfClass:[XXView class]]) {
                return YES;
            }
            break;
            
        default:
            if ([destination isKindOfClass:[XXViewController class]]) {
                NSAssert([[self class] _validateSupportedRouteTypesForXXViewController], @"%@ 's +supportedRouteTypes returns error types, if destination is an UIViewController, %@ can't only support ZIKViewRouteTypeAddAsSubview",[self class], [self class]);
                return YES;
            }
            break;
    }
    return NO;
}

#if ZIK_HAS_UIKIT
+ (BOOL)_validateSourceInNavigationStack:(XXViewController *)source {
    BOOL canPerformPush = [source respondsToSelector:@selector(navigationController)];
    if (!canPerformPush ||
        (canPerformPush && !source.navigationController)) {
        return NO;
    }
    return YES;
}

+ (BOOL)_validateDestination:(XXViewController *)destination notInNavigationStackOfSource:(XXViewController *)source {
    NSArray<XXViewController *> *viewControllersInStack = source.navigationController.viewControllers;
    if ([viewControllersInStack containsObject:destination]) {
        return NO;
    }
    return YES;
}


+ (BOOL)_validateSourceNotPresentedAnyView:(XXViewController *)source {
    if (source.presentedViewController) {
        return NO;
    }
    return YES;
}
#endif

+ (BOOL)_validateSourceInWindowHierarchy:(XXViewController *)source {
    if (source.parentViewController) {
        if ([self _validateSourceInWindowHierarchy:source.parentViewController]) {
            return YES;
        }
    }
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

+ (BOOL)_validateSupportedRouteTypesForXXView {
    ZIKViewRouteTypeMask supportedRouteTypes = [self supportedRouteTypes];
    if ((supportedRouteTypes & ZIKViewRouteTypeMaskCustom) == ZIKViewRouteTypeMaskCustom) {
        if (![self instancesRespondToSelector:@selector(performCustomRouteOnDestination:fromSource:configuration:)]) {
            return NO;
        }
    }
    if ([self supportRouteType:ZIKViewRouteTypeAddAsSubview] == NO &&
        [self supportRouteType:ZIKViewRouteTypeMakeDestination] == NO &&
        [self supportRouteType:ZIKViewRouteTypeCustom] == NO) {
        return NO;
    }
    return YES;
}

+ (BOOL)_validateSupportedRouteTypesForXXViewController {
    ZIKViewRouteTypeMask supportedRouteTypes = [self supportedRouteTypes];
    if ((supportedRouteTypes & ZIKViewRouteTypeMaskCustom) == ZIKViewRouteTypeMaskCustom) {
        if (![self instancesRespondToSelector:@selector(performCustomRouteOnDestination:fromSource:configuration:)]) {
            return NO;
        }
    }
    if (supportedRouteTypes == ZIKViewRouteTypeMaskAddAsSubview) {
        return NO;
    }
    return YES;
}

#pragma mark Error Handle

+ (NSString *)errorDomain {
    return ZIKViewRouteErrorDomain;
}

+ (NSError *)viewRouteErrorWithCode:(ZIKViewRouteError)code localizedDescription:(NSString *)description {
    if (description == nil) {
        description = @"";
    }
    return [NSError errorWithDomain:ZIKViewRouteErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey:description}];
}

+ (NSError *)viewRouteErrorWithCode:(ZIKViewRouteError)code localizedDescriptionFormat:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    return [self viewRouteErrorWithCode:code localizedDescription:description];
}

+ (void)setGlobalErrorHandler:(ZIKViewRouteGlobalErrorHandler)globalErrorHandler {
    dispatch_semaphore_wait(g_globalErrorSema, DISPATCH_TIME_FOREVER);
    g_globalErrorHandler = globalErrorHandler;
    dispatch_semaphore_signal(g_globalErrorSema);
}

+ (ZIKViewRouteGlobalErrorHandler)globalErrorHandler {
    return g_globalErrorHandler;
}

+ (void)notifyGlobalErrorWithRouter:(nullable __kindof ZIKViewRouter *)router action:(ZIKRouteAction)action error:(NSError *)error {
    void(^errorHandler)(__kindof ZIKViewRouter *_Nullable router, ZIKRouteAction action, NSError *error) = self.globalErrorHandler;
    if (errorHandler) {
        errorHandler(router, action, error);
    } else {
#ifdef DEBUG
        NSLog(@"❌ZIKViewRouter Error: router's action (%@) catch error: (%@),\nrouter:(%@)", action, error,router);
#endif
    }
}

//Call your errorHandler and globalErrorHandler, use this if you don't want to affect the routing
- (void)notifyError_errorCode:(ZIKViewRouteError)code
                 errorHandler:(void(^)(ZIKRouteAction routeAction, NSError *error))errorHandler
                       action:(ZIKRouteAction)action
             errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    NSError *error = [ZIKViewRouter errorWithCode:code localizedDescription:description];
    if (errorHandler) {
        errorHandler(action,error);
    }
    [[self class] notifyGlobalErrorWithRouter:self action:action error:error];
}

+ (void)notifyError_invalidPerformerWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self notifyGlobalErrorWithRouter:nil action:action error:[ZIKViewRouter errorWithCode:ZIKViewRouteErrorInvalidPerformer localizedDescription:description]];
}

- (void)notifyError_unsupportTypeWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self notifyError:[ZIKViewRouter errorWithCode:ZIKViewRouteErrorUnsupportType localizedDescriptionFormat:description] routeAction:action];
}

- (void)notifyError_unbalancedTransitionWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [[self class] notifyGlobalErrorWithRouter:self action:action error:[ZIKViewRouter errorWithCode:ZIKViewRouteErrorUnbalancedTransition localizedDescription:description]];
}

- (void)notifyError_invalidSourceWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self notifyError:[ZIKViewRouter errorWithCode:ZIKViewRouteErrorInvalidSource localizedDescriptionFormat:description] routeAction:action];
}

- (void)notifyError_invalidContainerWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self notifyError:[ZIKViewRouter errorWithCode:ZIKViewRouteErrorInvalidContainer localizedDescriptionFormat:description] routeAction:action];
}

- (void)notifyError_segueNotPerformedWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self notifyError:[ZIKViewRouter errorWithCode:ZIKViewRouteErrorSegueNotPerformed localizedDescriptionFormat:description] routeAction:action];
}

#pragma mark Getter/Setter

- (BOOL)autoCreated {
    return self.original_configuration.autoCreated;
}

#pragma mark Debug

+ (NSString *)descriptionOfRouteType:(ZIKViewRouteType)routeType {
    NSString *description;
    switch (routeType) {
#if ZIK_HAS_UIKIT
        case ZIKViewRouteTypePush:
            description = @"Push";
            break;
#endif
        case ZIKViewRouteTypePresentModally:
            description = @"PresentModally";
            break;
        case ZIKViewRouteTypePresentAsPopover:
            description = @"PresentAsPopover";
            break;
#if !ZIK_HAS_UIKIT
        case ZIKViewRouteTypePresentAsSheet:
            description = @"PresentAsSheet";
            break;
        case ZIKViewRouteTypePresentWithAnimator:
            description = @"PresentWithAnimator";
            break;
#endif
        case ZIKViewRouteTypePerformSegue:
            description = @"PerformSegue";
            break;
        case ZIKViewRouteTypeShow:
            description = @"Show";
            break;
#if ZIK_HAS_UIKIT
        case ZIKViewRouteTypeShowDetail:
            description = @"ShowDetail";
            break;
#endif
        case ZIKViewRouteTypeAddAsChildViewController:
            description = @"AddAsChildViewController";
            break;
        case ZIKViewRouteTypeAddAsSubview:
            description = @"AddAsSubview";
            break;
        case ZIKViewRouteTypeCustom:
            description = @"Custom";
            break;
        case ZIKViewRouteTypeMakeDestination:
            description = @"MakeDestination";
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
#if ZIK_HAS_UIKIT
        case ZIKViewRouteRealTypePush:
            description = @"Push";
            break;
#endif
        case ZIKViewRouteRealTypePresentModally:
            description = @"PresentModally";
            break;
        case ZIKViewRouteRealTypePresentAsPopover:
            description = @"PresentAsPopover";
            break;
#if !ZIK_HAS_UIKIT
        case ZIKViewRouteRealTypePresentAsSheet:
            description = @"PresentAsSheet";
            break;
        case ZIKViewRouteRealTypePresentWithAnimator:
            description = @"PresentWithAnimator";
            break;
        case ZIKViewRouteRealTypeShowWindow:
            description = @"ShowWindow";
            break;
#endif
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
    return [NSString stringWithFormat:@"%@,\nrealRouteType:%@,\nautoCreated:%d",[super description],[[self class] descriptionOfRealRouteType:self.realRouteType],self.autoCreated];
}

@end

@implementation ZIKViewRouter (Perform)

- (BOOL)canPerform {
    return [self _canPerformWithErrorMessage:NULL];
}

+ (BOOL)supportRouteType:(ZIKViewRouteType)type {
    ZIKViewRouteTypeMask supportedRouteTypes = [self supportedRouteTypes];
    ZIKViewRouteTypeMask mask = 1 << type;
    if ((supportedRouteTypes & mask) == mask) {
        return YES;
    }
    return NO;
}

+ (nullable instancetype)performPath:(ZIKViewRoutePath *)path configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder {
    return [self performPath:path configuring:configBuilder removing:nil];
}

+ (nullable instancetype)performPath:(ZIKViewRoutePath *)path {
    return [self performPath:path configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
        
    } removing:nil];
}

+ (nullable instancetype)performPath:(ZIKViewRoutePath *)path
                      successHandler:(void(^ _Nullable)(id destination))performerSuccessHandler
                        errorHandler:(void(^ _Nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler {
    return [self performPath:path configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
        if (performerSuccessHandler) {
            void(^successHandler)(id) = config.performerSuccessHandler;
            if (successHandler) {
                successHandler = ^(id destination) {
                    successHandler(destination);
                    performerSuccessHandler(destination);
                };
            } else {
                successHandler = performerSuccessHandler;
            }
            config.performerSuccessHandler = successHandler;
        }
        if (performerErrorHandler) {
            void(^errorHandler)(ZIKRouteAction, NSError *) = config.performerErrorHandler;
            if (errorHandler) {
                errorHandler = ^(ZIKRouteAction routeAction, NSError *error) {
                    errorHandler(routeAction, error);
                    performerErrorHandler(routeAction, error);
                };
            } else {
                errorHandler = performerErrorHandler;
            }
            config.performerErrorHandler = errorHandler;
        }
    }];
}

+ (nullable instancetype)performPath:(ZIKViewRoutePath *)path completion:(ZIKPerformRouteCompletion)performerCompletion {
    return [self performPath:path successHandler:^(id destination) {
        if (performerCompletion) {
            performerCompletion(YES, destination, ZIKRouteActionPerformRoute, nil);
        }
    } errorHandler:^(ZIKRouteAction routeAction, NSError *error) {
        if (performerCompletion) {
            performerCompletion(NO, nil, routeAction, error);
        }
    }];
}

+ (nullable instancetype)performPath:(ZIKViewRoutePath *)path preparation:(void(^)(id destination))prepare {
    return [self performPath:path configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
        config.prepareDestination = prepare;
    }];
}

+ (nullable instancetype)performPath:(ZIKViewRoutePath *)path
                         configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder
                            removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder {
    return [super performWithConfiguring:^(ZIKViewRouteConfiguration * _Nonnull config) {
        if (configBuilder) {
            configBuilder(config);
        }
        if (config.injected) {
            config = (ZIKViewRouteConfiguration *)config.injected;
        }
        [config configurePath:path];
    } removing:removeConfigBuilder];
}

+ (nullable instancetype)performPath:(ZIKViewRoutePath *)path
                   strictConfiguring:(void (NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<id> * _Nonnull, ZIKViewRouteConfiguration * _Nonnull))configBuilder {
    return [self performPath:path strictConfiguring:configBuilder strictRemoving:nil];
}

+ (nullable instancetype)performPath:(ZIKViewRoutePath *)path
                   strictConfiguring:(void (NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<id> * _Nonnull, ZIKViewRouteConfiguration * _Nonnull))configBuilder
                      strictRemoving:(void (NS_NOESCAPE ^)(ZIKViewRemoveStrictConfiguration<id> * _Nonnull))removeConfigBuilder {
    return [super performWithStrictConfiguring:(void(^)(ZIKPerformRouteStrictConfiguration<id> *, ZIKViewRouteConfiguration *))^(ZIKViewRouteStrictConfiguration<id> *strictConfig, ZIKViewRouteConfiguration *config) {
        if (configBuilder) {
            configBuilder(strictConfig, config);
        }
        if (config.injected) {
            config = (ZIKViewRouteConfiguration *)config.injected;
        }
        [config configurePath:path];
    } strictRemoving:(void(^)(ZIKRemoveRouteStrictConfiguration<id> *))removeConfigBuilder];
    
}

@end

@implementation ZIKViewRouter (PerformOnDestination)

+ (nullable instancetype)performOnDestination:(id)destination
                                         path:(ZIKViewRoutePath *)path
                                  configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder {
    return [self performOnDestination:destination path:path configuring:configBuilder removing:nil];
}

+ (nullable instancetype)performOnDestination:(id)destination
                                         path:(ZIKViewRoutePath *)path
                                  configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder
                                     removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder {
    void(^notifyError)(NSError *) = ^(NSError *error) {
        ZIKViewRouteConfiguration *configuration = [self defaultRouteConfiguration];
        configuration.routeType = ZIKViewRouteTypeMakeDestination;
        if (configBuilder) {
            configBuilder(configuration);
        }
        if (configuration.injected) {
            configuration = (ZIKViewRouteConfiguration *)configuration.injected;
        }
        configuration.routeType = ZIKViewRouteTypeMakeDestination;
        if (configuration.errorHandler) {
            configuration.errorHandler(ZIKRouteActionPerformOnDestination, error);
        }
        if (configuration.performerErrorHandler) {
            configuration.performerErrorHandler(ZIKRouteActionPerformOnDestination, error);
        }
        if (configuration.completionHandler) {
            configuration.completionHandler(NO, nil, ZIKRouteActionPerformOnDestination, error);
        }
    };
    if (![destination conformsToProtocol:@protocol(ZIKRoutableView)]) {
        NSError *error = [[self class] errorWithCode:ZIKRouteErrorInvalidConfiguration localizedDescription:[NSString stringWithFormat:@"Perform route on invalid destination: (%@)",destination]];
        [[self class] notifyGlobalErrorWithRouter:nil action:ZIKRouteActionPerformOnDestination error:error];
        notifyError(error);
        return nil;
    }
    if ([self isAbstractRouter] == NO && ![ZIKViewRouteRegistry isDestinationClass:[destination class] registeredWithRouter:self]) {
        NSError *error = [[self class] errorWithCode:ZIKRouteErrorInvalidConfiguration localizedDescription:[NSString stringWithFormat:@"Perform route on invalid destination (%@), this view is not registered with this router (%@)",destination,self]];
        [[self class] notifyGlobalErrorWithRouter:nil action:ZIKRouteActionPerformOnDestination error:error];
        notifyError(error);
        return nil;
    }
    ZIKViewRouter *router = [[self alloc] initWithConfiguring:^(ZIKPerformRouteConfiguration *config) {
        ZIKViewRouteConfiguration *configuration = (ZIKViewRouteConfiguration *)config;
        if (configBuilder) {
            configBuilder(configuration);
        }
        if (configuration.injected) {
            configuration = (ZIKViewRouteConfiguration *)configuration.injected;
        }
        [configuration configurePath:path];
    } removing:(void(^)(ZIKRemoveRouteConfiguration *))removeConfigBuilder];
    NSAssert([(ZIKViewRouteConfiguration *)router.original_configuration routeType] != ZIKViewRouteTypeMakeDestination, @"It's meaningless to get destination when you already offer a prepared destination.");
    [router notifyRouteState:ZIKRouterStateRouting];
    [router attachDestination:destination];
    [router performRouteOnDestination:destination configuration:router.original_configuration];
    return router;
}

+ (nullable instancetype)performOnDestination:(id)destination
                                         path:(ZIKViewRoutePath *)path {
    return [self performOnDestination:destination path:path configuring:^(__kindof ZIKViewRouteConfiguration * _Nonnull config) {
        
    } removing:nil];
}

+ (nullable instancetype)performOnDestination:(id)destination
                                         path:(ZIKViewRoutePath *)path
                            strictConfiguring:(void (NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<id> * _Nonnull, ZIKViewRouteConfiguration * _Nonnull))configBuilder {
    return [self performOnDestination:destination path:path strictConfiguring:configBuilder strictRemoving:nil];
}

+ (nullable instancetype)performOnDestination:(id)destination
                                         path:(ZIKViewRoutePath *)path
                            strictConfiguring:(void (NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<id> * _Nonnull, ZIKViewRouteConfiguration * _Nonnull))configBuilder
                               strictRemoving:(void (NS_NOESCAPE ^)(ZIKViewRemoveStrictConfiguration<id> * _Nonnull))removeConfigBuilder {
    return [self performOnDestination:destination path:path configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
        if (configBuilder) {
            ZIKViewRouteStrictConfiguration *strictConfig = [[ ZIKViewRouteStrictConfiguration alloc] initWithConfiguration:config];
            configBuilder(strictConfig, config);
        }
    } removing:^(ZIKViewRemoveConfiguration * _Nonnull config) {
        if (removeConfigBuilder) {
            ZIKViewRemoveStrictConfiguration *strictConfig = [[ZIKViewRemoveStrictConfiguration alloc] initWithConfiguration:config];
            removeConfigBuilder(strictConfig);
        }
    }];
}

@end

@implementation ZIKViewRouter (Prepare)

+ (nullable instancetype)prepareDestination:(id)destination
                                configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder {
    return [self prepareDestination:destination configuring:configBuilder removing:nil];
}

+ (nullable instancetype)prepareDestination:(id)destination
                                configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder
                                   removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder {
    void(^notifyError)(NSError *) = ^(NSError *error) {
        ZIKViewRouteConfiguration *configuration = [self defaultRouteConfiguration];
        configuration.routeType = ZIKViewRouteTypeMakeDestination;
        if (configBuilder) {
            configBuilder(configuration);
        }
        if (configuration.injected) {
            configuration = (ZIKViewRouteConfiguration *)configuration.injected;
        }
        configuration.routeType = ZIKViewRouteTypeMakeDestination;
        if (configuration.errorHandler) {
            configuration.errorHandler(ZIKRouteActionPrepareOnDestination, error);
        }
        if (configuration.performerErrorHandler) {
            configuration.performerErrorHandler(ZIKRouteActionPrepareOnDestination, error);
        }
        if (configuration.completionHandler) {
            configuration.completionHandler(NO, nil, ZIKRouteActionPrepareOnDestination, error);
        }
    };
    
    if (![destination conformsToProtocol:@protocol(ZIKRoutableView)]) {
        NSError *error = [[self class] errorWithCode:ZIKRouteErrorDestinationUnavailable localizedDescription:[NSString stringWithFormat:@"Prepare for invalid destination: (%@)",destination]];
        [[self class] notifyGlobalErrorWithRouter:nil action:ZIKRouteActionPrepareOnDestination error:error];
        notifyError(error);
        return nil;
    }
    if ([self isAbstractRouter] == NO && ![ZIKViewRouteRegistry isDestinationClass:[destination class] registeredWithRouter:self]) {
        NSError *error = [[self class] errorWithCode:ZIKRouteErrorDestinationUnavailable localizedDescription:[NSString stringWithFormat:@"Prepare for invalid destination (%@), this view is not registered with this router (%@)",destination,self]];
        [[self class] notifyGlobalErrorWithRouter:nil action:ZIKRouteActionPrepareOnDestination error:error];
        NSAssert2(NO, @"Prepare for invalid destination (%@), this view is not registered with this router (%@)",destination,self);
        notifyError(error);
        return nil;
    }
    ZIKViewRouter *router =  [[self alloc] initWithConfiguring:^(ZIKPerformRouteConfiguration * _Nonnull config) {
        ZIKViewRouteConfiguration *configuration = (ZIKViewRouteConfiguration *)config;
        configuration.routeType = ZIKViewRouteTypeMakeDestination;
        if (configBuilder) {
            configBuilder(configuration);
        }
        if (configuration.injected) {
            configuration = (ZIKViewRouteConfiguration *)configuration.injected;
        }
        configuration.routeType = ZIKViewRouteTypeMakeDestination;
    } removing:(void(^)(ZIKRemoveRouteConfiguration *))removeConfigBuilder];
    [router notifyRouteState:ZIKRouterStateRouting];
    [router attachDestination:destination];
    [router prepareDestinationForPerforming];
    
    NSNumber *routeType = [destination zix_routeTypeFromRouter];
    if (routeType == nil) {
        [(id)destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypeMakeDestination)];
    }
    [router notifyRouteState:ZIKRouterStateRouted];
    [router notifySuccessWithAction:ZIKRouteActionPrepareOnDestination];
    
    return router;
}

+ (nullable instancetype)prepareDestination:(id)destination strictConfiguring:(void (NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<id> * _Nonnull, ZIKViewRouteConfiguration * _Nonnull))configBuilder {
    return [self prepareDestination:destination strictConfiguring:configBuilder strictRemoving:nil];
}

+ (nullable instancetype)prepareDestination:(id)destination
                          strictConfiguring:(void (NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<id> * _Nonnull, ZIKViewRouteConfiguration * _Nonnull))configBuilder
                             strictRemoving:(void (NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveStrictConfiguration<id> * _Nonnull))removeConfigBuilder {
    return [self prepareDestination:destination configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
        if (configBuilder) {
            ZIKViewRouteStrictConfiguration *strictConfig = [[ZIKViewRouteStrictConfiguration alloc] initWithConfiguration:config];
            configBuilder(strictConfig, config);
        }
    } removing:^(ZIKViewRemoveConfiguration * _Nonnull config) {
        if (removeConfigBuilder) {
            ZIKViewRemoveStrictConfiguration *strictConfig = [[ZIKViewRemoveStrictConfiguration alloc] initWithConfiguration:config];
            removeConfigBuilder(strictConfig);
        }
    }];
}

@end

#import "ZIKViewRoute.h"

@implementation ZIKViewRouter (Register)

+ (BOOL)isRegistrationFinished {
    return ZIKViewRouteRegistry.registrationFinished;
}

+ (void)registerView:(Class)viewClass {
    NSParameterAssert([viewClass isSubclassOfClass:[XXView class]] ||
                      [viewClass isSubclassOfClass:[XXViewController class]]);
    NSAssert(!ZIKViewRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKViewRouteRegistry registerDestination:viewClass router:self];
}

+ (void)registerExclusiveView:(Class)viewClass {
    NSCParameterAssert([viewClass isSubclassOfClass:[XXView class]] ||
                       [viewClass isSubclassOfClass:[XXViewController class]]);
    NSCAssert(!ZIKViewRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKViewRouteRegistry registerExclusiveDestination:viewClass router:self];
}

+ (void)registerViewProtocol:(Protocol *)viewProtocol {
    NSAssert(!ZIKViewRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
#if ZIKROUTER_CHECK
    NSAssert1(protocol_conformsToProtocol(viewProtocol, @protocol(ZIKViewRoutable)), @"Routable destination protocol %@ should conforms to ZIKViewRoutable", NSStringFromProtocol(viewProtocol));
#endif
    [ZIKViewRouteRegistry registerDestinationProtocol:viewProtocol router:self];
}

+ (void)registerModuleProtocol:(Protocol *)configProtocol {
    NSAssert3([[self defaultRouteConfiguration] conformsToProtocol:configProtocol], @"The module config protocol (%@) should be conformed by the router (%@)'s defaultRouteConfiguration (%@).", NSStringFromProtocol(configProtocol), self, NSStringFromClass([[self defaultRouteConfiguration] class]));
    NSAssert(!ZIKViewRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
#if ZIKROUTER_CHECK
    NSAssert1(protocol_conformsToProtocol(configProtocol, @protocol(ZIKViewModuleRoutable)), @"Routable module config protocol %@ should conforms to ZIKViewModuleRoutable", NSStringFromProtocol(configProtocol));
#endif
    [ZIKViewRouteRegistry registerModuleProtocol:configProtocol router:self];
}

+ (void)registerIdentifier:(NSString *)identifier {
    NSAssert(!ZIKViewRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKViewRouteRegistry registerIdentifier:identifier router:self];
}

@end

@implementation ZIKViewRouter (RegisterMaking)

+ (void)registerViewProtocol:(Protocol<ZIKViewRoutable> *)viewProtocol forMakingView:(Class)viewClass {
    NSAssert(!ZIKViewRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKViewRouteRegistry registerDestinationProtocol:viewProtocol forMakingDestination:viewClass];
}

+ (void)registerViewProtocol:(Protocol<ZIKViewRoutable> *)viewProtocol forMakingView:(Class)viewClass factory:(id(*)(ZIKViewRouteConfiguration *))function {
    NSAssert(!ZIKViewRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKViewRouteRegistry registerDestinationProtocol:viewProtocol forMakingDestination:viewClass factoryFunction:function];
}

+ (void)registerViewProtocol:(Protocol<ZIKViewRoutable> *)viewProtocol forMakingView:(Class)viewClass making:(id  _Nullable (^)(ZIKViewRouteConfiguration * _Nonnull))makeDestination {
    NSParameterAssert([viewClass conformsToProtocol:viewProtocol]);
    NSAssert(!ZIKViewRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKViewRouteRegistry registerDestinationProtocol:viewProtocol forMakingDestination:viewClass factoryBlock:(id)makeDestination];
}

+ (void)registerModuleProtocol:(Protocol<ZIKViewModuleRoutable> *)configProtocol forMakingView:(Class)viewClass factory:(ZIKViewRouteConfiguration<ZIKConfigurationMakeable> * _Nonnull (*_Nonnull)(void))function {
    NSAssert(!ZIKViewRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKViewRouteRegistry registerModuleProtocol:configProtocol forMakingDestination:viewClass factoryFunction:function];
}

+ (void)registerModuleProtocol:(Protocol<ZIKViewModuleRoutable> *)configProtocol forMakingView:(Class)viewClass making:(ZIKViewRouteConfiguration<ZIKConfigurationMakeable> *(^)(void))makeConfiguration {
    NSAssert(!ZIKViewRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKViewRouteRegistry registerModuleProtocol:configProtocol forMakingDestination:viewClass factoryBlock:makeConfiguration];
}

+ (void)registerIdentifier:(NSString *)identifier forMakingView:(Class)viewClass {
    NSAssert(!ZIKViewRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKViewRouteRegistry registerIdentifier:identifier forMakingDestination:viewClass];
}

+ (void)registerIdentifier:(NSString *)identifier forMakingView:(Class)viewClass factory:(id(*_Nonnull)(ZIKViewRouteConfiguration *))function {
    NSAssert(!ZIKViewRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKViewRouteRegistry registerIdentifier:identifier forMakingDestination:viewClass factoryFunction:function];
}

+ (void)registerIdentifier:(NSString *)identifier forMakingView:(Class)viewClass making:(id  _Nullable (^)(ZIKViewRouteConfiguration * _Nonnull))makeDestination {
    NSAssert(!ZIKViewRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKViewRouteRegistry registerIdentifier:identifier forMakingDestination:viewClass factoryBlock:(id)makeDestination];
}

+ (void)registerIdentifier:(NSString *)identifier forMakingView:(Class)viewClass configurationFactory:(ZIKViewRouteConfiguration<ZIKConfigurationMakeable> * _Nonnull (*_Nonnull)(void))function {
    NSCAssert(!ZIKViewRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKViewRouteRegistry registerIdentifier:identifier forMakingDestination:viewClass configFactoryFunction:function];
}

+ (void)registerIdentifier:(NSString *)identifier forMakingView:(Class)viewClass configurationMaking:(ZIKViewRouteConfiguration<ZIKConfigurationMakeable> *(^)(void))makeConfiguration {
    NSCAssert(!ZIKViewRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKViewRouteRegistry registerIdentifier:identifier forMakingDestination:viewClass configFactoryBlock:makeConfiguration];
}

@end

void _registerViewProtocolWithSwiftFactory(Protocol<ZIKViewRoutable> *viewProtocol, Class viewClass, ZIKViewFactoryBlock block) {
    NSCAssert(!ZIKViewRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKViewRouteRegistry registerDestinationProtocol:viewProtocol forMakingDestination:viewClass factoryBlock:(id)block];
}

void _registerViewModuleProtocolWithSwiftFactory(Protocol<ZIKViewModuleRoutable> *moduleProtocol, Class viewClass, id(^block)(void)) {
    NSCAssert(!ZIKViewRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKViewRouteRegistry registerModuleProtocol:moduleProtocol forMakingDestination:viewClass factoryBlock:block];
}

void _registerViewIdentifierWithSwiftFactory(NSString *identifier, Class viewClass, ZIKViewFactoryBlock block) {
    NSCAssert(!ZIKViewRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKViewRouteRegistry registerIdentifier:identifier forMakingDestination:viewClass factoryBlock:(id)block];
}

void _registerViewModuleIdentifierWithSwiftFactory(NSString *identifier, Class viewClass, id(^block)(void)) {
    NSCAssert(!ZIKViewRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKViewRouteRegistry registerIdentifier:identifier forMakingDestination:viewClass configFactoryBlock:block];
}

@implementation ZIKViewRouter (Private)

+ (instancetype)routerFromView:(XXView *)destination source:(XXView *)source {
    return [self routerFromView:destination source:source configuring:nil];
}

+ (instancetype)routerFromView:(XXView *)destination source:(XXView *)source configuring:(void(^ _Nullable)(__kindof ZIKViewRouteConfiguration *config))configBuilder {
    NSParameterAssert(destination);
    NSParameterAssert(source);
    if (!destination || !source) {
        return nil;
    }
    
    NSAssert([self _validateSupportedRouteTypesForXXView], @"Router for UIView only supports ZIKViewRouteTypeAddAsSubview, ZIKViewRouteTypeMakeDestination and ZIKViewRouteTypeCustom, override +supportedRouteTypes in your router.");
#if ZIK_HAS_UIKIT
    ZIKViewRouteType routeType = ZIKViewRouteTypeAddAsSubview;
    ZIKViewRouteRealType realType = ZIKViewRouteRealTypeAddAsSubview;
#else
    ZIKViewRouteType routeType = ZIKViewRouteTypeAddAsSubview;
    ZIKViewRouteRealType realType = ZIKViewRouteRealTypeAddAsSubview;
    if ([source isKindOfClass:[NSWindow class]]) {
        routeType = ZIKViewRouteTypeCustom;
        realType = ZIKViewRouteRealTypeCustom;
    }
#endif
    
    ZIKViewRouter *router = [[self alloc] initWithConfiguring:^(ZIKPerformRouteConfiguration * _Nonnull config) {
        ZIKViewRouteConfiguration *configuration = (ZIKViewRouteConfiguration *)config;
        if (configBuilder) {
            configBuilder(configuration);
        }
        configuration.autoCreated = YES;
        configuration.routeType = routeType;
        configuration.source = source;
    } removing:nil];
    [router attachDestination:destination];
    router.realRouteType = realType;
    
    return router;
}

+ (instancetype)routerFromSegueIdentifier:(NSString *)identifier sender:(nullable id)sender destination:(XXViewController *)destination source:(XXViewController *)source {
    return [self routerFromSegueIdentifier:identifier sender:sender destination:destination source:source configuring:nil];
}

+ (instancetype)routerFromSegueIdentifier:(NSString *)identifier sender:(nullable id)sender destination:(XXViewController *)destination source:(XXViewController *)source configuring:(void(^ _Nullable)(__kindof ZIKViewRouteConfiguration *config))configBuilder {
    NSParameterAssert([destination isKindOfClass:[XXViewController class]]);
    NSParameterAssert([source isKindOfClass:[XXViewController class]]);
    if (![self shouldAutoCreateForDestination:destination fromSource:source]) {
        return nil;
    }
    ZIKViewRouter *router = [[self alloc] initWithConfiguring:^(ZIKPerformRouteConfiguration * _Nonnull config) {
        ZIKViewRouteConfiguration *configuration = (ZIKViewRouteConfiguration *)config;
        if (configBuilder) {
            configBuilder(configuration);
        }
        configuration.autoCreated = YES;
        configuration.routeType = ZIKViewRouteTypePerformSegue;
        configuration.source = source;
        configuration.configureSegue(^(ZIKViewRouteSegueConfiguration * _Nonnull segueConfig) {
            segueConfig.identifier = identifier;
            segueConfig.sender = sender;
        });
    } removing:nil];
    [router attachDestination:destination];
    return router;
}

Protocol<ZIKViewRoutable> *_Nullable _routableViewProtocolFromObject(id object) {
    if (zix_isObjcProtocol(object) == NO) {
        return nil;
    }
    Protocol *p = object;
    if (protocol_conformsToProtocol(p, @protocol(ZIKViewRoutable))) {
        return object;
    }
    return nil;
}

Protocol<ZIKViewModuleRoutable> *_Nullable _routableViewModuleProtocolFromObject(id object) {
    if (zix_isObjcProtocol(object) == NO) {
        return nil;
    }
    Protocol *p = object;
    if (protocol_conformsToProtocol(p, @protocol(ZIKViewModuleRoutable))) {
        return object;
    }
    return nil;
}

@end

@implementation ZIKViewRouter (Utility)

+ (void)enumerateAllViewRouters:(void(NS_NOESCAPE ^)(Class routerClass))handler {
    if (handler == nil) {
        return;
    }
    [ZIKViewRouteRegistry enumerateAllViewRouters:^(Class  _Nullable __unsafe_unretained routerClass, ZIKViewRoute * _Nullable route) {
        if (routerClass) {
            handler(routerClass);
        }
    }];
}

@end

@implementation ZIKViewRouter (Debug)

static NSTimeInterval _detectMemoryLeakDelay = 2;

+ (BOOL)shouldDetectMemoryLeak {
    return _detectMemoryLeakDelay > 0;
}

+ (NSTimeInterval)detectMemoryLeakDelay {
    return _detectMemoryLeakDelay;
}

+ (void)setDetectMemoryLeakDelay:(NSTimeInterval)detectMemoryLeakDelay {
    _detectMemoryLeakDelay = detectMemoryLeakDelay;
}

static void(^_didDetectLeakingHandler)(id);

+ (void(^)(id))didDetectLeakingHandler {
    return _didDetectLeakingHandler;
}

+ (void)setDidDetectLeakingHandler:(void(^)(id))handler {
    _didDetectLeakingHandler = handler;
}

@end

@implementation ZIKViewRouter (Deprecated)

+ (nullable instancetype)performFromSource:(nullable id<ZIKViewRouteSource>)source configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder {
    return [self performFromSource:source configuring:configBuilder removing:nil];
}

+ (nullable instancetype)performFromSource:(nullable id)source routeType:(ZIKViewRouteType)routeType {
    return [self performFromSource:source configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
        config.routeType = routeType;
    } removing:nil];
}

+ (nullable instancetype)performFromSource:(nullable id<ZIKViewRouteSource>)source
                                 routeType:(ZIKViewRouteType)routeType
                            successHandler:(void(^ _Nullable)(id destination))performerSuccessHandler
                              errorHandler:(void(^ _Nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler {
    ZIKViewRoutePath *path = [[ZIKViewRoutePath alloc] initWithRouteType:routeType source:source];
    return [self performPath:path successHandler:performerSuccessHandler errorHandler:performerErrorHandler];
}

+ (nullable instancetype)performFromSource:(nullable id<ZIKViewRouteSource>)source routeType:(ZIKViewRouteType)routeType completion:(ZIKPerformRouteCompletion)performerCompletion {
    ZIKViewRoutePath *path = [[ZIKViewRoutePath alloc] initWithRouteType:routeType source:source];
    return [self performPath:path completion:performerCompletion];
}

+ (nullable instancetype)performFromSource:(nullable id<ZIKViewRouteSource>)source
                               configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder
                                  removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder {
    return [super performWithConfiguring:^(ZIKViewRouteConfiguration * _Nonnull config) {
        if (configBuilder) {
            configBuilder(config);
        }
        if (config.injected) {
            config = (ZIKViewRouteConfiguration *)config.injected;
        }
        if (source) {
            config.source = source;
        }
    } removing:removeConfigBuilder];
}

+ (nullable instancetype)performFromSource:(id<ZIKViewRouteSource>)source
                         strictConfiguring:(void (NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<id> * _Nonnull, ZIKViewRouteConfiguration * _Nonnull))configBuilder {
    return [self performFromSource:source strictConfiguring:configBuilder strictRemoving:nil];
}

+ (nullable instancetype)performFromSource:(id<ZIKViewRouteSource>)source
                         strictConfiguring:(void (NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<id> * _Nonnull, ZIKViewRouteConfiguration * _Nonnull))configBuilder
                            strictRemoving:(void (NS_NOESCAPE ^)(ZIKViewRemoveStrictConfiguration<id> * _Nonnull))removeConfigBuilder {
    return [super performWithStrictConfiguring:(void(^)(ZIKPerformRouteStrictConfiguration<id> *, ZIKViewRouteConfiguration *))^(ZIKViewRouteStrictConfiguration<id> *strictConfig, ZIKViewRouteConfiguration * _Nonnull config) {
        if (configBuilder) {
            configBuilder(strictConfig, config);
        }
        if (config.injected) {
            config = (ZIKViewRouteConfiguration *)config.injected;
        }
        if (source) {
            config.source = source;
        };
    } strictRemoving:(void(^)(ZIKRemoveRouteStrictConfiguration<id> *))removeConfigBuilder];
}

+ (nullable instancetype)performOnDestination:(id)destination
                                   fromSource:(nullable id<ZIKViewRouteSource>)source
                                  configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder {
    return [self performOnDestination:destination fromSource:source configuring:configBuilder removing:nil];
}

+ (nullable instancetype)performOnDestination:(id)destination
                                   fromSource:(nullable id<ZIKViewRouteSource>)source
                                  configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder
                                     removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder {
    void(^notifyError)(NSError *) = ^(NSError *error) {
        ZIKViewRouteConfiguration *configuration = [self defaultRouteConfiguration];
        configuration.routeType = ZIKViewRouteTypeMakeDestination;
        if (configBuilder) {
            configBuilder(configuration);
        }
        if (configuration.injected) {
            configuration = (ZIKViewRouteConfiguration *)configuration.injected;
        }
        configuration.routeType = ZIKViewRouteTypeMakeDestination;
        if (configuration.errorHandler) {
            configuration.errorHandler(ZIKRouteActionPerformOnDestination, error);
        }
        if (configuration.performerErrorHandler) {
            configuration.performerErrorHandler(ZIKRouteActionPerformOnDestination, error);
        }
        if (configuration.completionHandler) {
            configuration.completionHandler(NO, nil, ZIKRouteActionPerformOnDestination, error);
        }
    };
    if (![destination conformsToProtocol:@protocol(ZIKRoutableView)]) {
        NSError *error = [[self class] errorWithCode:ZIKRouteErrorInvalidConfiguration localizedDescription:[NSString stringWithFormat:@"Perform route on invalid destination: (%@)",destination]];
        [[self class] notifyGlobalErrorWithRouter:nil action:ZIKRouteActionPerformOnDestination error:error];
        notifyError(error);
        return nil;
    }
    if ([self isAbstractRouter] == NO && ![ZIKViewRouteRegistry isDestinationClass:[destination class] registeredWithRouter:self]) {
        NSError *error = [[self class] errorWithCode:ZIKRouteErrorInvalidConfiguration localizedDescription:[NSString stringWithFormat:@"Perform route on invalid destination (%@), this view is not registered with this router (%@)",destination,self]];
        [[self class] notifyGlobalErrorWithRouter:nil action:ZIKRouteActionPerformOnDestination error:error];
        notifyError(error);
        return nil;
    }
    ZIKViewRouter *router = [[self alloc] initWithConfiguring:^(ZIKPerformRouteConfiguration *config) {
        ZIKViewRouteConfiguration *configuration = (ZIKViewRouteConfiguration *)config;
        if (configBuilder) {
            configBuilder(configuration);
        }
        if (configuration.injected) {
            configuration = (ZIKViewRouteConfiguration *)configuration.injected;
        }
        if (source) {
            configuration.source = source;
        }
    } removing:(void(^)(ZIKRemoveRouteConfiguration *))removeConfigBuilder];
    NSAssert([(ZIKViewRouteConfiguration *)router.original_configuration routeType] != ZIKViewRouteTypeMakeDestination, @"It's meaningless to get destination when you already offer a prepared destination.");
    [router notifyRouteState:ZIKRouterStateRouting];
    [router attachDestination:destination];
    [router performRouteOnDestination:destination configuration:router.original_configuration];
    return router;
}

+ (nullable instancetype)performOnDestination:(id)destination
                                   fromSource:(nullable id<ZIKViewRouteSource>)source
                                    routeType:(ZIKViewRouteType)routeType {
    return [self performOnDestination:destination fromSource:source configuring:^(__kindof ZIKViewRouteConfiguration * _Nonnull config) {
        config.routeType = routeType;
    } removing:nil];
}

+ (nullable instancetype)performOnDestination:(id)destination
                                   fromSource:(id<ZIKViewRouteSource>)source
                            strictConfiguring:(void (NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<id> * _Nonnull, ZIKViewRouteConfiguration * _Nonnull))configBuilder {
    return [self performOnDestination:destination fromSource:source strictConfiguring:configBuilder strictRemoving:nil];
}

+ (nullable instancetype)performOnDestination:(id)destination
                                   fromSource:(id<ZIKViewRouteSource>)source
                            strictConfiguring:(void (NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<id> * _Nonnull, ZIKViewRouteConfiguration * _Nonnull))configBuilder
                               strictRemoving:(void (NS_NOESCAPE ^)(ZIKViewRemoveStrictConfiguration<id> * _Nonnull))removeConfigBuilder {
    return [self performOnDestination:destination fromSource:source configuring:^(ZIKViewRouteConfiguration *config) {
        ZIKViewRouteStrictConfiguration *strictConfig = [[ZIKViewRouteStrictConfiguration alloc] initWithConfiguration:config];
        if (configBuilder) {
            configBuilder(strictConfig, config);
        }
    } removing:^(ZIKViewRemoveConfiguration *config) {
        ZIKViewRemoveStrictConfiguration *strictConfig = [[ZIKViewRemoveStrictConfiguration alloc] initWithConfiguration:config];
        if (removeConfigBuilder) {
            removeConfigBuilder(strictConfig);
        }
    }];
}

@end
