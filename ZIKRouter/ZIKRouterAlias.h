//
//  ZIKRouterAlias.h
//  ZIKRouter
//
//  Created by zuik on 2017/11/6.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKViewRouter.h"
#import "ZIKServiceRouter.h"

typedef ZIKRouteConfiguration ZIKRouteConfig;

typedef ZIKViewRouteConfiguration ZIKViewRouteConfig;
typedef ZIKViewRemoveConfiguration ZIKViewRemoveConfig;
typedef ZIKViewRouter<ZIKViewRouteConfig *, ZIKViewRemoveConfig *> ZIKDefaultViewRouter;

typedef ZIKServiceRouteConfiguration ZIKServiceRouteConfig;
typedef ZIKServiceRouter<ZIKServiceRouteConfig *, ZIKRouteConfig *> ZIKDefaultServiceRouter;
