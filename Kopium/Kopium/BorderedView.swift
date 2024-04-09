//
//  BorderedView.swift
//  Kopium
//
//  Created by Steve Suranie on 3/4/24.
//

import Foundation
import Cocoa

class BorderedView: NSView {
   
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if let myColor = NSColor(named:"kopium-text-dark") {
            let borderColor: NSColor = myColor.withAlphaComponent(0.2)
            let borderWidth: CGFloat = 1.0
            
            // Draw the border
            let borderPath = NSBezierPath(rect: bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2))
            borderColor.set()
            borderPath.lineWidth = borderWidth
            borderPath.stroke()
        }
    }
}
