//
//  SwiftSampleViewController.swift
//  ZIKRouterDemo
//
//  Created by zuik on 2017/9/8.
//  Copyright © 2017 zuik. All rights reserved.
//

import UIKit
import ZIKRouter
import ZRouter
import ZIKAlertModule

/// The protocol is routable in both Swift and objc.
@objc public protocol SwiftSampleViewInput: ZIKViewRoutable {
    
}

protocol PureSwiftSampleViewInput {
    
}

// Show how ZIKRouter working in a swifty way.
class SwiftSampleViewController: UIViewController, PureSwiftSampleViewInput, SwiftSampleViewInput, ZIKInfoViewDelegate, UIViewControllerPreviewingDelegate {
    
    var anyRouter: ZIKAnyViewRouter?
    var infoRouter: DestinationViewRouter<ZIKInfoViewProtocol>? {
        willSet { anyRouter = newValue?.router }
    }
    var switchableRouter: AnyViewRouter? {
        willSet { anyRouter = newValue?.router }
    }
    var alertRouter: ModuleViewRouter<RequiredCompatibleAlertModuleInput>?
    
    var adapterRouter: DestinationViewRouter<UIViewController & ZIKInfoViewProtocol>? {
        willSet { anyRouter = newValue?.router }
    }
    
    override func viewDidLoad() {
        if #available(iOS 9.0, *) {
            registerForPreviewing(with: self, sourceView: view)
        }
    }
    
    deinit {
        print("\(self) deinit")
    }
    
    @IBAction func testRouteForView(_ sender: Any) {
        // Not necessary to hold the router, here is just for demonstrating
        infoRouter = Router.perform(
            to: RoutableView<ZIKInfoViewProtocol>(),
            path: .presentModally(from: self),
            configuring: { (config, _) in
                config.prepareDestination = { [weak self] destination in
                    destination.delegate = self
                    destination.name = "zuik"
                    destination.age = 18
                }
        })
    }
    
    func handleRemoveInfoViewController(_ infoViewController: UIViewController) {
        guard let router = anyRouter, router.canRemove() else {
            return
        }
        router.removeRoute(successHandler: {
            print("remove success")
        }, errorHandler: { (action, error) in
            print("remove failed,error:%@",error)
        })
        anyRouter = nil
    }
    
    @IBAction func testRouteForConfig(_ sender: Any) {
        alertRouter = Router.perform(
            to: RoutableViewModule<RequiredCompatibleAlertModuleInput>(),
            path: .extensible(path: .presentCompatibleAlertFrom(self)),
            configuring: { (config, prepareModule) in
                config.successHandler = { d in
                    print("show custom alert complete")
                }
                config.errorHandler = { (action, error) in
                    print("show custom alert failed: %@",error)
                }
                prepareModule({ module in
                    module.title = "Compatible Alert"
                    module.message = "Test custom route for alert with UIAlertView and UIAlertController"
                    module.addCancelButtonTitle("Cancel", handler: {
                        print("Tap cancel alert")
                    })
                    module.addOtherButtonTitle("Hello", handler: {
                        print("Tap Hello alert")
                    })
                })
        })
    }
    
    @IBAction func testSwitchableRoute(_ sender: Any) {
        var switchableView: SwitchableView
        let viewType = arc4random() % 2
        switch viewType {
        case 0:
            switchableView = SwitchableView(RoutableView<ZIKInfoViewProtocol>())
        default:
            switchableView = SwitchableView(RoutableView<SwiftSampleViewInput>())
        }
        
        switchableRouter = Router.to(switchableView)?
            .perform(path: .push(from: self),
                     preparation: { [weak self] (destination) in
                        switch destination {
                        case let destination as UIViewController & ZIKInfoViewProtocol:
                            destination.delegate = self
                            destination.title = "switchable routed"
                        case let destination as UIViewController & SwiftSampleViewInput:
                            destination.title = "switchable routed"
                            break
                        default:
                            break
                        }
            })
    }
    
    @IBAction func testAdapterWithComposedType(_ sender: UIButton) {
        adapterRouter = Router.perform(to: RoutableView<RequiredInfoViewInput>(), path: .presentModally(from: self), preparation: { [weak self] (destination) in
            destination.delegate = self
            destination.name = "zuik"
            destination.age = 18
        })
    }
    
    @IBAction func testEasyViewRoute1(_ sender: Any) {
        let router = Router.perform(to: RoutableViewModule<EasyViewModuleInput>(), path: .presentModally(from: self)) { (config) in
            var config = config
            config.constructDestination("zuik", 12)
            config.didMakeDestination = { destination in
                print("did make destination: \(destination)")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            router?.removeRoute()
        }
    }
    
    @IBAction func testEasyViewRoute2(_ sender: Any) {
        let router = Router.perform(
            to: RoutableView<EasyViewInput2>(),
            path: .presentModally(from: self),
            configuring: { (config, _) in
                config.prepareDestination = { destination in
                    
                }
                config.successHandler = { destination in
                    
                }
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            router?.removeRoute()
        }
    }
    
    @IBAction func testEasyServiceRoute1(_ sender: Any) {
        let service = Router.makeDestination(to: RoutableService<EasyServiceInput>())
        print("easy service: \(String(describing: service))")
    }
    
    @IBAction func testEasyServiceRoute2(_ sender: Any) {
        let service = Router.makeDestination(to: RoutableService<EasyServiceInput2>())
        print("easy service: \(String(describing: service))")
        
        Router.perform(to: RoutableServiceModule<EasyServiceModuleInput>()) { (module) in
            var module = module
            module.constructDestination("123")            
            module.didMakeDestination = { destiantion in
                print("easy service2: \(String(describing: destiantion))")
            }
        }
    }

    @IBAction func testRouteForSwiftService(_ sender: Any) {
        let service = Router.makeDestination(to: RoutableService<SwiftServiceInput>())
        service?.swiftFunction()
    }
    
    @IBAction func testRouteForSwiftServiceModule(_ sender: Any) {
        Router.perform(to: RoutableServiceModule<SwiftServiceModuleInput>()) { (config) in
            config.constructDestination("123")
            config.didMakeDestination = { service in
                service.swiftFunction()
            }
        }
    }
    
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        let destination = Router.makeDestination(to: RoutableView<ZIKInfoViewProtocol>())
        return destination as? UIViewController
    }
    
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        guard let destination = viewControllerToCommit as? ZIKInfoViewProtocol else {
            return
        }
        infoRouter = Router.to(RoutableView<ZIKInfoViewProtocol>())?.perform(onDestination: destination, path: .presentModally(from: self), configuring: { (config, _) in
            config.prepareDestination = { [weak self] d in
                d.delegate = self
                d.name = "test"
            }
        })
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
