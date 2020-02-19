//
//  DrawView.swift
//  AngleCalculator
//
//  Created by Tushar Gusain on 18/02/20.
//  Copyright © 2020 Hot Cocoa Software. All rights reserved.
//

//
//  DrawView.swift
//  BNRanchTouchTracker
//
//  Created by Tushar Gusain on 04/09/19.
//  Copyright © 2019 Hot Cocoa Software. All rights reserved.
//

import Foundation
import UIKit

protocol DrawViewAngleDelegate {
    func showAngle(point: CGPoint?, angle: CGFloat?)
}

class DrawView: UIView {

    //MARK:- Property variables
    
    var delegate: DrawViewAngleDelegate?
    private var currentLines = [NSValue: Line]()
    private var finishedLines = [Line]() {
        didSet {
            ////buggy code
            if finishedLines.count < 2 {
                delegate?.showAngle(point: nil, angle: nil)
            }
        }
    }
    private var currentCircle : Circle?
    private var finishedCircles = [Circle]()
    
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var longPressGestureRecognizer: UILongPressGestureRecognizer!
    private var swipeGestureRecognizer: UISwipeGestureRecognizer!
    private var finalVelocity = CGFloat.zero
    private var selectedLineIndex: Int? {
        didSet {
            if selectedLineIndex == nil {
                let menu = UIMenuController.shared
                menu.setMenuVisible(false, animated: true)
            }
        }
    }
    
    @IBInspectable
    private var finishedLineColor: UIColor = UIColor.black {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    private var currentLineColor: UIColor = UIColor.red {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    private var lineWidth: CGFloat = 10 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    //MARK:- Contructor
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        isMultipleTouchEnabled = true
        
        selectedLineIndex = nil
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.delaysTouchesBegan = true
        addGestureRecognizer(doubleTapRecognizer)
        
        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        singleTapRecognizer.delaysTouchesBegan = true
        singleTapRecognizer.require(toFail: doubleTapRecognizer)
        addGestureRecognizer(singleTapRecognizer)
        
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        addGestureRecognizer(longPressGestureRecognizer)
        
        swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipe(_:)))
        swipeGestureRecognizer.direction = .up
        swipeGestureRecognizer.numberOfTouchesRequired = 3
        //        swipeGestureRecognizer.cancelsTouchesInView = false
        addGestureRecognizer(swipeGestureRecognizer)
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(moveLine(_:)))
        panGestureRecognizer.delegate = self
        panGestureRecognizer.cancelsTouchesInView = false
        panGestureRecognizer.require(toFail: swipeGestureRecognizer)
        addGestureRecognizer(panGestureRecognizer)
        
    }
    
    //MARK:- UIView Methods
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func draw(_ rect: CGRect) {
//        finishedLineColor.setStroke()
        for line in finishedLines {
            getColor(line: line).setStroke()
            stroke(line)
        }
        
        for (_,line) in currentLines {
            currentLineColor.setStroke()
            stroke(line)
        }
        
        for circle in finishedCircles {
            finishedLineColor.setStroke()
            arc(circle)
        }
        
        if let circle = currentCircle {
            currentLineColor.setStroke()
            arc(circle)
        }
        
        if let index = selectedLineIndex {
            UIColor.yellow.setStroke()
            let selectedLine = finishedLines[index]
            stroke(selectedLine)
        }
        
        checkIntersectingLines()
    }

}

//MARK:- Helper methods

extension DrawView {
    
    private func getQuadrant (line: Line)->Int {
        let dx = line.end.x - line.begin.x
        let dy = line.begin.y - line.end.y
        
        if (dx > 0 && dy > 0 ) {
            return 1
        } else if (dx < 0 && dy > 0) {
            return 2
        } else if (dx < 0 && dy < 0) {
            return 3
        } else if (dx > 0 && dy < 0) {
            return 4
        } else {
            return 0
        }
    }
    
