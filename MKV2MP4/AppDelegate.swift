//
//  AppDelegate.swift
//  MKV2MP4
//
//  Created by Kismet Iheke on 3/31/18.
//  2018 EXE LLC DOYOU License
//

import Cocoa
import Foundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSToolbarDelegate {
    
    @IBOutlet weak var window: NSWindow!
    
    let text = NSTextField(frame: NSRect(x: 20, y: 45, width: 260, height: 20))
    
    let indicator = NSProgressIndicator(frame: NSRect(x: 20, y: 20, width: 260, height: 20))
    
    var toolbar: NSToolbar!
    
    let toolbarItems: [[String: String]] = [
        ["title": "Add", "icon": NSImage.Name.addTemplate.rawValue, "identifier": "AddToolbarItem"]
    ]
    
    var toolbarTabsIdentifiers: [NSToolbarItem.Identifier] {
        return toolbarItems
            .compactMap { $0["identifier"] }
            .map{ NSToolbarItem.Identifier(rawValue: $0) }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        
        window.setContentSize(NSSize(width:400, height:80))
        
        toolbar = NSToolbar(identifier: NSToolbar.Identifier(rawValue: "TheToolbarIdentifier"))
        toolbar.allowsUserCustomization = true
        toolbar.delegate = self
        self.window?.toolbar = toolbar
        
        text.drawsBackground = true
        text.isBordered = false
        text.backgroundColor = NSColor.controlColor
        text.isEditable = false
        window.contentView?.addSubview(text)
        text.stringValue = "Select MKV File"
        
        indicator.minValue = 0.0
        indicator.maxValue = 1.0
        indicator.doubleValue = 0.0
        indicator.isIndeterminate = false
        window.contentView?.addSubview(indicator)
        
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
    guard let infoDictionary: [String : String] = toolbarItems.filter({ $0["identifier"] == itemIdentifier.rawValue }).first
            else { return nil }
        
    let toolbarItem: NSToolbarItem
        
    toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
    toolbarItem.label = infoDictionary["title"]!
            
    let iconImage = NSImage(named: NSImage.Name(rawValue: infoDictionary["icon"]!))
    let button = NSButton(frame: NSRect(x: 0, y: 0, width: 40, height: 40))
    button.title = ""
    button.image = iconImage
    button.bezelStyle = .texturedRounded
    button.action = #selector(browseFile(sender:))
    toolbarItem.view = button
        
    return toolbarItem
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return self.toolbarTabsIdentifiers;
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return self.toolbarDefaultItemIdentifiers(toolbar)
    }
    
    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return self.toolbarDefaultItemIdentifiers(toolbar)
    }
    
    func toolbarWillAddItem(_ notification: Notification) {
        print("toolbarWillAddItem", (notification.userInfo?["item"] as? NSToolbarItem)?.itemIdentifier ?? "")
    }
    
    func toolbarDidRemoveItem(_ notification: Notification) {
        print("toolbarDidRemoveItem", (notification.userInfo?["item"] as? NSToolbarItem)?.itemIdentifier ?? "")
    }
    
    func changeContainer(inputFilePath: String, outputFilePath: String, callback: @escaping (Bool) -> Void) -> (Process, DispatchWorkItem)? {
        guard let launchPath = Bundle.main.path(forResource: "ffmpeg", ofType: "") else {
            return nil
        }
        let process = Process()
        let task = DispatchWorkItem {
        process.launchPath = launchPath
        process.arguments = [
            "-i", inputFilePath,
            "-c",
            "copy", outputFilePath,
            "-hide_banner",
            "-stats"
        ]
            
        let pipe = Pipe()
        process.standardError = pipe
            let outHandle = pipe.fileHandleForReading
            
            outHandle.readabilityHandler = { pipe in
                if let line = String(data: pipe.readData(ofLength: 300), encoding: String.Encoding.utf8) {
                    
                    DispatchQueue.main.sync {
                        do {
                            let regex = try NSRegularExpression(pattern: "frame=(.*)", options: NSRegularExpression.Options.caseInsensitive)
                            let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count))
                            
                            if let match = matches.first {
                                let range = match.range(at:1)
                                if let swiftRange = Range(range, in: line) {
                                    let name = line[swiftRange]
                                    
                                    if let range = name.range(of: " ") {
                                        let firstPart = name[(name.startIndex)..<range.lowerBound]
                                        if firstPart != "" {
                                            self.indicator.doubleValue = (Double(firstPart))!/61629.00
                                            print(self.indicator.doubleValue)
                                        }
                                    }
                                }
                            }
                        } catch {
                            // regex was bad!
                        }
                        }
                        }
                    }
            func getDocumentsDirectory() -> URL {
                let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                return paths[0]
            }
        process.launch()
        process.terminationHandler = { process in
            callback(process.terminationStatus == 0)
            DispatchQueue.main.sync {
            self.indicator.doubleValue = 1
            }
            }
        }
        DispatchQueue.global(qos: .userInitiated).async(execute: task)
        
        return (process, task)
    }
    @IBAction func browseFile(sender: AnyObject) {
        
        self.indicator.doubleValue = 0.0
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose a .MKV file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = false;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["mkv"];
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                let openPath = result!.path
                let savePathURL = result!.deletingPathExtension().appendingPathExtension("mp4")
                let savePath = savePathURL.path
                changeContainer(inputFilePath: openPath, outputFilePath: savePath, callback: { result in self.printSomething(text: savePath)})
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    func printSomething(text: String) {
        print(text)
    }
}
