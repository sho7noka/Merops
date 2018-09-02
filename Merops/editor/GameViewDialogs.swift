//
//  GameViewMixin.swift
//  KARAS
//
//  Created by sumioka-air on 2018/01/06.
//  Copyright © 2018年 sho sumioka. All rights reserved.
//

#if os(OSX)
    import Cocoa
#elseif os(iOS)
    import UIKit
#endif

import SceneKit
import ModelIO
import Highlightr

final class OutLiner: View {
    let treeview = NSTreeNode()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SettingDialog: View, NSTextViewDelegate {
    
    let colorPallete = NSColorPanel()
    let txtProject = TextView()
    let btnProject = NSButton()
    let txtUsd = TextView()
    let btnUsd = NSButton()
    let txtPython = TextView()
    let btnPython = NSButton()
    
    init(frame: CGRect, setting: Settings) {
        super.init(frame: frame)
        
        txtProject.stringValue = setting.projectDir
        btnProject.title = "..."
        txtUsd.stringValue = setting.usdDir
        btnUsd.title = "..."
        txtPython.stringValue = setting.pythonDir
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
        self.addSubview(textview!)
    }
    
    override func performKeyEquivalent(with event: Event) -> Bool {
        super.keyDown(with: event)
        
        // Command + o
        if keybind(modify: Event.ModifierFlags.command, k: "o", e: event) {
            let op = NSOpenPanel()
            op.canChooseFiles = true
            op.allowsMultipleSelection = false
            op.allowedFileTypes = ["py", "usd", "usda"]
            
            if op.runModal() == NSApplication.ModalResponse.OK {
                let u = op.url
                setUsd(url: u!)
            }
        }
        
        // Command + s
        if keybind(modify: Event.ModifierFlags.command, k: "s", e: event) {
            try! self.textview?.string.write(to: self.url!, atomically: false, encoding: .utf8)
            
            self.view?.scene = SCNScene(mdlAsset: MDLAsset(url: url!))
        }
        
        /*
         Command + Enter
         http://pyobjc-dev.narkive.com/EgqnPAdl/crash-with-pyobjc-1-1-when-i-call-recursively-pyrun-simplestring
         https://www.hardcoded.net/articles/
        */
        /// - Tag: gil
        if keybind(modify: Event.ModifierFlags.command, k: "\r", e: event) {
            let state = PyGILState_Ensure()
//            Py_NewInterpreter()
//            PyGILState_Release(PyGILState_UNLOCKED)
//            PyObjC_BEGIN_WITH_GIL
            PyRun_SimpleStringFlags(textview?.string, nil)
//            PyObjC_END_WITH_GIL
//            PyGILState_Release(PyGILState_LOCKED)
            PyGILState_Release(state)
        }
        
        // escape
        if event.characters == "\u{1B}" {
            self.isHidden = true
        }
        return true
    }
    
    func setUsd(url: URL) -> String {
        let text = try! String(contentsOf: url,
                               encoding: String.Encoding.utf8)
        self.url = url
        setSyntax(file: url)
        self.textview?.string = text
        return text
    }
    
    private func setSyntax(file: URL) {
        switch file.pathExtension {
        case "py":
            let hilight = Highlightr()
//            hilight?.highlight()
            let code = hilight?.highlight("aaa", as: "python", fastRender: true)
//            textview.attributedStringValue = code!
        case "usd": break
        case "metal": break
        default:
            break
        }
//        let range = Range
//        let text = NSMutableAttributedString(attributedString:textview.attributedStringValue)
//        text.addAttribute(NSAttributedStringKey.foregroundColor, value: NSColor.red, range: range)
//        textview.attributedStringValue = text
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
