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

@interface ZIKViewRoutePath()
@property (nonatomic, strong) id<ZIKViewRouteSource> source;
@property (nonatomic) ZIKViewRouteType routeType;
@property (nonatomic, strong, nullable) ZIKViewRoutePopoverConfigure configurePopover;
@property (nonatomic, copy, nullable) NSString *segueIdentifier;
@property (nonatomic, strong, nullable) id segueSender;
@property (nonatomic, copy, nullable) void(^addingChildViewHandler)(UIViewController *destination, void(^completion)(void));

@end

@implementation ZIKViewRoutePath

+ (ZIKViewRoutePath *(^)(UIViewController *))pushFrom {
    return ^(UIViewController *source) {
        return [self pushFrom:source];
    };
}

+ (ZIKViewRoutePath *(^)(UIViewController *))presentModallyFrom {
    return ^(UIViewController *source) {
        return [self presentModallyFrom:source];
    };
}

+ (ZIKViewRoutePath *(^)(UIViewController *, ZIKViewRoutePopoverConfigure))presentAsPopoverFrom {
    return ^(UIViewController *source, ZIKViewRoutePopoverConfigure configure) {
        return [self presentAsPopoverFrom:source configure:configure];
    };
}

+ (ZIKViewRoutePath *(^)(UIViewController *, NSString *, id))performSegueFrom {
    return ^(UIViewController *source, NSString *identifier, id _Nullable sender) {
        return [self performSegueFrom:source identifier:identifier sender:sender];
    };
}

+ (ZIKViewRoutePath *(^)(UIViewController *))showFrom {
    return ^(UIViewController *source) {
        return [self showFrom:source];
    };
}

+ (ZIKViewRoutePath *(^)(UIViewController *))showDetailFrom {
    return ^(UIViewController *source) {
        return [self showDetailFrom:source];
    };
}

+ (ZIKViewRoutePath *(^)(UIViewController *, void(^)(UIViewController *destination, void(^completion)(void))))addAsChildViewControllerFrom {
    return ^(UIViewController *source, void(^addingChildViewHandler)(UIViewController *destination, void(^completion)(void))) {
        return [self addAsChildViewControllerFrom:source addingChildViewHandler:addingChildViewHandler];
    };
}

+ (ZIKViewRoutePath *(^)(UIView *))addAsSubviewFrom {
    return ^(UIView *source) {
        return [self addAsSubviewFrom:source];
    };
}

+ (ZIKViewRoutePath *(^)(id<ZIKViewRouteSource>))customFrom {
    return ^(id<ZIKViewRouteSource> source) {
        return [self customFrom:source];
    };
}

+ (ZIKViewRoutePath *(^)(UIViewController *))defaultPathFrom {
    return ^(UIViewController *source) {
        return [self defaultPathFrom:source];
    };
}

+ (ZIKViewRoutePath *)makeDestination {
    return [[ZIKViewRoutePath alloc] initWithRouteType:ZIKViewRouteTypeMakeDestination source:nil];
}

+ (instancetype)pushFrom:(UIViewController *)source {
    return [[ZIKViewRoutePath alloc] initWithRouteType:ZIKViewRouteTypePush source:source];
}

+ (instancetype)presentModallyFrom:(UIViewController *)source {
    return [[ZIKViewRoutePath alloc] initWithRouteType:ZIKViewRouteTypePresentModally source:source];
}

+ (instancetype)presentAsPopoverFrom:(UIViewController *)source configure:(ZIKViewRoutePopoverConfigure)configure {
    ZIKViewRoutePath *path = [[ZIKViewRoutePath alloc] initWithRouteType:ZIKViewRouteTypePresentAsPopover source:source];
    path.configurePopover = configure;
    return path;
}

+ (instancetype)performSegueFrom:(UIViewController *)source identifier:(nonnull NSString *)identifier sender:(nullable id)sender {
    ZIKViewRoutePath *path = [[ZIKViewRoutePath alloc] initWithRouteType:ZIKViewRouteTypePerformSegue source:source];
    path.segueIdentifier = identifier;
    path.segueSender = sender;
    return path;
}

+ (instancetype)showFrom:(UIViewController *)source {
    return [[ZIKViewRoutePath alloc] initWithRouteType:ZIKViewRouteTypeShow source:source];
}

+ (instancetype)showDetailFrom:(UIViewController *)source {
    return [[ZIKViewRoutePath alloc] initWithRouteType:ZIKViewRouteTypeShowDetail source:source];
}

