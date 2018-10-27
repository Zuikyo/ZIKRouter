//
//  AlertViewModuleInput.swift
//  ZIKRouterDemo-macOS
//
//  Created by zuik on 2018/10/27.
//Copyright © 2018 duoyi. All rights reserved.
//



import Cocoa

// Alert module for mac OS
protocol AlertViewModuleInput: class {
    var title: String { get set }
    var message: String? { get set }
    func addButton(withTitle title: String, handler: (() -> Void)?)
    func addCancelButton(withTitle title: String, handler: (() -> Void)?)
}

// Real alert is NSAlert, this is just for view router
class AlertViewController: NSViewController {
    
    override func loadView() {
        self.view = NSView()
    }

}
