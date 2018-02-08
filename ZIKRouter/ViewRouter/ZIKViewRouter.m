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
#import "ZIKViewRouterInternal.h"
#import "ZIKViewRouterPrivate.h"
#import "ZIKViewRouteRegistry.h"
#import "ZIKRouteRegistryInternal.h"
#import "ZIKViewRouteError.h"
#import <objc/runtime.h>
#import "ZIKRouterRuntime.h"
#import "UIViewController+ZIKViewRouter.h"
#import "UIView+ZIKViewRouter.h"
#import "ZIKPresentationState.h"
#import "UIView+ZIKViewRouterPrivate.h"
#import "UIViewController+ZIKViewRouterPrivate.h"
#import "UIStoryboardSegue+ZIKViewRouterPrivate.h"
#import "ZIKViewRouteConfiguration+Private.h"

NSNotificationName kZIKViewRouteWillPerformRouteNotification = @"kZIKViewRouteWillPerformRouteNotification";
NSNotificationName kZIKViewRouteDidPerformRouteNotification = @"kZIKViewRouteDidPerformRouteNotification";
NSNotificationName kZIKViewRouteWillRemoveRouteNotification = @"kZIKViewRouteWillRemoveRouteNotification";
NSNotificationName kZIKViewRouteDidRemoveRouteNotification = @"kZIKViewRouteDidRemoveRouteNotification";
NSNotificationName kZIKViewRouteRemoveRouteCanceledNotification = @"kZIKViewRouteRemoveRouteCanceledNotification";

static ZIKViewRouteGlobalErrorHandler g_globalErrorHandler;
static dispatch_semaphore_t g_globalErrorSema;
static NSMutableArray *g_preparingUIViewRouters;

@interface ZIKViewRouter ()
@property (nonatomic, assign) BOOL routingFromInternal;
@property (nonatomic, assign) ZIKViewRouteRealType realRouteType;
///Destination prepared. Only for UIView destination
@property (nonatomic, assign) BOOL prepared;
@property (nonatomic, strong, nullable) ZIKPresentationState *stateBeforeRoute;
@property (nonatomic, weak, nullable) UIViewController<ZIKViewRouteContainer> *container;
@property (nonatomic, strong, nullable) ZIKViewRouter *retainedSelf;
@end

@implementation ZIKViewRouter

@dynamic configuration;
@dynamic original_configuration;
@dynamic original_removeConfiguration;

+ (void)load {
    [ZIKRouteRegistry addRegistry:[ZIKViewRouteRegistry class]];
    g_globalErrorSema = dispatch_semaphore_create(1);
    g_preparingUIViewRouters = [NSMutableArray array];
    
    Class ZIKViewRouterClass = [ZIKViewRouter class];
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
    ZIKRouter_replaceMethodWithMethod([UIStoryboard class], @selector(instantiateInitialViewController), ZIKViewRouterClass, @selector(ZIKViewRouter_hook_instantiateInitialViewController));
}

+ (void)_didFinishRegistration {
    
}

static BOOL _isClassRoutable(Class class) {
    Class UIResponderClass = [UIResponder class];
    while (class && class != UIResponderClass) {
        if (class_conformsToProtocol(class, @protocol(ZIKRoutableView))) {
            return YES;
        }
        class = class_getSuperclass(class);
    }
    return NO;
}

#pragma mark Initialize

- (nullable instancetype)initWithConfiguration:(__kindof ZIKViewRouteConfiguration *)configuration removeConfiguration:(nullable __kindof ZIKViewRemoveConfiguration *)removeConfiguration {
    NSParameterAssert([configuration isKindOfClass:[ZIKViewRouteConfiguration class]]);
    
    if (!removeConfiguration) {
        removeConfiguration = [[self class] defaultRemoveConfiguration];
    }
    if (self = [super initWithConfiguration:configuration removeConfiguration:removeConfiguration]) {
        if (![[self class] _validateRouteTypeInConfiguration:configuration]) {
            [self _callbackError_unsupportTypeWithAction:ZIKRouteActionInit
                                        errorDescription:@"%@ doesn't support routeType:%ld, supported types: %ld",[self class],configuration.routeType,[[self class] supportedRouteTypes]];
            NSAssert(NO, @"%@ doesn't support routeType:%ld, supported types: %ld",[self class],(long)configuration.routeType,(long)[[self class] supportedRouteTypes]);
            return nil;
        } else if (![[self class] _validateRouteSourceNotMissedInConfiguration:configuration] ||
                   ![[self class] _validateRouteSourceClassInConfiguration:configuration]) {
            [self _callbackError_invalidSourceWithAction:ZIKRouteActionInit
                                        errorDescription:@"Source: (%@) is invalid for configuration: (%@)",configuration.source,configuration];
            NSAssert(NO, @"Source: (%@) is invalid for configuration: (%@)",configuration.source,configuration);
            return nil;
        } else {
            ZIKViewRouteType type = configuration.routeType;
            if (type == ZIKViewRouteTypePerformSegue) {
                if (![[self class] _validateSegueInConfiguration:configuration]) {
                    [self _callbackError_invalidConfigurationWithAction:ZIKRouteActionPerformRoute
                                                       errorDescription:@"SegueConfiguration : (%@) was invalid",configuration.segueConfiguration];
                    NSAssert(NO, @"SegueConfiguration : (%@) was invalid",configuration.segueConfiguration);
                    return nil;
                }
            } else if (type == ZIKViewRouteTypePresentAsPopover) {
                if (![[self class] _validatePopoverInConfiguration:configuration]) {
                    [self _callbackError_invalidConfigurationWithAction:ZIKRouteActionPerformRoute
                                                       errorDescription:@"PopoverConfiguration : (%@) was invalid",configuration.popoverConfiguration];
                    NSAssert(NO, @"PopoverConfiguration : (%@) was invalid",configuration.popoverConfiguration);
                    return nil;
                }
            } else if (type == ZIKViewRouteTypeCustom) {
                if (![[self class] validateCustomRouteConfiguration:configuration removeConfiguration:removeConfiguration]) {
                    [self _callbackError_invalidConfigurationWithAction:ZIKRouteActionPerformRoute
                                                       errorDescription:@"Configuration : (%@) was invalid for ZIKViewRouteTypeCustom",configuration];
                    NSAssert(NO, @"Configuration : (%@) was invalid for ZIKViewRouteTypeCustom",configuration);
                    return nil;
                }
            }
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleWillPerformRouteNotification:) name:kZIKViewRouteWillPerformRouteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleDidPerformRouteNotification:) name:kZIKViewRouteDidPerformRouteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleWillRemoveRouteNotification:) name:kZIKViewRouteWillRemoveRouteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleDidRemoveRouteNotification:) name:kZIKViewRouteDidRemoveRouteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleRemoveRouteCanceledNotification:) name:kZIKViewRouteRemoveRouteCanceledNotification object:nil];
    }
    return self;
}

