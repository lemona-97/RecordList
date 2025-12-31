//
//  GraphView.swift
//  RecordList
//
//  Created by wooseob on 12/29/25.
//

import UIKit

final class GraphView: UIView {

    private var amplitudes: [CGFloat] = []
    private let maxSamples = 150

    func addAmplitude(_ value: Float) {
        amplitudes.append(CGFloat(value))
        if amplitudes.count > maxSamples {
            amplitudes.removeFirst()
        }
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard amplitudes.count > 1 else { return }

        let path = UIBezierPath()
        let midY = rect.midY

        for (i, amp) in amplitudes.enumerated() {
            let x = rect.width * CGFloat(i) / CGFloat(maxSamples)
            let y = midY - amp * midY
            i == 0 ? path.move(to: CGPoint(x: x, y: y))
                   : path.addLine(to: CGPoint(x: x, y: y))
        }

       UIColor.white.setStroke()
        path.lineWidth = 2
        path.stroke()
    }
    
    func reset() {
        amplitudes.removeAll()
        setNeedsDisplay()
    }
}
