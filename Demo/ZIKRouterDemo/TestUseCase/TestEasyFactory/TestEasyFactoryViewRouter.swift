//
//  TestEasyFactoryViewRouter.swift
//  ZIKRouterDemo
//
//  Created by zuik on 2019/2/1.
//Copyright © 2019 zuik. All rights reserved.
//

import ZRouter
import ZIKRouter.Internal

class TestEasyFactoryViewRouter: ZIKViewRouter<TestEasyFactoryViewController, ViewRouteConfig> {
    
    override class func registerRoutableDestination() {
        registerExclusiveView(TestEasyFactoryViewController.self)
        registerIdentifier("testEasyFactory")
    }
    
    override func destination(with configuration: ViewRouteConfig) -> TestEasyFactoryViewController? {
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        let destination = sb.instantiateViewController(withIdentifier: "TestEasyFactoryViewController") as! TestEasyFactoryViewController
        destination.title = "Test Easy Factory"
        return destination
    }
    
    override func prepareDestination(_ destination: TestEasyFactoryViewController, configuration: ViewRouteConfig) {
        // Prepare destination
    }
}

extension TestEasyFactoryViewController: ZIKRoutableView {
    
}