+ (instancetype)routerFromView:(UIView *)destination source:(UIView *)source {
    NSParameterAssert(destination);
    NSParameterAssert(source);
    if (!destination || !source) {
        return nil;
    }
    NSAssert([self _validateSupportedRouteTypesForUIView], @"Router for UIView only suppourts ZIKViewRouteTypeAddAsSubview, ZIKViewRouteTypeGetDestination and ZIKViewRouteTypeCustom, override +supportedRouteTypes in your router.");
    
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

+ (BOOL)canMakeDestinationSynchronously {
    return YES;
}

- (void)performRouteWithSuccessHandler:(void(^)(void))performerSuccessHandler
                          errorHandler:(void(^)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler {
    ZIKRouterState state = self.state;
    if (state == ZIKRouterStateRouting) {
        [self _callbackError_errorCode:ZIKViewRouteErrorOverRoute
                          errorHandler:performerErrorHandler
                                action:ZIKRouteActionPerformRoute
                      errorDescription:@"%@ is routing, can't perform route again",self];
        return;
    } else if (state == ZIKRouterStateRouted) {
        [self _callbackError_actionFailedWithAction:ZIKRouteActionPerformRoute
                                   errorDescription:@"%@ 's state is routed, can't perform route again",self];
        return;
    } else if (state == ZIKRouterStateRemoving) {
        [self _callbackError_errorCode:ZIKViewRouteErrorActionFailed
                          errorHandler:performerErrorHandler
                                action:ZIKRouteActionPerformRoute
                      errorDescription:@"%@ 's state is removing, can't perform route again",self];
        return;
    }
    [super performRouteWithSuccessHandler:performerSuccessHandler errorHandler:performerErrorHandler];
}

- (void)performWithConfiguration:(__kindof ZIKViewRouteConfiguration *)configuration {
    NSParameterAssert(configuration);
    NSAssert([[[self class] defaultRouteConfiguration] isKindOfClass:[configuration class]], @"When using custom configuration class，you must override +defaultRouteConfiguration to return your custom configuration instance.");
    [[self class] increaseRecursiveDepth];
    if ([[self class] _validateInfiniteRecursion] == NO) {
        [self _callbackError_infiniteRecursionWithAction:ZIKRouteActionPerformRoute errorDescription:@"Infinite recursion for performing route detected, see -prepareDestination:configuration: for more detail. Recursive call stack:\n%@",[NSThread callStackSymbols]];
        [[self class] decreaseRecursiveDepth];
        return;
    }
    if (configuration.routeType == ZIKViewRouteTypePerformSegue) {
        [self performRouteOnDestination:nil configuration:configuration];
        [[self class] decreaseRecursiveDepth];
        return;
    }
    
    if ([NSThread isMainThread]) {
        [super performWithConfiguration:configuration];
        [[self class] decreaseRecursiveDepth];
    } else {
        NSAssert(NO, @"%@ performRoute should only be called in main thread!",self);
        dispatch_sync(dispatch_get_main_queue(), ^{
            [super performWithConfiguration:configuration];
            [[self class] decreaseRecursiveDepth];
        });
    }
}

+ (BOOL)canMakeDestination {
    if (![super canMakeDestination]) {
        return NO;
    }
    return [self supportRouteType:ZIKViewRouteTypeGetDestination];
}

+ (nullable id)makeDestinationWithPreparation:(void(^ _Nullable)(id destination))prepare {
    NSAssert(self != [ZIKViewRouter class], @"Only get destination from router subclass");
    if (![self canMakeDestination]) {
        NSAssert1(NO, @"The router (%@) doesn't support makeDestination",self);
        return nil;
    }
    __block id dest;
    ZIKViewRouter *router = [[self alloc] initWithConfiguring:(void(^)(ZIKPerformRouteConfiguration *))^(ZIKViewRouteConfiguration * _Nonnull config) {
        config.routeType = ZIKViewRouteTypeGetDestination;
        if (prepare) {
            config.prepareDestination = prepare;
        }
        void(^routeCompletion)(id destination) = config.routeCompletion;
        if (routeCompletion) {
            config.routeCompletion = ^(id  _Nonnull destination) {
                routeCompletion(destination);
                dest = destination;
            };
        } else {
            config.routeCompletion = ^(id  _Nonnull destination) {
                dest = destination;
            };
        }
    } removing:NULL];
    [router performRoute];
    return dest;
}

+ (nullable id)makeDestinationWithConfiguring:(void(^ _Nullable)(ZIKPerformRouteConfiguration *config))configBuilder {
    NSAssert(self != [ZIKViewRouter class], @"Only get destination from router subclass");
    if (![self canMakeDestination]) {
        NSAssert1(NO, @"The router (%@) doesn't support makeDestination",self);
        return nil;
    }
    __block id dest;
    ZIKViewRouteConfiguration *configuration = [[self class] defaultRouteConfiguration];
    if (configBuilder) {
        configBuilder(configuration);
    }
    void(^routeCompletion)(id destination) = configuration.routeCompletion;
    if (routeCompletion) {
        configuration.routeCompletion = ^(id  _Nonnull destination) {
            routeCompletion(destination);
            dest = destination;
        };
    } else {
        configuration.routeCompletion = ^(id  _Nonnull destination) {
            dest = destination;
        };
    }
    configuration.routeType = ZIKViewRouteTypeGetDestination;
    ZIKViewRouter *router = [[self alloc] initWithConfiguration:configuration removeConfiguration:nil];
    [router performRoute];
    return dest;
}

+ (BOOL)isAbstractRouter {
    return self == [ZIKViewRouter class];
}

#pragma mark ZIKViewRouterSubclass

+ (void)registerRoutableDestination {
    NSAssert1(NO, @"Subclass(%@) must override +registerRoutableDestination to register destination.",self);
}

- (id)destinationWithConfiguration:(__kindof ZIKViewRouteConfiguration *)configuration {
    NSAssert(NO, @"Router: %@ must override -destinationWithConfiguration: to return the destination！",[self class]);
    return nil;
}

+ (BOOL)destinationPrepared:(id)destination {
    NSAssert(self != [ZIKViewRouter class], @"Check destination prepared with it's router.");
    return YES;
}

- (void)prepareDestination:(id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    NSAssert([self class] != [ZIKViewRouter class], @"Prepare destination with it's router.");
}

- (void)didFinishPrepareDestination:(id)destination configuration:(nonnull __kindof ZIKViewRouteConfiguration *)configuration {
    NSAssert([self class] != [ZIKViewRouter class] ||
             configuration.routeType == ZIKViewRouteTypePerformSegue,
             @"Only ZIKViewRouteTypePerformSegue can use ZIKViewRouter class to perform route, otherwise, use a subclass of ZIKViewRouter for destination.");
}

+ (ZIKViewRouteTypeMask)supportedRouteTypes {
    return ZIKViewRouteTypeMaskUIViewControllerDefault;
}

#pragma mark Perform Route

- (BOOL)canPerformCustomRoute {
    return NO;
}

- (BOOL)_canPerformWithErrorMessage:(NSString **)message {
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
            
        case ZIKViewRouteTypePresentModally:
        case ZIKViewRouteTypePresentAsPopover: {
            if (![[self class] _validateSourceNotPresentedAnyView:source]) {
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

- (void)performRouteOnDestination:(nullable id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    [self notifyRouteState:ZIKRouterStateRouting];
    
    if (!destination &&
        [[self class] _validateDestinationShouldExistInConfiguration:configuration]) {
        [self notifyRouteState:ZIKRouterStateRouteFailed];
        [self _callbackError_actionFailedWithAction:ZIKRouteActionPerformRoute errorDescription:@"-destinationWithConfiguration: of router: %@ return nil when performRoute, configuration may be invalid or router has bad impletmentation in -destinationWithConfiguration. Configuration: %@",[self class],configuration];
        return;
    } else if (![[self class] _validateDestinationClass:destination inConfiguration:configuration]) {
        [self notifyRouteState:ZIKRouterStateRouteFailed];
        [self _callbackError_actionFailedWithAction:ZIKRouteActionPerformRoute errorDescription:@"Bad impletment in destinationWithConfiguration: of router: %@, invalid destination: %@ !",[self class],destination];
        NSAssert(NO, @"Bad impletment in destinationWithConfiguration: of router: %@, invalid destination: %@ !",[self class],destination);
        return;
    }
#if ZIKROUTER_CHECK
    if ([[self class] _validateDestinationShouldExistInConfiguration:configuration]) {
        [self _validateDestinationConformance:destination];
    }
#endif
    if (![[self class] _validateRouteSourceNotMissedInConfiguration:configuration]) {
        [self notifyRouteState:ZIKRouterStateRouteFailed];
        [self _callbackError_invalidSourceWithAction:ZIKRouteActionPerformRoute
                                    errorDescription:@"Source was dealloced when performRoute on (%@)",self];
        return;
    }
    
    id source = configuration.source;
    ZIKViewRouteType routeType = configuration.routeType;
    switch (routeType) {
        case ZIKViewRouteTypePush:
            [self _performPushOnDestination:destination fromSource:source];
            break;
            
        case ZIKViewRouteTypePresentModally:
            [self _performPresentModallyOnDestination:destination fromSource:source];
            break;
            
        case ZIKViewRouteTypePresentAsPopover:
            [self _performPresentAsPopoverOnDestination:destination fromSource:source popoverConfiguration:configuration.popoverConfiguration];
            break;
            
        case ZIKViewRouteTypeAddAsChildViewController:
            [self _performAddChildViewControllerOnDestination:destination fromSource:source];
            break;
            
        case ZIKViewRouteTypePerformSegue:
            [self _performSegueWithIdentifier:configuration.segueConfiguration.identifier fromSource:source sender:configuration.segueConfiguration.sender];
            break;
            
        case ZIKViewRouteTypeShow:
            [self _performShowOnDestination:destination fromSource:source];
            break;
            
        case ZIKViewRouteTypeShowDetail:
            [self _performShowDetailOnDestination:destination fromSource:source];
            break;
            
        case ZIKViewRouteTypeAddAsSubview:
            [self _performAddSubviewOnDestination:destination fromSource:source];
            break;
            
        case ZIKViewRouteTypeCustom:
            [self _performCustomOnDestination:destination fromSource:source];
            break;
            
        case ZIKViewRouteTypeGetDestination:
            [self _performGetDestination:destination fromSource:source];
            break;
    }
}

- (void)_performPushOnDestination:(UIViewController *)destination fromSource:(UIViewController *)source {
    NSParameterAssert([destination isKindOfClass:[UIViewController class]]);
    NSParameterAssert([source isKindOfClass:[UIViewController class]]);
    
    if (![[self class] _validateSourceInNavigationStack:source]) {
        [self notifyRouteState:ZIKRouterStateRouteFailed];
        [self _callbackError_invalidSourceWithAction:ZIKRouteActionPerformRoute
                                    errorDescription:@"Source: (%@) is not in any navigation stack when perform push.",source];
        return;
    }
    if (![[self class] _validateDestination:destination notInNavigationStackOfSource:source]) {
        [self notifyRouteState:ZIKRouterStateRouteFailed];
        [self _callbackError_overRouteWithAction:ZIKRouteActionPerformRoute
                                errorDescription:@"Pushing the same view controller instance more than once is not supported. Source: (%@), destination: (%@), viewControllers in navigation stack: (%@)",source,destination,source.navigationController.viewControllers];
        return;
    }
    UIViewController *wrappedDestination = [self _wrappedDestination:destination];
    [self beginPerformRoute];
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypePush)];
    self.realRouteType = ZIKViewRouteRealTypePush;
    [source.navigationController pushViewController:wrappedDestination animated:self.original_configuration.animated];
    [ZIKViewRouter _completeWithtransitionCoordinator:source.navigationController.transitionCoordinator
                                 transitionCompletion:^{
        [self endPerformRouteWithSuccess];
    }];
}

- (void)_performPresentModallyOnDestination:(UIViewController *)destination fromSource:(UIViewController *)source {
    NSParameterAssert([destination isKindOfClass:[UIViewController class]]);
    NSParameterAssert([source isKindOfClass:[UIViewController class]]);
    
    if (![[self class] _validateSourceNotPresentedAnyView:source]) {
        [self notifyRouteState:ZIKRouterStateRouteFailed];
        [self _callbackError_invalidSourceWithAction:ZIKRouteActionPerformRoute
                                    errorDescription:@"Warning: Attempt to present %@ on %@ whose view is not in the window hierarchy! %@ already presented %@.",destination,source,source,source.presentedViewController];
        return;
    }
    if (![[self class] _validateSourceInWindowHierarchy:source]) {
        [self notifyRouteState:ZIKRouterStateRouteFailed];
        [self _callbackError_invalidSourceWithAction:ZIKRouteActionPerformRoute
                                    errorDescription:@"Warning: Attempt to present %@ on %@ whose view is not in the window hierarchy! %@ 's view not in any superview.",destination,source,source];
        return;
    }
    UIViewController *wrappedDestination = [self _wrappedDestination:destination];
    [self beginPerformRoute];
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypePresentModally)];
    self.realRouteType = ZIKViewRouteRealTypePresentModally;
    [source presentViewController:wrappedDestination animated:self.original_configuration.animated completion:^{
        [self endPerformRouteWithSuccess];
    }];
}

- (void)_performPresentAsPopoverOnDestination:(UIViewController *)destination fromSource:(UIViewController *)source popoverConfiguration:(ZIKViewRoutePopoverConfiguration *)popoverConfiguration {
    NSParameterAssert([destination isKindOfClass:[UIViewController class]]);
    NSParameterAssert([source isKindOfClass:[UIViewController class]]);
    
    if (!popoverConfiguration) {
        [self notifyRouteState:ZIKRouterStateRouteFailed];
        [self _callbackError_invalidConfigurationWithAction:ZIKRouteActionPerformRoute
                                           errorDescription:@"Miss popoverConfiguration when perform presentAsPopover on source: (%@), router: (%@).",source,self];
        return;
    }
    if (![[self class] _validateSourceNotPresentedAnyView:source]) {
        [self notifyRouteState:ZIKRouterStateRouteFailed];
        [self _callbackError_invalidSourceWithAction:ZIKRouteActionPerformRoute
                                    errorDescription:@"Warning: Attempt to present %@ on %@ whose view is not in the window hierarchy! %@ already presented %@.",destination,source,source,source.presentedViewController];
        return;
    }
    if (![[self class] _validateSourceInWindowHierarchy:source]) {
        [self notifyRouteState:ZIKRouterStateRouteFailed];
        [self _callbackError_invalidSourceWithAction:ZIKRouteActionPerformRoute
                                    errorDescription:@"Warning: Attempt to present %@ on %@ whose view is not in the window hierarchy! %@ 's view not in any superview.",destination,source,source];
        return;
    }
    
    ZIKViewRouteRealType realRouteType = ZIKViewRouteRealTypePresentAsPopover;
    ZIKViewRouteConfiguration *configuration = self.original_configuration;
    
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
            [self _callbackError_invalidConfigurationWithAction:ZIKRouteActionPerformRoute
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
        
        UIViewController *wrappedDestination = [self _wrappedDestination:destination];
        [self beginPerformRoute];
        self.realRouteType = realRouteType;
        [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypePresentAsPopover)];
        [source presentViewController:wrappedDestination animated:configuration.animated completion:^{
            [self endPerformRouteWithSuccess];
        }];
        return;
    }
    
    //iOS7 iPad
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UIViewController *wrappedDestination = [self _wrappedDestination:destination];
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
        [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypePresentAsPopover)];
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
            [self _callbackError_invalidConfigurationWithAction:ZIKRouteActionPerformRoute
                                               errorDescription:@"Invalid popoverConfiguration: (%@) when perform presentAsPopover on source: (%@), router: (%@).",popoverConfiguration,source,self];
            self.routingFromInternal = NO;
            return;
        }
        
        [ZIKViewRouter _completeWithtransitionCoordinator:popover.contentViewController.transitionCoordinator
                                     transitionCompletion:^{
            [self endPerformRouteWithSuccess];
        }];
        return;
    }
    
    //iOS7 iPhone
    UIViewController *wrappedDestination = [self _wrappedDestination:destination];
    [self beginPerformRoute];
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypePresentAsPopover)];
    self.realRouteType = ZIKViewRouteRealTypePresentModally;
    [source presentViewController:wrappedDestination animated:configuration.animated completion:^{
        [self endPerformRouteWithSuccess];
    }];
}

- (void)_performSegueWithIdentifier:(NSString *)identifier fromSource:(UIViewController *)source sender:(nullable id)sender {
    
    ZIKViewRouteConfiguration *configuration = self.original_configuration;
    ZIKViewRouteSegueConfiguration *segueConfig = configuration.segueConfiguration;
    segueConfig.segueSource = nil;
    segueConfig.segueDestination = nil;
    segueConfig.destinationStateBeforeRoute = nil;
    
    self.routingFromInternal = YES;
    //Set nil in -ZIKViewRouter_hook_prepareForSegue:sender:
    [source setZix_sourceViewRouter:self];
    
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
        [self _callbackError_segueNotPerformedWithAction:ZIKRouteActionPerformRoute errorDescription:@"destination can't perform segue identitier:%@ now",identifier];
        self.routingFromInternal = NO;
        return;
    }
#if ZIKROUTER_CHECK
    if ([self class] != [ZIKViewRouter class]) {
        [self _validateDestinationConformance:destination];
    }
#endif
    NSParameterAssert([destination isKindOfClass:[UIViewController class]]);
    NSParameterAssert([source isKindOfClass:[UIViewController class]]);
    NSAssert(![source zix_sourceViewRouter], @"Didn't set sourceViewRouter to nil in -ZIKViewRouter_hook_prepareForSegue:sender:, router will not be dealloced before source was dealloced");
}

- (void)_performShowOnDestination:(UIViewController *)destination fromSource:(UIViewController *)source {
    NSParameterAssert([destination isKindOfClass:[UIViewController class]]);
    NSParameterAssert([source isKindOfClass:[UIViewController class]]);
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypeShow)];
    UIViewController *wrappedDestination = [self _wrappedDestination:destination];
    ZIKPresentationState *destinationStateBeforeRoute = [destination zix_presentationState];
    [self beginPerformRoute];
    
    [source showViewController:wrappedDestination sender:self.original_configuration.sender];
    
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

- (void)_performShowDetailOnDestination:(UIViewController *)destination fromSource:(UIViewController *)source {
    NSParameterAssert([destination isKindOfClass:[UIViewController class]]);
    NSParameterAssert([source isKindOfClass:[UIViewController class]]);
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypeShowDetail)];
    UIViewController *wrappedDestination = [self _wrappedDestination:destination];
    ZIKPresentationState *destinationStateBeforeRoute = [destination zix_presentationState];
    [self beginPerformRoute];
    
    [source showDetailViewController:wrappedDestination sender:self.original_configuration.sender];
    
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

- (void)_performAddChildViewControllerOnDestination:(UIViewController *)destination fromSource:(UIViewController *)source {
    NSParameterAssert([destination isKindOfClass:[UIViewController class]]);
    NSParameterAssert([source isKindOfClass:[UIViewController class]]);
    UIViewController *wrappedDestination = [self _wrappedDestination:destination];
//    [self beginPerformRoute];
    self.routingFromInternal = YES;
    [self prepareForPerformRouteOnDestination:destination];
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypeAddAsChildViewController)];
    [source addChildViewController:wrappedDestination];
    
//    self.realRouteType = ZIKViewRouteRealTypeAddAsChildViewController;
    self.realRouteType = ZIKViewRouteRealTypeUnknown;
//    [self endPerformRouteWithSuccess];
    [self notifyRouteState:ZIKRouterStateRouted];
    self.routingFromInternal = NO;
    [self notifyPerformRouteSuccessWithDestination:destination];
}

- (void)_performAddSubviewOnDestination:(UIView *)destination fromSource:(UIView *)source {
    NSParameterAssert([destination isKindOfClass:[UIView class]]);
    NSParameterAssert([source isKindOfClass:[UIView class]]);
    [self beginPerformRoute];
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypeAddAsSubview)];
    
    [source addSubview:destination];
    
    self.realRouteType = ZIKViewRouteRealTypeAddAsSubview;
    [self endPerformRouteWithSuccess];
}

