//
//  ZIKCompatibleAlertViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/6.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKCompatibleAlertViewRouter.h"
#import <objc/runtime.h>
@import ZIKRouter.Internal;

@interface UIAlertController (ZIKSimpleLabelRouter) <ZIKRoutableView>
@end
@implementation UIAlertController (ZIKSimpleLabelRouter)
@end

#pragma mark Compatible UIAlertView

@interface UIAlertView (ZIKCompatibleAlert) <ZIKRoutableView>
- (ZIKCompatibleAlertViewRouter *)zix_compatibleAlertRouter;
- (void)setZix_compatibleAlertRouter:(ZIKCompatibleAlertViewRouter *)router;
@end

@implementation UIAlertView (ZIKCompatibleAlert)

- (ZIKCompatibleAlertViewRouter *)zix_compatibleAlertRouter {
    return objc_getAssociatedObject(self, "zix_compatibleAlertRouter");
}

- (void)setZix_compatibleAlertRouter:(ZIKCompatibleAlertViewRouter *)router {
    objc_setAssociatedObject(self, "zix_compatibleAlertRouter", router, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@interface ZIKCompatibleAlertViewAction : NSObject
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) void(^handler)(void);
@property (nonatomic, assign) BOOL isCancelAction;
@property (nonatomic, assign) BOOL isDestructiveAction;
@end

@implementation ZIKCompatibleAlertViewAction

@end

#pragma mark Custom configuration

@interface ZIKCompatibleAlertViewConfiguration ()
@property (nonatomic, strong) NSMutableArray<ZIKCompatibleAlertViewAction *> *actions;
@end

@implementation ZIKCompatibleAlertViewConfiguration

- (instancetype)init {
    if (self = [super init]) {
        _actions = [NSMutableArray array];
    }
    return self;
}

- (void)addCancelButtonTitle:(NSString *)cancelButtonTitle handler:(void (^__nullable)(void))handler {
    NSParameterAssert(cancelButtonTitle);
    NSAssert(!self.actions.firstObject.isCancelAction, @"Can't add multi cancel buttons.");
    ZIKCompatibleAlertViewAction *action = [ZIKCompatibleAlertViewAction new];
    action.title = cancelButtonTitle;
    action.handler = handler;
    action.isCancelAction = YES;
    [self.actions insertObject:action atIndex:0];
}

- (void)addOtherButtonTitle:(NSString *)otherButtonTitle handler:(void (^__nullable)(void))handler {
    NSParameterAssert(otherButtonTitle);
    ZIKCompatibleAlertViewAction *action = [ZIKCompatibleAlertViewAction new];
    action.title = otherButtonTitle;
    action.handler = handler;
    [self.actions addObject:action];
}

- (void)addDestructiveButtonTitle:(NSString *)destructiveButtonTitle handler:(void (^)(void))handler {
    NSParameterAssert(destructiveButtonTitle);
    NSParameterAssert(handler);
    ZIKCompatibleAlertViewAction *action = [ZIKCompatibleAlertViewAction new];
    action.title = destructiveButtonTitle;
    action.handler = handler;
    action.isDestructiveAction = YES;
    [self.actions addObject:action];
}

- (id)copyWithZone:(nullable NSZone *)zone {
    ZIKCompatibleAlertViewConfiguration *config = [super copyWithZone:zone];
    [config setPropertiesFromConfiguration:self];
    return config;
}
@end

#pragma mark Implementation for custom route

//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation ZIKCompatibleAlertViewRouter

//#pragma clang diagnostic pop

+ (void)registerRoutableDestination {
    if (@available(iOS 8.0, *)) {
        [self registerView:[UIAlertController class]];
    }
    [self registerView:[UIAlertView class]];
    [self registerModuleProtocol:ZIKRoutable(ZIKCompatibleAlertModuleInput)];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKCompatibleAlertViewConfiguration *)configuration {
    id destination;
    if (@available(iOS 8.0, *)) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:configuration.title message:configuration.message preferredStyle:UIAlertControllerStyleAlert];
        for (ZIKCompatibleAlertViewAction *action in configuration.actions) {
            void(^handler)(void) = action.handler;
            UIAlertActionStyle style = UIAlertActionStyleDefault;
            if (action.isCancelAction) {
                style = UIAlertActionStyleCancel;
            } else if (action.isDestructiveAction) {
                style = UIAlertActionStyleDestructive;
            }
            UIAlertAction *alertAction = [UIAlertAction actionWithTitle:action.title style:style handler:^(UIAlertAction * _Nonnull action) {
                if (handler) {
                    handler();
                }
            }];
            [alertController addAction:alertAction];
        }
        destination = alertController;
    } else {
        NSString *cancelButtonTitle;
        if (configuration.actions.firstObject.isCancelAction) {
            cancelButtonTitle = configuration.actions.firstObject.title;
        }
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:configuration.title message:configuration.message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles: nil];
        NSArray<ZIKCompatibleAlertViewAction *> *actions = configuration.actions;
        for (int idx = 1; idx < actions.count; idx++) {
            ZIKCompatibleAlertViewAction *action = [actions objectAtIndex:idx];
            [alertView addButtonWithTitle:action.title];
        }
        [alertView setZix_compatibleAlertRouter:self];
        destination = alertView;
    }
    
    NSAssert([[[self class] defaultRouteConfiguration] conformsToProtocol:@protocol(ZIKCompatibleAlertModuleInput)], nil);
    return destination;
}

