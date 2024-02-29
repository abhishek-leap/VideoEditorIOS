//
//  GridView.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 24/08/22.
//

import UIKit

public class GridView: UIView {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func draw(_ rect: CGRect) {
        let screenSize = rect.size
        let linesCount = 3
        let verticalWidth = screenSize.width/CGFloat(linesCount)
        let horizontalWidth = screenSize.height/CGFloat(linesCount)
        UIColor(white: 1, alpha: 0.6).set()
        for i in 1..<linesCount {
            let linePosition = horizontalWidth*CGFloat(i)
            drawLine(start: CGPoint(x: 0, y: linePosition), end: CGPoint(x: screenSize.width, y: linePosition))
        }
        for i in 1..<linesCount {
            let linePosition = verticalWidth*CGFloat(i)
            drawLine(start: CGPoint(x: linePosition, y: 0), end: CGPoint(x: linePosition, y: screenSize.height))
        }
    }
    
    func drawLine(start: CGPoint, end: CGPoint) {
        let aPath = UIBezierPath()
        
        aPath.move(to: start)
        aPath.addLine(to: end)
        aPath.close()
        aPath.lineWidth = 0.5
        aPath.stroke()
    }
}