- (void)_performCustomOnDestination:(id)destination fromSource:(nullable id)source {
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypeCustom)];
    self.realRouteType = ZIKViewRouteRealTypeCustom;
    if ([self respondsToSelector:@selector(performCustomRouteOnDestination:fromSource:configuration:)]) {
        [self performCustomRouteOnDestination:destination fromSource:source configuration:self.original_configuration];
    } else {
        [self notifyRouteState:ZIKRouterStateRouteFailed];
        [self _callbackError_actionFailedWithAction:ZIKRouteActionPerformRoute errorDescription:@"Perform custom route but router(%@) didn't implement -performCustomRouteOnDestination:fromSource:configuration:",[self class]];
        NSAssert(NO, @"Perform custom route but router(%@) didn't implement -performCustomRouteOnDestination:fromSource:configuration:",[self class]);
    }
}

- (void)_performGetDestination:(id)destination fromSource:(nullable id)source {
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypeGetDestination)];
    self.routingFromInternal = YES;
    [self prepareForPerformRouteOnDestination:destination];
    self.stateBeforeRoute = [destination zix_presentationState];
    self.realRouteType = ZIKViewRouteRealTypeUnknown;
    [self notifyRouteState:ZIKRouterStateRouted];
    self.routingFromInternal = NO;
    [self notifyPerformRouteSuccessWithDestination:destination];
}

- (void)performCustomRouteOnDestination:(id)destination fromSource:(nullable id)source configuration:(ZIKViewRouteConfiguration *)configuration {
    NSAssert(NO, @"Subclass (%@) must override -performCustomRouteOnDestination:fromSource:configuration: to support custom route", [self class]);
}

- (UIViewController *)_wrappedDestination:(UIViewController *)destination {
    self.container = nil;
    ZIKViewRouteConfiguration *configuration = self.original_configuration;
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
        [self _callbackError_invalidContainerWithAction:ZIKRouteActionPerformRoute errorDescription:@"containerWrapper returns invalid container: %@",errorDescription];
        NSAssert(NO, @"containerWrapper returns invalid container");
        return destination;
    }
    self.container = container;
    return container;
}

+ (void)_prepareDestinationFromExternal:(id)destination router:(ZIKViewRouter *)router performer:(nullable id)performer {
    NSParameterAssert(destination);
    NSParameterAssert(router);
    
    if (![[router class] destinationPrepared:destination]) {
        if (!performer) {
            NSString *description = [NSString stringWithFormat:@"Can't find which custom UIView or UIViewController added destination:(%@) as subview, so we can't notify the performer to config the destination. You may add destination to a superview in code directly, and the superview is not a custom class. Please change your code and add subview by a custom view router with ZIKViewRouteTypeAddAsSubview. CallStack: %@",destination, [NSThread callStackSymbols]];
            [self _callbackError_invalidPerformerWithAction:ZIKRouteActionPerformRoute errorDescription:description];
            NSAssert(NO, description);
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
            [router _callbackError_invalidSourceWithAction:ZIKRouteActionPerformRoute errorDescription:@"Destination %@ 's performer :%@ missed -prepareDestinationFromExternal:configuration: to config destination.",destination, performer];
            NSAssert(NO, @"Destination %@ 's performer :%@ missed -prepareDestinationFromExternal:configuration: to config destination.",destination, performer);
        }
    }
    
    [router prepareForPerformRouteOnDestination:destination];
}

- (void)prepareForPerformRouteOnDestination:(id)destination {
    ZIKViewRouteConfiguration *configuration = self.original_configuration;
    if (configuration.prepareDestination) {
        configuration.prepareDestination(destination);
    }
    if ([self respondsToSelector:@selector(prepareDestination:configuration:)]) {
        [self prepareDestination:destination configuration:configuration];
    }
    if ([self respondsToSelector:@selector(didFinishPrepareDestination:configuration:)]) {
        [self didFinishPrepareDestination:destination configuration:configuration];
    }
}

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
            NSLog(@"⚠️Warning: segue(%@) 's destination(%@)'s state was not changed after perform route from source: %@. current state: %@. You may override %@'s -showViewController:sender:/-showDetailViewController:sender:/-presentViewController:animated:completion:/-pushViewController:animated: or use a custom segue, but didn't perform real presentation, or your presentation was async.",self,destination,source,destinationStateAfterRoute,source);
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
        completion();
        return;
    }
    [transitionCoordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        completion();
    }];
}

- (void)notifyPerformRouteSuccessWithDestination:(id)destination {
    ZIKViewRouteConfiguration *configuration = self.original_configuration;
    if (configuration.routeCompletion) {
        configuration.routeCompletion(destination);
    }
    [super notifySuccessWithAction:ZIKRouteActionPerformRoute];
}

- (void)beginPerformRoute {
    NSAssert(self.state == ZIKRouterStateRouting, @"state should be routing when begin to route.");
    self.retainedSelf = self;
    self.routingFromInternal = YES;
    id destination = self.destination;
    id source = self.original_configuration.source;
    [self prepareForPerformRouteOnDestination:destination];
    [ZIKViewRouter AOP_notifyAll_router:self willPerformRouteOnDestination:destination fromSource:source];
}

- (void)endPerformRouteWithSuccess {
    NSAssert(self.state == ZIKRouterStateRouting, @"state should be routing when end route.");
    id destination = self.destination;
    id source = self.original_configuration.source;
    [self notifyRouteState:ZIKRouterStateRouted];
    [ZIKViewRouter AOP_notifyAll_router:self didPerformRouteOnDestination:destination fromSource:source];
    self.routingFromInternal = NO;
    self.retainedSelf = nil;
    [self notifyPerformRouteSuccessWithDestination:destination];
}

- (void)endPerformRouteWithError:(NSError *)error {
    NSParameterAssert(error);
    NSAssert(self.state == ZIKRouterStateRouting, @"state should be routing when end route.");
    [self notifyRouteState:ZIKRouterStateRouteFailed];
    self.routingFromInternal = NO;
    self.retainedSelf = nil;
    [self _callbackErrorWithAction:ZIKRouteActionPerformRoute error:error];
}

//+ (ZIKViewRouteRealType)_realRouteTypeForViewController:(UIViewController *)destination {
//    ZIKViewRouteType routeType = [destination zix_routeType];
//    return [self _realRouteTypeForRouteTypeFromViewController:routeType];
//}

