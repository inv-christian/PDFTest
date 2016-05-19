//
//  PDFView.m
//  PDFTest
//
//  Created by Priya Rajagopal on 4/25/16.
//  Copyright © 2016 invicara. All rights reserved.
//

#import "PDFView.h"

@interface PDFView()
@property (nonnull,strong) UITapGestureRecognizer *doubleTap;
@property (nonnull,strong) UITapGestureRecognizer *singleTap;
@property (nonnull,strong) UISwipeGestureRecognizer *swipeLeft;
@property (nonnull,strong) UISwipeGestureRecognizer *swipeRight ;
@end

@implementation PDFView

// Create a new TiledPDFView with the desired frame and scale.
- (id)initWithFrame:(CGRect)frame scale:(CGFloat)scale
{
    self = [super initWithFrame:frame];
    if (self) {

        self.scale = scale;
        
        // adjust properties of CATiledLayer
        
        CATiledLayer *tiledLayer = (CATiledLayer *)[self layer];
        
        tiledLayer.levelsOfDetail = 4;
        tiledLayer.levelsOfDetailBias = 3;
        tiledLayer.tileSize = CGSizeMake(700,700);
        
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

-(void)layoutSubviews{
    NSLog(@"%s",__func__);
    [super layoutSubviews];

    self.contentScaleFactor = 1;
}

-(void)setInAnnotationMode:(BOOL)inAnnotationMode {
    _inAnnotationMode = inAnnotationMode;
    if (inAnnotationMode) {
        [self removeGestureRecognizers];
    }
    else {
        [self setupGestureRecognizers];
    }
}

-(void)setupGestureRecognizers {
    [self setupDoubleTapGestureRecognizers];
    [self setupSingleTapGestureRecognizers];
    [self setupSwipeLeftGestureRecognizers];
    [self setupSwipeRightGestureRecognizers];

}

-(void)setupDoubleTapGestureRecognizers {
    self.doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDoubleTap:)];
    self.doubleTap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:self.doubleTap];
}

-(void)setupSingleTapGestureRecognizers {
   self.singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSingleTap:)];
    [self addGestureRecognizer:self.singleTap];
}

-(void)setupSwipeLeftGestureRecognizers {
    self.swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipeLeft:)];
    self.swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self addGestureRecognizer:self.swipeLeft];
}

-(void)setupSwipeRightGestureRecognizers {
    self.swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipeRight:)];
    self.swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self addGestureRecognizer:self.swipeRight];
}

-(void)removeGestureRecognizers {
    [self removeGestureRecognizer:self.doubleTap];
    [self removeGestureRecognizer:self.singleTap];
    [self removeGestureRecognizer:self.swipeRight];
    [self removeGestureRecognizer:self.swipeLeft];
}


// Set the CGPDFPageRef for the view.
- (void)setPage:(CGPDFPageRef)newPage {
    if( self.pdfPage != NULL ) CGPDFPageRelease( self.pdfPage );
    if( newPage != NULL ) self.pdfPage = CGPDFPageRetain( newPage );
}

// Draw the CGPDFPageRef into the layer at the correct scale.
-(void)drawLayer:(CALayer*)layer inContext:(CGContextRef)context {
    
    NSLog(@"%s myScale:%f",__PRETTY_FUNCTION__,self.scale);

    // Print a blank page and return if our page is null.
    if( _pdfPage == NULL ) {
        return;
    }
    
    CGContextSaveGState(context);
    
    CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
    CGContextFillRect(context, self.bounds);
    
    CGRect pdfRect = CGPDFPageGetBoxRect( self.pdfPage, kCGPDFMediaBox );
    
    // Flip the context so that the PDF page is rendered right side up.
    CGContextTranslateCTM(context, 0.0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    NSInteger rotationAngle = CGPDFPageGetRotationAngle(self.pdfPage);
    if (rotationAngle != 0) {
        CGContextTranslateCTM(context, self.bounds.size.width/2, self.bounds.size.height/2);
        CGContextRotateCTM(context, -rotationAngle * M_PI/180.0);
        CGContextTranslateCTM(context, -pdfRect.size.width/2, -pdfRect.size.height/2);
    }
    
    // Scale the context so that the PDF page is rendered at the correct size for the zoom level.
    CGContextScaleCTM(context, self.scale, self.scale);
    
    CGContextDrawPDFPage(context, self.pdfPage);
    
    CGContextRestoreGState(context);
}


// Clean up.
- (void)dealloc {
    [self removeGestureRecognizers];
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

-(void)onSwipeLeft:(UIGestureRecognizer*)recognizer {
    NSLog(@"%s",__func__);
    if (self.delegate && [self.delegate respondsToSelector:@selector(onSwipe:withDirection:)]) {
        
        [self.delegate onSwipe:self withDirection:UISwipeGestureRecognizerDirectionLeft];
    }
}

-(void)onSwipeRight:(UIGestureRecognizer*)recognizer {
    NSLog(@"%s",__func__);
    if (self.delegate && [self.delegate respondsToSelector:@selector(onSwipe:withDirection:)]) {
        [self.delegate onSwipe:self withDirection:UISwipeGestureRecognizerDirectionRight];
    }
}
@end
