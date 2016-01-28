//
//  QuadDrawView.m
//  freehand
//
//  Created by Jared Halpern on 1/28/16.
//  Copyright © 2016 Jared Halpern. All rights reserved.
//

#import "QuadDrawView.h"

@implementation QuadDrawView
{
    UIBezierPath *path;
    UIImage *incrementalImage;
    CGPoint pts[4];
    uint ctr;
    CGFloat lineWidth;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self setMultipleTouchEnabled:NO];
        [self setBackgroundColor:[UIColor whiteColor]];
        path = [UIBezierPath bezierPath];
        lineWidth = 2.0;
        [path setLineWidth:lineWidth];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [incrementalImage drawInRect:rect];
    [path stroke];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    ctr = 0;
    UITouch *touch = [touches anyObject];
    pts[0] = [touch locationInView:self];
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    ctr++;
    pts[ctr] = p;
    if (ctr == 3) // note - 3 is the control point of the second segment of the quadratic curve
    {
        pts[2] = CGPointMake((pts[1].x + pts[3].x)/2.0, // avg control points
                             (pts[1].y + pts[3].y)/2.0);
        [path moveToPoint:pts[0]];
        
        [path addQuadCurveToPoint:pts[2] // end pt
                     controlPoint:pts[1]];
        
        [self setNeedsDisplay];
        pts[0] = pts[2];
        pts[1] = pts[3];
        ctr = 1;
    }
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (ctr == 0) // only one point acquired = user tapped on the screen
    {
        [path addArcWithCenter:pts[0] radius:lineWidth/2 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
        // draw "point"
    }
    else if (ctr == 1)
    {
        [path moveToPoint:pts[0]];
        [path addLineToPoint:pts[1]];
    }
    else if (ctr == 2)
    {
        [path moveToPoint:pts[0]];
        [path addQuadCurveToPoint:pts[2] controlPoint:pts[1]];
    }
    [self drawBitmap];
    [self setNeedsDisplay];
    [path removeAllPoints];
    ctr = 0;
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}
- (void)drawBitmap
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, 0.0);
    if (!incrementalImage)
    {
        UIBezierPath *rectpath = [UIBezierPath bezierPathWithRect:self.bounds];
        [[UIColor whiteColor] setFill];
        [rectpath fill];
    }
    [incrementalImage drawAtPoint:CGPointZero];
    [[UIColor blackColor] setStroke];
    [path stroke];
    incrementalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

@end