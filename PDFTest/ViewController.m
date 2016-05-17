//
//  ViewController.m
//  PDFTest
//
//  Created by Priya Rajagopal on 4/25/16.
//  Copyright © 2016 invicara. All rights reserved.
//

#import "ViewController.h"
#import "PDFView.h"
#import "OverlayView.h"
#import "Element.h"
#import "PDFGeometryViewModel.h"

@import GLKit;

static const CGFloat kMinPdfViewScale = 0.25;
static const CGFloat kMaxPdfViewScale = 8.0;


@interface ViewController () <UIScrollViewDelegate, ViewInteractionProtocol>
//@property (nonatomic,strong) NSURL* pdfURL;
//@property (nonatomic,strong) NSURL* geomURL;
@property (nonatomic,assign)CGPDFDocumentRef pdf;
@property (weak, nonatomic) IBOutlet UIScrollView *pdfScrollView;
@property CGPDFPageRef page;
@property (nonatomic,strong) PDFView* pdfView;
@property (nonatomic,strong) OverlayView* overlayView;
@property (nonatomic,strong) NSMutableArray* elements;
@property (nonatomic,assign) CGFloat pdfScale;
@property (nonatomic, strong)PDFGeometryViewModel* geomViewModel;

@end

@implementation ViewController {
    float _viewOrigin[3];
    float _viewDir[3];
    float _viewUpDir[3];
    float _viewCenter[3];
    float _viewOutline[4];
    int _viewScale;
    int _printZoom;
    float _viewOffset[2];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSURL* geomInfoURL = [[NSBundle mainBundle]URLForResource:@"geomInfo_racbasic.json" withExtension:nil];
    //NSURL* geomInfoURL = [[NSBundle mainBundle]URLForResource:@"geomInfo.json" withExtension:nil];
    self.geomViewModel = [[PDFGeometryViewModel alloc]initWithGeometryURL:geomInfoURL];
    
    
    //self.pdfURL = [[NSBundle mainBundle]URLForResource:@"floorplan" withExtension:@"pdf"];
    self.pdf = CGPDFDocumentCreateWithURL( (__bridge CFURLRef) self.geomViewModel .pdfURL );
    
    if (self.pdf == NULL) {
        CGPDFDocumentRelease(self.pdf);
    }
    else {
        self.page = CGPDFDocumentGetPage( self.pdf, 1 );
//        CGPDFDictionaryRef pageDict = CGPDFPageGetDictionary(self.page);
//        if( self.page != NULL ) {
//            CGPDFPageRetain( self.page );
//        }
        self.pdfScale = 1.0;
        
        CGRect pdfRect = CGPDFPageGetBoxRect( self.page, kCGPDFMediaBox );
        
        NSInteger rotationAngle = CGPDFPageGetRotationAngle(self.page);
        if (rotationAngle != 0) {
            float midX = pdfRect.size.width / 2;
            float midY = pdfRect.size.height / 2;
            CGAffineTransform trf = CGAffineTransformConcat(
                                      CGAffineTransformConcat(CGAffineTransformMakeTranslation(-midX, -midY),CGAffineTransformMakeRotation(-rotationAngle * M_PI/180.0)),
                                      CGAffineTransformMakeTranslation(midX, midY));
            pdfRect = CGRectApplyAffineTransform(pdfRect, trf);
            pdfRect.origin.x = 0;
            pdfRect.origin.y = 0;
        }
        
        [self loadPdfPageIntoViewFrame:pdfRect];

        self.overlayView.elements = self.geomViewModel.elements ;
        
        [self setupPdfScrollView];
      
    }
}

-(void)setupPdfScrollView {

    self.pdfScrollView.frame = self.pdfView.bounds;
    self.pdfScrollView.delegate = self;
    self.pdfScrollView.minimumZoomScale = kMinPdfViewScale;
    self.pdfScrollView.maximumZoomScale = kMaxPdfViewScale;
}