+ (BOOL)validateCustomRouteConfiguration:(ZIKCompatibleAlertViewConfiguration *)configuration removeConfiguration:(__kindof ZIKViewRemoveConfiguration *)removeConfiguration {
    if (![configuration.source isKindOfClass:[UIViewController class]]) {
        return NO;
    }
    if (!configuration.title && !configuration.message && configuration.actions.count == 0) {
        return NO;
    }
    return YES;
}

- (BOOL)canPerformCustomRoute {
    return [self _canPerformPresent];
}

- (BOOL)canRemoveCustomRoute {
    if (self.destination) {
        return YES;
    }
    return NO;
}

- (void)performCustomRouteOnDestination:(id)destination fromSource:(UIViewController *)source configuration:(ZIKCompatibleAlertViewConfiguration *)configuration {
    if (@available(iOS 8.0, *)) {
        if ([destination isKindOfClass:[UIAlertController class]]) {
            [self beginPerformRoute];
            [source presentViewController:destination animated:configuration.animated completion:^{
                [self endPerformRouteWithSuccess];
            }];
            return;
        }
    }
    if ([destination isKindOfClass:[UIAlertView class]]) {
        [self beginPerformRoute];
        [(UIAlertView *)destination show];
    } else {
        NSAssert(NO, nil);
    }
}
- (void)removeCustomRouteOnDestination:(id)destination fromSource:(UIViewController *)source removeConfiguration:(__kindof ZIKViewRemoveConfiguration *)removeConfiguration configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    if (@available(iOS 8.0, *)) {
        if ([destination isKindOfClass:[UIAlertController class]]) {
            [self beginRemoveRouteFromSource:source];
            [(UIAlertController *)destination dismissViewControllerAnimated:removeConfiguration.animated completion:^{
                [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
            }];
            return;
        }
    }
    if ([destination isKindOfClass:[UIAlertView class]]) {
        [self beginRemoveRouteFromSource:source];
        [(UIAlertView *)destination dismissWithClickedButtonIndex:0 animated:removeConfiguration.animated];
    } else {
        NSAssert(NO, nil);
    }
}

+ (ZIKViewRouteTypeMask)supportedRouteTypes {
    return ZIKViewRouteTypeMaskCustom;
}

+ (__kindof ZIKViewRouteConfiguration *)defaultRouteConfiguration {
    ZIKCompatibleAlertViewConfiguration *config = [ZIKCompatibleAlertViewConfiguration new];
    config.routeType = ZIKViewRouteTypeCustom;
    return config;
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    ZIKCompatibleAlertViewRouter *router = [alertView zix_compatibleAlertRouter];
    NSAssert(router && [router isKindOfClass:[self class]], nil);
    NSArray<ZIKCompatibleAlertViewAction *> *actions = [(ZIKCompatibleAlertViewConfiguration *)router.original_configuration actions];
    NSParameterAssert(buttonIndex <= actions.count - 1);
    
    ZIKCompatibleAlertViewAction *action = [actions objectAtIndex:buttonIndex];
    if (action.handler) {
        action.handler();
    }
}
- (void)didPresentAlertView:(UIAlertView *)alertView {
    ZIKViewRouter *router = [alertView zix_compatibleAlertRouter];
    NSAssert(router && [router isKindOfClass:[self class]], nil);
    if (router.state == ZIKRouterStateRouting) {
        [router endPerformRouteWithSuccess];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    ZIKCompatibleAlertViewRouter *router = [alertView zix_compatibleAlertRouter];
    NSAssert(router && [router isKindOfClass:[self class]], nil);
    if (router.routingFromInternal) {
        if (router.state == ZIKRouterStateRemoving) {
            [router endRemoveRouteWithSuccessOnDestination:alertView fromSource:router.original_configuration.source];
        }
    }
}
@end

