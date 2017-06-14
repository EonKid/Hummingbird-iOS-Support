//
//  AppDelegate.swift
//  BirdBlox
//
//  Created by birdbrain on 3/21/17.
//  Copyright © 2017 Birdbrain Technologies LLC. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
	var uiLoaded = false
	
	public var backendServer: BBTBackendServer
	
	override init() {
		self.backendServer = BBTBackendServer()
		super.init()
		
		self.backendServer["/ui/contentLoaded"] = { request in
			self.uiLoaded = true
			return .ok(.text("Hello webpage! I am a server."))
		}
	}


    func application(_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool{
        // Override point for customization after application launch.
		
		//Setting the tint color
		if #available(iOS 10.0, *) {
			self.window?.tintColor = UIColor(displayP3Red: 1.0, green: 137.0/255.0, blue: 64.0/255,
			                                 alpha: 1.0)
		} else {
			self.window?.tintColor = UIColor(red: 1.0, green: 137.0/255.0, blue: 64.0/255.0,
			                                 alpha: 1.0)
		}
		
		//Make sure date model is working
		let _ = DataModel.shared.getSetting("foo")
		
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
		
		
		self.backendServer.stop()
		
		guard self.uiLoaded else {
			return
		}
		
		guard let vc = self.window?.rootViewController as? ViewController else {
			return
		}
		
		vc.wv?.evaluateJavaScript("SaveManager.currentDoc();") { file, error in
			if let error = error {
				NSLog("Error autosaving file on exit \(error)")
				return
			}
			
			guard let file = file else {
				NSLog("File to autosave is nil")
				return
			}
			
			print("file to autosave \(file)")
		}
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
		self.backendServer.start()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		NSLog("applicationWillTerminate. Should have called enter background already." +
			"Please edit AppDelegate.swift.")
    }
	
	func application(_ app: UIApplication, open url: URL,
	                 options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
		
		defer {
			do {
				try FileManager.default.removeItem(at: url)
			} catch {
				NSLog("Unable to delete temp file")
			}
		}
		
		do {
			let contents = try String(contentsOf: url)
			let name = url.lastPathComponent.replacingOccurrences(of: ".bbx", with: "")
			
			
			let avname = DataModel.shared.availableName(from: name)! //This also sanitizes the name
			if DataModel.shared.save(bbxString: contents, withName: avname) == false {
				return false
			}
			
			guard self.uiLoaded else {
				DataModel.shared.addSetting("currentDoc", value: avname)
				DataModel.shared.addSetting("currentDocNamed", value: "true")
				return true
			}
			
			if let vc = window?.rootViewController as? ViewController,
				let safeName = avname.addingPercentEncoding(withAllowedCharacters: CharacterSet()) {
				print(safeName)
				vc.wv?.evaluateJavaScript("SaveManager.import('\(safeName)');") {
					(_, error) in
					print(error ?? "No Error")
				}
			}
		} catch {
			NSLog("I'm unable to open the file")
			return false
		}
		
		return true
	}

}

