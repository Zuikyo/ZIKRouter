//
//  TestViewRouter.swift
//  ZIKRouterDemo-macOS
//
//  Created by zuik on 2018/10/28.
//Copyright © 2018 duoyi. All rights reserved.
//

import ZRouter
import ZIKRouter.Internal

class TestViewRouter: ZIKViewRouter<TestViewController, ViewRouteConfig> {
    
    override class func registerRoutableDestination() {
        registerExclusiveView(TestViewController.self)
        register(RoutableView<TestViewInput>())
    }
    
    override func destination(with configuration: ViewRouteConfig) -> TestViewController? {
        let destination: TestViewController? = TestViewController()
        return destination
    }
    
    override func prepareDestination(_ destination: TestViewController, configuration: ViewRouteConfig) {
        destination.router = self
    }
    
    @objc class func applicationDidHide(_ notification: Notification) {
        print("\(self) handle applicationDidHide")
    }
    
    override class func router(_ router: ZIKViewRouter<AnyObject, ZIKViewRouteConfiguration>?, willPerformRouteOnDestination destination: TestViewController, fromSource source: Any?) {
        
        print("""
            ----------------------\nrouter: (\(router ?? "nil" as Any)),
            ➡️ will
            perform route
            from source: (\(source ?? "nil" as Any)),
            destination: (\(destination)),\n----------------------
            """
        )
    }
    
    override class func router(_ router: ZIKViewRouter<AnyObject, ZIKViewRouteConfiguration>?, didPerformRouteOnDestination destination: TestViewController, fromSource source: Any?) {
        print("""
            ----------------------\nrouter: (\(router ?? "nil" as Any)),
            ✅ did
            perform route
            from source: (\(source ?? "nil" as Any)),
            destination: (\(destination)),\n----------------------
            """
        )
    }
    
    override class func router(_ router: ZIKViewRouter<AnyObject, ZIKViewRouteConfiguration>?, willRemoveRouteOnDestination destination: TestViewController, fromSource source: Any?) {
        print("""
            ----------------------\nrouter: (\(router ?? "nil" as Any)),
            ⬅️ will
            remove route
            from source: (\(source ?? "nil" as Any)),
            destination: (\(destination)),\n----------------------
            """
        )
    }
    
    override class func router(_ router: ZIKViewRouter<AnyObject, ZIKViewRouteConfiguration>?, didRemoveRouteOnDestination destination: TestViewController, fromSource source: Any?) {
        print("""
            ----------------------\nrouter: (\(router ?? "nil" as Any)),
            ❎ did
            remove route
            from source: (\(source ?? "nil" as Any)),
            destination: (\(destination)),\n----------------------
            """
        )
    }
}

extension TestViewController: ZIKRoutableView {
    
}

extension RoutableView where Protocol == TestViewInput {
    init() { self.init(declaredTypeName: "TestViewInput") }
}
