//
//  actionController.swift
//  Pogo
//
//  Created by Uckermark on 16.10.22.
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI


public class Actions: ObservableObject {
    private var isWorking: Bool
    private var defaultScriptUrl: String
    var scripturl: String
    @Published var log: String
    @Published var verbose: Bool

    init() {
        isWorking = false
        log = ""
        verbose = false
        defaultScriptUrl = "https://uckermark.github.io/weedra1n.sh"
        scripturl = defaultScriptUrl
    }
    
    func Install() {
        guard !isWorking else {
            addToLog(msg: "[*] weedInstaller is busy")
            return
        }
        isWorking = true
        
        guard let tar = Bundle.main.path(forResource: "bootstrap", ofType: "tar") else {
            NSLog("[weedra1n] Could notfind Bootstrap")
            addToLog(msg: "[*] Could not find Bootstrap")
            isWorking = false
            return
        }
         
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "weedra1nHelper") else {
            NSLog("[weedra1n] Could not find helper?")
            addToLog(msg: "[*] Could not find helper")
            isWorking = false
            return
        }
         
        guard let deb = Bundle.main.path(forResource: "org.coolstar.sileo_2.4_iphoneos-arm64", ofType: ".deb") else {
            NSLog("[weedra1n] Could not find deb")
            addToLog(msg: "[*] Could not find Sileo deb")
            isWorking = false
            return
        }
        
