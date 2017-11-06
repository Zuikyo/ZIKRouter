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

///Mark the protocol routable 
@objc public protocol SwiftSampleViewInput: ZIKViewRoutable {
    
}

protocol PureSwiftSampleViewInput {
    
}
protocol PureSwiftSampleViewInput2 {
    
}

class SwiftSampleViewController: UIViewController,PureSwiftSampleViewInput, PureSwiftSampleViewInput2, SwiftSampleViewInput, ZIKInfoViewDelegate {
    var infoRouter: DefaultViewRouter?
    var alertRouter: ConfigurableViewRouter<ViewRouteConfig & ZIKCompatibleAlertConfigProtocol>?
    
    //You can inject alertRouterClass from outside, then use the router directly
    var alertRouterClass: ConfigurableViewRouter<ViewRouteConfig & ZIKCompatibleAlertConfigProtocol>.Type!
    
    @IBAction func testRouteForView(_ sender: Any) {
        testSwiftyRouteForView()
    }
    
    func testSwiftyRouteForView() {
        infoRouter = Router.perform(
            for: RoutableView<ZIKInfoViewProtocol>(),
            routeConfig: { config in
                config.source = self
                config.routeType = ViewRouteType.presentModally
        },
            preparation: { [weak self] destination in
                destination.delegate = self
                destination.name = "zuik"
                destination.age = 18
            })
    }
    
    func testRouteForView() {
        infoRouter = Registry.router(for: RoutableView<ZIKInfoViewProtocol>())?.perform { config in
            config.source = self
            config.routeType = ViewRouteType.presentModally
            config.prepareForRoute = { [weak self] d in
                guard let destination = d as? ZIKInfoViewProtocol else {
                    return
                }
                destination.delegate = self
                destination.name = "zuik"
                destination.age = 18
            }
        }
    }
    
    func handleRemoveInfoViewController(_ infoViewController: UIViewController!) {
        infoRouter?.removeRoute(successHandler: {
            print("remove success")
        }, errorHandler: { (action, error) in
            print("remove failed,error:%@",error)
        })
    }
    
    @IBAction func testRouteForConfig(_ sender: Any) {
        testSwiftyRouteForConfig()
    }
    
    func testSwiftyRouteForConfig() {
        let router = Router.perform(
            for: RoutableViewModule<ZIKCompatibleAlertConfigProtocol>(),
            routeConfig: { config in
                config.source = self
                config.routeCompletion = { d in
                    print("show custom alert complete")
                }
                config.errorHandler = { (action, error) in
                    print("show custom alert failed: %@",error)
                }
        },
            preparation: ({ module in
                module.title = "Compatible Alert"
                module.message = "Test custom route for alert with UIAlertView and UIAlertController"
                module.addCancelButtonTitle("Cancel", handler: {
                    print("Tap cancel alert")
                })
                module.addOtherButtonTitle("Hello", handler: {
                    print("Tap Hello alert")
                })
            }))
        alertRouter = (router as! ConfigurableViewRouter<ViewRouteConfig & ZIKCompatibleAlertConfigProtocol>)
    }
    
    func testRouteForConfig() {
        let router: DefaultViewRouter?
        router = Registry.router(for: RoutableViewModule<ZIKCompatibleAlertConfigProtocol>())?.perform { configuration in
            guard let config = configuration as? ViewRouteConfig & ZIKCompatibleAlertConfigProtocol else {
                return
            }
            config.source = self
            config.title = "Compatible Alert"
            config.message = "Test custom route for alert with UIAlertView and UIAlertController"
            config.addCancelButtonTitle("Cancel", handler: {
                print("Tap cancel alert")
            })
            config.addOtherButtonTitle("Hello", handler: {
                print("Tap Hello alert")
            })
            config.routeCompletion = { d in
                print("show custom alert complete")
            }
            config.errorHandler = { (action, error) in
                print("show custom alert failed: %@",error)
            }
        }
        alertRouter = (router as! ConfigurableViewRouter<ViewRouteConfig & ZIKCompatibleAlertConfigProtocol>)
    }
    
    @IBAction func testInjectedRouter(_ sender: Any) {
        let router = self.alertRouterClass.perform { config in
            config.source = self
            config.title = "Compatible Alert"
            config.message = "Test custom route for alert with UIAlertView and UIAlertController"
            config.addCancelButtonTitle("Cancel", handler: {
                print("Tap cancel alert")
            })
            config.addOtherButtonTitle("Hello", handler: {
                print("Tap Hello alert")
            })
            config.routeCompletion = { d in
                print("show custom alert complete")
            }
            config.errorHandler = { (action, error) in
                print("show custom alert failed: %@",error)
            }
        }
        alertRouter = router
    }

    @IBAction func testRouteForSwiftService(_ sender: Any) {
        let service = Router.makeDestination(for: RoutableService<SwiftServiceInput>())
        service?.swiftFunction()
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
