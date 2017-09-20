//
//  ZIKRouterSwift.swift
//  ZIKRouter
//
//  Created by zuik on 2017/9/8.
//  Copyright © 2017年 zuik. All rights reserved.
//

import UIKit
import ZIKRouter

//Rewrite return type to ZIKViewRouter.Type for ZIKViewRouterForView()
func ZIKSViewRouterForView(_ viewProtocol: Protocol)->ZIKViewRouter<ZIKViewRouteConfiguration, ZIKViewRemoveConfiguration>.Type? {
    return ZIKViewRouterForView(viewProtocol) as? ZIKViewRouter.Type
}

//Rewrite return type to ZIKViewRouter.Type for ZIKViewRouterForConfig()
func ZIKSViewRouterForConfig(_ configProtocol: Protocol)->ZIKViewRouter<ZIKViewRouteConfiguration, ZIKViewRemoveConfiguration>.Type? {
    return ZIKViewRouterForConfig(configProtocol) as? ZIKViewRouter.Type
}

//Rewrite return type to ZIKViewRouter.Type for ZIKServiceRouterForService()
func ZIKSServiceRouterForService(_ serviceProtocol: Protocol)->ZIKServiceRouter<ZIKServiceRouteConfiguration, ZIKRouteConfiguration>.Type? {
    return ZIKServiceRouterForService(serviceProtocol) as? ZIKServiceRouter.Type
}

//Rewrite return type to ZIKViewRouter.Type for ZIKServiceRouterForConfig()
func ZIKSServiceRouterForConfig(_ configProtocol: Protocol)->ZIKServiceRouter<ZIKServiceRouteConfiguration, ZIKRouteConfiguration>.Type? {
    return ZIKServiceRouterForConfig(configProtocol) as? ZIKServiceRouter.Type
}
