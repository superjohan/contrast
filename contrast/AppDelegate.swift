//
//  AppDelegate.swift
//  contrast
//
//  Created by Johan Halin on 13.9.2015.
//  Copyright © 2015 Aero Deko. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?
	
	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
		self.window = UIWindow.init(frame: UIScreen.mainScreen().bounds)
		self.window?.rootViewController = ContrastSwiftViewController.init()
		self.window?.makeKeyAndVisible()
		
		return true
	}
}
