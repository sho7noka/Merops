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

final class OutLiner: View {
    let treeview = NSTreeNode()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SettingDialog: View {
    let colorPallete = NSColorPanel()
    
    init(frame: CGRect, setting: Settings) {
        super.init(frame: frame)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class PythonConsole: View, TextFieldDelegate {
    let textview = TextView()

    init(frame: CGRect, view: GameView) {
        super.init(frame: frame)
        textview.delegate = self
        textview.frame = frame
        textview.backgroundColor = Color.black.withAlphaComponent(0.2)
        
        textview.lineBreakMode = .byWordWrapping
        textview.usesSingleLineMode = false
        textview.cell?.wraps = true
        textview.cell?.isScrollable = false
//        textview.lineBreakMode = .byWordWrapping

        self.addSubview(textview)
    }
    
    override func performKeyEquivalent(with event: Event) -> Bool {
        // Command + o
        if keybind(modify: Event.ModifierFlags.command, k: "o", e: event) {
            Swift.print("open")
        }
        
        // Command + s
        if keybind(modify: Event.ModifierFlags.command, k: "s", e: event) {
            Swift.print("save")
        }
        
        // Command + Enter
        if keybind(modify: Event.ModifierFlags.command, k: "\r", e: event) {
            Py_Initialize()
            PyRun_SimpleStringFlags(textview.stringValue, nil)
            Py_Finalize()
        }
        
        // escape
        if event.characters == "\u{1B}" {
            self.isHidden = true
        }
        
        super.keyDown(with: event)
        return true
    }
    
    func setUsd(url: URL) -> String {
        // URL(fileURLWithPath: "/Users/shosumioka/Merops/resource/index.html"
        let text = try! String(contentsOf: url,
                               encoding: String.Encoding.utf8)
        setSyntax(file: url)
        self.textview.stringValue = text
        return text
    }
    
    private func setSyntax(file: URL) {
        switch file.pathExtension {
        case "py": break
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