///routeType must from -[viewController zix_routeType]
+ (ZIKViewRouteRealType)_realRouteTypeForRouteTypeFromViewController:(ZIKViewRouteType)routeType {
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

#pragma mark Remove Route

- (BOOL)canRemove {
    NSAssert([NSThread isMainThread], @"Always check state in main thread, bacause state may change in main thread after you check the state in child thread.");
    return [self _canRemoveWithErrorMessage:NULL];
}

- (BOOL)canRemoveCustomRoute {
    return NO;
}

- (BOOL)_canRemoveWithErrorMessage:(NSString **)message {
    ZIKViewRouteConfiguration *configuration = self.original_configuration;
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
            if (![self _canPop]) {
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
            if (![self _canDismiss]) {
                [self notifyRouteState:ZIKRouterStateRemoved];
                if (message) {
                    *message = [NSString stringWithFormat:@"Router can't remove, destination is not presented when dismiss. router:%@",self];
                }
                return NO;
            }
            break;
        }
          
        case ZIKViewRouteRealTypeAddAsChildViewController: {
            if (![self _canRemoveFromParentViewController]) {
                [self notifyRouteState:ZIKRouterStateRemoved];
                if (message) {
                    *message = [NSString stringWithFormat:@"Router can't remove, doesn't have parent view controller when remove from parent. router:%@",self];
                }
                return NO;
            }
            break;
        }
            
        case ZIKViewRouteRealTypeAddAsSubview: {
            if (![self _canRemoveFromSuperview]) {
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

- (BOOL)_canPop {
    UIViewController *destination = self.destination;
    if (!destination.navigationController) {
        return NO;
    }
    return YES;
}

- (BOOL)_canDismiss {
    UIViewController *destination = self.destination;
    if (!destination.presentingViewController && /*can dismiss destination itself*/
        !destination.presentedViewController /*can dismiss destination's presentedViewController*/
        ) {
        return NO;
    }
    return YES;
}

- (BOOL)_canRemoveFromParentViewController {
    UIViewController *destination = self.destination;
    if (!destination.parentViewController) {
        return NO;
    }
    return YES;
}

- (BOOL)_canRemoveFromSuperview {
    UIView *destination = self.destination;
    if (!destination.superview) {
        return NO;
    }
    return YES;
}

- (void)removeRouteWithSuccessHandler:(void(^)(void))performerSuccessHandler
                         errorHandler:(void(^)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler {
    void(^doRemoveRoute)(void) = ^ {
        if (self.state != ZIKRouterStateRouted || !self.original_configuration) {
            [self _callbackError_errorCode:ZIKViewRouteErrorActionFailed
                              errorHandler:performerErrorHandler
                                    action:ZIKRouteActionRemoveRoute
                          errorDescription:@"State should be ZIKRouterStateRouted when removeRoute, current state:%ld, configuration:%@",self.state,self.original_configuration];
            return;
        }
        NSString *errorMessage;
        if (![self _canRemoveWithErrorMessage:&errorMessage]) {
            NSString *description = [NSString stringWithFormat:@"%@, configuration:%@",errorMessage,self.original_configuration];
            [self _callbackError_actionFailedWithAction:ZIKRouteActionRemoveRoute
                                       errorDescription:description];
            if (performerErrorHandler) {
                performerErrorHandler(ZIKRouteActionRemoveRoute,[[self class] errorWithCode:ZIKViewRouteErrorActionFailed localizedDescription:description]);
            }
            return;
        }
        
        [super removeRouteWithSuccessHandler:performerSuccessHandler errorHandler:performerErrorHandler];
    };
    
    if ([NSThread isMainThread]) {
        doRemoveRoute();
    } else {
        NSAssert(NO, @"%@ removeRoute should only be called in main thread!",self);
        dispatch_sync(dispatch_get_main_queue(), ^{
            doRemoveRoute();
        });
    }
}

- (void)removeDestination:(id)destination removeConfiguration:(__kindof ZIKRemoveRouteConfiguration *)removeConfiguration {
    [self notifyRouteState:ZIKRouterStateRemoving];
    if (!destination) {
        [self notifyRouteState:ZIKRouterStateRemoveFailed];
        [self _callbackError_actionFailedWithAction:ZIKRouteActionRemoveRoute
                                   errorDescription:@"Destination was deallced when removeRoute, router:%@",self];
        return;
    }
    
    if (removeConfiguration.prepareDestination) {
        removeConfiguration.prepareDestination(destination);
    }
    ZIKViewRouteConfiguration *configuration = self.original_configuration;
    if (configuration.routeType == ZIKViewRouteTypeCustom) {
        [self removeCustomRouteOnDestination:destination
                                  fromSource:self.original_configuration.source
                         removeConfiguration:self.original_removeConfiguration
                               configuration:configuration];
        return;
    }
    ZIKViewRouteRealType realRouteType = self.realRouteType;
    NSString *errorDescription;
    
    switch (realRouteType) {
        case ZIKViewRouteRealTypePush:
            [self _popOnDestination:destination];
            break;
            
        case ZIKViewRouteRealTypePresentModally:
            [self _dismissOnDestination:destination];
            break;
            
        case ZIKViewRouteRealTypePresentAsPopover:
            [self _dismissPopoverOnDestination:destination];
            break;
            
        case ZIKViewRouteRealTypeAddAsChildViewController:
            [self _removeFromParentViewControllerOnDestination:destination];
            break;
            
        case ZIKViewRouteRealTypeAddAsSubview:
            [self _removeFromSuperviewOnDestination:destination];
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
        [self _callbackError_actionFailedWithAction:ZIKRouteActionRemoveRoute
                                   errorDescription:errorDescription];
    }
}

- (void)_popOnDestination:(UIViewController *)destination {
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypePush)];
    UIViewController *source = destination.navigationController.visibleViewController;
    [self beginRemoveRouteFromSource:source];
    
    UINavigationController *navigationController;
    if (self.container.navigationController) {
        navigationController = self.container.navigationController;
    } else {
        navigationController = destination.navigationController;
    }
    UIViewController *popTo = (UIViewController *)self.original_configuration.source;
    
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

- (void)_dismissOnDestination:(UIViewController *)destination {
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypePresentModally)];
    UIViewController *source = destination.presentingViewController;
    [self beginRemoveRouteFromSource:source];
    
    [destination dismissViewControllerAnimated:self.original_removeConfiguration.animated completion:^{
        [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
    }];
}

- (void)_dismissPopoverOnDestination:(UIViewController *)destination {
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypePresentAsPopover)];
    UIViewController *source = destination.presentingViewController;
    [self beginRemoveRouteFromSource:source];
    
    if (NSClassFromString(@"UIPopoverPresentationController") ||
        [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) {
        [destination dismissViewControllerAnimated:self.original_removeConfiguration.animated completion:^{
            [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
        }];
        return;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    UIPopoverController *popover = objc_getAssociatedObject(destination, "zikrouter_popover");
#pragma clang diagnostic pop
    if (!popover) {
        NSAssert(NO, @"Didn't set UIPopoverController to destination in -_performPresentAsPopoverOnDestination:fromSource:popoverConfiguration:");
        [destination dismissViewControllerAnimated:self.original_removeConfiguration.animated completion:^{
            [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
        }];
        return;
    }
    [popover dismissPopoverAnimated:self.original_removeConfiguration.animated];
    [ZIKViewRouter _completeWithtransitionCoordinator:destination.transitionCoordinator
                                 transitionCompletion:^{
        [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
    }];
}

- (void)_removeFromParentViewControllerOnDestination:(UIViewController *)destination {
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypeAddAsChildViewController)];
    
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
        [destination setZix_routeTypeFromRouter:nil];
    }
}

- (void)_removeFromSuperviewOnDestination:(UIView *)destination {
    NSAssert(destination.superview, @"Destination doesn't have superview when remove from superview.");
    [destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypeAddAsSubview)];
    UIView *source = destination.superview;
    [self beginRemoveRouteFromSource:source];
    
    [destination removeFromSuperview];
    
    [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
}

- (void)removeCustomRouteOnDestination:(id)destination fromSource:(nullable id)source removeConfiguration:(ZIKViewRemoveConfiguration *)removeConfiguration configuration:(ZIKViewRouteConfiguration *)configuration {
    [self notifyRouteState:ZIKRouterStateRemoveFailed];
    [self _callbackError_actionFailedWithAction:ZIKRouteActionRemoveRoute errorDescription:@"Remove custom route but router(%@) didn't implement -removeCustomRouteOnDestination:fromSource:removeConfiguration:configuration:",[self class]];
    NSAssert(NO, @"Subclass (%@) must override -removeCustomRouteOnDestination:fromSource:configuration: to support removing custom route.",[self class]);
}

- (void)notifyRemoveRouteSuccess {
    [super notifySuccessWithAction:ZIKRouteActionRemoveRoute];
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
    NSAssert(self.state == ZIKRouterStateRemoving, @"state should be removing when end remove.");
    [self notifyRouteState:ZIKRouterStateRemoved];
    [self notifyRemoveRouteSuccess];
    if ([destination conformsToProtocol:@protocol(ZIKRoutableView)]) {
        [ZIKViewRouter AOP_notifyAll_router:self didRemoveRouteOnDestination:destination fromSource:source];
    } else {
        NSAssert([self isMemberOfClass:[ZIKViewRouter class]] && self.original_configuration.routeType == ZIKViewRouteTypePerformSegue, @"Only ZIKViewRouteTypePerformSegue's destination can not conform to ZIKRoutableView");
    }
    self.routingFromInternal = NO;
    self.container = nil;
    self.retainedSelf = nil;
}

- (void)endRemoveRouteWithError:(NSError *)error {
    NSParameterAssert(error);
    NSAssert(self.state == ZIKRouterStateRemoving, @"state should be removing when end remove.");
    [self notifyRouteState:ZIKRouterStateRemoveFailed];
    [self _callbackErrorWithAction:ZIKRouteActionRemoveRoute error:error];
    self.routingFromInternal = NO;
    self.retainedSelf = nil;
}

#pragma mark AOP

static void _enumerateRoutersForViewClass(Class viewClass,void(^handler)(Class routerClass)) {
    NSCParameterAssert(_isClassRoutable(viewClass));
    NSCParameterAssert(handler);
    if (!viewClass) {
        return;
    }
    Class UIViewControllerSuperclass = [UIViewController superclass];
    CFDictionaryRef destinationToRoutersMap = ZIKViewRouteRegistry.destinationToRoutersMap;
    while (viewClass != UIViewControllerSuperclass) {
        
        if (_isClassRoutable(viewClass)) {
            CFMutableSetRef routers = (CFMutableSetRef)CFDictionaryGetValue(destinationToRoutersMap, (__bridge const void *)(viewClass));
            NSSet *routerClasses = (__bridge NSSet *)(routers);
            for (Class class in routerClasses) {
                if (handler) {
                    handler(class);
                }
            }
        } else {
            break;
        }
        viewClass = class_getSuperclass(viewClass);
    }
}

+ (void)AOP_notifyAll_router:(nullable ZIKViewRouter *)router willPerformRouteOnDestination:(id)destination fromSource:(nullable id)source {
    NSParameterAssert([destination conformsToProtocol:@protocol(ZIKRoutableView)]);
    _enumerateRoutersForViewClass([destination class], ^(__unsafe_unretained Class routerClass) {
        if ([routerClass respondsToSelector:@selector(router:willPerformRouteOnDestination:fromSource:)]) {
            [routerClass router:router willPerformRouteOnDestination:destination fromSource:source];
        }
    });
}

+ (void)AOP_notifyAll_router:(nullable ZIKViewRouter *)router didPerformRouteOnDestination:(id)destination fromSource:(nullable id)source {
    NSParameterAssert([destination conformsToProtocol:@protocol(ZIKRoutableView)]);
    _enumerateRoutersForViewClass([destination class], ^(__unsafe_unretained Class routerClass) {
        if ([routerClass respondsToSelector:@selector(router:didPerformRouteOnDestination:fromSource:)]) {
            [routerClass router:router didPerformRouteOnDestination:destination fromSource:source];
        }
    });
}

+ (void)AOP_notifyAll_router:(nullable ZIKViewRouter *)router willRemoveRouteOnDestination:(id)destination fromSource:(nullable id)source {
    NSParameterAssert([destination conformsToProtocol:@protocol(ZIKRoutableView)]);
    _enumerateRoutersForViewClass([destination class], ^(__unsafe_unretained Class routerClass) {
        if ([routerClass respondsToSelector:@selector(router:willRemoveRouteOnDestination:fromSource:)]) {
            [routerClass router:router willRemoveRouteOnDestination:destination fromSource:(id)source];
        }
    });
}

+ (void)AOP_notifyAll_router:(nullable ZIKViewRouter *)router didRemoveRouteOnDestination:(id)destination fromSource:(nullable id)source {
    NSParameterAssert([destination conformsToProtocol:@protocol(ZIKRoutableView)]);
    _enumerateRoutersForViewClass([destination class], ^(__unsafe_unretained Class routerClass) {
        if ([routerClass respondsToSelector:@selector(router:didRemoveRouteOnDestination:fromSource:)]) {
            [routerClass router:router didRemoveRouteOnDestination:destination fromSource:(id)source];
        }
    });
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
 
 ZIKViewRouter hooks these methods for AOP and storyboard. In -willMoveToSuperview, -willMoveToWindow:, -prepareForSegue:sender:, it detects if the view is registered with a router, and auto create a router if it's not routed from it's router.
 */

///Update state when route action is not performed from router
- (void)_handleWillPerformRouteNotification:(NSNotification *)note {
    id destination = note.object;
    if (!self.destination || self.destination != destination) {
        return;
    }
    ZIKRouterState state = self.state;
    if (!self.routingFromInternal && state != ZIKRouterStateRouting) {
        ZIKViewRouteConfiguration *configuration = self.original_configuration;
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

- (void)_handleDidPerformRouteNotification:(NSNotification *)note {
    id destination = note.object;
    if (!self.destination || self.destination != destination) {
        return;
    }
    if (self.stateBeforeRoute &&
        self.original_configuration.routeType == ZIKViewRouteTypeGetDestination) {
        NSAssert(self.realRouteType == ZIKViewRouteRealTypeUnknown, @"real route type is unknown before destination is real routed");
        ZIKPresentationState *stateBeforeRoute = self.stateBeforeRoute;
        ZIKViewRouteDetailType detailRouteType = [ZIKPresentationState detailRouteTypeFromStateBeforeRoute:stateBeforeRoute stateAfterRoute:[destination zix_presentationState]];
        self.realRouteType = [ZIKViewRouter _realRouteTypeFromDetailType:detailRouteType];
        self.stateBeforeRoute = nil;
    }
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
        if (state != ZIKRouterStateRemoved ||
            (self.stateBeforeRoute &&
             self.original_configuration.routeType == ZIKViewRouteTypeGetDestination)) {
                [self notifyRouteState:ZIKRouterStateRemoving];//not performed from router (dealed by system, or your code)
            }
    }
    if (state == ZIKRouterStateRouting) {
        [self _callbackError_unbalancedTransitionWithAction:ZIKRouteActionRemoveRoute errorDescription:@"Unbalanced calls to begin/end appearance transitions for destination. This error occurs when you try and display a view controller before the current view controller is finished displaying. This may cause the UIViewController skips or messes up the order calling -viewWillAppear:, -viewDidAppear:, -viewWillDisAppear: and -viewDidDisappear:, and messes up the route state. Current error reason is trying to remove route on destination when destination is routing, router:(%@), callStack:%@",self,[NSThread callStackSymbols]];
    }
}

- (void)_handleDidRemoveRouteNotification:(NSNotification *)note {
    id destination = note.object;
    if (!self.destination || self.destination != destination) {
        return;
    }
    if (self.stateBeforeRoute &&
        self.original_configuration.routeType == ZIKViewRouteTypeGetDestination) {
        NSAssert(self.realRouteType == ZIKViewRouteRealTypeUnknown, @"real route type is unknown before destination is real routed");
        ZIKPresentationState *stateBeforeRoute = self.stateBeforeRoute;
        ZIKViewRouteDetailType detailRouteType = [ZIKPresentationState detailRouteTypeFromStateBeforeRoute:stateBeforeRoute stateAfterRoute:[destination zix_presentationState]];
        self.realRouteType = [ZIKViewRouter _realRouteTypeFromDetailType:detailRouteType];
        self.stateBeforeRoute = nil;
    }
    if (!self.routingFromInternal &&
        self.state != ZIKRouterStateRemoved) {
        [self notifyRouteState:ZIKRouterStateRemoved];//not performed from router (dealed by system, or your code)
        if (self.original_removeConfiguration.handleExternalRoute) {
            [self notifyRemoveRouteSuccess];
        }
    }
}

- (void)_handleRemoveRouteCanceledNotification:(NSNotification *)note {
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

static _Nullable Class _routerClassToRegisteredView(Class viewClass) {
    NSCParameterAssert([viewClass isSubclassOfClass:[UIView class]] ||
                       [viewClass isSubclassOfClass:[UIViewController class]]);
    NSCParameterAssert(_isClassRoutable(viewClass));
    NSCAssert(ZIKViewRouteRegistry.autoRegistrationFinished, @"Only get router after app did finish launch.");
    CFDictionaryRef destinationToDefaultRouterMap = ZIKViewRouteRegistry.destinationToDefaultRouterMap;
    while (viewClass) {
        if (!_isClassRoutable(viewClass)) {
            break;
        }
        Class routerClass = CFDictionaryGetValue(destinationToDefaultRouterMap, (__bridge const void *)(viewClass));
        if (routerClass) {
            return routerClass;
        } else {
            viewClass = class_getSuperclass(viewClass);
        }
    }
    
    NSCAssert1(NO, @"Didn't register any routerClass for viewClass (%@).",viewClass);
    return nil;
}

- (void)ZIKViewRouter_hook_willMoveToParentViewController:(UIViewController *)parent {
    [self ZIKViewRouter_hook_willMoveToParentViewController:parent];
    if (parent) {
        [(UIViewController *)self setZix_parentMovingTo:parent];
    } else {
        UIViewController *currentParent = [(UIViewController *)self parentViewController];
        NSAssert(currentParent, @"currentParent shouldn't be nil when removing from parent");
        [(UIViewController *)self setZix_parentRemovingFrom:currentParent];
    }
}

- (void)ZIKViewRouter_hook_didMoveToParentViewController:(UIViewController *)parent {
    [self ZIKViewRouter_hook_didMoveToParentViewController:parent];
    if (parent) {
//        NSAssert([(UIViewController *)self zix_parentMovingTo] ||
//                 [(UIViewController *)self zix_isRootViewControllerInContainer], @"parentMovingTo should be set in -ZIKViewRouter_hook_willMoveToParentViewController:. But if a container is from storyboard, it's not created with initWithRootViewController:, so rootViewController may won't call willMoveToParentViewController: before didMoveToParentViewController:.");
        
        [(UIViewController *)self setZix_parentMovingTo:nil];
    } else {
        //If you do removeFromSuperview before removeFromParentViewController, -didMoveToParentViewController:nil in child view controller may be called twice.
        //        NSAssert([(UIViewController *)self zix_parentRemovingFrom], @"RemovingFrom should be set in -ZIKViewRouter_hook_willMoveToParentViewController.");
        
        [(UIViewController *)self setZix_parentRemovingFrom:nil];
    }
}

- (void)ZIKViewRouter_hook_viewWillAppear:(BOOL)animated {
    UIViewController *destination = (UIViewController *)self;
    BOOL removing = destination.zix_removing;
    BOOL isRoutableView = ([self conformsToProtocol:@protocol(ZIKRoutableView)] == YES);
    if (removing) {
        [destination setZix_removing:NO];
        if (isRoutableView) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteRemoveRouteCanceledNotification object:destination];
        }
    }
    if (isRoutableView) {
        BOOL routed = [(UIViewController *)self zix_routed];
        if (!routed) {
            UIViewController *parentMovingTo = [(UIViewController *)self zix_parentMovingTo];
            [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteWillPerformRouteNotification object:destination];
            NSNumber *routeTypeFromRouter = [destination zix_routeTypeFromRouter];
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
    BOOL routed = [(UIViewController *)self zix_routed];
    UIViewController *parentMovingTo = [(UIViewController *)self zix_parentMovingTo];
    if (!routed &&
        [self conformsToProtocol:@protocol(ZIKRoutableView)]) {
        UIViewController *destination = (UIViewController *)self;
        [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteDidPerformRouteNotification object:destination];
        NSNumber *routeTypeFromRouter = [destination zix_routeTypeFromRouter];//This destination is routing from router
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
                    [routeTypeFromRouter integerValue] == ZIKViewRouteTypeGetDestination) {
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
                [routeTypeFromRouter integerValue] == ZIKViewRouteTypeGetDestination) {
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
    } else if (ZIKRouter_classIsCustomClass([destination class])) {
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
            [ZIKViewRouter _callbackGlobalErrorHandlerWithRouter:nil action:ZIKRouteActionRemoveRoute error:[ZIKViewRouter errorWithCode:ZIKViewRouteErrorUnbalancedTransition localizedDescriptionFormat:@"Unbalanced calls to begin/end appearance transitions for destination. This error occurs when you try and display a view controller before the current view controller is finished displaying. This may cause the UIViewController skips or messes up the order calling -viewWillAppear:, -viewDidAppear:, -viewWillDisAppear: and -viewDidDisappear:, and messes up the route state. Current error reason is already removed destination but destination appears again before -viewDidDisappear:, router:(%@), callStack:%@",self,[NSThread callStackSymbols]]];
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
            id performer = [destination zix_routePerformer];
            if (performer) {
                [ZIKViewRouter _prepareDestinationFromExternal:destination router:router performer:performer];
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

///Add subview by code or storyboard will auto create a corresponding router. We assume it's superview's view controller is the performer. If your custom class view use a routable view as it's part, the custom view should use a router to add and prepare the routable view, then the routable view don't need to search performer.

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
            ZIKViewRouter *destinationRouter = [destination zix_destinationViewRouter];
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
                    ![destination zix_firstAvailableUIViewController]) {
                    //end perform
                    [ZIKViewRouter AOP_notifyAll_router:destinationRouter willPerformRouteOnDestination:destination fromSource:destination.superview];
                    [destinationRouter endPerformRouteWithSuccess];
                }
                [destination setZix_destinationViewRouter:nil];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteWillRemoveRouteNotification object:destination];
            NSNumber *routeTypeFromRouter = [destination zix_routeTypeFromRouter];
            if (!routeTypeFromRouter ||
                [routeTypeFromRouter integerValue] == ZIKViewRouteTypeGetDestination) {
                [ZIKViewRouter AOP_notifyAll_router:nil willRemoveRouteOnDestination:destination fromSource:destination.superview];
            }
        } else if (!destination.zix_routed) {
            //Adding to a superview
            ZIKViewRouter *router;
            NSNumber *routeTypeFromRouter = [destination zix_routeTypeFromRouter];
            if (!routeTypeFromRouter) {
                //Not routing from router
                Class routerClass = _routerClassToRegisteredView([destination class]);
                NSAssert([routerClass isSubclassOfClass:[ZIKViewRouter class]], @"Router should be subclass of ZIKViewRouter.");
                NSAssert([routerClass _validateSupportedRouteTypesForUIView], @"Router for UIView only suppourts ZIKViewRouteTypeAddAsSubview, ZIKViewRouteTypeGetDestination and ZIKViewRouteTypeCustom, override +supportedRouteTypes in your router.");
                
                id performer = nil;
                BOOL needPrepare = NO;
                if (![routerClass destinationPrepared:destination]) {
                    needPrepare = YES;
                    if (destination.nextResponder) {
                        performer = [destination zix_routePerformer];
                    } else if (newSuperview.nextResponder) {
                        performer = [newSuperview zix_routePerformer];
                    }
                    //Adding to a superview on screen.
                    if (!performer && (newSuperview.window || [newSuperview isKindOfClass:[UIWindow class]])) {
                        NSString *description = [NSString stringWithFormat:@"Adding to a superview on screen. Can't find which custom UIView or UIViewController added destination:(%@) as subview, so we can't notify the performer to config the destination. You may add destination to a UIWindow in code directly. Please fix your code and add subview by a custom view router with ZIKViewRouteTypeAddAsSubview. Destination superview: (%@).",destination, newSuperview];
                        [ZIKViewRouter _callbackError_invalidPerformerWithAction:ZIKRouteActionPerformRoute errorDescription:description];
                        NSAssert(NO, description);
                    }
                }
                
                ZIKViewRouter *destinationRouter = [routerClass routerFromView:destination source:newSuperview];
                destinationRouter.routingFromInternal = YES;
                [destinationRouter notifyRouteState:ZIKRouterStateRouting];
                [destination setZix_destinationViewRouter:destinationRouter];
                if (needPrepare) {
                    if (performer) {
                        [ZIKViewRouter _prepareDestinationFromExternal:destination router:destinationRouter performer:performer];
                        destinationRouter.prepared = YES;
                    } else {
                        if (!newSuperview.window && ![newSuperview isKindOfClass:[UIWindow class]]) {
                            //Adding to a superview not on screen, can't search performer before -viewDidLoad. willMoveToSuperview: is called before willMoveToWindow:. Find performer and prepare in -ZIKViewRouter_hook_viewDidLoad, do willPerformRoute AOP in -ZIKViewRouter_hook_willMoveToWindow:
                            [g_preparingUIViewRouters addObject:destinationRouter];
                        }
                        NSAssert1(!newSuperview.window && ![newSuperview isKindOfClass:[UIWindow class]], @"When new superview is already on screen, performer should not be nil.You may add destination to a system UIViewController in code directly. Please fix your code and add subview by a custom view router with ZIKViewRouteTypeAddAsSubview. Destination superview: (%@).",newSuperview);
                    }
                } else {
                    [destinationRouter prepareDestination:destination configuration:destinationRouter.original_configuration];
                    [destinationRouter didFinishPrepareDestination:destination configuration:destinationRouter.original_configuration];
                    destinationRouter.prepared = YES;
                }
                router = destinationRouter;
                
                //Adding to a superview on screen.
                if (newSuperview.window || [newSuperview isKindOfClass:[UIWindow class]]) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteWillPerformRouteNotification object:destination];
                    NSNumber *routeTypeFromRouter = [destination zix_routeTypeFromRouter];
                    if (!routeTypeFromRouter ||
                        [routeTypeFromRouter integerValue] == ZIKViewRouteTypeGetDestination) {
                        [ZIKViewRouter AOP_notifyAll_router:router willPerformRouteOnDestination:destination fromSource:newSuperview];
                    }
                }
            }
        }
    }
    if (!newSuperview) {
//        NSAssert(destination.zix_routed == YES, @"zix_routed should be YES before remove");
        [destination setZix_routed:NO];
    }
    [self ZIKViewRouter_hook_willMoveToSuperview:newSuperview];
}

- (void)ZIKViewRouter_hook_didMoveToSuperview {
    UIView *destination = (UIView *)self;
    UIView *superview = destination.superview;
    if ([self conformsToProtocol:@protocol(ZIKRoutableView)]) {
        if (!superview) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteDidRemoveRouteNotification object:destination];
            NSNumber *routeTypeFromRouter = [destination zix_routeTypeFromRouter];
            if (!routeTypeFromRouter ||
                [routeTypeFromRouter integerValue] == ZIKViewRouteTypeGetDestination) {
                [ZIKViewRouter AOP_notifyAll_router:nil didRemoveRouteOnDestination:destination fromSource:nil];//Can't get source, source may already be dealloced here or is in dealloc
            }
            if (routeTypeFromRouter) {
                [destination setZix_routeTypeFromRouter:nil];
            }
        }
    }
    
    [self ZIKViewRouter_hook_didMoveToSuperview];
}

