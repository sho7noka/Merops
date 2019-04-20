//
//  AppDelegate.swift
//  Merops
//
//  Created by sumioka-air on 2017/04/30.
//  Copyright (c) 2017年 sho sumioka. All rights reserved.
//
#if os(OSX)
import Cocoa
import Python

public typealias View = NSView
public typealias Color = NSColor
public typealias Event = NSEvent
public typealias Image = NSImage
public typealias TextView = NSTextField
public typealias SuperViewController = NSViewController
public typealias GestureRecognizer = NSPanGestureRecognizer
public typealias TextFieldDelegate = NSTextFieldDelegate


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: NSWindow!
    
    func applicationDidBecomeActive(_ notification: Notification) {

        Py_Initialize()
        
        PyRun_SimpleStringFlags("""
import sys, os
pwd = os.environ[\"PWD\"]

os.environ[\"PATH\"] = pwd + \"/USD/bin\"
os.environ[\"PATH\"] = pwd + \"/USD/lib\"
os.environ[\"PYTHONPATH\"] = pwd + \"/USD/lib/python\"
sys.path.append(os.path.join(pwd, \"USD/lib/python\"))
sys.path.append(os.path.join(pwd, \"Python\"))
os.chdir(os.path.join(pwd, \"USD/lib/python\"))
""", nil)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Py_Finalize()
    }
}
    
#elseif os(iOS)
import UIKit

public typealias View = UIView
public typealias Color = UIColor
public typealias Event = UIEvent
public typealias Image = UIImage
public typealias TextView = UITextField
public typealias SuperViewController = UIViewController
public typealias GestureRecognizer = UIGestureRecognizer
public typealias TextFieldDelegate = UITextFieldDelegate
public typealias Float = CGFloat

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    internal func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let resourcePath = Bundle.main.resourcePath! + "/python3"
        let python_home = "PYTHONHOME=\(resourcePath)" as NSString
        unsetenv("PYTHONHOME")
        unsetenv("PYTHONPATH")
        putenv(UnsafeMutablePointer(mutating: python_home.utf8String))
        
//        Py_Initialize()
//        PyRun_SimpleStringFlags("import sys\nprint (sys.executable)", nil)
//        Py_Finalize()
        
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
