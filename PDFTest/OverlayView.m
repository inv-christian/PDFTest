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
#import "AnnotationView.h"


static const CGFloat kAnnotationTextFieldWidth = 150.0f;
static const CGFloat kAnnotationTextFieldHeight = 50.0f;

@interface OverlayView() <UITextViewDelegate>{
    CGPoint _lastPoint;
    
    CGMutablePathRef _currPath;
    
    BOOL _didMove;

}
@property (nonatomic, strong)PDFGeometryViewModel* viewModel;
@property (nonatomic, strong)UIImageView* drawAnnotationView;
@property (nonatomic, strong)UITextView* textAnnotationView;
@property (nonatomic, strong)AnnotationView* currentAnnotationView;
@property (nonatomic, strong)NSMutableArray <UIBezierPath*>* currentPaths;
@property (nonatomic, readwrite)NSMutableArray <UITextView*>* texts;
@property (nonatomic, assign)BOOL boundingBoxSetup;
@end

@implementation OverlayView

-(instancetype)initWithFrame:(CGRect)frame andPDFGeomViewModel:(PDFGeometryViewModel*)viewModel
{
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = NO;
        self.currentPaths = [[NSMutableArray alloc]initWithCapacity:0];
        self.texts  = [[NSMutableArray alloc]initWithCapacity:0];
        self.viewModel = viewModel;
        self.scale = 1.0;
        self.drawAnnotationView  = [self createAnnotationView];
        [self addSubview:self.drawAnnotationView];
        
      //  self.textAnnotationView = [self createTextAnnotationView];
        [self addSubview:self.textAnnotationView];
        
        self.currentAnnotationView = nil;
      //   [self addSubview:self.currentAnnotationView];
       // [self setupGestureRecognizers];
    }
    return self;
}

//-(void)layoutSubviews {
//    [super layoutSubviews];
//    [self setupGestureRecognizers];
//}

- (void)dealloc {
    
    
}

- (UIImageView*) createAnnotationView {
    UIImageView *temp = [[UIImageView alloc] initWithImage:nil];
    temp.frame = self.frame;
    return temp;
}

- (UITextView*) createTextAnnotationView {
    UITextView *temp = [[UITextView alloc] initWithFrame:CGRectMake(0, 0,kAnnotationTextFieldWidth, kAnnotationTextFieldHeight) ];
    temp.hidden = YES;
    temp.text = @"Text";
 
    return temp;
}


-(AnnotationView*)createCurrentAnnotationView {
    AnnotationView* currView = [[AnnotationView alloc]initWithFrame:CGRectMake(0, 0, kAnnotationTextFieldWidth, kAnnotationTextFieldHeight)];
    [self.currentAnnotationView setHidden:YES];
 //  [self.currentAnnotationView.layer needsDisplayOnBoundsChange];
//    self.currentAnnotationView.backgroundColor = [UIColor colorWithRed:214.0/255 green:214.0/255 blue:214.0/255 alpha:1.0];
//    self.currentAnnotationView.backgroundColor = [UIColor redColor];
//    self.currentAnnotationView.layer.cornerRadius = 2.0;
    
    return currView;
}

-(void)drawRect:(CGRect)rect
{
    NSLog(@"%s scale:%f",__PRETTY_FUNCTION__,self.scale);
    
    //[self setupBoundingBoxes];
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    CGContextSetLineWidth(context, 1);
    
    for (Element* elem in self.elements) {
        
        if ([elem selectedStateChanged]) {
            //[self drawElement:elem inContext:context];
            [elem draw:context];
        }
        CGContextStrokePath(context);
    }
    
  
    
    CGContextRestoreGState(context);
    if (self.inTextAnnotationMode) {
        [self.currentAnnotationView setNeedsDisplay ];
    }
    
}



-(NSArray<UIBezierPath*>*)annotationPaths {
    if (_currPath) {
        NSMutableArray* temp = [[NSMutableArray alloc]initWithCapacity:0];
        [temp addObjectsFromArray:self.currentPaths];
        [temp addObject:[UIBezierPath bezierPathWithCGPath:_currPath]];
        return temp;
    }
    return  nil;
 
    
}

-(NSArray<UITextView*>*)annotationTexts {
    if (self.textAnnotationView) {
        NSMutableArray* temp = [[NSMutableArray alloc]initWithCapacity:0];
        [temp addObjectsFromArray:self.texts];
        
        
        CGRect textViewFrame = self.textAnnotationView.frame;
        textViewFrame.origin.x = CGRectGetMinX(self.currentAnnotationView.frame) + 10;
        textViewFrame.origin.y = CGRectGetMinY(self.currentAnnotationView.frame) + 10;
       
        UITextView* tempText = [[UITextView alloc]initWithFrame:textViewFrame];
        tempText.text = self.textAnnotationView.text;
        
        
        [temp addObject:tempText];
        return temp;
    }
    return  nil;
    
    
}

-(void)setInTextAnnotationMode:(BOOL)inTextAnnotationMode {
    _inTextAnnotationMode = inTextAnnotationMode;
    if (!inTextAnnotationMode) {
        [self.textAnnotationView resignFirstResponder];
        [self.textAnnotationView removeFromSuperview];
   
        [self.currentAnnotationView setHidden:YES];
        [self.currentAnnotationView removeFromSuperview];
  
    }
   
}
#pragma mark - gesture recognizer helpers
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