    private func getColor(line: Line) -> UIColor {
        
        let quadrant = getQuadrant(line: line)
        
        switch quadrant {
            
        case 1: return .blue
        case 2: return .green
        case 3: return .orange
        case 4: return .purple
        default: return .black
        }
    }
    
    private func stroke(_ line: Line)  {
        let path = UIBezierPath()
        path.lineWidth = line.width
        path.lineCapStyle = .round
        
        path.move(to: line.begin)
        path.addLine(to: line.end)
        
        path.stroke()
    }
    
    private func arc(_ circle: Circle) {
        let path = UIBezierPath()
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        let start = CGPoint(x: circle.center.x + circle.radius, y: circle.center.y)
        path.move(to: start)
        path.addArc(withCenter: circle.center, radius: circle.radius, startAngle: CGFloat.zero, endAngle: 2*CGFloat.pi, clockwise: true)
        
        path.stroke()
    }
    
    private func getCenter(a: CGPoint, b: CGPoint) -> CGPoint {
        let x = (a.x + b.x)/2
        let y = (b.y + b.y)/2
        
        return CGPoint(x: x, y: y)
    }
    
    private func getRadius(a: CGPoint, b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        
        return pow((dx * dx + dy * dy), 0.5)/2
    }
    
    private func indexOfLine(at point: CGPoint) -> Int? {
        for (index,line) in finishedLines.enumerated() {
            let begin = line.begin
            let end = line.end
            
            
            for t in stride(from: CGFloat(0), to: 1.0, by: 0.05) {
                let x = begin.x + (end.x - begin.x) * t
                let y = begin.y + (end.y - begin.y) * t
                
                if (hypot(x - point.x, y - point.y) < 20) {
                    return index
                }
            }
        }
        return nil
    }
    
    private func getWidth(velocity: CGPoint) -> CGFloat {
        
        let speed = pow((velocity.x * velocity.x + velocity.y * velocity.y), 0.5)
        
        if speed < 100 {
            return 5
        } else {
            return (speed/50 - 1) + 5
        }
    }
    
    private func onSegment(p: CGPoint, q: CGPoint, r: CGPoint) -> Bool {
        if (q.x <= max(p.x, r.x) && q.x >= min(p.x, r.x) && q.y <= max(p.y, r.y) && q.y >= min(p.y, r.y)) {
           return true
        }
      
        return false
    }
      
    private func orientation(p: CGPoint, q: CGPoint, r: CGPoint) -> Int {
        let val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
      
        if (val == 0) {
            return 0  //// colinear
        }
      
        return val > 0 ? 1: 2 //// clock or counterclock wise
    }
      
    //// The main function that returns true if line segment 'p1q1'
    //// and 'p2q2' intersect.
    private func doIntersect(l1: Line, l2: Line) -> Bool {
        let p1 = CGPoint(x: l1.begin.x, y: -l1.begin.y)
        let q1 = CGPoint(x: l1.end.x, y: -l1.end.y)
        let p2 = CGPoint(x: l2.begin.x, y: -l2.begin.y)
        let q2 = CGPoint(x: l2.end.x, y: -l2.end.y)
        
        let o1 = orientation(p: p1, q: q1, r: p2);
        let o2 = orientation(p: p1, q: q1, r: q2);
        let o3 = orientation(p: p2, q: q2, r: p1);
        let o4 = orientation(p: p2, q: q2, r: q1);
      
        //// General case
        if (o1 != o2 && o3 != o4) {
            return true
        }
      
        //// Special Cases
        //// p1, q1 and p2 are colinear and p2 lies on segment p1q1
        if (o1 == 0 && onSegment(p: p1, q: p2, r: q1)) {
            return true
        }
      
        //// p1, q1 and q2 are colinear and q2 lies on segment p1q1
        if (o2 == 0 && onSegment(p: p1, q: q2, r: q1)) {
            return true
        }
      
        //// p2, q2 and p1 are colinear and p1 lies on segment p2q2
        if (o3 == 0 && onSegment(p: p2, q: p1, r: q2)) {
            return true
            
        }
      
         //// p2, q2 and q1 are colinear and q1 lies on segment p2q2
        if (o4 == 0 && onSegment(p: p2, q: q1, r: q2)) {
            return true
        }
      
        return false
    }
    
