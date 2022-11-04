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
                    self.installAria()
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
                                            self.runPatch(url: self.scripturl)
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
                        self.addToLog(msg: "[*] Removing Strap")
                    }
                }
            }
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
    
    func installAria() {
        guard let aria = Bundle.main.path(forResource: "aria2_1.36.0_iphoneos-arm64", ofType: ".deb") else {
            addToLog(msg: "[weedra1n] Could not find aria2 deb")
            return
        }
        guard let libaria = Bundle.main.path(forResource: "libaria2-0_1.36.0_iphoneos-arm64", ofType: ".deb") else {
            addToLog(msg: "[weedra1n] Could not find libaria2 deb")
            return
        }
        guard let libcAres = Bundle.main.path(forResource: "libc-ares2_1.17.2_iphoneos-arm64", ofType: ".deb") else {
            addToLog(msg: "[weedra1n] Could not find libc-ares deb")
            return
        }
        guard let libjemalloc = Bundle.main.path(forResource: "libjemalloc2_5.2.1-3_iphoneos-arm64", ofType: ".deb") else {
            addToLog(msg: "[weedra1n] Could not find libjemalloc deb")
            return
        }
        guard let libssh = Bundle.main.path(forResource: "libssh2-1_1.10.0-1_iphoneos-arm64", ofType: ".deb") else {
            addToLog(msg: "[weedra1n] Could not find libssh2 deb")
            return
        }
        guard let libuv = Bundle.main.path(forResource: "libuv1_1.44.1_iphoneos-arm64", ofType: ".deb") else {
            addToLog(msg: "[weedra1n] Could not find libuv deb")
            return
        }
        //install debs
        let ret0 = spawn(command: "/var/jb/usr/bin/dpkg", args: ["-i", libuv], root: true)
        let ret1 = spawn(command: "/var/jb/usr/bin/dpkg", args: ["-i", libssh], root: true)
        let ret2 = spawn(command: "/var/jb/usr/bin/dpkg", args: ["-i", libjemalloc], root: true)
        let ret3 = spawn(command: "/var/jb/usr/bin/dpkg", args: ["-i", libcAres], root: true)
        let ret4 = spawn(command: "/var/jb/usr/bin/dpkg", args: ["-i", libaria], root: true)
        let ret5 = spawn(command: "/var/jb/usr/bin/dpkg", args: ["-i", aria], root: true)
        DispatchQueue.main.async { [self] in
            if ret0.0 == 0 && ret1.0 == 0 && ret2.0 == 0 && ret3.0 == 0 && ret4.0 == 0 && ret5.0 == 0 {
                addToLog(msg: "[*] Installing aria2")
            } else {
                addToLog(msg: "[*] Failed to install aria2")
            }
            vLog(msg: ret0.1)
            vLog(msg: ret1.1)
            vLog(msg: ret2.1)
            vLog(msg: ret3.1)
            vLog(msg: ret4.1)
            vLog(msg: ret5.1)
        }
    }
    
    func runPatch(url: String) {
        let fileName = URL(fileURLWithPath: url).lastPathComponent
        let ret = spawn(command: "/var/jb/usr/bin/aria2c", args: [url, "-d", "/var/jb/"], root: true)
        DispatchQueue.main.async { [self] in
            if ret.0 != 0 {
                addToLog(msg: "[*] Could not download script")
                vLog(msg: ret.1)
                vLog(msg: "script url:" + url)
                return
            }
            addToLog(msg: "[*] Patching Bootstrap")
        }
        let ret0 = spawn(command: "/var/jb/usr/bin/chmod", args: ["+x", "/var/jb/" + fileName], root: true)
        let ret1 = spawn(command: "/var/jb/usr/bin/sh", args: ["/var/jb/" + fileName], root: true)
        DispatchQueue.main.async { [self] in
            if ret1.0 != 0 || ret0.0 != 0 {
                addToLog(msg: "[*] Failed to run script")
                vLog(msg: ret0.1)
                vLog(msg: ret1.1)
                vLog(msg: "script url:" + url)
                return
            }
        }
    }

    func useDefaultScript() {
        self.scripturl = self.defaultScriptUrl
    }
    
    func canOpenURL(string: String?) -> Bool {
        let regEx = "((https|http)://)((\\w|-)+)(([.]|[/])((\\w|-)+))+"
        let predicate = NSPredicate(format:"SELF MATCHES %@", argumentArray:[regEx])
        return predicate.evaluate(with: string)
    }
}
