//
//  CALayer+Extension.swift
//  RecordList
//
//  Created by wooseob on 12/29/25.
//

import UIKit

extension CAGradientLayer {
   
   /// 주어진 각도(angle)에 따라 그라디언트 레이어의 시작점과 끝점을 설정합니다.
   ///
   /// - 중요:
   /// *0°* 는 왼쪽에서 오른쪽으로 흐르는 수평 그라디언트를 의미합니다.
   ///
   /// 양수 각도를 입력하면 시계 방향(clockwise)으로 회전합니다.
   ///
   ///    * 예: *400°* 는 *40°* 와 동일한 결과를 가집니다.
   ///
   /// 음수 각도를 입력해도 회전 방향은 시계 방향입니다.
   ///
   ///    * 예: *-15°* 는 *345°* 와 동일한 결과를 가집니다.
   ///
   /// - 매개변수:
   ///     - angle: 그라디언트의 각도 값
   func calculatePoints(for angle: CGFloat) {
      
      
      var ang = (-angle).truncatingRemainder(dividingBy: 360)
      
      if ang < 0 { ang = 360 + ang }
      
      let n: CGFloat = 0.5
      
      switch ang {
         
      case 0...45, 315...360:
         let a = CGPoint(x: 0, y: n * tanx(ang) + n)
         let b = CGPoint(x: 1, y: n * tanx(-ang) + n)
         startPoint = a
         endPoint = b
         
      case 45...135:
         let a = CGPoint(x: n * tanx(ang - 90) + n, y: 1)
         let b = CGPoint(x: n * tanx(-ang - 90) + n, y: 0)
         startPoint = a
         endPoint = b
         
      case 135...225:
         let a = CGPoint(x: 1, y: n * tanx(-ang) + n)
         let b = CGPoint(x: 0, y: n * tanx(ang) + n)
         startPoint = a
         endPoint = b
         
      case 225...315:
         let a = CGPoint(x: n * tanx(-ang - 90) + n, y: 0)
         let b = CGPoint(x: n * tanx(ang - 90) + n, y: 1)
         startPoint = a
         endPoint = b
         
      default:
         let a = CGPoint(x: 0, y: n)
         let b = CGPoint(x: 1, y: n)
         startPoint = a
         endPoint = b
         
      }
   }
   
   /// Private function to aid with the math when calculating the gradient angle
   private func tanx(_ 𝜽: CGFloat) -> CGFloat {
      return tan(𝜽 * CGFloat.pi / 180)
   }
   
   // Overloads
   /// Sets the start and end points on a gradient layer for a given angle.
   func calculatePoints(for angle: Int) {
      calculatePoints(for: CGFloat(angle))
   }
   
   /// Sets the start and end points on a gradient layer for a given angle.
   func calculatePoints(for angle: Float) {
      calculatePoints(for: CGFloat(angle))
   }
   
   /// Sets the start and end points on a gradient layer for a given angle.
   func calculatePoints(for angle: Double) {
      calculatePoints(for: CGFloat(angle))
   }
}
