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

class SettingDialog: View {

}

class OutLiner: View {
    
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
