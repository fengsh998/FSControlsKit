//
//  FSAdCycleItem.swift
//  FSAdCycleView
//
//  Created by fengsh on 14/9/15.
//  Copyright © 2015年 fengsh. All rights reserved.
//

import Foundation

@objc(FSAdvertViewCellInterface)

public protocol FSAdvertViewCellInterface
{
    //public optional
}

@objc(FSAdvertViewCell)
@available(iOS 8.0, *)
public class FSAdvertViewCell : UIView,FSAdvertViewCellInterface
{
    private var _contentView : UIView!
    private var _identity : String!
    var currentIndex : Int = -1
    
    private var isTouchMove : Bool = false
    private var isTouchCancel : Bool = false

    public var contentView : UIView
    {
        get{
            return _contentView;
        }
    }
    
    public var identity : String
    {
        get{
            return _identity
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    deinit{
        //print("free.")
    }
    
    func initcontrols()
    {
        _contentView = UIView(frame: bounds)
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(_contentView)
        
        let hc = NSLayoutConstraint.constraintsWithVisualFormat("|[_contentView]|", options: NSLayoutFormatOptions.AlignmentMask, metrics: nil, views: ["_contentView" : _contentView])
        let vc = NSLayoutConstraint.constraintsWithVisualFormat("V:|[_contentView]|", options: NSLayoutFormatOptions.AlignmentMask, metrics: nil, views: ["_contentView" : _contentView])
        
        self.addConstraints(hc)
        self.addConstraints(vc)
    }
    
    public convenience init(idstring:String)
    {
        self.init(frame: CGRectZero)
        _identity = idstring
        initcontrols()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func findFSAdvertView(currentview : UIView?) -> FSAdvertView?
    {
        if currentview === nil
        {
            return nil
        }
        
        if (currentview is FSAdvertView)
        {
            return (currentview as? FSAdvertView)
        }
        else
        {
            return findFSAdvertView(currentview?.superview)
        }
    }
    
    public override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView?
    {
        let clickView = super.hitTest(point, withEvent: event)
        
        /*
        //如果点在cell上
        if ((clickView === contentView) || (clickView === self))
        {
        let v = findFSAdvertView(clickView)
        if currentIndex != -1
        {
        v?.delegate.FSAdvertForCellDidSelected?(v, index: currentIndex)
        }
        
        return clickView
        }
        */
        
        return clickView
    }
    
    public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        super.touchesBegan(touches, withEvent: event)
        
        //print("他取 begin")
        isTouchMove = false
        isTouchCancel = false
    }
    
    public override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?)
    {
        super.touchesCancelled(touches, withEvent: event)
        //print("他取 cancel")
        isTouchCancel = true
    }
    
    public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        super.touchesEnded(touches, withEvent: event)
        //print("他取 end")
        
        if !isTouchMove && !isTouchCancel
        {
            let v = findFSAdvertView(self)
            if currentIndex != -1
            {
                v?.delegate.FSAdvertForCellDidSelected?(v, index: currentIndex)
            }
        }
    }
    
    public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        super.touchesMoved(touches, withEvent: event)
        //print("他取 move")
        isTouchMove = true
    }
}


@objc(FSAdvertViewImageCell)
@available(iOS 8.0, *)
public class FSAdvertViewImageCell : FSAdvertViewCell
{
    private var _imageview : UIImageView!

    public var imageview : UIImageView {
        get {
           return _imageview
        }
    }
    
//    @available(iOS 7.0, *)
//    func iOS7Work() {
//        // do stuff
//        
//        if #available(iOS 8.0, *) {
//            
//        }
//    }
    
    override func initcontrols()
    {
        super.initcontrols()
        _imageview = UIImageView()
        
        _imageview.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(_imageview)
        
        let hc = NSLayoutConstraint.constraintsWithVisualFormat("|[_imageview]|", options: NSLayoutFormatOptions.AlignmentMask, metrics: nil, views: ["_imageview" : _imageview])
        let vc = NSLayoutConstraint.constraintsWithVisualFormat("V:|[_imageview]|", options: NSLayoutFormatOptions.AlignmentMask, metrics: nil, views: ["_imageview" : _imageview])
        
        contentView.addConstraints(hc)
        contentView.addConstraints(vc)
    
    }
}