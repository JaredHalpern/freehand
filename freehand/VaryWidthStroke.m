//
//  VaryWidthStroke.m
//  freehand
//
//  Created by Jared Halpern on 1/28/16.
//  Copyright © 2016 Jared Halpern. All rights reserved.
//

#import "VaryWidthStroke.h"

#define CAPACITY 100
#define FF .2
#define LOWER 0.01
#define UPPER 1.0


typedef struct
{
    CGPoint firstPoint;
    CGPoint secondPoint;
} LineSegment; // ................. (1)

@implementation VaryWidthStroke
{
    UIImage *incrementalImage;
    CGPoint pts[5];
    uint ctr;
    CGPoint pointsBuffer[CAPACITY];
    uint bufIdx;
    dispatch_queue_t drawingQueue;
    BOOL isFirstTouchPoint;
    LineSegment lastSegmentOfPrev;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        
        [self setMultipleTouchEnabled:NO];
        drawingQueue = dispatch_queue_create("drawingQueue", NULL);
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(eraseDrawing:)];
        tap.numberOfTapsRequired = 2; // Tap twice to clear drawing!
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)eraseDrawing:(UITapGestureRecognizer *)t
{
    incrementalImage = nil;
    [self setNeedsDisplay];
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    ctr = 0;
    bufIdx = 0;
    UITouch *touch = [touches anyObject];
    pts[0] = [touch locationInView:self];
    isFirstTouchPoint = YES;
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
        
        for ( int i = 0; i < 4; i++)
        {
            pointsBuffer[bufIdx + i] = pts[i];
        }
        
        bufIdx += 4;
        
        CGRect bounds = self.bounds;
        
        dispatch_async(drawingQueue, ^{
            
            UIBezierPath *offsetPath = [UIBezierPath bezierPath]; // ................. (2)
            
            if (bufIdx == 0)
                return;
            
            LineSegment ls[4]; // array of cgpoints
            
            for ( int i = 0; i < bufIdx; i += 4)
            {
                if (isFirstTouchPoint) // ................. (3)
                {
                    // don't create offset points
                    ls[0] = (LineSegment){
                        pointsBuffer[0],
                        pointsBuffer[0]
                    };
                    
                    [offsetPath moveToPoint:ls[0].firstPoint];
                    isFirstTouchPoint = NO;
                } else {
                    ls[0] = lastSegmentOfPrev;
                }
                
                
                float frac1 = FF/clamp(len_sq(pointsBuffer[i], pointsBuffer[i+1]), LOWER, UPPER); // ................. (4)
                float frac2 = FF/clamp(len_sq(pointsBuffer[i+1], pointsBuffer[i+2]), LOWER, UPPER);
                float frac3 = FF/clamp(len_sq(pointsBuffer[i+2], pointsBuffer[i+3]), LOWER, UPPER);
                ls[1] = [self lineSegmentPerpendicularTo:(LineSegment){pointsBuffer[i], pointsBuffer[i+1]} ofRelativeLength:frac1]; // ................. (5)
                ls[2] = [self lineSegmentPerpendicularTo:(LineSegment){pointsBuffer[i+1], pointsBuffer[i+2]} ofRelativeLength:frac2];
                ls[3] = [self lineSegmentPerpendicularTo:(LineSegment){pointsBuffer[i+2], pointsBuffer[i+3]} ofRelativeLength:frac3];
                
                [offsetPath moveToPoint:ls[0].firstPoint]; // ................. (6)
                [offsetPath addCurveToPoint:ls[3].firstPoint controlPoint1:ls[1].firstPoint controlPoint2:ls[2].firstPoint];
                [offsetPath addLineToPoint:ls[3].secondPoint];
                [offsetPath addCurveToPoint:ls[0].secondPoint controlPoint1:ls[2].secondPoint controlPoint2:ls[1].secondPoint];
                [offsetPath closePath];
                
                lastSegmentOfPrev = ls[3]; // ................. (7)
                // Suggestion: Apply smoothing on the shared line segment of the two adjacent offsetPaths
                
            }
            UIGraphicsBeginImageContextWithOptions(bounds.size, YES, 0.0);
            
            if (!incrementalImage)
            {
                UIBezierPath *rectpath = [UIBezierPath bezierPathWithRect:self.bounds];
                [[UIColor whiteColor] setFill];
                [rectpath fill];
            }
            [incrementalImage drawAtPoint:CGPointZero];
            [[UIColor blackColor] setStroke];
            [[UIColor blackColor] setFill];
            [offsetPath stroke]; // ................. (8)
            [offsetPath fill];
            incrementalImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            [offsetPath removeAllPoints];
            dispatch_async(dispatch_get_main_queue(), ^{
                bufIdx = 0;
                [self setNeedsDisplay];
            });
        });
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
    if (ctr == 0) // only one point acquired = user tapped on the screen
    {
        UIBezierPath *path;
        [path addArcWithCenter:pts[0] radius:5.0 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
        // draw "point"
    }
    
    [self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

- (LineSegment)lineSegmentPerpendicularTo:(LineSegment)pp ofRelativeLength:(float)fraction
{
    CGFloat x0 = pp.firstPoint.x, y0 = pp.firstPoint.y, x1 = pp.secondPoint.x, y1 = pp.secondPoint.y;
    
    CGFloat dx, dy;
    dx = x1 - x0;
    dy = y1 - y0;
    
    CGFloat xa, ya, xb, yb;
    xa = x1 + fraction/2 * dy;
    ya = y1 - fraction/2 * dx;
    xb = x1 - fraction/2 * dy;
    yb = y1 + fraction/2 * dx;
    
    return (LineSegment){ (CGPoint){xa, ya}, (CGPoint){xb, yb} };
    
}

float len_sq(CGPoint p1, CGPoint p2)
{
    float dx = p2.x - p1.x;
    float dy = p2.y - p1.y;
    return dx * dx + dy * dy;
}

float clamp(float value, float lower, float higher)
{
    if (value < lower)
        return lower;
    
    if (value > higher)
        return higher;
    
    return value;
}

@end
