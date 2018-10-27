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
    
}

extension TestViewController: ZIKRoutableView {
    
}

extension RoutableView where Protocol == TestViewInput {
    init() { self.init(declaredTypeName: "TestViewInput") }
}
