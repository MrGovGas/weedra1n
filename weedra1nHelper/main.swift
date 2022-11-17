//
//  main.swift
//  PogoHelper
//
//  Created by Amy While on 12/09/2022.
//

import Foundation
import ArgumentParser
import SWCompression

struct Strap: ParsableCommand {
    
    @Option(name: .shortAndLong, help: "The path to the .tar file you want to strap with")
    var input: String?
    
    @Flag(name: .shortAndLong, help: "Remove the bootstrap")
    var remove: Bool = false
    
    @Flag(name: .shortAndLong, help: "Download latest build")
    var update: Bool = false
    
    @Flag(name: .shortAndLong, help: "Extract ipa from zip")
    var extract: Bool = false
    
    @Flag(name: .shortAndLong, help: "Remove the custom documents directory")
    var clean: Bool = false
    
    mutating func run() throws {
        NSLog("[weedInstaller] Spawned!")
        guard getuid() == 0 else { fatalError() }

        if let input = input {
            NSLog("[weedInstaller] Attempting to install \(input)")
            let active = "/private/preboot/active"
            let uuid: String
            do {
                uuid = try String(contentsOf: URL(fileURLWithPath: active), encoding: .utf8)
            } catch {
                NSLog("[weedInstaller] Could not find active directory")
                fatalError()
            }
            let dest = "/private/preboot/\(uuid)/procursus"
            do {
                try autoreleasepool {
                    let data = try Data(contentsOf: URL(fileURLWithPath: input))
                    let container = try TarContainer.open(container: data)
                    NSLog("[weedInstaller] Opened Container")
                    for entry in container {
                        do {
                            var path = entry.info.name
                            if path.first == "." {
                                path.removeFirst()
                            }
                            if path == "/" || path == "/var" {
                                continue
                            }
                            path = path.replacingOccurrences(of: "/var/jb", with: dest)
                            switch entry.info.type {
                            case .symbolicLink:
                                var linkName = entry.info.linkName
                                if !linkName.contains("/") || linkName.contains("..") {
                                    var tmp = path.split(separator: "/").map { String($0) }
                                    tmp.removeLast()
                                    tmp.append(linkName)
                                    linkName = tmp.joined(separator: "/")
                                    if linkName.first != "/" {
                                        linkName = "/" + linkName
                                    }
                                    linkName = linkName.replacingOccurrences(of: "/var/jb", with: dest)
                                } else {
                                    linkName = linkName.replacingOccurrences(of: "/var/jb", with: dest)
                                }
                                NSLog("[POGO] \(entry.info.linkName) at \(linkName) to \(path)")
                                try FileManager.default.createSymbolicLink(atPath: path, withDestinationPath: linkName)
                            case .directory:
                                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
                            case .regular:
                                guard let data = entry.data else { continue }
                                try data.write(to: URL(fileURLWithPath: path))
                            default:
                                NSLog("[weedInstaller] Unknown Action for \(entry.info.type)")
                            }
                            var attributes = [FileAttributeKey: Any]()
                            attributes[.posixPermissions] = entry.info.permissions?.rawValue
                            attributes[.ownerAccountName] = entry.info.ownerUserName
                            var ownerGroupName = entry.info.ownerGroupName
                            if ownerGroupName == "staff" && entry.info.ownerUserName == "root" {
                                ownerGroupName = "wheel"
                            }
                            attributes[.groupOwnerAccountName] = ownerGroupName
                            do {
                                try FileManager.default.setAttributes(attributes, ofItemAtPath: path)
                            } catch {
                                continue
                            }
                        } catch {
                            NSLog("[weedInstaller] error \(error.localizedDescription)")
                        }
                    }
                }
            } catch {
                NSLog("[weedInstaller] Failed with error \(error.localizedDescription)")
                return
            }
            NSLog("[weedInstaller] Strapped to \(dest)")
            do {
                if !FileManager.default.fileExists(atPath: "/var/jb") {
                    try FileManager.default.createSymbolicLink(atPath: "/var/jb", withDestinationPath: dest)
                }
            } catch {
                NSLog("[weedInstaller] Failed to make link")
                fatalError()
            }
            NSLog("[weedInstaller] Linked to /var/jb")
            var attributes = [FileAttributeKey: Any]()
            attributes[.posixPermissions] = 0o755
            attributes[.ownerAccountName] = "mobile"
            attributes[.groupOwnerAccountName] = "mobile"
            do {
                try FileManager.default.setAttributes(attributes, ofItemAtPath: "/var/jb/var/mobile")
            } catch {
                NSLog("[weedInstaller] thats wild")
            }
        } else if remove {
            let active = "/private/preboot/active"
            let uuid: String
            do {
                uuid = try String(contentsOf: URL(fileURLWithPath: active), encoding: .utf8)
            } catch {
                NSLog("[weedInstaller] Could not find active directory")
                fatalError()
            }
            let dest = "/private/preboot/\(uuid)/procursus"
            do {
                try FileManager.default.removeItem(at: URL(fileURLWithPath: dest))
                try FileManager.default.removeItem(at: URL(fileURLWithPath: "/var/jb"))
            } catch {
                NSLog("[weedInstaller] Failed with error \(error.localizedDescription)")
            }
            
        } else if update {
            if !FileManager().fileExists(atPath: "/var/mobile/Documents/weedra1n/") {
                let path = URL(string: "file:///var/mobile/Documents/weedra1n")!
                do {
                    try FileManager().createDirectory(at: path, withIntermediateDirectories: false)
                } catch {
                    NSLog("[*] Could not create working directory: \(error.localizedDescription)")
                }
            }
            let url = URL(string: 
"https://nightly.link/Uckermark/weedra1n/workflows/build/main/weedra1n.zip")
            FileDownloader.loadFileSync(url: url!) { (path, error) in
                NSLog("[*] Downloaded to path \(path!)")
            }
        } else if extract {
            let documentsUrl = URL(string: "file:///var/mobile/Documents/weedra1n")!
            let zipUrl = documentsUrl.appendingPathComponent("weedra1n.zip")
            do {
                let data = try Data(contentsOf: zipUrl)
                let container = try ZipContainer.open(container: data)
                for entry in container {
                    var path = entry.info.name
                    if path.first == "." {
                        path.removeFirst()
                    }
                    NSLog("[*] Unpacking \(path)")
                    guard let data = entry.data else {
                        DispatchQueue.main.async {
                            NSLog("[*] Invalid Item in zip")
                        }
                        return
                    }
                    let entryUrl = documentsUrl.appendingPathComponent(path)
                    try data.write(to: entryUrl)
                }
                try FileManager().removeItem(at: zipUrl)
            } catch {
                DispatchQueue.main.async {
                    NSLog("[*] Error while updating: \(error.localizedDescription)")
                }
            }
        } else if clean {
            let documentsPath = "/var/mobile/Documents/weedra1n"
            do {
                try FileManager().removeItem(atPath: documentsPath)
            } catch {
                NSLog("[*] Removal failed")
            }
        }
    }
}

