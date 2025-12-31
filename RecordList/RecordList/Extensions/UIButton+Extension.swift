//
//  UIButton+Extension.swift
//  RecordList
//
//  Created by wooseob on 12/29/25.
//

import UIKit

@IBDesignable
class CustomButton: UIButton {
   @IBInspectable var borderWidth: CGFloat = 0.0 {
      didSet {
         layer.borderWidth = borderWidth
      }
   }
   
   @IBInspectable var borderColor: UIColor = UIColor.white {
      didSet {
         layer.borderColor = borderColor.cgColor
      }
   }
   
   @IBInspectable var cornerRadius: CGFloat = 0.0 {
      didSet {
         layer.cornerRadius = cornerRadius
      }
   }
   
   override init(frame: CGRect) {
      super.init(frame: frame)
   }
   
   required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)

   }
}
