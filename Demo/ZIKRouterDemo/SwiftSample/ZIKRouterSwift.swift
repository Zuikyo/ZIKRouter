//
//  ZIKRouterSwift.swift
//  ZIKRouter
//
//  Created by zuik on 2017/9/8.
//  Copyright © 2017 zuik. All rights reserved.
//

import UIKit
import ZIKRouter.Internal

open class DynamicRouter {
    open class func router<DestinationType>(forView viewProtocol:DestinationType.Type) -> ZIKViewRouter<ZIKViewRouteConfiguration, ZIKViewRemoveConfiguration>.Type? {
        let routerClass = _Swift_ZIKViewRouterForView(viewProtocol) as? ZIKViewRouter.Type
        return routerClass
    }
    open class func router<DestinationType>(forService serviceProtocol:DestinationType.Type) -> ZIKServiceRouter<ZIKServiceRouteConfiguration, ZIKRouteConfiguration>.Type? {
        let routerClass = _Swift_ZIKServiceRouterForService(serviceProtocol) as? ZIKServiceRouter.Type
        return routerClass
    }
    open class func instantiateView<DestinationType>(for viewProtocol:DestinationType.Type, preparation prepare: @escaping (DestinationType) -> Swift.Void) -> DestinationType? {
        let routerClass: ZIKViewRouter.Type? = _Swift_ZIKViewRouterForView(viewProtocol) as? ZIKViewRouter.Type
        let router = routerClass?.init(configure: { config in
            config.routeType = ZIKViewRouteType.getDestination
            config.prepareForRoute = { d in
                let destination = d as! DestinationType
                prepare(destination)
            }
        }, removeConfigure: nil)
        router?.performRoute()
        return router?.destination as? DestinationType
    }
    open class func instantiateService<DestinationType>(for serviceProtocol:DestinationType.Type, configure configBuilder: (ZIKServiceRouteConfiguration) -> Swift.Void) -> DestinationType? {
        let routerClass: ZIKServiceRouter.Type? = _Swift_ZIKServiceRouterForService(serviceProtocol) as? ZIKServiceRouter.Type
        let router = routerClass?.init(configure: configBuilder, removeConfigure: nil)
        router?.performRoute()
        return router?.destination as? DestinationType
    }
}



//Rewrite return type to ZIKViewRouter.Type for ZIKViewRouterForView()
public func ZIKSViewRouterForView(_ viewProtocol: Protocol)->ZIKViewRouter<ZIKViewRouteConfiguration, ZIKViewRemoveConfiguration>.Type? {
    return ZIKViewRouterForView(viewProtocol) as? ZIKViewRouter.Type
}

//Rewrite return type to ZIKViewRouter.Type for ZIKViewRouterForConfig()
public func ZIKSViewRouterForConfig(_ configProtocol: Protocol)->ZIKViewRouter<ZIKViewRouteConfiguration, ZIKViewRemoveConfiguration>.Type? {
    return ZIKViewRouterForConfig(configProtocol) as? ZIKViewRouter.Type
}

//Rewrite return type to ZIKViewRouter.Type for ZIKServiceRouterForService()
public func ZIKSServiceRouterForService(_ serviceProtocol: Protocol)->ZIKServiceRouter<ZIKServiceRouteConfiguration, ZIKRouteConfiguration>.Type? {
    return ZIKServiceRouterForService(serviceProtocol) as? ZIKServiceRouter.Type
}

//Rewrite return type to ZIKViewRouter.Type for ZIKServiceRouterForConfig()
public func ZIKSServiceRouterForConfig(_ configProtocol: Protocol)->ZIKServiceRouter<ZIKServiceRouteConfiguration, ZIKRouteConfiguration>.Type? {
    return ZIKServiceRouterForConfig(configProtocol) as? ZIKServiceRouter.Type
}


