//
//  ServiceRouter.swift
//  ZRouter
//
//  Created by zuik on 2017/11/5.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import ZIKRouter

///Type safe service router for declared service protocol. Generic parameter `Destination` is the protocol conformed by the service. See `ViewRoute` to learn how to declare a routable protocol.
open class ServiceRouter<Destination> {
    
}

public protocol ServiceRoutePerformer {
    associatedtype Destination
}

public extension ServiceRoutePerformer {
    
    /// Perform route with service protocol and prepare the destination with the protocol.
    ///
    /// - Parameters:
    ///   - configure: Configure the configuration for service route.
    ///   - prepare: Prepare the destination with the protocol.
    /// - Returns: The service router.
    public static func perform(
        routeConfig configure: (ServiceRouteConfig) -> Swift.Void,
        preparation prepare: ((Destination) -> Swift.Void)? = nil
        ) -> DefaultServiceRouter? {
        return Router.perform(forServiceProtocol: Destination.self, routeConfig: configure, preparation: prepare)
    }
    
    /// Get view destination conforming the service protocol.
    ///
    /// - Parameters:
    ///   - prepare: Prepare the destination with the protocol.
    /// - Returns: The service destination.
    public static func makeDestination(preparation prepare: ((Destination) -> Swift.Void)? = nil) -> Destination? {
        return Router.makeDestination(forServiceProtocol: Destination.self, preparation: prepare)
    }
}

///All objc protocols inherited from ZIKServiceRoutable are routable.
public extension ServiceRouter where Destination: ZIKServiceRoutable {
    public static var route: ServiceRoute<Destination>.Type {
        return ServiceRoute<Destination>.self
    }
}

///Wrapper router for routable service protocol.
///SeeAlso: `ViewRoute`.
public struct ServiceRoute<Service>: ServiceRoutePerformer {
    public typealias Destination = Service
}
