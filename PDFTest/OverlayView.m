//
//  OverlayView.m
//  PDFTest
//
//  Created by Christian Utama on 5/5/16.
//  Copyright © 2016 invicara. All rights reserved.
//

#import "OverlayView.h"
#import "Element.h"

@interface OverlayView()
@end

@implementation OverlayView

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = NO;
    }
    return self;
}

-(void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor yellowColor].CGColor);
    CGContextSetLineWidth(context, 3);
    
    for (Element* elem in self.elements) {
        //if (elem.selected)
            [elem draw:context];
    }
    
    CGContextStrokePath(context);
}

@end