+ (instancetype)addAsChildViewControllerFrom:(UIViewController *)source addingChildViewHandler:(void(^)(UIViewController *destination, void(^completion)(void)))addingChildViewHandler {
    ZIKViewRoutePath *path = [[ZIKViewRoutePath alloc] initWithRouteType:ZIKViewRouteTypeAddAsChildViewController source:source];
    path.addingChildViewHandler = addingChildViewHandler;
    return path;
}

+ (instancetype)addAsSubviewFrom:(UIViewController *)source {
    return [[ZIKViewRoutePath alloc] initWithRouteType:ZIKViewRouteTypeAddAsSubview source:source];
}

+ (instancetype)customFrom:(UIViewController *)source {
    return [[ZIKViewRoutePath alloc] initWithRouteType:ZIKViewRouteTypeCustom source:source];
}

+ (instancetype)defaultPathFrom:(UIViewController *)source {
    ZIKViewRoutePath *path = [[ZIKViewRoutePath alloc] initWithRouteType:ZIKViewRouteTypeCustom source:source];
    path.useDefault = YES;
    return path;
}

- (instancetype)initWithRouteType:(ZIKViewRouteType)routeType source:(id<ZIKViewRouteSource>)source {
    if (self= [super init]) {
        _source = source;
        _routeType = routeType;
    }
    return self;
}

@end

@interface ZIKViewRouter()
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
@dynamic successHandler;

- (instancetype)init {
    if (self = [super init]) {
        [self configDefaultValue];
    }
    return self;
}

