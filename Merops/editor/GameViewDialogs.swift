//
//  GameViewMixin.swift
//  Merops
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
//import Highlightr
import Foundation
import ObjectiveC

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
    
    func save(){
        
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
        let dev = NSAttributedString(string: " Developpers")
        let range = NSRange(location: 9, length: 0)
        textview?.setSelectedRange(range)
//        textview?.performValidatedReplacement(in: range, with: dev)
//        textview?.lnv_setUpLineNumberView()
        self.addSubview(textview!)
    }
    
    override func viewDidMoveToWindow() {
//        self.textview?.becomeFirstResponder()
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
//            let state = PyGILState_Ensure()
            
            let txt = textview?.string
//            if PyRun_SimpleStringFlags(txt, nil) != 0 {
//                PyRun_SimpleStringFlags(txt, nil)
//                PyErr_Print()
//                return true
//            }
//            PyGILState_Release(state)
//            PyEval_RestoreThread(thread)
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
        case "py": break
//            let hilight = Highlightr()
//            hilight?.highlight()
//            let code = hilight?.highlight("aaa", as: "python", fastRender: true)
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

protocol CurrentLineHighlighting: AnyObject {
    
    var needsUpdateLineHighlight: Bool { get set }
    var lineHighLightRect: NSRect? { get set }
    var lineHighLightColor: NSColor? { get }
}


//extension CurrentLineHighlighting where Self: NSTextView {
//    func drawCurrentLine(in dirtyRect: NSRect) {
//
//        if self.needsUpdateLineHighlight {
//            self.invalidateLineHighLightRect()
//            self.needsUpdateLineHighlight = false
//        }
//
//        guard
//            let rect = self.lineHighLightRect,
//            let color = self.lineHighLightColor,
//            rect.intersects(dirtyRect)
//            else { return }
//
//        // draw highlight
//        NSGraphicsContext.saveGraphicsState()
//
//        color.setFill()
//        rect.fill()
//
//        NSGraphicsContext.restoreGraphicsState()
//    }

//    private func invalidateLineHighLightRect() {
//
//        let lineRange = (self.string as NSString).lineRange(for: self.selectedRange)
//        guard
//            var rect = self.boundingRe
//            var rect = self.boundingRect(for: lineRange),
//            let textContainer = self.textContainer
//            else { return }
//
//        rect.origin.x = textContainer.lineFragmentPadding
//        rect.size.width = textContainer.size.width - 2 * textContainer.lineFragmentPadding
//
//        self.lineHighLightRect = rect
//    }
//}


//var LineNumberViewAssocObjKey: UInt8 = 0
//
//extension NSTextView {
//    var lineNumberView:LineNumberRulerView {
//        get {
//            return objc_getAssociatedObject(self, &LineNumberViewAssocObjKey) as! LineNumberRulerView
//        }
//        set {
//            objc_setAssociatedObject(self, &LineNumberViewAssocObjKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//    }
//
//    func lnv_setUpLineNumberView() {
//        if font == nil {
//            font = NSFont.systemFont(ofSize: 16)
//        }
//
//        if let scrollView = enclosingScrollView {
//            lineNumberView = LineNumberRulerView(textView: self)
//
//            scrollView.verticalRulerView = lineNumberView
//            scrollView.hasVerticalRuler = true
//            scrollView.rulersVisible = true
//        }
//
//        postsFrameChangedNotifications = true
//        NotificationCenter.default.addObserver(self, selector: #selector(lnv_framDidChange), name: NSView.frameDidChangeNotification, object: self)
//
//        NotificationCenter.default.addObserver(self, selector: #selector(lnv_textDidChange), name: NSText.didChangeNotification, object: self)
//    }
//
//    @objc func lnv_framDidChange(notification: NSNotification) {
//
//        lineNumberView.needsDisplay = true
//    }
//
//    @objc func lnv_textDidChange(notification: NSNotification) {
//
//        lineNumberView.needsDisplay = true
//    }
//}
//
//class LineNumberRulerView: NSRulerView {
//
//    var font: NSFont! {
//        didSet {
//            self.needsDisplay = true
//        }
//    }
//
//    init(textView: NSTextView) {
//        super.init(scrollView: textView.enclosingScrollView!, orientation: NSRulerView.Orientation.verticalRuler)
//        self.font = textView.font ?? NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
//        self.clientView = textView
//
//        self.ruleThickness = 40
//    }
//
//    required init(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//
//    override func drawHashMarksAndLabels(in rect: NSRect) {
//
//        if let textView = self.clientView as? NSTextView {
//            if let layoutManager = textView.layoutManager {
//
//                let relativePoint = self.convert(NSZeroPoint, from: textView)
//                let lineNumberAttributes = [NSAttributedStringKey.font: textView.font!, NSAttributedStringKey.foregroundColor: NSColor.gray] as [NSAttributedStringKey : Any]
//
//                let drawLineNumber = { (lineNumberString:String, y:CGFloat) -> Void in
//                    let attString = NSAttributedString(string: lineNumberString, attributes: lineNumberAttributes)
//                    let x = 35 - attString.size().width
//                    attString.draw(at: NSPoint(x: x, y: relativePoint.y + y))
//                }
//
//                let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: textView.visibleRect, in: textView.textContainer!)
//                let firstVisibleGlyphCharacterIndex = layoutManager.characterIndexForGlyph(at: visibleGlyphRange.location)
//
//                let newLineRegex = try! NSRegularExpression(pattern: "\n", options: [])
//                // The line number for the first visible line
//                var lineNumber = newLineRegex.numberOfMatches(in: textView.string, options: [], range: NSMakeRange(0, firstVisibleGlyphCharacterIndex)) + 1
//
//                var glyphIndexForStringLine = visibleGlyphRange.location
//
//                // Go through each line in the string.
//                while glyphIndexForStringLine < NSMaxRange(visibleGlyphRange) {
//
//                    // Range of current line in the string.
//                    let characterRangeForStringLine = (textView.string as NSString).lineRange(
//                        for: NSMakeRange( layoutManager.characterIndexForGlyph(at: glyphIndexForStringLine), 0 )
//                    )
//                    let glyphRangeForStringLine = layoutManager.glyphRange(forCharacterRange: characterRangeForStringLine, actualCharacterRange: nil)
//
//                    var glyphIndexForGlyphLine = glyphIndexForStringLine
//                    var glyphLineCount = 0
//
//                    while ( glyphIndexForGlyphLine < NSMaxRange(glyphRangeForStringLine) ) {
//
//                        // See if the current line in the string spread across
//                        // several lines of glyphs
//                        var effectiveRange = NSMakeRange(0, 0)
//
//                        // Range of current "line of glyphs". If a line is wrapped,
//                        // then it will have more than one "line of glyphs"
//                        let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndexForGlyphLine, effectiveRange: &effectiveRange, withoutAdditionalLayout: true)
//
//                        if glyphLineCount > 0 {
//                            drawLineNumber("-", lineRect.minY)
//                        } else {
//                            drawLineNumber("\(lineNumber)", lineRect.minY)
//                        }
//
//                        // Move to next glyph line
//                        glyphLineCount += 1
//                        glyphIndexForGlyphLine = NSMaxRange(effectiveRange)
//                    }
//
//                    glyphIndexForStringLine = NSMaxRange(glyphRangeForStringLine)
//                    lineNumber += 1
//                }
//
//                // Draw line number for the extra line at the end of the text
//                if layoutManager.extraLineFragmentTextContainer != nil {
//                    drawLineNumber("\(lineNumber)", layoutManager.extraLineFragmentRect.minY)
//                }
//            }
//        }
//    }
//}
