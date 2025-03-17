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

        let label = STULabel()
        
        label.text = "Hello, STULabel!"
        label.textColor = .labelColor
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}
