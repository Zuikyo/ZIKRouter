//
//  ZIKViewRouter+ZIKViper.m
//  ZIKViperDemo
//
//  Created by zuik on 2017/6/15.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKViewRouter+ZIKViper.h"
#import "ZIKRouter+Private.h"
#import "ZIKViperRouter.h"
#import "ZIKViperViewPrivate.h"
#import "ZIKViperPresenterPrivate.h"
#import "ZIKViperInteractorPrivate.h"

@implementation ZIKViewRouter (ZIKViper)

- (nullable ZIKViewRouter *)parentRouter {
    id parentRouter;
    id<ZIKViperPresenter> presenter = [(id)self presenter];
    id<ZIKViperView> view = presenter.view;
    if ([(id)view isKindOfClass:[UIView class]]) {
        parentRouter = [(id)view parentRouter];
    } else if ([(id)view isKindOfClass:[UIViewController class]]) {
        parentRouter = [(id)view parentRouter];
    } else {
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"view: %@ of presenter: %@ is not supported",view,presenter] userInfo:nil] raise];
    }
    return parentRouter;
}

- (BOOL)isViperAssemblied {
    id<ZIKViperViewPrivate> view = self.destination;
    return [ZIKViewRouter isViperAssembliedForView:view];
}

+ (BOOL)isViperAssembliedForView:(id<ZIKViperViewPrivate>)view {
    if (!view) {
        return NO;
    }
    NSAssert([view conformsToProtocol:@protocol(ZIKViperViewPrivate)], @"Only available when destination is ZIKViperView");
    id<ZIKViperPresenterPrivate> presenter = [view presenter];
    if (!presenter) {
        return NO;
    }
    id<ZIKViperInteractor> interactor = presenter.interactor;
    if (!interactor) {
        return NO;
    }
    return YES;
}

- (void)assemblyViperForView:(id<ZIKViperViewPrivate>)view
                   presenter:(id<ZIKViperPresenterPrivate>)presenter
                  interactor:(id<ZIKViperInteractorPrivate>)interactor {
    NSParameterAssert([view conformsToProtocol:@protocol(ZIKViperViewPrivate)]);
    NSParameterAssert([presenter conformsToProtocol:@protocol(ZIKViperPresenterPrivate)]);
    NSParameterAssert([interactor conformsToProtocol:@protocol(ZIKViperInteractor)]);
    interactor.eventHandler = presenter;
    interactor.dataSource = presenter;
    presenter.interactor = interactor;
    presenter.view = view;
    presenter.router = self;
    view.presenter = presenter;
}

@end
