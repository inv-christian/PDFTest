//
//  OverlayView.m
//  PDFTest
//
//  Created by Christian Utama on 5/5/16.
//  Copyright © 2016 invicara. All rights reserved.
//

#import "OverlayView.h"
#import "Element.h"
#import "PDFGeometryViewModel.h"

@interface OverlayView()
@property (nonatomic, strong)PDFGeometryViewModel* viewModel;
@property (nonatomic, assign)BOOL boundingBoxSetup;
@end

@implementation OverlayView

-(instancetype)initWithFrame:(CGRect)frame andPDFGeomViewModel:(PDFGeometryViewModel*)viewModel
{
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = NO;
        self.viewModel = viewModel;
        self.scale = 1.0;
        [self setupGestureRecognizers];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    [self setupGestureRecognizers];
}

-(void)drawRect:(CGRect)rect
{
    //[self setupBoundingBoxes];
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    CGContextSetLineWidth(context, 0.5/self.scale);
    CGContextSetShouldAntialias(context, NO);
    CGContextSetAllowsAntialiasing(context, NO);
    
    for (Element* elem in self.elements) {
        
        if ([elem selectedStateChanged]) {
            //[self drawElement:elem inContext:context];
            [elem draw:context];
        }
        CGContextStrokePath(context);
        
    }
    
    CGContextRestoreGState(context);
    
}

-(void)setupGestureRecognizers {
    [self setupDoubleTapGestureRecognizers];
    [self setupSingleTapGestureRecognizers];
    
}


-(void)setupDoubleTapGestureRecognizers {
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTap];
}

-(void)setupSingleTapGestureRecognizers {
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSingleTap:)];
    [self addGestureRecognizer:singleTap];
}


/*-(void)setupBoundingBoxes {
    if (!self.boundingBoxSetup) {
    
        // we have to draw all the paths in order to compute the bounding boxes of each path...
        for (Element* element in self.elements) {
            CGContextRef context = UIGraphicsGetCurrentContext();
            
            CGContextSaveGState(context);
            for (NSArray* geom in element.geometries) {
                for (int i=0; i < geom.count; i+= 6) {
                    if (i <= geom.count - 6) {
                        
                        float arr[6];
                        [self getPoints:geom startOffset:i toArray:arr];
                        
                        GLKVector2 p1 = [self.viewModel convertToPixel:arr inRect:CGContextGetClipBoundingBox(context)];
                        GLKVector2 p2 = [self.viewModel convertToPixel:(arr+3) inRect:CGContextGetClipBoundingBox(context)];
                        
                        CGContextMoveToPoint(context, p1.x, p1.y);
                        CGContextAddLineToPoint(context, p2.x, p2.y);
                    }
                }
            }
            
            CGPathRef aPathRef = CGContextCopyPath(context);
            
            // Close the path
            CGContextClosePath(context);
            
            CGRect boundingBox = CGPathGetBoundingBox(aPathRef);
            NSLog(@" minimal enclosing rect: %.2f %.2f %.2f %.2f", boundingBox.origin.x, boundingBox.origin.y, boundingBox.size.width, boundingBox.size.height);
            CGContextSetStrokeColorWithColor(context, [UIColor clearColor].CGColor);
            CGContextStrokePath(context);
            element.boundingBox = boundingBox;
            
            CGContextRestoreGState(context);
            CGPathRelease(aPathRef);
            
        }
        self.boundingBoxSetup = YES;
    }
    
}*/

//
//-(void)drawElement:(Element*)element inContext:(CGContextRef)context {
//    
//    // we are drawing the path twice -
//      for (NSArray* geom in element.geometries) {
//        for (int i=0; i < geom.count; i+= 6) {
//            if (i <= geom.count - 6) {
//                
//                float arr[6];
//                [self getPoints:geom startOffset:i toArray:arr];
//                
//                GLKVector2 p1 = [self.viewModel convertToPixel:arr inRect:CGContextGetClipBoundingBox(context)];
//                GLKVector2 p2 = [self.viewModel convertToPixel:(arr+3) inRect:CGContextGetClipBoundingBox(context)];
//                
//                
//                CGContextMoveToPoint(context, p1.x, p1.y);
//                CGContextAddLineToPoint(context, p2.x, p2.y);
//            }
//        }
//    }
//    
//    
//    // Close the path
//    CGContextClosePath(context);
//    
//
//    CGContextSetStrokeColorWithColor(context, [UIColor yellowColor].CGColor);
//    CGContextStrokePath(context);
//    
//}


-(void)getPoints:(NSArray*)arr startOffset:(int)offset toArray:(float*)out
{
    for (int i=0; i < 6; i++)
        out[i] = [[arr objectAtIndex:(offset + i)] floatValue];
}

#pragma mark - gesture recognizer
-(void)onDoubleTap:(UIGestureRecognizer*)recognizer {
    NSLog(@"%s",__func__);
    if (self.delegate && [self.delegate respondsToSelector:@selector(onDoubleTapped:)]) {
        [self.delegate onDoubleTapped:self];
    }
    
}

-(void)onSingleTap:(UIGestureRecognizer*)recognizer {
    NSLog(@"%s",__func__);
    if (self.delegate && [self.delegate respondsToSelector:@selector(onSingleTapped:atLocation:)]) {
        CGPoint point = [recognizer locationInView:recognizer.view]; // Tap location
        
        [self.delegate onSingleTapped:self atLocation:point];
    }
    
}
@end