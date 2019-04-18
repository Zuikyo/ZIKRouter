//
//  TestViewController.swift
//  ZIKRouterDemo-macOS
//
//  Created by zuik on 2018/10/28.
//  Copyright © 2018 zuik. All rights reserved.
//

import Cocoa
import ZRouter
import ZIKRouter

class TestViewController: NSViewController, TestViewInput {
    var message: String = "" {
        didSet {
            if isViewLoaded {
                messageLabel.stringValue = message
            }
        }
    }
    @IBOutlet weak var messageLabel: NSTextField!
    
    var router: ZIKViewRouter<TestViewController, ViewRouteConfig>!
    
    override func viewDidLoad() {
        messageLabel.stringValue = message
    }
    
    @IBAction func removeSelf(_ sender: Any) {
        router.removeRoute(configuring: { (config) in
            config.performerSuccessHandler = {
                print("remove test view success")
            }
            config.performerErrorHandler = { (action, error) in
                print("remove test view failed")
            }
        })
    }
}