    private func checkIntersectingLines() {
        for i in 0..<finishedLines.count {
            for j in i+1..<finishedLines.count {
                print("line 1: ", finishedLines[i])
                print("line 2: ", finishedLines[j])
                let intersect = doIntersect(l1: finishedLines[i], l2: finishedLines[j])
                print("Do intersect: ", intersect)
                if intersect {
                    let angle = findAngleBetweenLines(l1: finishedLines[i], l2: finishedLines[j])
                    print("angle between these two lines in degree is:- ", angle);
                    if angle > 0 {
                        let poi = getPointOfIntersection(l1: finishedLines[i], l2: finishedLines[j])
                        delegate?.showAngle(point: poi, angle: angle)
                    }
                }
            }
        }
    }
    
    private func findAngleBetweenLines(l1: Line, l2: Line) -> CGFloat {
        let x1 = l1.begin.x
        let y1 = l1.begin.y
        let x2 = l1.end.x
        let y2 = l1.end.y
        let x3 = l2.begin.x
        let y3 = l2.begin.y
        let x4 = l2.end.x
        let y4 = l2.end.y
        
        let m1 = (y2 - y1)/(x2 - x1) ////slope of line1
        let m2 = (y4 - y3)/(x4 - x3) ////slope of line2
        var k = (m1 - m2)/(1 + m1 * m2)
        if(k < 0) {
            k = -k
        }
        
        return 57.692 * atan(k)  ////1rad=57.692degree
    }
    
    private func getPointOfIntersection(l1: Line, l2: Line) -> CGPoint {
        //// Line AB represented as a1x + b1y = c1
        let a1 = l1.end.y - l1.begin.y
        let b1 = l1.begin.x - l1.end.x
        let c1 = a1 * (l1.begin.x) + b1 * (l1.begin.y);
        
        //// Line CD represented as a2x + b2y = c2
        let a2 = l2.end.y - l2.begin.y
        let b2 = l2.begin.x - l2.end.x
        let c2 = a2 * (l2.begin.x) + b2 * (l2.begin.y)
        
        let determinant = a1 * b2 - a2 * b1;
        
        let x = (b2 * c1 - b1 * c2) / determinant
        let y = (a1 * c2 - a2 * c1) / determinant
        
        return CGPoint(x: x, y: y)
    }
    
}

//MARK:- UIView touch methods

