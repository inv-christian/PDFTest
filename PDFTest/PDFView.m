//
//  PDFView.m
//  PDFTest
//
//  Created by Priya Rajagopal on 4/25/16.
//  Copyright © 2016 invicara. All rights reserved.
//

#import "PDFView.h"

static const CGFloat kMinPdfViewScale = 0.25;
static const CGFloat kMaxPdfViewScale = 5.0;

@interface PDFView()

@end

@implementation PDFView

// Create a new TiledPDFView with the desired frame and scale.
- (id)initWithFrame:(CGRect)frame scale:(CGFloat)scale
{
    self = [super initWithFrame:frame];
    if (self) {

        self.myScale = scale;
        self.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.layer.borderWidth = 5;
        [self setupGestureRecognizers];
    }
    return self;
}


// The layer's class should be CATiledLayer.
+ (Class)layerClass
{
    return [CATiledLayer class];
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



// Set the CGPDFPageRef for the view.
- (void)setPage:(CGPDFPageRef)newPage {
    if( self.pdfPage != NULL ) CGPDFPageRelease( self.pdfPage );
    if( newPage != NULL ) self.pdfPage = CGPDFPageRetain( newPage );
}

- (void)setScale:(CGFloat)scale {
    self.myScale = scale;
    //[self setNeedsDisplay];
}

// Draw the CGPDFPageRef into the layer at the correct scale.
-(void)drawLayer:(CALayer*)layer inContext:(CGContextRef)context {
    
    NSLog(@"%s myScale:%f",__PRETTY_FUNCTION__,self.myScale);

    // Fill the background with white.
    CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
    CGContextFillRect(context, self.bounds);
    
    // Print a blank page and return if our page is null.
    if( _pdfPage == NULL ) {
        return;
    }
    
    CGContextSaveGState(context);
    // Flip the context so that the PDF page is rendered right side up.
    CGContextTranslateCTM(context, 0.0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // Scale the context so that the PDF page is rendered at the correct size for the zoom level.
    CGContextScaleCTM(context, self.myScale, self.myScale);
    CGContextDrawPDFPage(context, self.pdfPage);
    CGContextRestoreGState(context);
}


// Clean up.
- (void)dealloc {
    if( self.pdfPage != NULL ) {
        CGPDFPageRelease( self.pdfPage );
    }
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
