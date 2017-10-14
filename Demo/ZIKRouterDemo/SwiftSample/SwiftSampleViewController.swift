//
//  SwiftSampleViewController.swift
//  ZIKRouterDemo
//
//  Created by zuik on 2017/9/8.
//  Copyright © 2017 zuik. All rights reserved.
//

import UIKit
import ZIKRouter

///Mark the protocol routable 
@objc protocol SwiftSampleViewProtocol: ZIKViewRoutable {
    
}

class SwiftSampleViewController: UIViewController, SwiftSampleViewProtocol, ZIKInfoViewDelegate {
    var infoRouter: ZIKViewRouter<ZIKViewRouteConfiguration, ZIKViewRemoveConfiguration>?
    var alertRouter: ZIKViewRouter<ZIKViewRouteConfiguration & ZIKCompatibleAlertConfigProtocol, ZIKViewRemoveConfiguration>?
    
    //You can inject alertRouterClass from outside, then use the router directly
    var alertRouterClass: ZIKViewRouter<ZIKViewRouteConfiguration & ZIKCompatibleAlertConfigProtocol, ZIKViewRemoveConfiguration>.Type!
    
    @IBAction func testRouteForView(_ sender: Any) {
        self.infoRouter = ZIKSViewRouterForView(ZIKInfoViewProtocol.self)?.perform { config in
            config.source = self
            config.routeType = ZIKViewRouteType.presentModally
            config.prepareForRoute = { [weak self] d in
                let destination = d as! ZIKInfoViewProtocol
                destination.delegate = self
                destination.name = "zuik"
                destination.age = 18
            }
        }
    }
    
    func handleRemoveInfoViewController(_ infoViewController: UIViewController!) {
        if (self.infoRouter != nil) {
            self.infoRouter?.removeRoute(successHandler: {
                print("remove success")
            }, performerErrorHandler: { (action, error) in
                print("remove failed,error:%@",error)
            })
        }
    }
    
    @IBAction func testRouteForConfig(_ sender: Any) {
        let router: ZIKViewRouter<ZIKViewRouteConfiguration, ZIKViewRemoveConfiguration>?
        
        router = ZIKSViewRouterForConfig(ZIKCompatibleAlertConfigProtocol.self)?.perform { configuration in
            let config = configuration as! ZIKViewRouteConfiguration & ZIKCompatibleAlertConfigProtocol
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
            config.performerErrorHandler = { (action, error) in
                print("show custom alert failed: %@",error)
            }
        }
        self.alertRouter = (router as! ZIKViewRouter<ZIKViewRouteConfiguration & ZIKCompatibleAlertConfigProtocol, ZIKViewRemoveConfiguration>)
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
            config.performerErrorHandler = { (action, error) in
                print("show custom alert failed: %@",error)
            }
        }
        self.alertRouter = router
    }

    @IBAction func testRouteForSwiftService(_ sender: Any) {
        ZIKSServiceRouterForService(SwiftServiceProtocol.self)?.perform { config in
            config.routeCompletion = { d in
                let destination = d as! SwiftServiceProtocol
                destination.swiftFunction()
            }
        }
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