extension DrawView {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(#function)
        if touches.count == 2 {
            var location = [CGPoint]()
            for touch in touches {
                location.append(touch.location(in: self))
            }
            currentCircle = Circle(center: getCenter(a: location[0],b: location[1]), radius: getRadius(a: location[0],b: location[1]))
            
        } else {
            for touch in touches {
                let location = touch.location(in: self)
                let newLine = Line(begin: location, end: location,width: CGFloat.zero)
                let key = NSValue(nonretainedObject: touch)
                
                currentLines[key] = newLine
            }
        }
        
        setNeedsDisplay()
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(#function)
        if touches.count == 2 {
            var location = [CGPoint]()
            for touch in touches {
                location.append(touch.location(in: self))
            }
            currentCircle?.center = getCenter(a: location[0],b: location[1])
            currentCircle?.radius = getRadius(a: location[0],b: location[1])
        } else {
            for touch in touches {
                let location = touch.location(in: self)
                let key = NSValue(nonretainedObject: touch)
                
                currentLines[key]?.end = location
                let pps = panGestureRecognizer.velocity(in: self)
                currentLines[key]?.width = getWidth(velocity: pps)
            }
        }
        
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count == 2 {
            var location = [CGPoint]()
            for touch in touches {
                location.append(touch.location(in: self))
            }
            if var circle = currentCircle {
                circle.center = getCenter(a: location[0],b: location[1])
                circle.radius = getRadius(a: location[0],b: location[1])
                finishedCircles.append(circle)
                currentCircle = nil
            }
        } else {
            for touch in touches {
                let key =  NSValue(nonretainedObject: touch)
                if var line = currentLines[key] {
                    let location = touch.location(in: self)
                    line.end = location
                    finishedLines.append(line)
                    currentLines.removeValue(forKey: key)
                }
            }
        }
        
        setNeedsDisplay()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(#function)
        
        currentLines.removeAll()
        currentCircle = nil
        selectedLineIndex = nil
        
        setNeedsDisplay()
    }
}



//MARK:- Gesture recognizer delegate methods

extension DrawView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        //        if gestureRecognizer == swipeGestureRecognizer || otherGestureRecognizer == swipeGestureRecognizer {
        //           print("condition satisfied setting to false")
        //            return false
        //        }
        return true
    }
}

//MARK:- Gesture recognizer action methods

extension DrawView {
    
    @objc func tap(_ gestureRecognizer: UIGestureRecognizer) {
        print("single tap")
        
        let point = gestureRecognizer.location(in: self)
        selectedLineIndex = indexOfLine(at: point)
        let menu = UIMenuController.shared
        if selectedLineIndex != nil {
            
            becomeFirstResponder()
            
            let deleteItem = UIMenuItem(title: "Delete", action: #selector(deleteLine(_:)))
            menu.menuItems = [deleteItem]

            let targetRect = CGRect(origin: point, size: CGSize(width: 2, height: 2))
            menu.setTargetRect(targetRect, in: self)
            
            menu.setMenuVisible(true, animated: true)
        } else {
            menu.setMenuVisible(false, animated: true)
        }
        
        setNeedsDisplay()
    }
    
    @objc func doubleTap(_ gestureRecognizer: UIGestureRecognizer) {
        print(#function)
        
        currentLines.removeAll()
        finishedLines.removeAll()
        finishedCircles.removeAll()
        currentCircle = nil
        selectedLineIndex = nil
        
        setNeedsDisplay()
    }
    
    @objc func longPress(_ gestureRecognizer: UIGestureRecognizer) {
        print(#function)
        
        if gestureRecognizer.state == .began {
            let point = gestureRecognizer.location(in: self)
            selectedLineIndex = indexOfLine(at: point)
            if selectedLineIndex != nil {
                currentLines.removeAll()
            }
        } else if gestureRecognizer.state == .ended {
            selectedLineIndex = nil
        }
        setNeedsDisplay()
    }
    
    @objc func moveLine(_ gestureRecognizer: UIPanGestureRecognizer) {
        print(#function)

        let menu = UIMenuController.shared
        
        if !menu.isMenuVisible {
            if let index = selectedLineIndex {
                if gestureRecognizer.state == .changed {
                    let translation = gestureRecognizer.translation(in: self)
                    
                    finishedLines[index].begin.x += translation.x
                    finishedLines[index].begin.y += translation.y
                    
                    finishedLines[index].end.x += translation.x
                    finishedLines[index].end.y += translation.y
                    
                    gestureRecognizer.setTranslation(CGPoint.zero, in: self)
                    
                    setNeedsDisplay()
                }
            } else {
                return
            }
        }
    }
    
    @objc func deleteLine(_ sender: UIMenuController) {
        if let index = selectedLineIndex {
            finishedLines.remove(at: index)
            selectedLineIndex = nil
            setNeedsDisplay()
        }
    }
    
    @objc func swipe(_ gestureRecognizer: UIGestureRecognizer) {
        print(#function)
        
    }
    
}
