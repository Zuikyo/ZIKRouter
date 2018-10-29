//
//  MainViewController.swift
//  ZIKRouterDemo-macOS
//
//  Created by zuik on 2018/10/27.
//  Copyright © 2018 duoyi. All rights reserved.
//

import Cocoa
import ZIKLoginModule
import ZRouter

enum TestRouteType: Int {
    case presentModally = 0
    case presentAsPopover
    case presentAsSheet
    case presentWithAnimator
    case performSegue
    case show
    case addAsChildViewController
    case addAsSubview
    case custom
    case makeDestination
    case modulization
}

class MainViewController: NSViewController {
    
    var selectedTestType: TestRouteType = .presentModally

    @IBAction func selectTestCase(_ sender: NSPopUpButton) {
        let index = sender.indexOfSelectedItem
        if let type = TestRouteType(rawValue: index) {
            selectedTestType = type
        }
    }
    
    @IBAction func show(_ sender: NSButton) {
        switch selectedTestType {
        case .presentModally:
            testPresentModally()
        case .presentAsPopover:
            testPresentAsPopover(sender)
        case .presentAsSheet:
            testPresentAsSheet()
        case .presentWithAnimator:
            testPresentWithAnimator()
        case .performSegue:
            testPerformSegue()
        case .show:
            testShow()
        case .addAsChildViewController:
            testAddAsChildViewController()
        case .addAsSubview:
            testAddAsSubview()
        case .custom:
            testCustom()
        case .makeDestination:
            testMakeDestination()
        case .modulization:
            testModulization()
        }
    }
    
    func testPresentModally() {
        Router.perform(to: RoutableView<TestViewInput>(), path: .presentModally(from: self), configuring: { (config,_) in
            config.prepareDestination = { destination in
                destination.message = "testPresentModally"
            }
            config.successHandler = { d in
                
            }
            })
    }
    
    func testPresentAsPopover(_ sender: NSButton) {
        Router.perform(
            to: RoutableView<TestViewInput>(),
            path: .presentAsPopover(from: self, configure: { (config) in
                config.sourceRect = NSMakeRect(0, 0, 200, 200)
                config.sourceView = sender
            }),
            preparation: { (destination) in
                destination.message = "testPresentAsPopover"
        })
    }
    
    func testPresentAsSheet() {
        Router.perform(to: RoutableView<TestViewInput>(), path: .presentAsSheet(from: self), preparation: { (destination) in
            destination.message = "testPresentAsSheet"
        })
    }
    
    func testPresentWithAnimator() {
        Router.perform(to: RoutableView<TestViewInput>(), path: ViewRoutePath.present(from: self, animator: TestAnimator()), preparation: { (destination) in
            destination.message = "testPresentWithAnimator"
        })
    }
    
    func testPerformSegue() {
        Router.perform(to: RoutableView<TestViewInput>(), path: ViewRoutePath.performSegue(from: self, identifier: "TestViewRouter", sender: nil), preparation: { (destination) in
            destination.message = "testPerformSegue"
        })
    }
    
    func testShow() {
        Router.perform(to: RoutableView<TestViewInput>(), path: .show, preparation: { (destination) in
            destination.message = "testShow"
        })
    }
    
    func testAddAsChildViewController() {
        Router.perform(
            to: RoutableView<TestViewInput>(),
            path: .addAsChildViewController(from: self, addingChildViewHandler: { [weak self] (destination, completion) in
                guard let self = self else {
                    return
                }
                self.view.addSubview(destination.view)
                completion()
            }),
            preparation: { (destination) in
                destination.message = "testAddAsChildViewController"
        })
    }
    
    func testAddAsSubview() {
        Router.perform(to: RoutableView<TestSubviewInput>(), path: .addAsSubview(from: self.view), preparation: { destination in
            destination.frame = NSMakeRect(100, 50, 100, 100)
        })
    }
    
    func testCustom() {
        Router.perform(to: RoutableView<TestViewInput>(), path: .custom(from: self), preparation: { destination in
            destination.message = "testCustom"
        })
    }
    
    func testPerformAlert() {
        Router.perform(to: RoutableViewModule<AlertViewModuleInput>(), path: .defaultPath(from: self), configuring: { (config, prepareModule) in
            prepareModule({ module in
                module.title = "testCustom"
                module.message = "This is a NSAlert from view router"
                module.addButton(withTitle: "Hello", handler: {
                    print("Hello button is tapped")
                })
                module.addButton(withTitle: "Hi", handler: {
                    print("Hi button is tapped")
                })
                module.addCancelButton(withTitle: "Cancel", handler: {
                    print("Cancel button is tapped")
                })
            })
        })
    }
    
    func testMakeDestination() {
        let dest = Router.makeDestination(to: RoutableView<TestViewInput>(), preparation: { (destination) in
            destination.message = "testMakeDestination"
        })
        guard let destination = dest else {
            return
        }
        Router.to(RoutableView<TestViewInput>())?.perform(onDestination: destination, path: .presentModally(from: self))
    }
    
    func testModulization() {
        Router.perform(to: RoutableView<RequiredLoginViewInput>(), path: .defaultPath(from: self))
    }
}


class TestAnimator: NSObject, NSViewControllerPresentationAnimator {
    func animatePresentation(of viewController: NSViewController, from fromViewController: NSViewController) {
        fromViewController.view.addSubview(viewController.view)
    }
    
    func animateDismissal(of viewController: NSViewController, from fromViewController: NSViewController) {
        viewController.view.removeFromSuperview()
    }
}
