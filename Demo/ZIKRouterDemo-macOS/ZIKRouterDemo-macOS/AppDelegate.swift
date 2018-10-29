//
//  AppDelegate.swift
//  ZIKRouterDemo-macOS
//
//  Created by zuik on 2018/10/27.
//  Copyright © 2018 duoyi. All rights reserved.
//

import Cocoa
import ZRouter

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
    }

    func applicationDidHide(_ notification: Notification) {
        // Notify custom event
        Router.enumerateAllViewRouters { (routerType) in
            if routerType.responds(to: #selector(applicationDidHide(_:))) {
                routerType.perform(#selector(applicationDidHide(_:)), with: notification)
            }
        }
        Router.enumerateAllServiceRouters { (routerType) in
            if routerType.responds(to: #selector(applicationDidHide(_:))) {
                routerType.perform(#selector(applicationDidHide(_:)), with: notification)
            }
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

