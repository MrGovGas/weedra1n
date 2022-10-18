//
//  actionController.swift
//  Pogo
//
//  Created by Uckermark on 16.10.22.
//

import Foundation


public class Actions: ObservableObject {
    private var isWorking: Bool
    @Published var log: String
    @Published var verbose: Bool
    
    init() {
        isWorking = false
        log = ""
        verbose = false //TODO: fetch from plist
    }
    
    func Install() {
        guard !isWorking else {
            self.addToLog(msg: "[*] Pogo is busy")
            return
        }
        
        isWorking = true
        guard let tar = Bundle.main.path(forResource: "bootstrap", ofType: "tar") else {
            NSLog("[POGO] Could notfind Bootstrap")
            self.addToLog(msg: "[*] Could not find Bootstrap")
            isWorking = false
            return
        }
         
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "PogoHelper") else {
            NSLog("[POGO] Could not find helper?")
            self.addToLog(msg: "[*] Could not find helper")
            isWorking = false
            return
        }
         
        guard let deb = Bundle.main.path(forResource: "org.coolstar.sileo_2.4_iphoneos-arm64", ofType: ".deb") else {
            NSLog("[POGO] Could not find deb")
            self.addToLog(msg: "[*] Could not find Sileo deb")
            isWorking = false
            return
        }
        
        self.addToLog(msg: "[*] Installing Bootstrap")
        DispatchQueue.global(qos: .utility).async { [self] in
            vLog(msg: spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true).1)
            let ret = spawn(command: helper, args: ["-i", tar], root: true)
            vLog(msg: spawn(command: "/var/jb/usr/bin/chmod", args: ["4755", "/var/jb/usr/bin/sudo"], root: true).1)
            vLog(msg: spawn(command: "/var/jb/usr/bin/chown", args: ["root:wheel", "/var/jb/usr/bin/sudo"], root: true).1)
            DispatchQueue.main.async {
                self.vLog(msg: ret.1)
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
                                    let ret = spawn(command: "/var/jb/usr/bin/uicache", args: ["-p", "/var/jb/Applications/Sileo-Nightly.app"], root: true)
                                    DispatchQueue.main.async {
                                        self.vLog(msg: ret.1)
                                        if ret.0 != 0 {
                                            self.addToLog(msg: "[*] Failed to run uicache")
                                            self.isWorking = false
                                            return
                                        }
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

        }
        self.addToLog(msg: "[*] Removing Strap")
        DispatchQueue.global(qos: .utility).async { [self] in
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
        DispatchQueue.global(qos: .utility).async { [self] in
            // for every .app file in /var/jb/Applications, run uicache -p
            let fm = FileManager.default
            let apps = try? fm.contentsOfDirectory(atPath: "/var/jb/Applications")
            if apps == nil {
                DispatchQueue.main.async {
                    self.addToLog(msg: "[*] Could not access Applications")
                }
            }
            for app in apps ?? [] {
                if app.hasSuffix(".app") {
                    let ret = spawn(command: "/var/jb/usr/bin/uicache", args: ["-p", "/var/jb/Applications/\(app)"], root: true)
                    DispatchQueue.main.async {
                        self.vLog(msg: ret.1)
                        if ret.0 != 0 {
                            self.addToLog(msg: "[*] failed to refresh IconCache (\(ret))")
                            return
                        }
                        self.addToLog(msg: "[*] Rebuilt Icon Cache")
                    }
                }
            }
        }
    }

    func remountPreboot() {
        let ret = spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
        vLog(msg: ret.1)
        if ret.0 >= 0 {
            addToLog(msg: "[*] Remounted Preboot R/W")
        } else {
            addToLog(msg: "[*] Failed to remount Preboot R/W")
        }
    }
    
    func launchDaemons() {
        let ret = spawn(command: "/var/jb/bin/launchctl", args: ["bootstrap", "system", "/var/jb/Library/LaunchDaemons"], root: true)
        vLog(msg: ret.1)
        if ret.0 >= 0 {
            addToLog(msg: "[*] Launched Daemons")
        } else {
            addToLog(msg: "[*] Failed to launch Daemons")
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
        log = msg + "\n" + log
    }
    
    func vLog(msg: String) {
        DispatchQueue.main.async {
            if self.verbose {
                self.addToLog(msg: msg)
            }
        }
    }
    
    func saveLog() {
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let name = "Pogo-\(month)-\(day)-\(hour)-\(minute).log"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
        
        do {
            try log.write(to: url, atomically: true, encoding: .utf8)
            let content = log
            vLog(msg: "Saving log to file")
            if try String(contentsOf: url) == content {
                addToLog(msg: "[*] Log saved to Documents")
            }
        } catch {
            NSLog("[POGO] Could not create logfile: \(error.localizedDescription)")
            addToLog(msg: "[*] Failed to save log")
            vLog(msg: String(error.localizedDescription))
        }
    }
}