- (void)ZIKViewRouter_hook_willMoveToWindow:(nullable UIWindow *)newWindow {
    UIView *destination = (UIView *)self;
    BOOL routed = destination.zix_routed;
    if ([self conformsToProtocol:@protocol(ZIKRoutableView)]) {
        if (!routed) {
            ZIKViewRouter *router;
            UIView *source;
            NSNumber *routeTypeFromRouter = [destination zix_routeTypeFromRouter];
            BOOL searchPerformerInDidMoveToWindow = NO;
            if (!routeTypeFromRouter) {
                ZIKViewRouter *destinationRouter = [destination zix_destinationViewRouter];
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
                    Class routerClass = _routerClassToRegisteredView([destination class]);
                    NSAssert([routerClass isSubclassOfClass:[ZIKViewRouter class]], @"Router should be subclass of ZIKViewRouter.");
                    NSAssert([routerClass _validateSupportedRouteTypesForUIView], @"Router for UIView only suppourts ZIKViewRouteTypeAddAsSubview, ZIKViewRouteTypeGetDestination and ZIKViewRouteTypeCustom, override +supportedRouteTypes in your router.");
                    
                    source = destination.superview;
                    
                    if (!destinationRouter) {
                        destinationRouter = [routerClass routerFromView:destination source:source];
                        destinationRouter.routingFromInternal = YES;
                        [destinationRouter notifyRouteState:ZIKRouterStateRouting];
                        [destination setZix_destinationViewRouter:destinationRouter];
                    }
                    
                    if (!destinationRouter.prepared) {
                        id performer = nil;
                        BOOL needPrepare = NO;
                        BOOL onScreen = NO;
                        if (![routerClass destinationPrepared:destination]) {
                            needPrepare = YES;
                            onScreen = ([destination zix_firstAvailableUIViewController] != nil);
                            
                            if (onScreen) {
                                performer = [destination zix_routePerformer];
                            }
                            
                            if (onScreen) {
                                if (!performer) {
                                    NSString *description;
                                    if (failedToPrepareDescription) {
                                        description = failedToPrepareDescription;
                                    } else {
                                        description = [NSString stringWithFormat:@"Can't find which custom UIView or UIViewController added destination:(%@) as subview, so we can't notify the performer to config the destination. You may add destination to a UIWindow in code directly, and the UIWindow is not a custom class. Please change your code and add subview by a custom view router with ZIKViewRouteTypeAddAsSubview. Destination superview: %@.",destination, destination.superview];
                                    }
                                    [ZIKViewRouter _callbackError_invalidPerformerWithAction:ZIKRouteActionPerformRoute errorDescription:description];
                                    NSAssert(NO, description);
                                }
                                NSAssert(ZIKRouter_classIsCustomClass(performer), @"performer should be a subclass of UIViewController in your project.");
                            }
                        }
                        if (onScreen) {
                            if (needPrepare) {
                                [ZIKViewRouter _prepareDestinationFromExternal:destination router:destinationRouter performer:performer];
                            } else {
                                [destinationRouter prepareDestination:destination configuration:destinationRouter.original_configuration];
                                [destinationRouter didFinishPrepareDestination:destination configuration:destinationRouter.original_configuration];
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
    BOOL routed = destination.zix_routed;
    if ([self conformsToProtocol:@protocol(ZIKRoutableView)]) {
        if (!routed) {
            ZIKViewRouter *router;
            NSNumber *routeTypeFromRouter = [destination zix_routeTypeFromRouter];
            if (!routeTypeFromRouter) {
                ZIKViewRouter *destinationRouter = destination.zix_destinationViewRouter;
                NSAssert(destinationRouter, @"destinationRouter should be set in -ZIKViewRouter_hook_willMoveToSuperview:");
                router = destinationRouter;
                
                //Find performer and prepare for destination added to a superview not on screen in -ZIKViewRouter_hook_willMoveToSuperview
                if (g_preparingUIViewRouters.count > 0) {
                    if ([g_preparingUIViewRouters containsObject:destinationRouter]) {
                        [g_preparingUIViewRouters removeObject:destinationRouter];
                        id performer = [destination zix_routePerformer];
                        if (performer) {
                            [ZIKViewRouter _prepareDestinationFromExternal:destination router:destinationRouter performer:performer];
                            router.prepared = YES;
                            
                        } else {
                            NSString *description = [NSString stringWithFormat:@"Didn't find performer when UIView is already on screen. Can't find which custom UIView or UIViewController added destination:(%@) as subview, so we can't notify the performer to config the destination. You may add destination to a UIWindow in code directly, and the UIWindow is not a custom class. Please change your code and add subview by a custom view router with ZIKViewRouteTypeAddAsSubview. Destination superview: %@.",destination, destination.superview];
                            [ZIKViewRouter _callbackError_invalidPerformerWithAction:ZIKRouteActionPerformRoute errorDescription:description];
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
                [destination setZix_destinationViewRouter:nil];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kZIKViewRouteDidPerformRouteNotification object:destination];
            if (!routeTypeFromRouter ||
                [routeTypeFromRouter integerValue] == ZIKViewRouteTypeGetDestination) {
                [ZIKViewRouter AOP_notifyAll_router:router didPerformRouteOnDestination:destination fromSource:superview];
            }
            if (routeTypeFromRouter) {
                [destination setZix_routeTypeFromRouter:nil];
            }
            if (router) {
                router.routingFromInternal = NO;
                [router notifyPerformRouteSuccessWithDestination:destination];
            }
        }
    }
    
    [self ZIKViewRouter_hook_didMoveToWindow];
    if (!routed && window) {
        [destination setZix_routed:YES];
    }
}

///Auto prepare storyboard's routable initial view controller or it's routable child view controllers
- (nullable __kindof UIViewController *)ZIKViewRouter_hook_instantiateInitialViewController {
    UIViewController *initialViewController = [self ZIKViewRouter_hook_instantiateInitialViewController];
    
    NSMutableArray<UIViewController *> *routableViews;
    if ([initialViewController conformsToProtocol:@protocol(ZIKRoutableView)]) {
        routableViews = [NSMutableArray arrayWithObject:initialViewController];
    }
    NSArray<UIViewController *> *childViews = [ZIKViewRouter routableViewsInContainerViewController:initialViewController];
    if (childViews.count > 0) {
        if (routableViews == nil) {
            routableViews = [NSMutableArray array];
        }
        [routableViews addObjectsFromArray:childViews];
    }
    for (UIViewController *destination in routableViews) {
        Class routerClass = _routerClassToRegisteredView([destination class]);
        NSAssert([routerClass isSubclassOfClass:[ZIKViewRouter class]], @"Destination's view router should be subclass of ZIKViewRouter");
        [routerClass prepareDestination:destination configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
            
        }];
    }
    return initialViewController;
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
    Class currentClassCalling = [(UIViewController *)self zix_currentClassCallingPrepareForSegue];
    if (!currentClassCalling) {
        currentClassCalling = [self class];
    }
    [(UIViewController *)self setZix_currentClassCallingPrepareForSegue:[currentClassCalling superclass]];
    
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
    
    //The router performing route for this view controller
    ZIKViewRouter *sourceRouter = [(UIViewController *)self zix_sourceViewRouter];
    if (sourceRouter) {
        //This segue is performed from router, see -_performSegueWithIdentifier:fromSource:sender:
        ZIKViewRouteSegueConfiguration *configuration = [(ZIKViewRouteConfiguration *)sourceRouter.original_configuration segueConfiguration];
        if (!configuration.segueSource) {
            NSAssert([segue.identifier isEqualToString:configuration.identifier], @"should be same identifier");
            [sourceRouter attachDestination:destination];
            configuration.segueSource = source;
            configuration.segueDestination = destination;
            configuration.destinationStateBeforeRoute = [destination zix_presentationState];
            if (isUnwindSegue) {
                sourceRouter.realRouteType = ZIKViewRouteRealTypeUnwind;
            }
        }
        
        [(UIViewController *)self setZix_sourceViewRouter:nil];
        [source setZix_sourceViewRouter:sourceRouter];//Set nil in -ZIKViewRouter_hook_seguePerform
    }
    
    //The sourceRouter and routers for child view controllers conform to ZIKRoutableView in destination
    NSMutableArray<ZIKViewRouter *> *destinationRouters;
    NSMutableArray<UIViewController *> *routableViews;
    
    if (!isUnwindSegue) {
        destinationRouters = [NSMutableArray array];
        if ([destination conformsToProtocol:@protocol(ZIKRoutableView)]) {//if destination is ZIKRoutableView, create router for it
            if (sourceRouter && [(ZIKViewRouteConfiguration *)sourceRouter.original_configuration segueConfiguration].segueDestination == destination) {
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
                Class routerClass = _routerClassToRegisteredView([routableView class]);
                NSAssert([routerClass isSubclassOfClass:[ZIKViewRouter class]], @"Destination's view router should be subclass of ZIKViewRouter");
                ZIKViewRouter *destinationRouter = [routerClass routerFromSegueIdentifier:segue.identifier sender:sender destination:routableView source:(UIViewController *)self];
                destinationRouter.routingFromInternal = YES;
                ZIKViewRouteSegueConfiguration *segueConfig = [(ZIKViewRouteConfiguration *)destinationRouter.original_configuration segueConfiguration];
                NSAssert(destinationRouter && segueConfig, @"Failed to create router.");
                segueConfig.destinationStateBeforeRoute = [routableView zix_presentationState];
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
    [(UIViewController *)self setZix_currentClassCallingPrepareForSegue:nil];
    
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
        UIViewController * routableView = router.destination;
        NSAssert(routableView, @"Destination wasn't set when create destinationRouters");
        [routableView setZix_routeTypeFromRouter:@(ZIKViewRouteTypePerformSegue)];
        [router notifyRouteState:ZIKRouterStateRouting];
        if (sourceRouter) {
            //Segue is performed from a router
            [router prepareForPerformRouteOnDestination:routableView];
        } else {
            //View controller is from storyboard, need to notify the performer of segue to config the destination
            [ZIKViewRouter _prepareDestinationFromExternal:routableView router:router performer:(UIViewController *)self];
        }
        [ZIKViewRouter AOP_notifyAll_router:router willPerformRouteOnDestination:routableView fromSource:source];
    }
}

- (void)ZIKViewRouter_hook_seguePerform {
    Class currentClassCalling = [(UIStoryboardSegue *)self zix_currentClassCallingPerform];
    if (!currentClassCalling) {
        currentClassCalling = [self class];
    }
    [(UIStoryboardSegue *)self setZix_currentClassCallingPerform:[currentClassCalling superclass]];
    
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
    ZIKViewRouter *sourceRouter = [source zix_sourceViewRouter];//Was set in -ZIKViewRouter_hook_prepareForSegue:sender:
    NSArray<ZIKViewRouter *> *destinationRouters = [destination zix_destinationViewRouters];
    
    //Call original implementation of current class
    [self ZIKViewRouter_hook_seguePerform];
    [(UIStoryboardSegue *)self setZix_currentClassCallingPerform:nil];
    
    if (destinationRouters.count > 0) {
        [destination setZix_destinationViewRouters:nil];
    }
    if (sourceRouter) {
        [source setZix_sourceViewRouter:nil];
    }
    
    id <UIViewControllerTransitionCoordinator> transitionCoordinator = [source zix_currentTransitionCoordinator];
    if (!transitionCoordinator) {
        transitionCoordinator = [destination zix_currentTransitionCoordinator];
    }
    if (sourceRouter) {
        //Complete unwind route. Unwind route doesn't need to config destination
        if (sourceRouter.realRouteType == ZIKViewRouteRealTypeUnwind &&
            [(ZIKViewRouteConfiguration *)sourceRouter.original_configuration segueConfiguration].segueDestination == destination) {
            [ZIKViewRouter _completeWithtransitionCoordinator:transitionCoordinator transitionCompletion:^{
                [sourceRouter notifyRouteState:ZIKRouterStateRouted];
                sourceRouter.routingFromInternal = NO;
                [sourceRouter notifyPerformRouteSuccessWithDestination:destination];
            }];
            return;
        }
    }
    
    //Complete routable views
    for (NSInteger idx = 0; idx < destinationRouters.count; idx++) {
        ZIKViewRouter *router = [destinationRouters objectAtIndex:idx];
        UIViewController *routableView = router.destination;
        ZIKPresentationState *destinationStateBeforeRoute = [(ZIKViewRouteConfiguration *)router.original_configuration segueConfiguration].destinationStateBeforeRoute;
        NSAssert(destinationStateBeforeRoute, @"Didn't set state in -ZIKViewRouter_hook_prepareForSegue:sender:");
        [ZIKViewRouter _completeRouter:router
          analyzeRouteTypeForDestination:routableView
                                  source:source
             destinationStateBeforeRoute:destinationStateBeforeRoute
                   transitionCoordinator:transitionCoordinator
                              completion:^{
                                  NSAssert(router.state == ZIKRouterStateRouting, @"state should be routing when end route");
                                  [router notifyRouteState:ZIKRouterStateRouted];
                                  if (sourceRouter) {
                                      if (routableView == sourceRouter.destination) {
                                          NSAssert(idx == 0, @"If destination is in destinationRouters, it should be at index 0.");
                                          NSAssert(router == sourceRouter, nil);
                                      }
                                  }
                                  [ZIKViewRouter AOP_notifyAll_router:router didPerformRouteOnDestination:routableView fromSource:source];
                                  router.routingFromInternal = NO;
                                  [router notifyPerformRouteSuccessWithDestination:routableView];
                              }];
    }
    //Complete unroutable view
    if (sourceRouter && [(ZIKViewRouteConfiguration *)sourceRouter.original_configuration segueConfiguration].segueDestination == destination && ![destination conformsToProtocol:@protocol(ZIKRoutableView)]) {
        ZIKPresentationState *destinationStateBeforeRoute = [(ZIKViewRouteConfiguration *)sourceRouter.original_configuration segueConfiguration].destinationStateBeforeRoute;
        NSAssert(destinationStateBeforeRoute, @"Didn't set state in -ZIKViewRouter_hook_prepareForSegue:sender:");
        [ZIKViewRouter _completeRouter:sourceRouter
          analyzeRouteTypeForDestination:destination
                                  source:source
             destinationStateBeforeRoute:destinationStateBeforeRoute
                   transitionCoordinator:transitionCoordinator
                              completion:^{
                                  [sourceRouter notifyRouteState:ZIKRouterStateRouted];
                                  sourceRouter.routingFromInternal = NO;
                                  [sourceRouter notifyPerformRouteSuccessWithDestination:destination];
                              }];
    }
}

///Search child view controllers conforming to ZIKRoutableView in vc, if the vc is a container or is system class
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
    
    if (ZIKRouter_classIsCustomClass([vc class]) == NO) {
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

+ (BOOL)_validateRouteSourceClassInConfiguration:(ZIKViewRouteConfiguration *)configuration {
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

- (BOOL)_validateDestinationConformance:(id)destination {
#if ZIKROUTER_CHECK
    Class routerClass = [self class];
    CFMutableSetRef viewProtocols = (CFMutableSetRef)CFDictionaryGetValue(ZIKViewRouteRegistry._check_routerToDestinationProtocolsMap, (__bridge const void *)(routerClass));
    if (viewProtocols != NULL) {
        for (Protocol *viewProtocol in (__bridge NSSet*)viewProtocols) {
            if (!class_conformsToProtocol([destination class], viewProtocol)) {
                NSAssert(NO, @"Bad implementation in router (%@)'s -destinationWithConfiguration:. The destiantion (%@) doesn't conforms to registered view protocol (%@).",routerClass, destination, NSStringFromProtocol(viewProtocol));
                return NO;
            }
        }
    }
#endif
    return YES;
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
        (!popoverConfig.barButtonItem && !popoverConfig.sourceView)) {
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
            if ([destination isKindOfClass:[UIView class]]) {
                NSAssert([[self class] _validateSupportedRouteTypesForUIView], @"%@ 's +supportedRouteTypes returns error types, if destination is a UIView, %@ only support ZIKViewRouteTypeAddAsSubview and ZIKViewRouteTypeCustom",[self class], [self class]);
                return YES;
            }
            break;
        case ZIKViewRouteTypeCustom:
            if ([destination isKindOfClass:[UIView class]]) {
                NSAssert([[self class] _validateSupportedRouteTypesForUIView], @"%@ 's +supportedRouteTypes returns error types, if destination is a UIView, %@ only support ZIKViewRouteTypeAddAsSubview and ZIKViewRouteTypeCustom, if use ZIKViewRouteTypeCustom, router must implement -performCustomRouteOnDestination:fromSource:configuration:.",[self class], [self class]);
                return YES;
            } else if ([destination isKindOfClass:[UIViewController class]]) {
                NSAssert([[self class] _validateSupportedRouteTypesForUIViewController], @"%@ 's +supportedRouteTypes returns error types, if destination is a UIViewController, %@ can't support ZIKViewRouteTypeAddAsSubview, if use ZIKViewRouteTypeCustom, router must implement -performCustomRouteOnDestination:fromSource:configuration:.",[self class], [self class]);
                return YES;
            }
            break;
            
        case ZIKViewRouteTypePerformSegue:
            NSAssert(!destination, @"ZIKViewRouteTypePerformSegue's destination should be created by UIKit automatically");
            return YES;
            break;
        
        case ZIKViewRouteTypeGetDestination:
            if ([destination isKindOfClass:[UIViewController class]] || [destination isKindOfClass:[UIView class]]) {
                return YES;
            }
            break;
            
        default:
            if ([destination isKindOfClass:[UIViewController class]]) {
                NSAssert([[self class] _validateSupportedRouteTypesForUIViewController], @"%@ 's +supportedRouteTypes returns error types, if destination is a UIViewController, %@ can't support ZIKViewRouteTypeAddAsSubview",[self class], [self class]);
                return YES;
            }
            break;
    }
    return NO;
}

+ (BOOL)_validateSourceInNavigationStack:(UIViewController *)source {
    BOOL canPerformPush = [source respondsToSelector:@selector(navigationController)];
    if (!canPerformPush ||
        (canPerformPush && !source.navigationController)) {
        return NO;
    }
    return YES;
}

+ (BOOL)_validateDestination:(UIViewController *)destination notInNavigationStackOfSource:(UIViewController *)source {
    NSArray<UIViewController *> *viewControllersInStack = source.navigationController.viewControllers;
    if ([viewControllersInStack containsObject:destination]) {
        return NO;
    }
    return YES;
}

+ (BOOL)_validateSourceNotPresentedAnyView:(UIViewController *)source {
    if (source.presentedViewController) {
        return NO;
    }
    return YES;
}

+ (BOOL)_validateSourceInWindowHierarchy:(UIViewController *)source {
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

+ (BOOL)_validateSupportedRouteTypesForUIView {
    ZIKViewRouteTypeMask supportedRouteTypes = [self supportedRouteTypes];
    if ((supportedRouteTypes & ZIKViewRouteTypeMaskCustom) == ZIKViewRouteTypeMaskCustom) {
        if (![self instancesRespondToSelector:@selector(performCustomRouteOnDestination:fromSource:configuration:)]) {
            return NO;
        }
    }
    if ((supportedRouteTypes & ZIKViewRouteTypeMaskAddAsSubview & ZIKViewRouteTypeMaskGetDestination & ZIKViewRouteTypeMaskCustom) != 0) {
        return NO;
    }
    return YES;
}

+ (BOOL)_validateSupportedRouteTypesForUIViewController {
    ZIKViewRouteTypeMask supportedRouteTypes = [self supportedRouteTypes];
    if ((supportedRouteTypes & ZIKViewRouteTypeMaskCustom) == ZIKViewRouteTypeMaskCustom) {
        if (![self instancesRespondToSelector:@selector(performCustomRouteOnDestination:fromSource:configuration:)]) {
            return NO;
        }
    }
    if ((supportedRouteTypes & ZIKViewRouteTypeMaskAddAsSubview) == ZIKViewRouteTypeMaskAddAsSubview) {
        return NO;
    }
    return YES;
}

+ (BOOL)_validateInfiniteRecursion {
    NSUInteger maxRecursiveDepth = 200;
    if ([self recursiveDepth] > maxRecursiveDepth) {
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

- (void)_callbackErrorWithAction:(ZIKRouteAction)routeAction error:(NSError *)error {
    [[self class] _callbackGlobalErrorHandlerWithRouter:self action:routeAction error:error];
    [super notifyError:error routeAction:routeAction];
}

//Call your errorHandler and globalErrorHandler, use this if you don't want to affect the routing
- (void)_callbackError_errorCode:(ZIKViewRouteError)code
                    errorHandler:(void(^)(ZIKRouteAction routeAction, NSError *error))errorHandler
                          action:(ZIKRouteAction)action
                errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    
    NSError *error = [[self class] errorWithCode:code localizedDescription:description];
    [[self class] _callbackGlobalErrorHandlerWithRouter:self action:action error:error];
    if (errorHandler) {
        errorHandler(action,error);
    }
}

+ (void)_callbackError_invalidPerformerWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self _callbackGlobalErrorHandlerWithRouter:nil action:action error:[[self class] errorWithCode:ZIKViewRouteErrorInvalidPerformer localizedDescription:description]];
}

+ (void)_callbackError_invalidProtocolWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [[self class] _callbackGlobalErrorHandlerWithRouter:nil action:action error:[[self class] errorWithCode:ZIKViewRouteErrorInvalidProtocol localizedDescription:description]];
    NSAssert(NO, @"Error when get router for viewProtocol: %@",description);
}

- (void)_callbackError_invalidConfigurationWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self _callbackErrorWithAction:action error:[[self class] errorWithCode:ZIKViewRouteErrorInvalidConfiguration localizedDescription:description]];
}

- (void)_callbackError_unsupportTypeWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self _callbackErrorWithAction:action error:[[self class] errorWithCode:ZIKViewRouteErrorUnsupportType localizedDescription:description]];
}

- (void)_callbackError_unbalancedTransitionWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [[self class] _callbackGlobalErrorHandlerWithRouter:self action:action error:[[self class] errorWithCode:ZIKViewRouteErrorUnbalancedTransition localizedDescription:description]];
    NSAssert(NO, @"Unbalanced calls to begin/end appearance transitions for destination. This error occurs when you try and display a view controller before the current view controller is finished displaying. This may cause the UIViewController skips or messes up the order calling -viewWillAppear:, -viewDidAppear:, -viewWillDisAppear: and -viewDidDisappear:, and messes up the route state.");
}

- (void)_callbackError_invalidSourceWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self _callbackErrorWithAction:action error:[[self class] errorWithCode:ZIKViewRouteErrorInvalidSource localizedDescription:description]];
}

- (void)_callbackError_invalidContainerWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self _callbackErrorWithAction:action error:[[self class] errorWithCode:ZIKViewRouteErrorInvalidContainer localizedDescription:description]];
}

- (void)_callbackError_actionFailedWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self _callbackErrorWithAction:action error:[[self class] errorWithCode:ZIKViewRouteErrorActionFailed localizedDescription:description]];
}

