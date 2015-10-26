//
//  FSAdCycle.swift
//  FSAdCycleView
//
//  Created by fengsh on 14/9/15.
//  Copyright © 2015年 fengsh. All rights reserved.
//

import Foundation

import FSWeakTimer

@objc (FSAdvertViewDelegate)
@available(iOS 8.0, *)
public protocol FSAdvertViewDelegate
{
    ///返回一共有多少个广告图
    func FSAdvertViewCount(adcycle:FSAdvertView!) -> Int
    ///返回第i个视窗
    func FSAdvertViewForCell(adcycle:FSAdvertView!,index:Int) -> FSAdvertViewCell!
    ///点击第i个cell索引
    optional func FSAdvertForCellDidSelected(adcycle:FSAdvertView!,index:Int)
}

///接口
@objc (FSAdvertViewInterface)
public protocol FSAdvertViewInterface
{
    func previous()
    func next()
}

enum CycleScrollowDirection
{
    case cycleNone,directionLeft,directionRight
}

///广告轮播控件
@objc (FSAdvertView)
@available(iOS 8.0, *)
public class FSAdvertView : UIView ,FSAdvertViewInterface,UIScrollViewDelegate
{
    private var _pages : Array<UIView>! = Array()
    /// containerView 用来动态控制contentsize
    private var _containerView : UIView!
    /// 轮播混动view
    private var _scview : UIScrollView!
    /// 轮播总数
    private var totalCount : Int! = 0
    //全局的时间间隔
    private var interval = 2.5
    private var _autoPlay = true
    //页数指示器
    public var pageCtrl : UIPageControl!
    
    private var currentIndex = 0
    /// 重用队列，暂时还未用上
    private var reuseItems : Dictionary<String,Array<FSAdvertViewCell!>!> = Dictionary()
    /// 当前显示的item
    public var visableItems : Array<FSAdvertViewCell!> = Array()
    
    public weak var delegate : FSAdvertViewDelegate!
    //顺时针播放，默认为逆时针 //暂不开放
    private var clockwisePlay = false
    //定时器
    var timer : NSTimer?
    //自动播放
    public var autoPlay : Bool {
        willSet(newValue) {
            _autoPlay = newValue
        }
        didSet {
            if _autoPlay
            {
                if totalCount > 1
                {
                    resume()
                }
            }
            else
            {
                supand()
            }
        }
    }
    
    func supand()
    {
        //暂停
        self.timer?.fireDate = NSDate.distantFuture()
    }
    
    func resume()
    {
        //恢复
        self.timer?.fireDate = NSDate()
    }
    
    override init(frame: CGRect)
    {
        self.autoPlay = true
        super.init(frame: frame)
        initControls()

        self.timer = WeakTimerFactory.timerWithTimeInterval(interval, userInfo: nil, repeats: true, callback: { [weak self] () -> Void in
            self?.doAutoLoop()
        })
    }
    
    deinit
    {
        self.timer?.invalidate()
    }
    
