//
// Copyright © 2021 osy. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI

private var memoryAlertOnce = false

@objc public extension VMDisplayViewController {
    var largeScreen: Bool {
        traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular
    }
    
    var runInBackground: Bool {
        bool(forSetting: "RunInBackground")
    }
    
    var disableIdleTimer: Bool {
        bool(forSetting: "DisableIdleTimer")
    }
}

// MARK: - View Loading
public extension VMDisplayViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if largeScreen {
            prefersStatusBarHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        for notification in notifications {
            NotificationCenter.default.removeObserver(notification)
        }
        notifications.removeAllObjects()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if runInBackground {
            logger.info("Start location tracking to enable running in background")
            UTMLocationManager.sharedInstance().startUpdatingLocation()
        }
        delegate.displayDidAppear()
    }
}

@objc extension VMDisplayViewController {
    func enterSuspended(isBusy busy: Bool) {
        if !busy {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    func enterLive() {
        UIApplication.shared.isIdleTimerDisabled = disableIdleTimer
    }
    
    private func suspend() {
        // dummy function for selector
    }
    
    func terminateApplication() {
        DispatchQueue.main.async { [self] in
            // animate to home screen
            let app = UIApplication.shared
            app.performSelector(onMainThread: #selector(suspend), with: nil, waitUntilDone: true)
            
            // wait 2 seconds while app is going background
            Thread.sleep(forTimeInterval: 2)
            
            // exit app when app is in background
            exit(0);
        }
    }
}

// MARK: Toolbar hiding
public extension VMDisplayViewController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if touch.type == .direct {
                delegate.displayDidAssertUserInteraction()
                break
            }
        }
        super.touchesBegan(touches, with: event)
    }
}

