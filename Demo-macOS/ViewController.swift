//
//  ViewController.swift
//  Demo-macOS
//
//  Created by JH on 12/16/24.
//  Copyright © 2024 STULabel. All rights reserved.
//

import Cocoa
import STULabel

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let labelLayer = STULabelLayer()
        
        labelLayer.text = "Hello, STULabel!"
        labelLayer.textColor = .labelColor
        view.wantsLayer = true
        view.layer?.addSublayer(labelLayer)
        labelLayer.frame = .init(x: 50, y: 50, width: 200, height: 40)
        labelLayer.isGeometryFlipped = true
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}