    //MARK:- 初始化
    func initControls()
    {
        //内容容器
        _containerView = UIView(frame: CGRectMake(0, 0, frame.width, frame.height))
        _containerView.translatesAutoresizingMaskIntoConstraints = false
        
        //轮播视窗
        _scview = UIScrollView(frame: CGRectMake(0, 0, frame.width, frame.height))
        _scview.translatesAutoresizingMaskIntoConstraints = false
        _scview.delegate = self
        _scview.pagingEnabled = true
        _scview.showsHorizontalScrollIndicator = false
        _scview .addSubview(_containerView)
        addSubview(_scview)
        
        let preview = UIView()
        preview.translatesAutoresizingMaskIntoConstraints = false
        let visableview = UIView()
        visableview.translatesAutoresizingMaskIntoConstraints = false
        let nextview = UIView()
        nextview.translatesAutoresizingMaskIntoConstraints = false
        
        _pages.append(preview)
        _pages.append(visableview)
        _pages.append(nextview)
        
        _containerView.addSubview(preview)
        _containerView.addSubview(visableview)
        _containerView.addSubview(nextview)
        
        pageCtrl = UIPageControl()
        pageCtrl.translatesAutoresizingMaskIntoConstraints = false
        pageCtrl.hidesForSinglePage = true
        
        addSubview(pageCtrl)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func updateConstraints()
    {
        super.updateConstraints()

        _scview.removeConstraints(_scview.constraints)
        
        let hc = NSLayoutConstraint.constraintsWithVisualFormat("|[_containerView]|", options: NSLayoutFormatOptions.AlignmentMask, metrics: nil, views: ["_containerView" : _containerView])
        let vc = NSLayoutConstraint.constraintsWithVisualFormat("V:|[_containerView]|", options: NSLayoutFormatOptions.AlignmentMask, metrics: nil, views: ["_containerView" : _containerView])
        
        _scview.addConstraints(hc)
        _scview.addConstraints(vc)
        
        //轮播窗与父视窗一样大
        let h = NSLayoutConstraint.constraintsWithVisualFormat("|[_scview]|", options: NSLayoutFormatOptions.AlignmentMask, metrics: nil, views: ["_scview" : _scview])
        let v = NSLayoutConstraint.constraintsWithVisualFormat("V:|[_scview]|", options: NSLayoutFormatOptions.AlignmentMask, metrics: nil, views: ["_scview" : _scview])
        
        self.addConstraints(h)
        self.addConstraints(v)
        
        let height = NSLayoutConstraint(item: _containerView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: _scview, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0)
        
        _scview.addConstraint(height)

        _containerView.removeConstraints(_containerView.constraints)
        
        let pv = _pages[0]
        
        var t = NSLayoutConstraint(item: _containerView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: pv, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0)
        var l = NSLayoutConstraint(item: _containerView, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: pv, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0)
        var b = NSLayoutConstraint(item: _containerView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: pv, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
        
        var w = NSLayoutConstraint(item: _scview, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: pv, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0)

        _containerView.addConstraint(t)
        _containerView.addConstraint(l)
        _containerView.addConstraint(b)
        _scview.addConstraint(w)
        
        let cv = _pages[1]
        
        t = NSLayoutConstraint(item: _containerView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: cv, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0)
        l = NSLayoutConstraint(item: cv, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: pv, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0)
        b = NSLayoutConstraint(item: _containerView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: cv, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
        
        w = NSLayoutConstraint(item: _scview, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: cv, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0)
 
        _containerView.addConstraint(t)
        _containerView.addConstraint(l)
        _containerView.addConstraint(b)
        _scview.addConstraint(w)
        
        let nv = _pages[2]
        
        
        t = NSLayoutConstraint(item: _containerView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: nv, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0)
        l = NSLayoutConstraint(item: nv, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: cv, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0)
        b = NSLayoutConstraint(item: _containerView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: nv, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
        
        w = NSLayoutConstraint(item: _scview, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nv, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0)
        
        let contentW = NSLayoutConstraint(item: nv, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: _containerView, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0)
        
        _containerView.addConstraint(t)
        _containerView.addConstraint(l)
        _containerView.addConstraint(b)
        _scview.addConstraint(w)
        _containerView.addConstraint(contentW)
        
        
        let hv = NSLayoutConstraint.constraintsWithVisualFormat("|[pageCtrl]|", options: NSLayoutFormatOptions.AlignmentMask, metrics: nil, views: ["pageCtrl" : pageCtrl])
        let vv = NSLayoutConstraint.constraintsWithVisualFormat("V:[pageCtrl(10)]-(5)-|", options: NSLayoutFormatOptions.AlignmentMask, metrics: nil, views: ["pageCtrl" : pageCtrl])
        
        self.addConstraints(hv)
        self.addConstraints(vv)
        
    }
    
    public func reuseCycleItemForIdentityString(idstring:String) -> FSAdvertViewCell!
    {
        var reuseitems = reuseItems[idstring]
        
        if let cycleitem = reuseitems?.first
        {
            reuseitems?.removeFirst()
            return cycleitem
        }
        
        return nil
    }
    
    public func reloadData()
    {
        supand()
        
        toDoLoadDelegate()
        
        if autoPlay
        {
            resume()
        }
    }
    
    public func next()
    {
        currentIndex = getNextSafeIndexByIndex(currentIndex)
    }
    
    public func previous()
    {
        currentIndex = getPreSafeIndexByIndex(currentIndex)
    }
    
    func doAutoLoop()
    {
        let w = CGRectGetWidth(self.frame)
        _scview.setContentOffset(CGPointMake(w*2, 0), animated: true)
    }
    
    //MARK:- scrollview delegate
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        let w = CGRectGetWidth(self.frame)
        
        let offset = scrollView.contentOffset.x
        
        if offset == 0
        {
            previous()
        }
        else if offset == w * 2
        {
            next()
        }
        
        todoReload()
        //加载完成才显示点
        pageCtrl.currentPage = currentIndex
    }
 
    //时间触发器 设置滑动时动画true，会触发的方法
    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView)
    {
        self.scrollViewDidEndDecelerating(scrollView)
    }
    
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        //如果用户手动拖动到了一个整数页的位置就不会发生滑动了 所以需要判断手动调用滑动停止滑动方法
        if !decelerate {
            self.scrollViewDidEndDecelerating(scrollView)
        }
    }
    
    func scrollToVisable()
    {
        let w = CGRectGetWidth(self.frame)
        _scview.setContentOffset(CGPointMake(w, 0), animated: false)
    }
}

@available(iOS 8.0, *)
private extension FSAdvertView
{
    func toDoLoadDelegate()
    {
        totalCount = delegate?.FSAdvertViewCount(self)
        
        if totalCount > 0
        {
            //重置索引
            currentIndex = 0
            pageCtrl.numberOfPages = totalCount
            pageCtrl.currentPage = currentIndex
            
            if autoPlay //只有用户开启自动轮播时
            {
                autoPlay = totalCount > 1
            }
            
            _scview.scrollEnabled = totalCount > 1
            
            todoReload()
        }

    }
    
