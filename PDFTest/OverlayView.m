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
@property (nonatomic, weak) NSMutableArray* elements;
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

-(void)setElements:(NSMutableArray*)elements
{
    self.elements = elements;
}

-(void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor yellowColor].CGColor);
    CGContextSetLineWidth(context, 3);
    
    for (Element* elem in self.elements) {
        [elem draw:context];
    }
}

@end