//
//  GameViewMixin.swift
//  Merops
//
//  Created by sumioka-air on 2018/01/06.
//  Copyright © 2018年 sho sumioka. All rights reserved.
//

import Foundation
#if os(OSX)
    import Cocoa
    import Python
#elseif os(iOS)
    import UIKit
#endif

import SceneKit
import ModelIO
import ObjectiveGit


final class OutLiner: View {
    let treeview = NSTreeNode()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SettingDialog: View, TextFieldDelegate {
    
    let colorPallete = NSColorPanel()
    let txtProject = TextView()
    let btnProject = NSButton()
    let txtUsd = TextView()
    let btnUsd = NSButton()
    let txtPython = TextView()
    let btnPython = NSButton()
    
    init(frame: CGRect, setting: Settings) {
        super.init(frame: frame)
        
        txtProject.text = setting.projectDir
        btnProject.title = "..."
        txtUsd.text = setting.usdDir
        btnUsd.title = "..."
        txtPython.text = setting.pythonDir
        btnPython.title = "..."
        
        [txtProject, txtUsd, txtPython].forEach {
            self.addSubview($0)
        }
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class PythonConsole: View, NSTextViewDelegate {
    var textview: NSTextView?
    var url: URL?
    var view: GameView?

    init(frame: CGRect, view: GameView) {
        super.init(frame: frame)
        self.view = view
        
        textview = NSTextView(frame: frame)
        textview?.backgroundColor = Color.black.withAlphaComponent(0.5)
        let range = NSRange(location: 9, length: 0)
        textview?.setSelectedRange(range)
        self.addSubview(textview!)
    }
    
    func setText(url: URL) -> String {
        let text = try! String(contentsOf: url, encoding: String.Encoding.utf8)
        self.url = url
        setSyntax(file: url)
        self.textview?.string = text
        return text
    }
    
    override func performKeyEquivalent(with event: Event) -> Bool {
        super.keyDown(with: event)
        
        // escape
        if event.characters == "\u{1B}" {
            self.isHidden = true
        }
        
        if keybind(modify: Event.ModifierFlags.command, k: "q", e: event) {
//            NSApplication
        }
        
        // Command + o
        if keybind(modify: Event.ModifierFlags.command, k: "o", e: event) {
            let op = NSOpenPanel()
            op.canChooseFiles = true
            op.allowsMultipleSelection = false
            op.allowedFileTypes = ["py", "usd", "usda"]
            
            if op.runModal() == NSApplication.ModalResponse.OK {
                let u = op.url
                _ = setText(url: u!)
                self.url = u!
            }
        }
        
        // Command + s
        if keybind(modify: Event.ModifierFlags.command, k: "s", e: event) {
            try! self.textview?.string.write(to: self.url!, atomically: false, encoding: .utf8)
            self.view?.scene = SCNScene(mdlAsset: MDLAsset(url: url!))
        }
        
        /// - Tag: gil / Command + Enter
        if keybind(modify: Event.ModifierFlags.command, k: "\r", e: event) {
            let state = PyGILState_Ensure()
            let txt = textview?.string
            PyRun_SimpleStringFlags(txt, nil)
            PyGILState_Release(state)
            return true
        }
        return true
    }
    
    private func setSyntax(file: URL) {
        switch file.pathExtension {
        case "py": break
        case "usd": break
        case "metal": break
        default:
            break
        }
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