- (void)_callbackError_segueNotPerformedWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self _callbackErrorWithAction:action error:[[self class] errorWithCode:ZIKViewRouteErrorSegueNotPerformed localizedDescription:description]];
}

- (void)_callbackError_overRouteWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self _callbackErrorWithAction:action error:[[self class] errorWithCode:ZIKViewRouteErrorOverRoute localizedDescription:description]];
}

- (void)_callbackError_infiniteRecursionWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self _callbackErrorWithAction:action error:[[self class] errorWithCode:ZIKViewRouteErrorInfiniteRecursion localizedDescription:description]];
}

#pragma mark Getter/Setter

- (BOOL)autoCreated {
    return self.original_configuration.autoCreated;
}

+ (NSUInteger)recursiveDepth {
    NSNumber *depth = objc_getAssociatedObject(self, @"ZIKViewRouter_recursiveDepth");
    if ([depth isKindOfClass:[NSNumber class]]) {
        return [depth unsignedIntegerValue];
    }
    return 0;
}

+ (void)setRecursiveDepth:(NSUInteger)depth {
    objc_setAssociatedObject(self, @"ZIKViewRouter_recursiveDepth", @(depth), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)increaseRecursiveDepth {
    NSUInteger depth = [self recursiveDepth];
    [self setRecursiveDepth:++depth];
}

+ (void)decreaseRecursiveDepth {
    NSUInteger depth = [self recursiveDepth];
    [self setRecursiveDepth:--depth];
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

+ (nullable instancetype)performFromSource:(nullable id<ZIKViewRouteSource>)source configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder {
    return [super performWithConfiguring:^(ZIKViewRouteConfiguration * _Nonnull config) {
        if (configBuilder) {
            configBuilder(config);
        }
        if (source) {
            config.source = source;
        }
    }];
}

+ (nullable instancetype)performFromSource:(nullable id<ZIKViewRouteSource>)source
                               configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder
                                  removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder {
    return [super performWithConfiguring:^(ZIKViewRouteConfiguration * _Nonnull config) {
        if (configBuilder) {
            configBuilder(config);
        }
        if (source) {
            config.source = source;
        }
    } removing:removeConfigBuilder];
}

+ (nullable instancetype)performFromSource:(nullable id)source routeType:(ZIKViewRouteType)routeType {
    return [super performWithConfiguring:^(ZIKPerformRouteConfiguration *configuration) {
        ZIKViewRouteConfiguration *config = (ZIKViewRouteConfiguration *)configuration;
        if (source) {
            config.source = source;
        }
        config.routeType = routeType;
    }];
}

+ (nullable instancetype)performFromSource:(id<ZIKViewRouteSource>)source
                         strictConfiguring:(void (^)(ZIKViewRouteConfiguration * _Nonnull,
                                                     void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
                                                     void (^ _Nonnull)(void (^ _Nonnull)(ZIKViewRouteConfiguration * _Nonnull))
                                                     ))configBuilder {
    return [super performWithStrictConfiguring:^(ZIKViewRouteConfiguration * _Nonnull config,
                                                 void (^ _Nonnull prepareDest)(void (^ _Nonnull)(id _Nonnull)),
                                                 void (^ _Nonnull prepareModule)(void (^ _Nonnull)(ZIKViewRouteConfiguration * _Nonnull))) {
        if (configBuilder) {
            configBuilder(config,prepareDest,prepareModule);
        }
        if (source) {
            config.source = source;
        }
    }];
}

+ (nullable instancetype)performFromSource:(id<ZIKViewRouteSource>)source
                         strictConfiguring:(void (^)(ZIKViewRouteConfiguration * _Nonnull,
                                                     void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
                                                     void (^ _Nonnull)(void (^ _Nonnull)(ZIKViewRouteConfiguration * _Nonnull))
                                                     ))configBuilder
                            strictRemoving:(void (^)(ZIKViewRemoveConfiguration * _Nonnull,
                                                     void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull))
                                                     ))removeConfigBuilder {
    return [super performWithStrictConfiguring:^(ZIKViewRouteConfiguration * _Nonnull config,
                                                 void (^ _Nonnull prepareDest)(void (^ _Nonnull)(id _Nonnull)),
                                                 void (^ _Nonnull prepareModule)(void (^ _Nonnull)(ZIKViewRouteConfiguration * _Nonnull))) {
        if (configBuilder) {
            configBuilder(config,prepareDest,prepareModule);
        }
        if (source) {
            config.source = source;
        }
    } strictRemoving:removeConfigBuilder];
}

