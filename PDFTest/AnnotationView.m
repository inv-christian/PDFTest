//
//  AnnotationView.m
//  PDFTest
//
//  Created by Priya Rajagopal on 5/24/16.
//  Copyright © 2016 invicara. All rights reserved.
//

#import "AnnotationView.h"

@implementation AnnotationView


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    NSLog(@"%s",__func__);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    CGContextSetLineWidth(context, 0.5);
    
      CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextAddRect(context, self.frame);
    CGContextStrokeRect(context, self.frame);
    
  //  CGContextStrokePath(context);
    
    CGContextRestoreGState(context);

}


@end
