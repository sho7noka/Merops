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

import WebKit
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

final class PythonConsole: View, WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "startRecording":
            print("startRecordingが呼ばれる")
        case "toggleMicInput":
            print("toggleMicInputが呼ばれる") //<--が呼ばれる
            guard let contentBody = message.body as? String,
                let data = contentBody.data(using: String.Encoding.utf8) else { return }
            if let json = try! JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.allowFragments) as? Dictionary<String, Bool>, let isUsingMic = json["usingMic"] {
                if isUsingMic {
                    print("micを使っている")
                } else {
                    print("micを使っていない")
                }
            }
        case "youtubeStart":
            print("youtubeStartが呼ばれる")
        case "youtubeEnd":
            print("youtubeStoppedが呼ばれる")
        default:
            print("default")
        }
    }
    
    var wkview: WKWebView?
    var textview: NSTextView?
    var url: URL?
    var view: GameView?

    init(frame: CGRect, view: GameView) {
        super.init(frame: frame)
        self.view = view
        
        let config = WKWebViewConfiguration()
        wkview = WKWebView(frame: frame, configuration: config)
        wkview?.loadHTMLString("", baseURL: URL(fileURLWithPath: "WKView/index.html"))
        
        textview?.backgroundColor = Color.black.withAlphaComponent(0.5)
        self.addSubview(wkview!)
    }
    
    func setText(url: URL) -> String {
        
        let text = try! String(contentsOf: url, encoding: String.Encoding.utf8)
        self.url = url

        let script = String(format: "document.getElementById('iPadVolumeData').value = \"%@\";", text)
        wkview?.evaluateJavaScript(script, completionHandler: nil)

        self.textview?.string = text
        return text
    }

    #if os(OSX)
    override func performKeyEquivalent(with event: Event) -> Bool {
        super.keyDown(with: event)
        
        // escape
        if event.characters == "\u{1B}" {
            self.isHidden = true
        }
        
        if keybind(modify: Event.ModifierFlags.command, k: "q", e: event) || keybind(modify: Event.ModifierFlags.command, k: "w", e: event) {
            self.isHidden = true
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
            PyEval_InitThreads()
            PyEval_AcquireLock()
            let state = PyGILState_Ensure()
            let txt = textview?.string
            PyRun_SimpleStringFlags(txt, nil)
            PyGILState_Release(state)
            PyEval_ReleaseLock()
            return true
        }
        return true
    }
    #endif
    
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