class FileDownloader {
    static func loadFileSync(url: URL, completion: @escaping (String?, Error?) -> Void)
    {
        let documentsUrl = URL(string: "file:///var/mobile/Documents/weedra1n/")!
        
        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
        
        if FileManager().fileExists(atPath: destinationUrl.path)
        {
            print("File already exists [\(destinationUrl.path)]")
            completion(destinationUrl.path, nil)
        }
        else if let dataFromURL = NSData(contentsOf: url)
        {
            if dataFromURL.write(to: destinationUrl, atomically: true)
            {
                print("file saved [\(destinationUrl.path)]")
                completion(destinationUrl.path, nil)
            }
            else
            {
                print("error saving file")
                let error = NSError(domain:"Error saving file", code:1001, userInfo:nil)
                completion(destinationUrl.path, error)
            }
        }
        else
        {
            let error = NSError(domain:"Error downloading file", code:1002, userInfo:nil)
            completion(destinationUrl.path, error)
        }
    }
    
    static func loadFileAsync(url: URL, completion: @escaping (String?, Error?) -> Void)
    {
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
        
        if FileManager().fileExists(atPath: destinationUrl.path)
        {
            print("File already exists [\(destinationUrl.path)]")
            completion(destinationUrl.path, nil)
        }
        else
        {
            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            let task = session.dataTask(with: request, completionHandler:
                                            {
                data, response, error in
                if error == nil
                {
                    if let response = response as? HTTPURLResponse
                    {
                        if response.statusCode == 200
                        {
                            if let data = data
                            {
                                if let _ = try? data.write(to: destinationUrl, options: Data.WritingOptions.atomic)
                                {
                                    completion(destinationUrl.path, error)
                                }
                                else
                                {
                                    completion(destinationUrl.path, error)
                                }
                            }
                            else
                            {
                                completion(destinationUrl.path, error)
                            }
                        }
                    }
                }
                else
                {
                    completion(destinationUrl.path, error)
                }
            })
            task.resume()
        }
    }
}

Strap.main()