@end

@implementation ZIKViewRouter (PerformOnDestination)

+ (nullable instancetype)performOnDestination:(id)destination
                                   fromSource:(nullable id<ZIKViewRouteSource>)source
                                  configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder {
    return [self performOnDestination:destination fromSource:source configuring:configBuilder removing:nil];
}

+ (nullable instancetype)performOnDestination:(id)destination
                                   fromSource:(nullable id<ZIKViewRouteSource>)source
                                  configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder
                                     removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder {
    if (![destination conformsToProtocol:@protocol(ZIKRoutableView)]) {
        [[self class] _callbackGlobalErrorHandlerWithRouter:nil action:ZIKRouteActionInit error:[[self class] errorWithCode:ZIKViewRouteErrorInvalidConfiguration localizedDescription:[NSString stringWithFormat:@"Perform route on invalid destination: (%@)",destination]]];
        NSAssert1(NO, @"Perform route on invalid destination: (%@)",destination);
        return nil;
    }
    if (![ZIKViewRouteRegistry isDestinationClass:[destination class] registeredWithRouter:self]) {
        [[self class] _callbackGlobalErrorHandlerWithRouter:nil action:ZIKRouteActionPerformOnDestination error:[[self class] errorWithCode:ZIKViewRouteErrorInvalidConfiguration localizedDescription:[NSString stringWithFormat:@"Perform route on invalid destination (%@), this view is not registered with this router (%@)",destination,self]]];
        NSAssert2(NO, @"Perform route on invalid destination (%@), this view is not registered with this router (%@)",destination,self);
        return nil;
    }
    ZIKViewRouter *router = [[self alloc] initWithConfiguring:^(ZIKPerformRouteConfiguration *config) {
        ZIKViewRouteConfiguration *configuration = (ZIKViewRouteConfiguration *)config;
        if (configBuilder) {
            configBuilder(configuration);
        }
        if (source) {
            configuration.source = source;
        }
    } removing:(void(^)(ZIKRemoveRouteConfiguration *))removeConfigBuilder];
    NSAssert([(ZIKViewRouteConfiguration *)router.original_configuration routeType] != ZIKViewRouteTypeGetDestination, @"It's meaningless to get destination when you already offer a prepared destination.");
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
                            strictConfiguring:(void (^)(ZIKViewRouteConfiguration * _Nonnull,
                                                        void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
                                                        void (^ _Nonnull)(void (^ _Nonnull)(ZIKViewRouteConfiguration * _Nonnull))
                                                        ))configBuilder {
    return [self performOnDestination:destination fromSource:source strictConfiguring:configBuilder strictRemoving:nil];
}

+ (nullable instancetype)performOnDestination:(id)destination
                                   fromSource:(id<ZIKViewRouteSource>)source
                            strictConfiguring:(void (^)(ZIKViewRouteConfiguration * _Nonnull,
                                                        void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
                                                        void (^ _Nonnull)(void (^ _Nonnull)(ZIKViewRouteConfiguration * _Nonnull))
                                                        ))configBuilder
                               strictRemoving:(void (^)(ZIKViewRemoveConfiguration * _Nonnull,
                                                        void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull))
                                                        ))removeConfigBuilder {
    return [self performOnDestination:destination fromSource:source configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
        if (configBuilder) {
            void(^prepareDest)(void(^)(id)) = ^(void(^prepare)(id dest)) {
                if (prepare) {
                    config.prepareDestination = prepare;
                }
            };
            void(^prepareModule)(void(^)(id)) = ^(void(^prepare)(ZIKViewRouteConfiguration *module)) {
                if (prepare) {
                    prepare(config);
                }
            };
            configBuilder(config,prepareDest,prepareModule);
        }
    } removing:^(ZIKViewRemoveConfiguration * _Nonnull config) {
        if (removeConfigBuilder) {
            void(^prepareDest)(void(^)(id)) = ^(void(^prepare)(id dest)) {
                if (prepare) {
                    config.prepareDestination = prepare;
                }
            };
            removeConfigBuilder(config,prepareDest);
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
    if (![destination conformsToProtocol:@protocol(ZIKRoutableView)]) {
        [[self class] _callbackGlobalErrorHandlerWithRouter:nil action:ZIKRouteActionPrepareOnDestination error:[[self class] errorWithCode:ZIKViewRouteErrorInvalidConfiguration localizedDescription:[NSString stringWithFormat:@"Prepare for invalid destination: (%@)",destination]]];
        NSAssert1(NO, @"Prepare for invalid destination: (%@)",destination);
        return nil;
    }
    if (![ZIKViewRouteRegistry isDestinationClass:[destination class] registeredWithRouter:self]) {
        [[self class] _callbackGlobalErrorHandlerWithRouter:nil action:ZIKRouteActionPrepareOnDestination error:[[self class] errorWithCode:ZIKViewRouteErrorInvalidConfiguration localizedDescription:[NSString stringWithFormat:@"Prepare for invalid destination (%@), this view is not registered with this router (%@)",destination,self]]];
        NSAssert2(NO, @"Prepare for invalid destination (%@), this view is not registered with this router (%@)",destination,self);
        return nil;
    }
    ZIKViewRouteConfiguration *configuration = [[self class] defaultRouteConfiguration];
    configuration.routeType = ZIKViewRouteTypeGetDestination;
    if (configBuilder) {
        configBuilder(configuration);
    }
    ZIKViewRemoveConfiguration *removeConfiguration;
    if (removeConfigBuilder) {
        removeConfiguration = [self defaultRemoveConfiguration];
        removeConfigBuilder(removeConfiguration);
    }
    ZIKViewRouter *router =  [[self alloc] initWithConfiguration:configuration removeConfiguration:removeConfiguration];
    [router attachDestination:destination];
    [router prepareForPerformRouteOnDestination:destination];
    
    NSNumber *routeType = [destination zix_routeTypeFromRouter];
    if (routeType == nil) {
        [(id)destination setZix_routeTypeFromRouter:@(ZIKViewRouteTypeGetDestination)];
    }
    return router;
}

+ (nullable instancetype)prepareDestination:(id)destination strictConfiguring:(void (^)(ZIKViewRouteConfiguration * _Nonnull, void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)), void (^ _Nonnull)(void (^ _Nonnull)(ZIKViewRouteConfiguration * _Nonnull))))configBuilder {
    return [self prepareDestination:destination strictConfiguring:configBuilder strictRemoving:nil];
}

