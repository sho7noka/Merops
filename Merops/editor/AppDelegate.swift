//
//  AppDelegate.swift
//  Merops
//
//  Created by sumioka-air on 2017/04/30.
//  Copyright (c) 2017年 sho sumioka. All rights reserved.
//
#if os(OSX)
    
import Cocoa
public typealias SuperViewController = NSViewController
public typealias Color = NSColor
public typealias Event = NSEvent
public typealias View = NSView
public typealias TextView = NSTextField
public typealias GestureRecognizer = NSPanGestureRecognizer
public typealias TextFieldDelegate = NSTextFieldDelegate

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: NSWindow!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {

    }
}
    
#elseif os(iOS)
    
import UIKit
public typealias SuperViewController = UIViewController
public typealias Color = UIColor
public typealias Event = UIEvent
public typealias View = UIView
public typealias TextView = UITextField
public typealias GestureRecognizer = UIGestureRecognizer
public typealias Float = CGFloat
public typealias TextFieldDelegate = UITextFieldDelegate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    internal func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {

    }

    func applicationDidEnterBackground(_ application: UIApplication) {

    }

    func applicationWillEnterForeground(_ application: UIApplication) {

    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }

}
#endif
