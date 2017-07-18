//
//  ZIKViewRouter+ZIKViper.h
//  ZIKViperDemo
//
//  Created by zuik on 2017/6/15.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKViewRouter.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ZIKViperViewPrivate;
@protocol ZIKViperPresenterPrivate;
@protocol ZIKViperInteractorPrivate;

@interface ZIKViewRouter (ZIKViper)
- (nullable ZIKViewRouter *)parentRouter;
- (BOOL)isViperAssemblied;
+ (BOOL)isViperAssembliedForView:(id<ZIKViperViewPrivate>)view;
- (void)assemblyViperForView:(id<ZIKViperViewPrivate>)view
                   presenter:(id<ZIKViperPresenterPrivate>)presenter
                  interactor:(id<ZIKViperInteractorPrivate>)interactor;
@end

NS_ASSUME_NONNULL_END