+ (nullable instancetype)prepareDestination:(id)destination
                          strictConfiguring:(void (^)(ZIKViewRouteConfiguration * _Nonnull,
                                                      void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
                                                      void (^ _Nonnull)(void (^ _Nonnull)(ZIKViewRouteConfiguration * _Nonnull))
                                                      ))configBuilder
                             strictRemoving:(void (^ _Nullable)(ZIKViewRemoveConfiguration * _Nonnull,
                                                                void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull))
                                                                ))removeConfigBuilder {
    return [self prepareDestination:destination configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
        if (configBuilder) {
            void(^prepareDest)(void(^)(id)) = ^(void(^prepare)(id dest)) {
                if (prepare) {
                    config.prepareDestination = prepare;
                }
            };
            void(^prepareModule)(void(^)(id)) = ^(void(^prepare)(ZIKViewRouteConfiguration *module)) {
                if (prepare) {
                    prepare(config);
                }
            };
            configBuilder(config,prepareDest,prepareModule);
        }
    } removing:^(ZIKViewRemoveConfiguration * _Nonnull config) {
        if (removeConfigBuilder) {
            void(^prepareDest)(void(^)(id)) = ^(void(^prepare)(id dest)) {
                if (prepare) {
                    config.prepareDestination = prepare;
                }
            };
            removeConfigBuilder(config,prepareDest);
        }
    }];
}

@end

@implementation ZIKViewRouter (Register)

+ (void)registerView:(Class)viewClass {
    Class routerClass = self;
    Class destinationClass = viewClass;
    NSParameterAssert([viewClass isSubclassOfClass:[UIView class]] ||
                      [viewClass isSubclassOfClass:[UIViewController class]]);
    NSParameterAssert(_isClassRoutable(viewClass));
    NSAssert(!ZIKViewRouteRegistry.autoRegistrationFinished, @"Only register in +registerRoutableDestination.");
    NSAssert([NSThread isMainThread], @"Call in main thread for thread safety.");
    [ZIKViewRouteRegistry registerDestination:viewClass router:self];
    return;
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKRouter class]]);
    NSAssert3(!ZIKViewRouteRegistry.destinationToExclusiveRouterMap ||
              (ZIKViewRouteRegistry.destinationToExclusiveRouterMap && !CFDictionaryGetValue(ZIKViewRouteRegistry.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass))), @"There is a registered exclusive router (%@), can't register this router (%@) for this destinationClass (%@).",CFDictionaryGetValue(ZIKViewRouteRegistry.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass)), routerClass,destinationClass);
    
    CFMutableDictionaryRef destinationToDefaultRouterMap = ZIKViewRouteRegistry.destinationToDefaultRouterMap;
    if (!CFDictionaryContainsKey(destinationToDefaultRouterMap, (__bridge const void *)(destinationClass))) {
        CFDictionarySetValue(destinationToDefaultRouterMap, (__bridge const void *)(destinationClass), (__bridge const void *)(routerClass));
    }
    CFMutableDictionaryRef destinationToRoutersMap = ZIKViewRouteRegistry.destinationToRoutersMap;
    CFMutableSetRef routers = (CFMutableSetRef)CFDictionaryGetValue(destinationToRoutersMap, (__bridge const void *)(destinationClass));
    if (routers == NULL) {
        routers = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue(destinationToRoutersMap, (__bridge const void *)(destinationClass), routers);
    }
    CFSetAddValue(routers, (__bridge const void *)(routerClass));
    
#if ZIKROUTER_CHECK
    CFMutableSetRef destinations = (CFMutableSetRef)CFDictionaryGetValue(ZIKViewRouteRegistry._check_routerToDestinationsMap, (__bridge const void *)(routerClass));
    if (destinations == NULL) {
        destinations = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue(ZIKViewRouteRegistry._check_routerToDestinationsMap, (__bridge const void *)(routerClass), destinations);
    }
    CFSetAddValue(destinations, (__bridge const void *)(destinationClass));
#endif
}

+ (void)registerExclusiveView:(Class)viewClass {
    NSCParameterAssert([viewClass isSubclassOfClass:[UIView class]] ||
                       [viewClass isSubclassOfClass:[UIViewController class]]);
    NSCParameterAssert(_isClassRoutable(viewClass));
    NSCAssert(!ZIKViewRouteRegistry.autoRegistrationFinished, @"Only register in +registerRoutableDestination.");
    NSCAssert([NSThread isMainThread], @"Call in main thread for thread safety.");
    [ZIKViewRouteRegistry registerExclusiveDestination:viewClass router:self];
}

+ (void)registerViewProtocol:(Protocol *)viewProtocol {
    NSAssert(!ZIKViewRouteRegistry.autoRegistrationFinished, @"Only register in +registerRoutableDestination.");
    NSAssert([NSThread isMainThread], @"Call in main thread for thread safety.");
#if ZIKROUTER_CHECK
    NSAssert1(protocol_conformsToProtocol(viewProtocol, @protocol(ZIKViewRoutable)), @"%@ should conforms to ZIKViewRoutable in DEBUG mode for safety checking", NSStringFromProtocol(viewProtocol));
#endif
    [ZIKViewRouteRegistry registerDestinationProtocol:viewProtocol router:self];
}

+ (void)registerModuleProtocol:(Protocol *)configProtocol {
    NSAssert2([[self defaultRouteConfiguration] conformsToProtocol:configProtocol], @"configProtocol(%@) should be conformed by this router(%@)'s defaultRouteConfiguration.",NSStringFromProtocol(configProtocol),self);
    NSAssert(!ZIKViewRouteRegistry.autoRegistrationFinished, @"Only register in +registerRoutableDestination.");
    NSAssert([NSThread isMainThread], @"Call in main thread for thread safety.");
#if ZIKROUTER_CHECK
    NSAssert1(protocol_conformsToProtocol(configProtocol, @protocol(ZIKViewModuleRoutable)), @"%@ should conforms to ZIKViewModuleRoutable in DEBUG mode for safety checking", NSStringFromProtocol(configProtocol));
#endif
    [ZIKViewRouteRegistry registerModuleProtocol:configProtocol router:self];
}

@end

_Nullable Class _ZIKViewRouterToView(Protocol *viewProtocol) {
    NSCParameterAssert(viewProtocol);
    NSCAssert(ZIKViewRouteRegistry.autoRegistrationFinished, @"Only get router after app did finish launch.");
    if (!viewProtocol) {
        [ZIKViewRouter _callbackError_invalidProtocolWithAction:ZIKRouteActionToView errorDescription:@"ZIKViewRouter.toView() viewProtocol is nil"];
        return nil;
    }
    Class routerClass = [ZIKViewRouteRegistry routerToDestination:viewProtocol];
    if (routerClass) {
        return routerClass;
    }
    [ZIKViewRouter _callbackError_invalidProtocolWithAction:ZIKRouteActionToView
                                           errorDescription:@"Didn't find view router for view protocol: %@, this protocol was not registered.",viewProtocol];
    NSCAssert1(NO, @"Didn't find view router for view protocol: %@, this protocol was not registered.",viewProtocol);
    return nil;
}

_Nullable Class _ZIKViewRouterToModule(Protocol *configProtocol) {
    NSCParameterAssert(configProtocol);
    NSCAssert(ZIKViewRouteRegistry.autoRegistrationFinished, @"Only get router after app did finish launch.");
    if (!configProtocol) {
        [ZIKViewRouter _callbackError_invalidProtocolWithAction:ZIKRouteActionToViewModule errorDescription:@"ZIKViewRouter.toModule() configProtocol is nil"];
        return nil;
    }
    
    Class routerClass = [ZIKViewRouteRegistry routerToModule:configProtocol];
    if (routerClass) {
        return routerClass;
    }
    [ZIKViewRouter _callbackError_invalidProtocolWithAction:ZIKRouteActionToViewModule
                                           errorDescription:@"Didn't find view router for config protocol: %@, this protocol was not registered.",configProtocol];
    NSCAssert1(NO, @"Didn't find view router for config protocol: %@, this protocol was not registered.",configProtocol);
    return nil;
}

@implementation ZIKViewRouter (Private)

+ (BOOL)shouldCheckImplementation {
#if ZIKROUTER_CHECK
    return YES;
#else
    return NO;
#endif
}

+ (BOOL)_isAutoRegistrationFinished {
    return ZIKViewRouteRegistry.autoRegistrationFinished;
}

+ (void)_swift_registerViewProtocol:(id)viewProtocol {
    NSCParameterAssert(ZIKRouter_isObjcProtocol(viewProtocol));
    [self registerViewProtocol:viewProtocol];
}

+ (void)_swift_registerConfigProtocol:(id)configProtocol {
    NSCParameterAssert(ZIKRouter_isObjcProtocol(configProtocol));
    [self registerModuleProtocol:configProtocol];
}

+ (_Nullable Class)validateRegisteredViewClasses:(ZIKViewClassValidater)handler {
#if ZIKROUTER_CHECK
    Class routerClass = self;
    CFMutableSetRef views = (CFMutableSetRef)CFDictionaryGetValue(ZIKViewRouteRegistry._check_routerToDestinationsMap, (__bridge const void *)(routerClass));
    __block Class badClass = nil;
    [(__bridge NSSet *)(views) enumerateObjectsUsingBlock:^(Class  _Nonnull viewClass, BOOL * _Nonnull stop) {
        if (handler) {
            if (!handler(viewClass)) {
                badClass = viewClass;
                *stop = YES;
            }
            ;
        }
    }];
    return badClass;
#else
    return nil;
#endif
}

+ (void)_callbackGlobalErrorHandlerWithRouter:(nullable __kindof ZIKViewRouter *)router action:(ZIKRouteAction)action error:(NSError *)error {
    dispatch_semaphore_wait(g_globalErrorSema, DISPATCH_TIME_FOREVER);
    
    ZIKViewRouteGlobalErrorHandler errorHandler = g_globalErrorHandler;
    if (errorHandler) {
        errorHandler(router, action, error);
    } else {
#ifdef DEBUG
        NSLog(@"❌ZIKViewRouter Error: router's action (%@) catch error: (%@),\nrouter:(%@)", action, error,router);
#endif
    }
    
    dispatch_semaphore_signal(g_globalErrorSema);
}

_Nullable Class _swift_ZIKViewRouterToView(id viewProtocol) {
    return _ZIKViewRouterToView(viewProtocol);
}

_Nullable Class _swift_ZIKViewRouterToModule(id configProtocol) {
    return _ZIKViewRouterToModule(configProtocol);
}

@end

@implementation ZIKViewRouter (Deprecated)

+ (nullable instancetype)performFromSource:(id<ZIKViewRouteSource>)source
                          routeConfiguring:(void (^)(ZIKViewRouteConfiguration * _Nonnull,
                                                     void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
                                                     void (^ _Nonnull)(void (^ _Nonnull)(ZIKViewRouteConfiguration * _Nonnull))
                                                     ))configBuilder {
    return [self performFromSource:source strictConfiguring:configBuilder];
}

+ (nullable instancetype)performFromSource:(id<ZIKViewRouteSource>)source
                          routeConfiguring:(void (^)(ZIKViewRouteConfiguration * _Nonnull,
                                                     void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
                                                     void (^ _Nonnull)(void (^ _Nonnull)(ZIKViewRouteConfiguration * _Nonnull))
                                                     ))configBuilder
                             routeRemoving:(void (^)(ZIKViewRemoveConfiguration * _Nonnull,
                                                     void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull))
                                                     ))removeConfigBuilder {
    return [self performFromSource:source strictConfiguring:configBuilder strictRemoving:removeConfigBuilder];
}

+ (nullable instancetype)performOnDestination:(id)destination
                                   fromSource:(id<ZIKViewRouteSource>)source
                             routeConfiguring:(void (^)(ZIKViewRouteConfiguration * _Nonnull,
                                                        void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
                                                        void (^ _Nonnull)(void (^ _Nonnull)(ZIKViewRouteConfiguration * _Nonnull))
                                                        ))configBuilder {
    return [self performOnDestination:destination fromSource:source strictConfiguring:configBuilder];
}

+ (nullable instancetype)performOnDestination:(id)destination
                                   fromSource:(id<ZIKViewRouteSource>)source
                             routeConfiguring:(void (^)(ZIKViewRouteConfiguration * _Nonnull,
                                                        void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
                                                        void (^ _Nonnull)(void (^ _Nonnull)(ZIKViewRouteConfiguration * _Nonnull))
                                                        ))configBuilder
                                routeRemoving:(void (^)(ZIKViewRemoveConfiguration * _Nonnull,
                                                        void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull))
                                                        ))removeConfigBuilder {
    return [self performOnDestination:destination fromSource:source strictConfiguring:configBuilder strictRemoving:removeConfigBuilder];
}

+ (nullable instancetype)prepareDestination:(id)destination routeConfiguring:(void (^)(ZIKViewRouteConfiguration * _Nonnull, void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)), void (^ _Nonnull)(void (^ _Nonnull)(ZIKViewRouteConfiguration * _Nonnull))))configBuilder {
    return [self prepareDestination:destination strictConfiguring:configBuilder];
}

+ (nullable instancetype)prepareDestination:(id)destination
                           routeConfiguring:(void (^)(ZIKViewRouteConfiguration * _Nonnull,
                                                      void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
                                                      void (^ _Nonnull)(void (^ _Nonnull)(ZIKViewRouteConfiguration * _Nonnull))
                                                      ))configBuilder
                              routeRemoving:(void (^ _Nullable)(ZIKViewRemoveConfiguration * _Nonnull,
                                                                void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull))
                                                                ))removeConfigBuilder {
    return [self prepareDestination:destination strictConfiguring:configBuilder strictRemoving:removeConfigBuilder];
}

@end
