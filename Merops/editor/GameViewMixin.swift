//
//  GameViewMixin.swift
//  KARAS
//
//  Created by sumioka-air on 2018/01/06.
//  Copyright © 2018年 sho sumioka. All rights reserved.
//

import Cocoa

class ExportDialog: View {

}

class SettingDialog: View {

}

class DiffDialog: View {
    
}

class OutLiner: View {

}

final class ConsoleView: View {
    let textview = NSTextField()

    init() {
        super.init(frame: .zero)
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        textview.frame = frame
        setup()
//        var setting = Settings()
//        setting.double = 1
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func pipe() {
    }

    func show() {
    }

    private func setup() {
        textview.backgroundColor = Color.black.withAlphaComponent(0.1)
        self.addSubview(textview)
//        textview.insertText("AAA")
    }

    private func drawRect(dirtyRect: NSRect) {
//        [[NSColor colorWithDeviceWhite:0.0 alpha:0.75] set];
//        NSRectFillUsingOperation(dirtyRect, NSCompositeSourceOver);
    }

}
