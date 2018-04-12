//
//  ZIKViewRouterPrivate.h
//  ZIKRouter
//
//  Created by zuik on 2017/10/21.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKViewRouter.h"
#import "ZIKViewRouterType.h"

NS_ASSUME_NONNULL_BEGIN

///Private methods.
@interface ZIKViewRouter<__covariant Destination: id, __covariant RouteConfig: ZIKViewRouteConfiguration *> (Private)

+ (BOOL)shouldCheckImplementation;

///Is auto registration all finished.
+ (BOOL)_isRegistrationFinished;

+ (void)_swift_registerViewProtocol:(id)viewProtocol;

+ (void)_swift_registerConfigProtocol:(id)configProtocol;

#pragma mark Internal Initializer

+ (instancetype)routerFromSegueIdentifier:(NSString *)identifier sender:(nullable id)sender destination:(UIViewController *)destination source:(UIViewController *)source;
+ (instancetype)routerFromView:(UIView *)destination source:(UIView *)source;

@end

extern ZIKAnyViewRouterType *_Nullable _ZIKViewRouterToView(Protocol *viewProtocol);

extern ZIKAnyViewRouterType *_Nullable _ZIKViewRouterToModule(Protocol *configProtocol);

///Private method for ZRouter.
extern ZIKAnyViewRouterType *_Nullable _swift_ZIKViewRouterToView(id viewProtocol);
///Private method for ZRouter.
extern ZIKAnyViewRouterType *_Nullable _swift_ZIKViewRouterToModule(id configProtocol);

NS_ASSUME_NONNULL_END
