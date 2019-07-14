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
        descriptionView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin, .flexibleWidth, .flexibleHeight]
        descriptionView.font = UIFont.systemFont(ofSize: 16)
        
        let code1 = """
        OC:
            [ZIKRouterToView(ZIKLoginViewInput) performPath:ZIKViewRoutePath.pushFrom(self)]
        
        Swift:
            Router.perform(to: RoutableView<ZIKLoginViewInput>(), path: .presentModally(from: self))

        """
        let code2 = """
        OC:
            // See See DemoRouteAdapter.m
            [ZIKViewRouteAdapter registerDestinationAdapter:ZIKRoutable(RequiredLoginViewInput) forAdaptee:ZIKRoutable(ZIKLoginViewInput)]
        
        Swift:
            ZIKViewRouteAdapter.register(adapter: RoutableView<RequiredLoginViewInput>(), forAdaptee: RoutableView<ZIKLoginViewInput>())

        """
        let code3 = """
        OC:
            [ZIKRouterToView(RequiredLoginViewInput) performPath:ZIKViewRoutePath.pushFrom(self)]
        
        Swift:
            Router.perform(to: RoutableView<RequiredLoginViewInput>(), path: .presentModally(from: self))

        """
        let code4 = """
        // ZIKLoginModule requires an alert module with ZIKLoginModuleRequiredAlertInput
        // The host app binds ZIKLoginModuleRequiredAlertInput with the real provided alert module ZIKCompatibleAlertModuleInput

        OC:
        // See DemoRouteAdapter.m
        [ZIKViewRouteAdapter registerModuleAdapter:ZIKRoutable(ZIKLoginModuleRequiredAlertInput) forAdaptee:ZIKRoutable(ZIKCompatibleAlertModuleInput)]

        Swift:
        ZIKViewRouteAdapter.register(adapter: RoutableView<ZIKLoginModuleRequiredAlertInput>(), forAdaptee: RoutableView<ZIKCompatibleAlertModuleInput>())

        """
        let content = """
        How to decouple modules:
        
        1. Get module or show view module with its protocol:
        \(code1)
        This decouples the login module from the login class.
        
        2. Adapt required protocol with the provided protocol:
        \(code2)
        Then RequiredLoginViewInput works like ZIKLoginViewInput:
        
        \(code3)
        This decouples the login module from its protocol. The host app can replace it with another login module easily.
        
        
        3. Inject dependency with adapter:
        \(code4)
        Then ZIKLoginModule and ZIKAlertModule are totally decoupled.
        You can replace the provided alert module with any other alert module.
        See AlertViewModuleInput in ZIKRouterDemo-macOS.
        """
        descriptionView.text = content
        let attributedString = NSMutableAttributedString(string: descriptionView.text)
        let contentString = content as NSString
        attributedString.addAttribute(NSAttributedStringKey.backgroundColor, value: UIColor.green, range: contentString.range(of: code1))
        attributedString.addAttribute(NSAttributedStringKey.backgroundColor, value: UIColor.green, range: contentString.range(of: code2))
        attributedString.addAttribute(NSAttributedStringKey.backgroundColor, value: UIColor.green, range: contentString.range(of: code3))
        attributedString.addAttribute(NSAttributedStringKey.backgroundColor, value: UIColor.green, range: contentString.range(of: code4))
        attributedString.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 16), range: NSRange(location: 0, length: descriptionView.text.count))
        descriptionView.attributedText = attributedString
        descriptionView.isEditable = false
        view.addSubview(descriptionView)
    }

    @objc func showLoginView() {
        Router.perform(to: RoutableView<RequiredLoginViewInput>(), path: .presentModally(from: self))
    }
}
