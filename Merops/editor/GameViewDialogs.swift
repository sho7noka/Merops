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


final class SettingDialog: View {
    let colorPallete = NSColorPanel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class OutLiner: View {
    let treeview = NSTreeNode()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

final class ConsoleView: View {
    let textview = TextView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        textview.frame = frame
        textview.backgroundColor = Color.black.withAlphaComponent(0.1)
        self.addSubview(textview)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
