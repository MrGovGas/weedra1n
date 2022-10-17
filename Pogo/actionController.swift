//
//  actionController.swift
//  Pogo
//
//  Created by Uckermark on 16.10.22.
//

import Foundation


public class Actions: ObservableObject {
    private var isWorking = false
    @Published var status = ""
    @Published var log = ""
    
    func Install() {
        guard !isWorking else {
            self.addToLog(msg: "[*] Pogo is busy")
            return
        }
        isWorking = true
        guard let tar = Bundle.main.path(forResource: "bootstrap", ofType: "tar") else {
            NSLog("[POGO] Could notfind Bootstrap")
            self.status = "Could not find Bootstrap"
            self.addToLog(msg: "[*] Could not find Bootstrap")
            isWorking = false
            return
        }
         
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "PogoHelper") else {
            NSLog("[POGO] Could not find helper?")
            self.status = "Could not find helper"
            self.addToLog(msg: "[*] Could not find helper")
            isWorking = false
            return
        }
         
        guard let deb = Bundle.main.path(forResource: "org.coolstar.sileo_2.4_iphoneos-arm64", ofType: ".deb") else {
            NSLog("[POGO] Could not find deb")
            self.status = "Could not find deb"
            self.addToLog(msg: "[*] Could not find Sileo deb")
            isWorking = false
            return
        }
        
        status = "Installing Bootstrap"
        self.addToLog(msg: "[*] Installing Bootstrap")
        DispatchQueue.global(qos: .utility).async { [self] in
            spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
            let ret = spawn(command: helper, args: ["-i", tar], root: true)
            spawn(command: "/var/jb/usr/bin/chmod", args: ["4755", "/var/jb/usr/bin/sudo"], root: true)
            spawn(command: "/var/jb/usr/bin/chown", args: ["root:wheel", "/var/jb/usr/bin/sudo"], root: true)
            DispatchQueue.main.async {
                if ret != 0 {
                    self.status = "Error Installing Bootstrap \(ret)"
                    self.addToLog(msg: "[*] Error Installing Bootstrap")
                    self.isWorking = false
                    return
                }
                self.status = "Preparing Bootstrap"
                self.addToLog(msg: "[*] Preparing Bootstrap")
                DispatchQueue.global(qos: .utility).async {
                    let ret = spawn(command: "/var/jb/usr/bin/sh", args: ["/var/jb/prep_bootstrap.sh"], root: true)
                    DispatchQueue.main.async {
                        if ret != 0 {
                            self.isWorking = false
                            return
                        }
                        self.status = "Installing Sileo"
                        self.addToLog(msg: "[*] Installing Sileo")
                        DispatchQueue.global(qos: .utility).async {
                            let ret = spawn(command: "/var/jb/usr/bin/dpkg", args: ["-i", deb], root: true)
                            DispatchQueue.main.async {
                                if ret != 0 {
                                    self.status = "Failed to install Sileo \(ret)"
                                    self.addToLog(msg: "[*] Failed to install Sileo")
                                    self.isWorking = false
                                    return
                                }
                                self.status = "UICache Sileo"
                                self.addToLog(msg: "[*] UICache Sileo")
                                DispatchQueue.global(qos: .utility).async {
                                    let ret = spawn(command: "/var/jb/usr/bin/uicache", args: ["-p", "/var/jb/Applications/Sileo-Nightly.app"], root: true)
                                    DispatchQueue.main.async {
                                        if ret != 0 {
                                            self.status = "Failed to uicache \(ret)"
                                            self.addToLog(msg: "[*] Failed to run uicache")
                                            self.isWorking = false
                                            return
                                        }
                                        self.status = "uicache succesful, have fun!"
                                        self.addToLog(msg: "[*] Installed Sileo")
                                        self.isWorking = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func Remove() {
        guard !isWorking else {
            self.addToLog(msg: "[*] Pogo is busy")
            return
        }
        isWorking = true
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "PogoHelper") else {
            NSLog("[POGO] Could not find helper?")
            self.status = "Could not find helper"
            self.addToLog(msg: "[*] Could not find helper")
            self.isWorking = false
            return
        }
        status = "Unregistering apps"
        self.addToLog(msg: "[*] Unregistering apps")
        DispatchQueue.global(qos: .utility).async { [self] in
            // for every .app file in /var/jb/Applications, run uicache -u
            let fm = FileManager.default
            let apps = try? fm.contentsOfDirectory(atPath: "/var/jb/Applications")
            for app in apps ?? [] {
                if app.hasSuffix(".app") {
                    let ret = spawn(command: "/var/jb/usr/bin/uicache", args: ["-u", "/var/jb/Applications/\(app)"], root: true)
                    DispatchQueue.main.async {
                        if ret != 0 {
                            self.status = "failed to unregister \(ret)"
                            self.addToLog(msg: "[*] failed to unregister \(ret)")
                            self.isWorking = false
                            return
                        }
                    }
                }
            }

        }
        status = "Removing Strap"
        self.addToLog(msg: "[*] Removing Strap")
        DispatchQueue.global(qos: .utility).async { [self] in
            let ret = spawn(command: helper, args: ["-r"], root: true)
            self.status = "trying to remove"
            DispatchQueue.main.async { [self] in
                if ret != 0 {
                    self.status = "Failed to remove Strap \(ret)"
                    self.isWorking = false
                    return
                }
                self.status = "Strap removed!"
                self.addToLog(msg: "[*] Strap removed!")
                self.isWorking = false
            }
        }
    }
    
    func runUiCache() {
        DispatchQueue.global(qos: .utility).async { [self] in
            // for every .app file in /var/jb/Applications, run uicache -p
            let fm = FileManager.default
            let apps = try? fm.contentsOfDirectory(atPath: "/var/jb/Applications")
            for app in apps ?? [] {
                if app.hasSuffix(".app") {
                    let ret = spawn(command: "/var/jb/usr/bin/uicache", args: ["-p", "/var/jb/Applications/\(app)"], root: true)
                    DispatchQueue.main.async {
                        if ret != 0 {
                            self.status = "failed to uicache \(ret)"
                            self.addToLog(msg: "[*] failed to refresh IconCache")
                            return
                        }
                        self.status = "uicache succesful, have fun!"
                        self.addToLog(msg: "[*] Resfreshed IconCache")
                    }
                }
            }
        }
    }

    func remountPreboot() {
        spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
        self.status = "Remounted Preboot R/W"
        self.addToLog(msg: "[*] Remounted Preboot R/W")
    }
    
    func launchDaemons() {
        spawn(command: "/var/jb/bin/launchctl", args: ["bootstrap", "system", "/var/jb/Library/LaunchDaemons"], root: true)
        self.status = "Launched Daemons"
        self.addToLog(msg: "[*] Launched Daemons")
    }
    
    func respring() {
        spawn(command: "/var/jb/usr/bin/sbreload", args: [], root: true)
    }
    
    func runTools() {
        self.runUiCache()
        self.remountPreboot()
        self.launchDaemons()
        self.respring()
    }
    
    func addToLog(msg: String) {
        self.log = self.log + msg + "\n"
        let ns = self.log as NSString
        var lines = 0
        ns.enumerateLines { (str, _) in
            lines += 1
        }
        if (lines > 10) {
            var rlog = ""
            var isFirst = true
            ns.enumerateLines { (str, _) in
                if (isFirst) {
                    isFirst = false
                } else {
                    rlog = rlog + str + "\n"
                }
            }
            self.log = rlog
        }
    }
}
