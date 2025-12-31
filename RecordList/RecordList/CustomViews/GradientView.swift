//
//  GradientView.swift
//  RecordList
//
//  Created by wooseob on 12/29/25.
//

import UIKit

@IBDesignable
final class GradientView: CustomView {
    let gradientLayer = CAGradientLayer()
    
    @IBInspectable
    var startGradientColor: UIColor? {
        didSet {
            setGradient(startGradientColor: startGradientColor, endGradientColor: endGradientColor, angle: angle)
        }
    }
    
    @IBInspectable
    var endGradientColor: UIColor? {
        didSet {
            setGradient(startGradientColor: startGradientColor, endGradientColor: endGradientColor, angle: angle)
        }
    }
    
    @IBInspectable
    var angle: CGFloat = 0.0 {
        didSet {
            setGradient(startGradientColor: startGradientColor, endGradientColor: endGradientColor, angle: angle)
        }
    }
    
    @IBInspectable override var cornerRadius: CGFloat {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

private extension GradientView {
   func setGradient(
       startGradientColor: UIColor?,
       endGradientColor: UIColor?,
       angle: CGFloat = 0.0
   ) {
       if let startGradientColor = startGradientColor, let endGradientColor = endGradientColor {
           gradientLayer.colors = [startGradientColor.cgColor, endGradientColor.cgColor]
           gradientLayer.borderColor = layer.borderColor
           gradientLayer.borderWidth = layer.borderWidth
           gradientLayer.cornerRadius = layer.cornerRadius
           gradientLayer.calculatePoints(for: angle)
           
           layer.insertSublayer(gradientLayer, at: 0)
       } else {
           gradientLayer.removeFromSuperlayer()
       }
   }
}
