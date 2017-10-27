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

NS_ASSUME_NONNULL_BEGIN

///Private methods.
@interface ZIKViewRouter ()

///Is registration all finished.
+ (BOOL)_isLoadFinished;

@end

///Private method for ZIKRouterSwift.
extern _Nullable Class _Swift_ZIKViewRouterForView(id viewProtocol);
///Private method for ZIKRouterSwift.
extern _Nullable Class _Swift_ZIKViewRouterForConfig(id configProtocol);

NS_ASSUME_NONNULL_END
