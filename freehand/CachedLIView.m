//
//  CachedLIView.m
//  freehand
//
//  Created by Jared Halpern on 1/28/16.
//  Copyright © 2016 Jared Halpern. All rights reserved.
//

#import "CachedLIView.h"

@interface CachedLIView ()
@property (nonatomic, strong) UIBezierPath *path;
@property (nonatomic, strong) UIImage *incrementalImage;

@end

@implementation CachedLIView

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
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    [self.path moveToPoint:p];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    [self.path addLineToPoint:p];
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    [self.path addLineToPoint:p];
    [self drawBitmap]; // eventually cache the drawing periodically instead of only when the user lifts finger
    [self setNeedsDisplay];
    [self.path removeAllPoints];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

- (void)drawBitmap
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, 0.0);
    [[UIColor blackColor] setStroke];
    if (!self.incrementalImage) // first draw; paint background white by ...
    {
        UIBezierPath *rectpath = [UIBezierPath bezierPathWithRect:self.bounds]; // enclosing bitmap by a rectangle defined by another UIBezierPath object
        [[UIColor whiteColor] setFill];
        [rectpath fill]; // filling it with white
    }
    [self.incrementalImage drawAtPoint:CGPointZero];
    [self.path stroke];
    self.incrementalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}
@end