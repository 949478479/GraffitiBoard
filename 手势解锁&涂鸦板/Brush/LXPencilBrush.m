//
//  LXPencilBrush.m
//  手势解锁&涂鸦板
//
//  Created by 从今以后 on 15/7/6.
//  Copyright (c) 2015年 949478479. All rights reserved.
//

#import "LXPencilBrush.h"


@interface LXPencilBrush ()

/** 绘图路径. */
@property (nonatomic) CGMutablePathRef path;

/** 当前点. */
@property (nonatomic) CGPoint currentPoint;

/** 上一点. */
@property (nonatomic) CGPoint previousPoint;

/** 是否需要绘制. */
@property (nonatomic) BOOL needsDraw;

@end


@implementation LXPencilBrush

// 普通画笔相对基类有些特殊,这里重写了几个属性,初始点干脆用不到.
// needsDraw 需要根据两次移动间距决定,相应的 previousPoint 和 currentPoint 也并不是每次移动都一定刷新值.
@synthesize currentPoint  = _currentPoint;
@synthesize previousPoint = _previousPoint;
@synthesize needsDraw     = _needsDraw;

#pragma mark - dealloc

- (void)dealloc
{
    if (_path) {
        CGPathRelease(_path);
    }
}

#pragma mark - LXPaintBrush 协议方法

- (void)beginAtPoint:(CGPoint)point
{
    self.needsDraw     = YES;
    self.previousPoint = point;
    self.currentPoint  = point;

    // 普通画笔比较特殊,要保证之前的每一个移动点都在,因此需要一条路径.
    if (self.path) {
        CGPathRelease(self.path);
    }
    self.path = CGPathCreateMutable();

    CGPathMoveToPoint   (self.path, NULL, point.x, point.y);
    CGPathAddLineToPoint(self.path, NULL, point.x, point.y); // 为了点下去就能画一个点.
}

- (void)moveToPoint:(CGPoint)point
{
    // 移动距离小于笔画宽度一半,基本看不出来,没必要重绘.
    CGFloat dx = point.x - self.currentPoint.x;
    CGFloat dy = point.y - self.currentPoint.y;
    if ( (dx * dx + dy * dy) < (self.lineWidth * self.lineWidth / 4) ) {
        self.needsDraw = NO;
        return;
    }

    self.needsDraw     = YES;
    self.previousPoint = self.currentPoint;
    self.currentPoint  = point;

    CGPathAddLineToPoint(self.path, NULL, point.x, point.y);
}

- (void)end
{
    if (self.path) {
        CGPathRelease(self.path);
        self.path = NULL;
    }
    self.needsDraw = NO;
}

- (CGRect)redrawRect
{
    // 普通画笔和画矩形之类的不一样.每次重绘当前点和上一点之间的小矩形即可,没必要包含起点.
    CGFloat minX = fmin(self.currentPoint.x, self.previousPoint.x) - self.lineWidth / 2;
    CGFloat minY = fmin(self.currentPoint.y, self.previousPoint.y) - self.lineWidth / 2;
    CGFloat maxX = fmax(self.currentPoint.x, self.previousPoint.x) + self.lineWidth / 2;
    CGFloat maxY = fmax(self.currentPoint.y, self.previousPoint.y) + self.lineWidth / 2;

    return CGRectMake(minX, minY, maxX - minX, maxY - minY);
}

#pragma mark - 父类方法

- (void)configureContext:(CGContextRef)context
{
    [super configureContext:context];

    // 普通画笔工具在基类的基础上添加自己自定义的路径即可.
    CGContextAddPath(context, self.path);
}

@end