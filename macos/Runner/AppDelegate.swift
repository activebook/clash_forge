import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
  
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    let flutterViewController = self.mainFlutterWindow?.contentViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.activebook.clash_forge/proxy_settings",
                                      binaryMessenger: flutterViewController.engine.binaryMessenger)
    
    channel.setMethodCallHandler { (call, result) in
      if call.method == "getProxySettings" {
        result(self.getProxySettings())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    super.applicationDidFinishLaunching(notification)
  }
  
  private func getProxySettings() -> [String: Any] {
    let proxies = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any] ?? [:]
    var settings: [String: Any] = [:]
    
    // HTTP Proxy
    if let httpEnabled = proxies["HTTPEnable"] as? Int, httpEnabled == 1,
       let httpProxy = proxies["HTTPProxy"] as? String,
       let httpPort = proxies["HTTPPort"] as? Int {
        settings["httpProxy"] = "\(httpProxy):\(httpPort)"
    }
    
    // HTTPS Proxy
    if let httpsEnabled = proxies["HTTPSEnable"] as? Int, httpsEnabled == 1,
       let httpsProxy = proxies["HTTPSProxy"] as? String,
       let httpsPort = proxies["HTTPSPort"] as? Int {
        settings["httpsProxy"] = "\(httpsProxy):\(httpsPort)"
    }
    
    // SOCKS Proxy
    if let socksEnabled = proxies["SOCKSEnable"] as? Int, socksEnabled == 1,
       let socksProxy = proxies["SOCKSProxy"] as? String,
       let socksPort = proxies["SOCKSPort"] as? Int {
        settings["socksProxy"] = "\(socksProxy):\(socksPort)"
    }
    
    return settings
  }
}