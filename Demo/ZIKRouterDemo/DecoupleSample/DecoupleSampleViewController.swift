//
//  DecoupleSampleViewController.swift
//  ZIKRouterDemo
//
//  Created by zuik on 2019/6/22.
//  Copyright © 2019 zuik. All rights reserved.
//

import UIKit
import ZRouter
import ZIKLoginModule

class DecoupleSampleViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        let button = UIButton(type: .system)
        button.setTitle("show login view", for: .normal)
        button.frame.size = CGSize(width: 200, height: 100)
        button.center = CGPoint(x: view.center.x, y: 150)
        button.addTarget(self, action: #selector(showLoginView), for: .touchUpInside)
        view.addSubview(button)
        
        let descriptionView = UITextView()
        descriptionView.frame.origin = CGPoint(x: 0, y: 200)
        descriptionView.frame.size = CGSize(width: 400, height: 650)
        descriptionView.center.x = view.center.x
        descriptionView.font = UIFont.systemFont(ofSize: 16)
        descriptionView.text = """
        How to decouple modules:
        
        1. Get module or show view module with its protocol:
        OC:
            [ZIKRouterToView(ZIKLoginViewInput) performPath:ZIKViewRoutePath.pushFrom(self)]
        
        Swift:
            Router.perform(to: RoutableView<ZIKLoginViewInput>(), path: .presentModally(from: self))
        
        This decouples the login module. The host app can replace it with another login module easily.
        
        
        2. Inject dependency with adapter:
        // ZIKLoginModule requires an alert module with ZIKLoginModuleRequiredAlertInput
        // The host app binds ZIKLoginModuleRequiredAlertInput with the real provided alert module ZIKCompatibleAlertModuleInput
        // See DemoRouteAdapter.m
        [ZIKViewRouteAdapter registerModuleAdapter:ZIKRoutable(ZIKLoginModuleRequiredAlertInput) forAdaptee:ZIKRoutable(ZIKCompatibleAlertModuleInput)]
        
        Then ZIKLoginModule and ZIKAlertModule are totally decoupled.
        You can replace the provided alert module with any other alert module.
        See AlertViewModuleInput in ZIKRouterDemo-macOS.
        """
        let attributedString = NSMutableAttributedString(string: descriptionView.text)
        attributedString.addAttribute(NSAttributedStringKey.backgroundColor, value: UIColor.green, range: NSRange(location: 79, length: 190))
        attributedString.addAttribute(NSAttributedStringKey.backgroundColor, value: UIColor.green, range: NSRange(location: 402, length: 372))
        attributedString.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 16), range: NSRange(location: 0, length: descriptionView.text.count))
        descriptionView.attributedText = attributedString
        descriptionView.isEditable = false
        view.addSubview(descriptionView)
    }

    @objc func showLoginView() {
        Router.perform(to: RoutableView<ZIKLoginViewInput>(),
                       path: .presentModally(from: self))
    }
}
