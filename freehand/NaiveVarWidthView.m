//
//  NaiveVarWidthView.m
//  freehand
//
//  Created by Jared Halpern on 1/28/16.
//  Copyright © 2016 Jared Halpern. All rights reserved.
//

#import "NaiveVarWidthView.h"

@implementation NaiveVarWidthView
{
    UIBezierPath *path;
    UIImage *incrementalImage;
    CGPoint pts[5];
    uint ctr;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setMultipleTouchEnabled:NO];
        path = [UIBezierPath bezierPath];
    }
    return self;
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
    
    if (ctr == 4)
    {
        pts[3] = CGPointMake((pts[2].x + pts[4].x)/2.0,
                             (pts[2].y + pts[4].y)/2.0);
        
        [path moveToPoint:pts[0]];
        [path addCurveToPoint:pts[3] controlPoint1:pts[1] controlPoint2:pts[2]];
        
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, 0.0); // render after every drawing update, 60/4 = 25 times per second
        
        if (!incrementalImage)
        {
            UIBezierPath *rectpath = [UIBezierPath bezierPathWithRect:self.bounds];
            [[UIColor whiteColor] setFill];
            [rectpath fill];
        }
        [incrementalImage drawAtPoint:CGPointZero];
        [[UIColor blackColor] setStroke];
        
        float speed = 0.0;
        
        for (int i = 0; i < 3; i++)
        {
            float dx = pts[i+1].x - pts[i].x;
            float dy = pts[i+1].y - pts[i].y;
            speed += sqrtf(dx * dx + dy * dy);
        } // straight-line distance between adjacent points as a (rough) approximation for the length of the Bezier curve.
        
#define FUDGE_FACTOR 100 // emperically determined
        
        float width = FUDGE_FACTOR/speed;
        
        [path setLineWidth:width];
        [path stroke];
        incrementalImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [self setNeedsDisplay];
        
        [path removeAllPoints]; // After the offscreen bitmap render, remove all the points in our UIBezierPath instance and start fresh.
                                // happens after every four touch points acquired.
        pts[0] = pts[3];
        pts[1] = pts[4];
        ctr = 1;
        
    }
}

- (void)drawRect:(CGRect)rect
{
    [incrementalImage drawInRect:rect];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self setNeedsDisplay];
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

@end