    func todoReload()
    {
        let nx = getNextSafeIndexByIndex(currentIndex)
        let px = getPreSafeIndexByIndex(currentIndex)
        
        toDoLoadCellItem(px,container: _pages[0])
        toDoLoadCellItem(currentIndex,container: _pages[1])
        toDoLoadCellItem(nx,container: _pages[2])
        
        scrollToVisable()
    }
    
    func toDoLoadCellItem(index:Int,container:UIView)
    {
        let item = delegate?.FSAdvertViewForCell(self,index:index)
        
        if let cellview = item
        {
            cellview.translatesAutoresizingMaskIntoConstraints = false
            
            cellview.currentIndex = index
            
            container.removeConstraints(container.constraints)
            
            for i in 0..<container.subviews.count
            {
                /* 重用还有小小问题
                let willremovecell = container.subviews[i]
                if willremovecell is FSAdvertViewCell
                {
                    let cell = (willremovecell as! FSAdvertViewCell)
                    addCellToReuseQueue(cell)
                    
                    removeFromFifoVisable(cell)
                }
                */
                container.subviews[i].removeFromSuperview()
            }
            
            container.addSubview(cellview)
            
            let hc = NSLayoutConstraint.constraintsWithVisualFormat("|[cellview]|", options: NSLayoutFormatOptions.AlignmentMask, metrics: nil, views: ["cellview" : cellview])
            let vc = NSLayoutConstraint.constraintsWithVisualFormat("V:|[cellview]|", options: NSLayoutFormatOptions.AlignmentMask, metrics: nil, views: ["cellview" : cellview])
            
            container.addConstraints(hc)
            container.addConstraints(vc)
            
            //visableItems.append(cellview)
        }
    }
    
    @available(iOS 8.0, *)
    func getReuseQueue(idstring:String) -> Array<FSAdvertViewCell!>
    {
        if let has = reuseItems[idstring]
        {
            return has
        }

        return Array()
    }
    
    /**
    获取下一页索引
    
    :param: index 当前的索引
    
    :returns: 相对当前索引下的下一页索引
    */
    func getNextSafeIndexByIndex(index:Int) -> Int
    {
        if clockwisePlay
        {  //顺时针
            return index - 1 < 0 ? totalCount - 1 : index - 1
        }
        else
        {
            return index + 1 == totalCount ? 0 : index + 1
        }
    }
    
    /**
    获取上一页索引
    
    :param: index 当前的索引
    
    :returns: 相对当前索引下的上一页索引
    */
    func getPreSafeIndexByIndex(index:Int) -> Int
    {
        if clockwisePlay
        {  //顺时针
            return index + 1 == totalCount ? 0 : index + 1
        }
        else
        {
            return index - 1 < 0 ? totalCount - 1 : index - 1
        }
    }
    
    @available(iOS 8.0, *)
    func addCellToReuseQueue(cell:FSAdvertViewCell)
    {
        let idstr = cell.identity
        var reuselist = getReuseQueue(idstr)
        reuselist.append(cell)
        reuseItems[idstr] = reuselist
    }
    
    @available(iOS 8.0, *)
    func removeFromFifoVisable(cell:FSAdvertViewCell)
    {
        let idx = visableItems.indexOf({ (e) -> Bool in
            return e === cell
        })
        
        if idx != nil
        {
            visableItems.removeAtIndex(idx!)
        }
    }

}