        addToLog(msg: "[*] Installing Bootstrap")
        DispatchQueue.global(qos: .utility).async { [self] in
            let ret1 = spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true).1
            let ret = spawn(command: helper, args: ["-i", tar], root: true)
            let ret2 = spawn(command: "/var/jb/usr/bin/chmod", args: ["4755", "/var/jb/usr/bin/sudo"], root: true).1
            let ret3 = spawn(command: "/var/jb/usr/bin/chown", args: ["root:wheel", "/var/jb/usr/bin/sudo"], root: true).1
            DispatchQueue.main.async {
                //self.vLog(msg: ret.1) //DO NOT UNCOMMENT, IT'S BROKEN
                self.vLog(msg: ret1)
                self.vLog(msg: ret2)
                self.vLog(msg: ret3)
                if ret.0 != 0 {
                    self.addToLog(msg: "[*] Error Installing Bootstrap")
                    self.isWorking = false
                    return
                }
                self.addToLog(msg: "[*] Preparing Bootstrap")
                DispatchQueue.global(qos: .utility).async {
                    let ret = spawn(command: "/var/jb/usr/bin/sh", args: ["/var/jb/prep_bootstrap.sh"], root: true)
                    DispatchQueue.main.async {
                        self.vLog(msg: ret.1)
                        if ret.0 != 0 {
                            self.isWorking = false
                            return
                        }
                        self.addToLog(msg: "[*] Installing Sileo")
                        DispatchQueue.global(qos: .utility).async {
                            let ret = spawn(command: "/var/jb/usr/bin/dpkg", args: ["-i", deb], root: true)
                            DispatchQueue.main.async {
                                self.vLog(msg: ret.1)
                                if ret.0 != 0 {
                                    self.addToLog(msg: "[*] Failed to install Sileo")
                                    self.isWorking = false
                                    return
                                }
                                self.addToLog(msg: "[*] UICache Sileo")
                                DispatchQueue.global(qos: .utility).async {
                                    let ret = spawn(command: "/var/jb/usr/bin/uicache", args: ["-p", "/var/jb/Applications/Sileo.app"], root: true)
                                    DispatchQueue.main.async {
                                        self.vLog(msg: ret.1)
                                        if ret.0 != 0 {
                                            self.addToLog(msg: "[*] Failed to run uicache")
                                            self.isWorking = false
                                            return
                                        }
                                        DispatchQueue.global(qos: .utility).async {
                                            self.runPatch()
                                            DispatchQueue.main.async {
                                                self.addToLog(msg: "[*] Successfully installed Procursus and Sileo")
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
        }
    }

    func Remove() {
        guard !isWorking else {
            self.addToLog(msg: "[*] weedInstaller is busy")
            return
        }
        isWorking = true
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "weedra1nHelper") else {
            NSLog("[weedra1n] Could not find helper?")
            self.addToLog(msg: "[*] Could not find helper")
            self.isWorking = false
            return
        }
        self.addToLog(msg: "[*] Unregistering apps")
        DispatchQueue.global(qos: .utility).async { [self] in
            // for every .app file in /var/jb/Applications, run uicache -u
            let fm = FileManager.default
            let apps = try? fm.contentsOfDirectory(atPath: "/var/jb/Applications")
            for app in apps ?? [] {
                if app.hasSuffix(".app") {
                    let ret = spawn(command: "/var/jb/usr/bin/uicache", args: ["-u", "/var/jb/Applications/\(app)"], root: true)
                    DispatchQueue.main.async {
                        self.vLog(msg: ret.1)
                        if ret.0 != 0 {
                            self.addToLog(msg: "[*] failed to unregister \(ret)")
                            self.isWorking = false
                            return
                        }
                    }
                }
            }
            self.addToLog(msg: "[*] Removing Strap")
            let ret = spawn(command: helper, args: ["-r"], root: true)
            DispatchQueue.main.async { [self] in
                self.vLog(msg: ret.1)
                if ret.0 != 0 {
                    self.addToLog(msg: "Failed to remove Strap (\(ret))")
                    self.isWorking = false
                    return
                }
                self.addToLog(msg: "[*] Strap removed!")
                self.isWorking = false
            }
        }
    }
    
    func runUiCache() {
        // for every .app file in /var/jb/Applications, run uicache -p
        let fm = FileManager.default
        let apps = try? fm.contentsOfDirectory(atPath: "/var/jb/Applications")
        if apps == nil {
            self.addToLog(msg: "[*] Could not access Applications")
        }
        for app in apps ?? [] {
            if app.hasSuffix(".app") {
                let ret = spawn(command: "/var/jb/usr/bin/uicache", args: ["-p", "/var/jb/Applications/\(app)"], root: true)
                self.vLog(msg: ret.1)
                self.addToLog(msg: "[*] App \(app) refreshed")
                if ret.0 != 0 {
                    self.addToLog(msg: "[*] failed to rebuild IconCache (\(ret))")
                    return
                }
            }
        }
        self.addToLog(msg: "[*] Rebuilt Icon Cache")
    }

    func remountPreboot() {
        let ret = spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
        vLog(msg: ret.1)
        if ret.0 == 0 {
            addToLog(msg: "[*] Remounted Preboot R/W")
        } else {
            addToLog(msg: "[*] Failed to remount Preboot R/W")
        }
    }
    
    func launchDaemons() {
        let ret = spawn(command: "/var/jb/bin/launchctl", args: ["bootstrap", "system", "/var/jb/Library/LaunchDaemons"], root: true)
        vLog(msg: ret.1)
        if ret.0 != 0 && ret.0 != 34048 {
            addToLog(msg: "[*] Failed to launch Daemons")
        } else {
            addToLog(msg: "[*] Launched Daemons")
        }
    }
    
    func respring() {
        let ret = spawn(command: "/var/jb/usr/bin/sbreload", args: [], root: true)
        vLog(msg: ret.1)
        if ret.0 != 0 {
            addToLog(msg: "[*] Respring failed")
        }
    }
    
    func runTools() {
        runUiCache()
        remountPreboot()
        launchDaemons()
        respring()
    }
    
    func addToLog(msg: String) {
        NSLog(msg)
        log = msg + "\n" + log
    }
    
    func vLog(msg: String) {
        if verbose {
            addToLog(msg: msg)
        }
    }
    
    func runPatch() {
        guard let url = Bundle.main.url(forResource: "patch", withExtension: ".sh")?.absoluteString else {
            addToLog(msg: "[*] Could not find patch")
            return
        }
        let path = url.replacingOccurrences(of: "file://", with: "")
        DispatchQueue.main.async { [self] in
            addToLog(msg: "[*] Patching Bootstrap")
        }
        let ret = spawn(command: "/var/jb/usr/bin/sh", args: [path], root: true)
        DispatchQueue.main.async { [self] in
            if ret.0 != 0 {
                addToLog(msg: "[*] Failed to run script")
                vLog(msg: ret.1)
                vLog(msg: "script path: " + path)
                return
            }
        }
    }
}