-(void)convertNSArray:(NSArray*)arr toFloatArray:(float*)out
{
    for (int i=0; i < arr.count; i++)
        out[i] = [[arr objectAtIndex:i] floatValue];
}


-(void)dealloc {
    if (self.pdf != NULL) {
        CGPDFDocumentRelease(self.pdf);
    }
    
    if (self.page != NULL) {
        CGPDFPageRelease( self.page );
    }
}

-(void)loadPdfPageIntoViewFrame:(CGRect)frame {
    
    PDFView*  pdfView = [[PDFView alloc] initWithFrame:frame scale:self.pdfScale];
    pdfView.delegate = self;
    
    [pdfView setPage:self.page];
    
    [self.pdfScrollView addSubview:pdfView];
    self.pdfView = pdfView;
    self.pdfScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self setPdfPageViewConstraints];
    self.overlayView = [[OverlayView alloc] initWithFrame:frame andPDFGeomViewModel:self.geomViewModel];
    self.overlayView.delegate = self;

    [self.pdfView addSubview:self.overlayView];
    
}


-(void)restoreView {
    self.pdfScrollView.zoomScale = 1.0;
    
}

-(void)highlightSelectedElementAtLocation:(CGPoint)location {
    __block float minDistance = FLT_MAX;
    __block Element* closestElement = nil;
    
    [self.geomViewModel.elements enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        Element* element = obj;
      //  element.selected = NO;
        
        float distance = [element distanceToPoint:location viewRect:self.pdfView.bounds];
        if (distance < 5 && distance < minDistance) {
            minDistance = distance;
            closestElement = element;
        }
        /*if (CGRectContainsPoint( element.boundingBox ,location)) {
            NSLog(@"%@",NSStringFromCGRect(element.boundingBox) );
            element.selected = YES;
            NSLog(@"Contains point");
        }*/
    }];
    
    if (closestElement != nil) {
        closestElement.selected = !closestElement.selected;
    }
    
    [self.overlayView setNeedsDisplay];
    
}

#pragma maerk - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return scrollView.subviews[0];
}

-(void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view {
   
    NSLog(@"%s",__func__);
    
}

-(void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view atScale:(CGFloat)scale {
    NSLog(@"%s %f",__func__, scale);
    self.overlayView.scale = scale;
    [self.overlayView setNeedsDisplay];
}



#pragma mark - ViewInteractionProtocol
-(void)onDoubleTapped:(PDFView*)view {
    [self restoreView];
}

-(void)onSingleTapped:(UIView*)view atLocation:(CGPoint)location {
    NSLog(@"Tapped at location %@", NSStringFromCGPoint(location));
   //   [self.overlayView setNeedsDisplay];
    /* sample code to add overlay view
     Need info to map selected location to element in pdf doc and to add overlay view*/
    //UIView * overlayView = [[UIView alloc]initWithFrame:CGRectMake( location.x-10,location.y-10 , 20, 20)];
    //[overlayView setBackgroundColor:[UIColor yellowColor]];
    //[self.pdfView addSubview:overlayView];
     
    [self highlightSelectedElementAtLocation:location];
}

#pragma mark - auto kayout
- (void)setPdfPageViewConstraints
{
    NSLayoutConstraint *xConstraint = [NSLayoutConstraint constraintWithItem:self.pdfView
                                                                   attribute:NSLayoutAttributeCenterX
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.pdfScrollView
                                                                   attribute:NSLayoutAttributeCenterX
                                                                  multiplier:1.0
                                                                    constant:0];
//    NSLayoutConstraint *yConstraint = [NSLayoutConstraint constraintWithItem:self.pdfView
//                                                                   attribute:NSLayoutAttributeCenterY
//                                                                   relatedBy:NSLayoutRelationEqual
//                                                                      toItem:self.pdfScrollView
//                                                                   attribute:NSLayoutAttributeCenterY
//                                                                  multiplier:1.0
//                                                                    constant:0];
//    
    
    [self.pdfScrollView addConstraints:@[ xConstraint ]];
}
@end