- (void)configurePath:(ZIKViewRoutePath *)path {
    if (path.useDefault) {
        if (self.source == nil) {
            id source = path.source;
            if (self.routeType == ZIKViewRouteTypeAddAsSubview && [source isKindOfClass:[UIViewController class]]) {
                self.source = [(UIViewController *)path.source view];
            } else {
                self.source = path.source;
            }
        }
        return;
    }
    if (path.source) {
        self.source = path.source;
    }
    self.routeType = path.routeType;
    switch (path.routeType) {
        case ZIKViewRouteTypePresentAsPopover:
            if (path.configurePopover) {
                self.configurePopover(path.configurePopover);
            }
            break;
        case ZIKViewRouteTypePerformSegue: {
            self.configureSegue(^(ZIKViewRouteSegueConfiguration * _Nonnull segueConfig) {
                if (path.segueIdentifier) {
                    segueConfig.identifier = path.segueIdentifier;
                }
                if (path.segueSender) {
                    segueConfig.sender = path.segueSender;
                }
            });
        }
            break;
        case ZIKViewRouteTypeAddAsChildViewController:
            if (path.addingChildViewHandler) {
                self.addingChildViewHandler = path.addingChildViewHandler;
            }
            break;
        default:
            break;
    }
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
        ZIKViewRouteSegueConfiguration *segueConfiguration = [ZIKViewRouteSegueConfiguration new];
        if (configure) {
            configure(segueConfiguration);
        } else {
            [ZIKViewRouter notifyGlobalErrorWithRouter:nil
                                                action:ZIKRouteActionPerformRoute
                                                 error:[ZIKRouter errorWithCode:ZIKRouteErrorInvalidConfiguration
                                                        localizedDescriptionFormat:@"When configureSegue for configuration : %@, configure block should not be nil !",self]];
        }
        if (!segueConfiguration.identifier && !strongSelf.autoCreated) {
            [ZIKViewRouter notifyGlobalErrorWithRouter:nil
                                                action:ZIKRouteActionPerformRoute
                                                 error:[ZIKRouter errorWithCode:ZIKRouteErrorInvalidConfiguration
                                                        localizedDescriptionFormat:@"configureSegue didn't assign segue identifier for configuration: %@", self]];
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
        ZIKViewRoutePopoverConfiguration *popoverConfiguration = [ZIKViewRoutePopoverConfiguration new];
        if (configure) {
            configure(popoverConfiguration);
        } else {
            [ZIKViewRouter notifyGlobalErrorWithRouter:nil
                                                action:ZIKRouteActionPerformRoute
                                                 error:[ZIKViewRouter errorWithCode:ZIKRouteErrorInvalidConfiguration
                                                        localizedDescriptionFormat:@"When configurePopover for configuration : %@, configure should not be nil !",self]];
        }
        if (!popoverConfiguration.sourceView && !popoverConfiguration.barButtonItem) {
            [ZIKViewRouter notifyGlobalErrorWithRouter:nil
                                                action:ZIKRouteActionPerformRoute
                                                 error:[ZIKViewRouter errorWithCode:ZIKRouteErrorInvalidConfiguration
                                                        localizedDescriptionFormat:@"configurePopover didn't assign sourceView or barButtonItem for configuration: %@", self]];
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
    config.addingChildViewHandler = self.addingChildViewHandler;
    config.popoverConfiguration = [self.popoverConfiguration copy];
    config.segueConfiguration = [self.segueConfiguration copy];
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
    config.removingChildViewHandler = self.removingChildViewHandler;
    config.handleExternalRoute = self.handleExternalRoute;
    return config;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"animated:%d,handleExternalRoute:%d",self.animated,self.handleExternalRoute];
}

@end

@implementation UIView (ZIKViewRouteSource)
@end
@implementation UIViewController (ZIKViewRouteSource)
@end
@implementation UINavigationController (ZIKViewRouteContainer)
@end
@implementation UITabBarController (ZIKViewRouteContainer)
@end
@implementation UISplitViewController (ZIKViewRouteContainer)
@end

@implementation ZIKViewRouteStrictConfiguration
@dynamic configuration;
@dynamic prepareDestination;
@dynamic successHandler;

- (instancetype)initWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    if (self = [super initWithConfiguration:configuration]) {
        NSCParameterAssert([configuration isKindOfClass:[ZIKViewRouteConfiguration class]]);
    }
    return self;
}
- (id<ZIKViewRouteSource>)source {
    return self.configuration.source;
}
- (void)setSource:(id<ZIKViewRouteSource>)source {
    self.configuration.source = source;
}
- (ZIKViewRouteType)routeType {
    return self.configuration.routeType;
}
- (void)setRouteType:(ZIKViewRouteType)routeType {
    self.configuration.routeType = routeType;
}
- (BOOL)animated {
    return self.configuration.animated;
}
- (void)setAnimated:(BOOL)animated {
    self.configuration.animated = animated;
}
- (ZIKViewRouteContainerWrapper)containerWrapper {
    return self.configuration.containerWrapper;
}
- (void)setContainerWrapper:(ZIKViewRouteContainerWrapper)containerWrapper {
    self.configuration.containerWrapper = containerWrapper;
}
- (id)sender {
    return self.configuration.sender;
}
- (void)setSender:(id)sender {
    self.configuration.sender = sender;
}
- (ZIKViewRoutePopoverConfiger)configurePopover {
    return self.configuration.configurePopover;
}
- (ZIKViewRouteSegueConfiger)configureSegue {
    return self.configuration.configureSegue;
}
- (void(^)(UIViewController *destination, void(^completion)(void)))addingChildViewHandler {
    return self.configuration.addingChildViewHandler;
}
- (void)setAddingChildViewHandler:(void (^)(UIViewController * _Nonnull, void (^ _Nonnull)(void)))addingChildViewHandler {
    self.configuration.addingChildViewHandler = addingChildViewHandler;
}
- (ZIKViewRoutePopoverConfiguration *)popoverConfiguration {
    return self.configuration.popoverConfiguration;
}
- (ZIKViewRouteSegueConfiguration *)segueConfiguration {
    return self.configuration.segueConfiguration;
}
- (BOOL)handleExternalRoute {
    return self.configuration.handleExternalRoute;
}
- (void)setHandleExternalRoute:(BOOL)handleExternalRoute {
    self.configuration.handleExternalRoute = handleExternalRoute;
}
@end

@implementation ZIKViewRemoveStrictConfiguration
@dynamic configuration;
- (instancetype)initWithConfiguration:(ZIKViewRemoveConfiguration *)configuration {
    if (self = [super initWithConfiguration:configuration]) {
        NSCParameterAssert([configuration isKindOfClass:[ZIKViewRemoveConfiguration class]]);
    }
    return self;
}
- (BOOL)animated {
    return self.configuration.animated;
}
- (void)setAnimated:(BOOL)animated {
    self.configuration.animated = animated;
}
- (void(^)(UIViewController *destination, void(^completion)(void)))removingChildViewHandler {
    return self.configuration.removingChildViewHandler;
}
- (void)setRemovingChildViewHandler:(void (^)(UIViewController * _Nonnull, void (^ _Nonnull)(void)))removingChildViewHandler {
    self.configuration.removingChildViewHandler = removingChildViewHandler;
}
- (BOOL)handleExternalRoute {
    return self.configuration.handleExternalRoute;
}
- (void)setHandleExternalRoute:(BOOL)handleExternalRoute {
    self.configuration.handleExternalRoute = handleExternalRoute;
}
@end
