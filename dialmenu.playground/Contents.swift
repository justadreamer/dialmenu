//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

func rnd() -> CGFloat {
    return CGFloat(arc4random_uniform(255))/255.0
}

func distanceBetween(p1 : CGPoint, p2 : CGPoint) -> CGFloat {
    let dx : CGFloat = p1.x - p2.x
    let dy : CGFloat = p1.y - p2.y
    return sqrt(dx * dx + dy * dy)
}

class InflateBehavior : UIDynamicBehavior {
    var view: UIView?
    var point: CGPoint?  //a point close to which we inflate the view
    var maxInflation: CGFloat = 1.5 //max inflation in % of the original size
    var minInflation: CGFloat = 0.75
    var distThreshold: CGFloat = 100
    override init() {
        super.init()
        action = { [unowned self] in
            guard let view = self.view,
                let point = self.point else {
                return
            }
            let d = CGFloat(distanceBetween(p1: view.center, p2: point))
            
            let diff:CGFloat = (self.maxInflation - self.minInflation)
            let startScale = self.minInflation + diff/2
            var scale: CGFloat = startScale + diff * (self.distThreshold/2 - d)/self.distThreshold/2
            if scale > self.maxInflation {
                scale = self.maxInflation
            } else if scale < self.minInflation {
                scale = self.minInflation
            }
            view.layer.transform = CATransform3DScale(CATransform3DIdentity, scale, scale, 1)
            
        }
    }
}

class DialMenu : UIView {
    var itemViews: [UIView] = [] {
        didSet {
            setup()
        }
    }
    var snap: UISnapBehavior?
    var animator: UIDynamicAnimator?
    var snapPoints: [CGPoint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        animator = UIDynamicAnimator(referenceView: self)
        let N = Float(self.itemViews.count)
        let r = Float(100)
        for i in 0..<self.itemViews.count {
            let v = self.itemViews[i]
            v.center = CGPoint(x: self.center.x + CGFloat(r * sin(Float(i) * 2 * Float.pi/N)), y: self.center.y - CGFloat(r * cos(Float(i) * 2 * Float.pi/N)))
            self.addSubview(v)
            self.snapPoints.append(v.center)
        }
    }
    
    func initialAnimation() {
        for v in self.itemViews {
            v.center = CGPoint(x:self.bounds.size.width/2,y:self.bounds.size.height/2)
        }
        
        UIView.animate(withDuration: 1, animations: {
            for i in 0..<self.itemViews.count {
                let v = self.itemViews[i]
                v.center = self.snapPoints[i]
            }
        }) { finished in
            self.applyAttachments()
            self.applyInflate()
        }
    }
    
    func applyAttachments() {

        var prev: UIView?
        
        for v in self.itemViews {
            let attachToCenter = UIAttachmentBehavior(item: v, attachedToAnchor: self.center)
            animator?.addBehavior(attachToCenter)
            
            if let prevView = prev {
                let attachToPrev = UIAttachmentBehavior(item: v, attachedTo: prevView)
                animator?.addBehavior(attachToPrev)
            }
            
            let recognizer = UIPanGestureRecognizer(target: self, action: #selector(onPan))
            v.addGestureRecognizer(recognizer)

            prev = v
        }
    }
    
    func applyInflate() {
        self.itemViews.forEach {
            let inflate = InflateBehavior()
            inflate.view = $0
            inflate.point = self.snapPoints[0]
            animator?.addBehavior(inflate)
        }
    }
    
    func onPan(recognizer: UIPanGestureRecognizer) {
        if let v = recognizer.view {
            if recognizer.state == .began {
                if let snap = snap {
                    animator?.removeBehavior(snap)
                }
                snap = UISnapBehavior(item: v, snapTo: recognizer.location(in: self))
                animator?.addBehavior(snap!)
            } else if recognizer.state == .ended {
                snap?.snapPoint = closestSnapPoint(to: recognizer.location(in: self))
            } else if recognizer.state == .changed {
                snap?.snapPoint = recognizer.location(in: self)
            }
        }
    }
    
    func closestSnapPoint(to point:CGPoint) -> CGPoint {
        var result = self.snapPoints.first!
        var dist = distanceBetween(p1: result, p2: point)

        for p in self.snapPoints {
            let cur = distanceBetween(p1: p, p2: point)
            if cur < dist {
                dist = cur
                result = p
            }
        }
        return result
    }
}

let container = UIView(frame: CGRect(x:0,y:0,width:320,height:480))

container.backgroundColor = UIColor.white

PlaygroundPage.current.liveView = container
PlaygroundPage.current.needsIndefiniteExecution = true


let dialMenu = DialMenu(frame: container.bounds)
dialMenu.backgroundColor = UIColor.clear

var views : [UIView] = []

let s = CGFloat(50)
for _ in 0..<9 {
    let v = UIView(frame: CGRect(x:0,y:0,width:s,height:s))
    v.layer.cornerRadius = s/2
    v.backgroundColor = UIColor(red: rnd(), green: rnd(), blue: rnd(), alpha: 1.0)
    views.append(v)
}

dialMenu.itemViews = views
container.addSubview(dialMenu)
dialMenu.initialAnimation()