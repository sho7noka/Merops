//
//  GameViewMixin.swift
//  Merops
//
//  Created by sumioka-air on 2018/01/06.
//  Copyright © 2018年 sho sumioka. All rights reserved.
//

#if os(OSX)

    import Cocoa

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

#elseif os(iOS)

    import UIKit

    final class SettingDialog: View, TextFieldDelegate {

    }

#endif
