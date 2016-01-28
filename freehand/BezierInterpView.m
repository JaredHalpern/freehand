//
//  BezierInterpView.m
//  freehand
//
//  Created by Jared Halpern on 1/28/16.
//  Copyright © 2016 Jared Halpern. All rights reserved.
//

#import "BezierInterpView.h"

@interface BezierInterpView ()
@property (nonatomic, strong) UIBezierPath *path;
@property (nonatomic, strong) UIImage *incrementalImage;
@property (nonatomic, assign) uint ctr; // a counter variable to keep track of the point index

@end

@implementation BezierInterpView
{
    CGPoint pts[4]; // keep track of 4 pts of bezier path segment
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self setMultipleTouchEnabled:NO];
        [self setBackgroundColor:[UIColor whiteColor]];
        self.path = [UIBezierPath bezierPath];
        [self.path setLineWidth:2.0];
    }
    return self;
    
}

- (void)drawRect:(CGRect)rect
{
    [self.incrementalImage drawInRect:rect];
    [self.path stroke];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.ctr = 0;
    UITouch *touch = [touches anyObject];
    pts[0] = [touch locationInView:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    self.ctr++;
    pts[self.ctr] = p;
    if (self.ctr == 3) // 4th point
    {
        [self.path moveToPoint:pts[0]];
        [self.path addCurveToPoint:pts[3] controlPoint1:pts[1] controlPoint2:pts[2]]; // this is how a Bezier curve is appended to a path. We are adding a cubic Bezier from pt[0] to pt[3], with control points pt[1] and pt[2]
        [self setNeedsDisplay];
        pts[0] = [self.path currentPoint];
        self.ctr = 0;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    [self drawBitmap];
    [self setNeedsDisplay];
    pts[0] = [self.path currentPoint]; // let the second endpoint of the current Bezier segment be the first one for the next Bezier segment
    [self.path removeAllPoints];
    self.ctr = 0;
    
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

- (void)drawBitmap
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, 0.0);
    [[UIColor blackColor] setStroke];
    if (!self.incrementalImage) // first time; paint background white
    {
        UIBezierPath *rectpath = [UIBezierPath bezierPathWithRect:self.bounds];
        [[UIColor whiteColor] setFill];
        [rectpath fill];
    }
    [self.incrementalImage drawAtPoint:CGPointZero];
    [self.path stroke];
    self.incrementalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

@end
