//
//  TestSubview.swift
//  ZIKRouterDemo-macOS
//
//  Created by zuik on 2018/10/28.
//  Copyright © 2018 duoyi. All rights reserved.
//

import AppKit
import ZIKRouter
import ZRouter

class TestSubview: NSView, SubviewInput {
    var router: ZIKViewRouter<TestSubview, ViewRouteConfig>!
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        assembleSubviews()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        assembleSubviews()
    }
    
    func assembleSubviews() {
        self.setFrameSize(NSSize(width: 100, height: 100))
        self.layer?.backgroundColor = NSColor.red.cgColor
        if #available(OSX 10.12, *) {
            let button = NSButton(title: "remove self", target: self, action: #selector(removeSelf(_:)))
            button.frame = NSMakeRect(0, 0, 100, 30)
            self.addSubview(button)
        }
    }
    
    @objc func removeSelf(_ sender: Any) {
        router.removeRoute(configuring: { (config) in
            config.successHandler = {
                print("remove test view success")
            }
            config.errorHandler = { (action, error) in
                print("remove test view failed")
            }
        })
    }
}