- (void) drawAnnotations {
    UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 1.5f);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    
    
    CGContextSetShouldAntialias(currentContext, YES);
    NSDictionary* attr = @{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Thin" size:15]};
    for (UITextView *textView in self.annotationTexts) {
        [textView.text drawWithRect:textView.frame options:0 attributes:attr context:nil];
    }


    CGContextSetLineJoin(currentContext, kCGLineJoinRound);
 
    CGContextSetLineCap(currentContext, kCGLineCapRound);
    CGContextSetLineWidth(currentContext, 5.0);
    CGContextSetStrokeColorWithColor(currentContext, [UIColor redColor].CGColor);
  
    //Draw Paths
    for (UIBezierPath *path in self.currentPaths) {
        CGContextAddPath(currentContext, path.CGPath);
    }
    
    CGContextAddPath(currentContext, _currPath);
    CGContextStrokePath(currentContext);
    
    //Saving
    self.drawAnnotationView.image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
}



- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.inDrawAnnotationMode && !self.inTextAnnotationMode) {
        return;
    }
    UITouch *touch = [touches anyObject];
    _lastPoint = [touch locationInView:self];
    
    if (self.inTextAnnotationMode) {
        
        if (!self.currentAnnotationView) {
            if ([self.currentAnnotationView.layer containsPoint:_lastPoint]) {
                [self.textAnnotationView resignFirstResponder];
                return;
               
            }
            else {
                self.currentAnnotationView =  [[AnnotationView alloc]initWithFrame:CGRectMake(_lastPoint.x, _lastPoint.y, kAnnotationTextFieldWidth, kAnnotationTextFieldHeight) ];

                if (!self.textAnnotationView) {
                    
                    self.textAnnotationView = [[UITextView alloc] initWithFrame:CGRectMake(5, 5, kAnnotationTextFieldWidth-10, kAnnotationTextFieldHeight-10) ];
                    
                    self.textAnnotationView.delegate = self;
                    self.textAnnotationView.hidden = NO;
                    [self.currentAnnotationView addSubview:self.textAnnotationView];

                    [self addSubview:self.currentAnnotationView];
                    [self.textAnnotationView becomeFirstResponder];
                

                }
                [self.currentAnnotationView setNeedsDisplay];
                return;

//                CGRect textViewFrame = self.textAnnotationView.frame;
//                textViewFrame.origin.x = CGRectGetMinX(self.currentAnnotationView.frame) + 10;
//                textViewFrame.origin.y = CGRectGetMinY(self.currentAnnotationView.frame) + 10;
////
//                UITextView* tempText = [[UITextView alloc]initWithFrame:textViewFrame];
//                tempText.text = self.textAnnotationView.text;
//                [self.texts addObject:tempText];
//                [self.textAnnotationView resignFirstResponder];
//        
//                [self.currentAnnotationView setHidden:YES];
//                
             }
          
        }
        
      
        self.currentAnnotationView.frame = CGRectMake(_lastPoint.x, _lastPoint.y, kAnnotationTextFieldWidth, kAnnotationTextFieldHeight) ;
        
//        self.currentAnnotationView =  [[AnnotationView alloc]initWithFrame:CGRectMake(_lastPoint.x, _lastPoint.y, kAnnotationTextFieldWidth, kAnnotationTextFieldHeight) ];
//
//        self.textAnnotationView  = [[UITextView alloc] initWithFrame:CGRectMake(5, 5, kAnnotationTextFieldWidth-10, kAnnotationTextFieldHeight-10) ];
// 
//        self.textAnnotationView .delegate = self;
//        
//        [self.currentAnnotationView addSubview:self.textAnnotationView];
//        self.textAnnotationView.hidden = NO;
//        
//        [self addSubview:self.currentAnnotationView];
        
     //   [self.textAnnotationView becomeFirstResponder];
        [self.currentAnnotationView setHidden:NO];
        [self.currentAnnotationView setNeedsDisplay];
        
       
    }
    
    else {
        if (_currPath) {
            [self.currentPaths addObject:[UIBezierPath bezierPathWithCGPath:_currPath]];
        }
        _currPath = CGPathCreateMutable();
        CGPathMoveToPoint(_currPath, NULL, _lastPoint.x, _lastPoint.y);
        _didMove = NO;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.inDrawAnnotationMode && !self.inTextAnnotationMode) {
        return;
    }
    
    _didMove = YES;
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self];
    if (self.inTextAnnotationMode) {
        CGRect currFrame = self.currentAnnotationView.frame;
        currFrame.origin.x = currentPoint.x;
        currFrame.origin.y = currentPoint.y;
        self.currentAnnotationView.frame = currFrame;
        [self.currentAnnotationView setNeedsDisplay ];

    }
    else {
        //Update path
        CGPathAddLineToPoint(_currPath, NULL, currentPoint.x, currentPoint.y);
        [self drawAnnotations];
    }
    _lastPoint = currentPoint;
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.inTextAnnotationMode ) {
        return;
    }
    if (!self.inDrawAnnotationMode ) {
        return;
    }
    if (!_didMove) {
        UITouch *touch = [touches anyObject];
        CGPoint currentPoint = [touch locationInView:self];
        CGPathAddEllipseInRect(_currPath, NULL, CGRectMake(currentPoint.x - 2.f, currentPoint.y - 2.f, 4.f, 4.f));
        [self drawAnnotations];
    }
    _didMove = NO;
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

#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView
{
    CGFloat fixedWidth = kAnnotationTextFieldWidth;
    CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth-10, MAXFLOAT)] ;
    CGRect newFrame = textView.frame;
    CGFloat height = fmaxf( newSize.height ,kAnnotationTextFieldHeight-10);
    newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth-10), height);
    textView.frame = newFrame;
    
    CGRect viewFrame = self.currentAnnotationView.frame;
    CGFloat viewHeight = fmaxf( newSize.height + 10 ,kAnnotationTextFieldHeight);
    viewFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), viewHeight);
 
    self.currentAnnotationView.frame = viewFrame;
    [self.currentAnnotationView setNeedsDisplay];
}
@end