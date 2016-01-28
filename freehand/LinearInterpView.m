//
//  LinearInterpView.m
//  freehand_test
//
//  Created by Jared Halpern on 1/28/16.
//  Copyright © 2016 Jared Halpern. All rights reserved.
//

#import "LinearInterpView.h"

@interface LinearInterpView ()

@property (nonatomic, strong) UIBezierPath *path;

@end

@implementation LinearInterpView

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
    [[UIColor blackColor] setStroke];
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
    [self touchesMoved:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}
@end