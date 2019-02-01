//
//  TestEasyFactoryViewController.swift
//  ZIKRouterDemo
//
//  Created by zuik on 2019/2/1.
//  Copyright © 2019 zuik. All rights reserved.
//

import UIKit
import ZRouter

class TestEasyFactoryViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func testEasyView1(_ sender: Any) {
        Router.perform(to: RoutableView<EasyInfoViewProtocol1>(), path: .show(from: self)) { (destination) in
            destination.name = "zuik"
            destination.age = 18
        }
    }
    @IBAction func testEasyView2(_ sender: Any) {
        Router.perform(to: RoutableView<EasyInfoViewProtocol2>(), path: .show(from: self)) { (destination) in
            destination.name = "zuik"
            destination.age = 18
        }
    }
    @IBAction func testEasyService1(_ sender: Any) {
        let service = Router.makeDestination(to: RoutableService<EasyTimeServiceInput1>())
        Router.perform(to: RoutableViewModule<RequiredCompatibleAlertModuleInput>(), path: .defaultPath(from: self)) { (module) in
            module.message = service?.currentTimeString()
            module.addOtherButtonTitle("OK")
        }
    }
    @IBAction func testEasyService2(_ sender: Any) {
        let service = Router.makeDestination(to: RoutableService<EasyTimeServiceInput2>())
        Router.perform(to: RoutableViewModule<RequiredCompatibleAlertModuleInput>(), path: .defaultPath(from: self)) { (module) in
            module.message = service?.currentTimeString()
            module.addOtherButtonTitle("OK")
        }
    }
}


