//
//  TestSubviewRouter.swift
//  ZIKRouterDemo-macOS
//
//  Created by zuik on 2018/10/28.
//Copyright © 2018 duoyi. All rights reserved.
//

import ZRouter
import ZIKRouter.Internal

class TestSubviewRouter: ZIKViewRouter<TestSubview, ViewRouteConfig> {
    
    override class func registerRoutableDestination() {
        registerExclusiveView(TestSubview.self)
        register(RoutableView<TestSubviewInput>())
    }
    
    override func destination(with configuration: ViewRouteConfig) -> TestSubview? {
        let destination: TestSubview? = TestSubview()
        return destination
    }
    
    override func prepareDestination(_ destination: TestSubview, configuration: ViewRouteConfig) {
        destination.router = self
    }
    
    // If the destiantion is NSView, override and return route types for NSView
    override class func supportedRouteTypes() -> ZIKViewRouteTypeMask {
        return .viewDefault
    }
    
    override class func router(_ router: ZIKViewRouter<AnyObject, ZIKViewRouteConfiguration>?, willPerformRouteOnDestination destination: TestSubview, fromSource source: Any?) {
        print("""
            ----------------------\nrouter: (\(router ?? "nil" as Any)),
            ➡️ will
            perform route
            from source: (\(source ?? "nil" as Any)),
            destination: (\(destination))\n----------------------
            """
        )
    }
    
    override class func router(_ router: ZIKViewRouter<AnyObject, ZIKViewRouteConfiguration>?, didPerformRouteOnDestination destination: TestSubview, fromSource source: Any?) {
        print("""
            ----------------------\nrouter: (\(router ?? "nil" as Any)),
            ✅ did
            perform route
            from source: (\(source ?? "nil" as Any)),
            destination: (\(destination))\n----------------------
            """
        )
    }
    
    override class func router(_ router: ZIKViewRouter<AnyObject, ZIKViewRouteConfiguration>?, willRemoveRouteOnDestination destination: TestSubview, fromSource source: Any?) {
        print("""
            ----------------------\nrouter: (\(router ?? "nil" as Any)),
            ⬅️ will
            remove route
            from source: (\(source ?? "nil" as Any)),
            destination: (\(destination))\n----------------------
            """
        )
    }
    
    override class func router(_ router: ZIKViewRouter<AnyObject, ZIKViewRouteConfiguration>?, didRemoveRouteOnDestination destination: TestSubview, fromSource source: Any?) {
        print("""
            ----------------------\nrouter: (\(router ?? "nil" as Any)),
            ❎ did
            remove route
            from source: (\(source ?? "nil" as Any)),
            destination: (\(destination))\n----------------------
            """
        )
    }
}

extension TestSubview: ZIKRoutableView {

}

extension RoutableView where Protocol == TestSubviewInput {
    init() { self.init(declaredTypeName: "NSView & SubviewInput") }
}
