//
//  SwiftSampleViewController.swift
//  ZIKRouterDemo
//
//  Created by zuik on 2017/9/8.
//  Copyright © 2017年 zuik. All rights reserved.
//

import UIKit
import ZIKRouter

///Mark the protocol routable 
@objc protocol SwiftSampleViewProtocol: ZIKViewRoutable {
    
}

class SwiftSampleViewController: UIViewController, SwiftSampleViewProtocol, ZIKInfoViewDelegate {
    var router: ZIKViewRouter?
    
    @IBAction func testViewRouter(_ sender: Any) {
        self.router = ZIKSViewRouterForView(ZIKInfoViewProtocol.self)?.perform { config in
            config.source = self
            config.routeType = ZIKViewRouteType.push
            config.prepareForRoute = { [weak self] des in
                let destination = des as! ZIKInfoViewProtocol
                destination.delegate = self
                destination.name = "zuik"
                destination.age = 18
            }
        }
    }
    
    func handleRemoveInfoViewController(_ infoViewController: UIViewController!) {
        if (self.router != nil) {
            self.router?.removeRoute(successHandler: { 
                print("remove success")
            }, performerErrorHandler: { (action, error) in
                print("remove failed,error:%@",error)
            })
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
