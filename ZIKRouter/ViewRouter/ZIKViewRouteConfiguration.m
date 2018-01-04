//
//  ZIKViewRouteConfiguration.m
//  ZIKRouter
//
//  Created by zuik on 2017/9/18.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKViewRouteConfiguration.h"
#import "ZIKViewRouterInternal.h"
#import "ZIKPresentationState.h"
#import "ZIKRouterInternal.h"
#import "ZIKViewRouteError.h"

ZIKRouteAction const ZIKRouteActionToView = @"ZIKRouteActionToView";
ZIKRouteAction const ZIKRouteActionToViewModule = @"ZIKRouteActionToViewModule";
ZIKRouteAction const ZIKRouteActionPrepareOnDestination = @"ZIKRouteActionPrepareOnDestination";
ZIKRouteAction const ZIKRouteActionPerformOnDestination = @"ZIKRouteActionPerformOnDestination";

@interface ZIKViewRouter()
+ (void)_callbackGlobalErrorHandlerWithRouter:(__kindof ZIKViewRouter *)router action:(SEL)action error:(NSError *)error;
+ (NSString *)descriptionOfRouteType:(ZIKViewRouteType)routeType;
@end

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

@implementation ZIKViewRouteConfiguration
@dynamic prepareDestination;
@dynamic routeCompletion;

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
            [ZIKViewRouter _callbackGlobalErrorHandlerWithRouter:nil
                                                            action:@selector(configureSegue)
                                                             error:[ZIKViewRouter errorWithCode:ZIKViewRouteErrorInvalidConfiguration
                                                                     localizedDescriptionFormat:@"segueConfiguration for configuration: %@ should only configure once",self]];
            NSAssert(NO, @"segueConfiguration for configuration: %@ should only configure once",self);
        }
        ZIKViewRouteSegueConfiguration *segueConfiguration = [ZIKViewRouteSegueConfiguration new];
        if (configure) {
            configure(segueConfiguration);
        } else {
            [ZIKViewRouter _callbackGlobalErrorHandlerWithRouter:nil
                                                            action:@selector(configureSegue)
                                                             error:[ZIKViewRouter errorWithCode:ZIKViewRouteErrorInvalidConfiguration
                                                                     localizedDescriptionFormat:@"When configureSegue for configuration : %@, configure block should not be nil !",self]];
            NSAssert(NO, @"When configureSegue for configuration : %@, configure block should not be nil !",self);
        }
        if (!segueConfiguration.identifier && !strongSelf.autoCreated) {
            [ZIKViewRouter _callbackGlobalErrorHandlerWithRouter:nil
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
            [ZIKViewRouter _callbackGlobalErrorHandlerWithRouter:nil
                                                            action:@selector(configureSegue)
                                                             error:[ZIKViewRouter errorWithCode:ZIKViewRouteErrorInvalidConfiguration
                                                                     localizedDescriptionFormat:@"popoverConfiguration for configuration: %@ should only configure once",self]];
            NSAssert(NO, @"popoverConfiguration for configuration: %@ should only configure once",self);
        }
        ZIKViewRoutePopoverConfiguration *popoverConfiguration = [ZIKViewRoutePopoverConfiguration new];
        if (configure) {
            configure(popoverConfiguration);
        } else {
            [ZIKViewRouter _callbackGlobalErrorHandlerWithRouter:nil
                                                            action:@selector(configureSegue)
                                                             error:[ZIKViewRouter errorWithCode:ZIKViewRouteErrorInvalidConfiguration
                                                                     localizedDescriptionFormat:@"When configurePopover for configuration : %@, configure should not be nil !",self]];
            NSAssert(NO, @"When configurePopover for configuration : %@, configure should not be nil !",self);
        }
        if (!popoverConfiguration.sourceView && !popoverConfiguration.barButtonItem) {
            [ZIKViewRouter _callbackGlobalErrorHandlerWithRouter:nil
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
    config.prepareDestination = self.prepareDestination;
    config.routeCompletion = self.routeCompletion;
    config.handleExternalRoute = self.handleExternalRoute;
    return config;
}

- (NSString *)description {
    NSString *description = [NSString stringWithFormat:@"%@: source:%@, routeType:%@, animated:%d, handleExternalRoute:%d",super.description,self.source,[ZIKViewRouter descriptionOfRouteType:self.routeType],self.animated,self.handleExternalRoute];
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
    config.handleExternalRoute = self.handleExternalRoute;
    return config;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"animated:%d,handleExternalRoute:%d",self.animated,self.handleExternalRoute];
}

@end
