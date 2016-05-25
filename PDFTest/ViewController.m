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

typedef NS_ENUM(NSInteger,ANNOTATION_MODE) {
     ANNOTATIONMODE_TEXT = 0,
     ANNOTATIONMODE_DRAW = 1
};

static const CGFloat kMinPdfViewScale = 0.25;
static const CGFloat kMaxPdfViewScale = 10.0;


@interface ViewController () <UIScrollViewDelegate, ViewInteractionProtocol>

@property (nonatomic,assign)CGPDFDocumentRef pdf;
@property (weak, nonatomic) IBOutlet UIScrollView *pdfScrollView;
@property CGPDFPageRef page;
@property (nonatomic,strong) PDFView* pdfView;
@property (nonatomic,strong) OverlayView* overlayView;
@property (nonatomic,strong) NSMutableArray* elements;
@property (nonatomic,assign) CGFloat pdfScale;
@property (nonatomic, strong)PDFGeometryViewModel* geomViewModel;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (nonatomic, assign) NSInteger currentPageIndex;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *forwardButton;
@property (weak, nonatomic) IBOutlet UIButton *annotationButton;
@property (weak, nonatomic) IBOutlet UIButton *textAnnotationButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *titleBarItem;

@property (assign,nonatomic)BOOL inDrawAnnotationMode;
@property (assign,nonatomic)BOOL inTextAnnotationMode;

- (IBAction)annotationTapped:(UIButton *)sender;
- (IBAction)onBackTapped:(UIButton *)sender;
- (IBAction)onForwardTapped:(UIButton *)sender;
- (IBAction)onSave:(UIButton *)sender;
- (IBAction)textAnnotationTapped:(UIButton *)sender;

@end

@implementation ViewController

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
    NSURL* geomInfoURL = [[NSBundle mainBundle]URLForResource:@"geomInfo-gemmedical.json" withExtension:nil];

    //NSURL* geomInfoURL = [[NSBundle mainBundle]URLForResource:@"geomInfo.json" withExtension:nil];
    self.geomViewModel = [[PDFGeometryViewModel alloc]initWithGeometryURL:geomInfoURL];
    self.currentPageIndex = 0;
    self.backButton.enabled = NO;
    NSInteger numPages =  self.geomViewModel.pdfs.count;
    if (self.currentPageIndex == numPages -1){
          self.forwardButton.enabled = NO;
    }
    
    [self displayPdfPageAtCurrentIndex];
    
    //self.pdfURL = [[NSBundle mainBundle]URLForResource:@"floorplan" withExtension:@"pdf"];
}

-(void)displayPdfPageAtCurrentIndex {
    NSLog(@"%s page : %ld",__func__,(long)self.currentPageIndex);
    self.inDrawAnnotationMode = NO;
    self.inTextAnnotationMode = NO;
    self.annotationButton.selected = NO;
    [self setupRegularMode:ANNOTATIONMODE_TEXT];
    [self setupRegularMode:ANNOTATIONMODE_DRAW];
    PDFDetails* details = self.geomViewModel.pdfs[self.currentPageIndex];
    
    NSURL* pdfUrl = details.pdfURL;
    
    self.pdf = CGPDFDocumentCreateWithURL( (__bridge CFURLRef) pdfUrl );
    self.navigationItem.title = details.name;
    
    if (self.pdf != NULL) {
        self.pageControl.numberOfPages = self.geomViewModel.pdfs.count;
       
        self.page = CGPDFDocumentGetPage( self.pdf, 1 );
   
        CGPDFPageRetain(self.page);
     
        self.pdfScale = 1.0;
        
        CGRect pdfRect = CGPDFPageGetBoxRect( self.page, kCGPDFMediaBox );
//        
//        NSInteger rotationAngle = CGPDFPageGetRotationAngle(self.page);
//        if (rotationAngle != 0) {
//            float midX = pdfRect.size.width / 2;
//            float midY = pdfRect.size.height / 2;
//            CGAffineTransform trf = CGAffineTransformConcat(
//                                                            CGAffineTransformConcat(CGAffineTransformMakeTranslation(-midX, -midY),CGAffineTransformMakeRotation(-rotationAngle * M_PI/180.0)),
//                                                            CGAffineTransformMakeTranslation(midX, midY));
//            pdfRect = CGRectApplyAffineTransform(pdfRect, trf);
//            pdfRect.origin.x = 0;
//            pdfRect.origin.y = 0;
//        }
//        
        [self loadPdfPageIntoViewFrame:pdfRect];
        
        self.pageControl.numberOfPages = CGPDFDocumentGetNumberOfPages(self.pdf);
        
        // kick off geometry loading in BG
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [details loadGeometryElementsWithCompletionHandler:^(NSArray<Element *> *elements) {
                NSLog(@"Loading geom ");
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

                self.overlayView.elements = elements ;
            }];

        });
        

        
        if (self.page != NULL) {
            CGPDFPageRelease(self.page);
        }
    }
    if (self.pdf != NULL) {
        CGPDFDocumentRelease(self.pdf);
        
    }

}


-(void)setupRegularMode:(ANNOTATION_MODE)mode  {

  //  self.pdfScrollView.frame = self.pdfView.bounds;
    self.pdfScrollView.delegate = self;
    self.pdfScrollView.minimumZoomScale = kMinPdfViewScale;
    self.pdfScrollView.maximumZoomScale = kMaxPdfViewScale;
    self.pdfScrollView.scrollEnabled = YES;
    if (mode == ANNOTATIONMODE_DRAW) {
        self.annotationButton.selected = NO;
    }
    else if (mode == ANNOTATIONMODE_TEXT) {
        self.textAnnotationButton.selected = NO;
    }

    
}

-(void)setupAnnotationMode:(ANNOTATION_MODE)mode {
    
    //  self.pdfScrollView.frame = self.pdfView.bounds;
    self.pdfScrollView.delegate = self;
    self.pdfScrollView.minimumZoomScale = 1.0;
    self.pdfScrollView.maximumZoomScale = 1.0;
    self.pdfScrollView.scrollEnabled = NO;
    if (mode == ANNOTATIONMODE_DRAW) {
        self.annotationButton.selected = YES;
    }
    else if (mode == ANNOTATIONMODE_TEXT) {
        self.textAnnotationButton.selected = YES;
    }
    
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
    
   // [self.pdfScrollView setFrame:frame];
    if (self.pdfView) {
        
        [self.pdfView removeFromSuperview];
    }
    
    self.pdfView = [[PDFView alloc] initWithFrame:frame scale:1.0];
    self.pdfView.delegate = self;
    
    [self.pdfView setPage:self.page];
    self.pdfScrollView.zoomScale = 1.0;
    
    [self.pdfScrollView addSubview:self.pdfView];

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
    NSLog(@"%s, index %d",__func__,self.currentPageIndex);
    if (self.overlayView.elements) {
        __block float minDistance = FLT_MAX;
        __block Element* closestElement = nil;
        PDFDetails* details = self.geomViewModel.pdfs[self.currentPageIndex];
        NSArray* elements = details.elements;
        
        [elements enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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
    else {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:@"Geometry still loading. Element selection cannot be done until thats completed" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
    }
    
}

#pragma maerk - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.pdfView;
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

-(void)onSwipe:(UIView *)view withDirection:(UISwipeGestureRecognizerDirection)swipeDirection {
    NSLog(@"%s",__func__);
    switch (swipeDirection) {
        case UISwipeGestureRecognizerDirectionLeft:
             [self onForwardTapped:nil];
            break;
        case UISwipeGestureRecognizerDirectionRight:
            [self onBackTapped:nil];
            break;
        default:
            NSLog(@"Unreciognized swipe gesture: %ld",swipeDirection);
    }
   
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
    
    
    [self.pdfScrollView addConstraints:@[ xConstraint ]];
}



#pragma mark - AnnotationsViewDataSource
-(NSArray<UIBezierPath*>*)annotationPaths {
    return [self.overlayView annotationPaths];
}

#pragma mark - IBActions
- (IBAction)onBackTapped:(UIButton *)sender {
    if (self.currentPageIndex == 0) {
        return;
    }
    self.currentPageIndex = self.currentPageIndex - 1;
    self.forwardButton.enabled = YES;
    if (self.currentPageIndex == 0) {
        self.backButton.enabled = NO;
    }
    
    [self displayPdfPageAtCurrentIndex];
   
    
}

- (IBAction)onForwardTapped:(UIButton *)sender {
    NSInteger totalNumPages = self.geomViewModel.pdfs.count;
    if (self.currentPageIndex == totalNumPages-1) {
        return;
    }
    self.backButton.enabled = YES;
    self.currentPageIndex = self.currentPageIndex + 1;
    if (self.currentPageIndex ==  totalNumPages-1) {
        self.forwardButton.enabled = NO;
        
    }
     
    [self displayPdfPageAtCurrentIndex];

}

- (IBAction)onSave:(UIButton *)sender {
    PDFDetails* details = self.geomViewModel.pdfs[self.currentPageIndex];
    NSURL* pdfUrl = details.pdfURL;

    [self.pdfView drawPdfToFile:pdfUrl withAnnotations:self.overlayView.annotationPaths andTextAnnotations:self.overlayView.annotationTexts];
    [self resetAnnotationMode];
    
}

-(void)resetAnnotationMode {
    if (self.inTextAnnotationMode) {
        self.inTextAnnotationMode = !self.inTextAnnotationMode;
        [self setupRegularMode:ANNOTATIONMODE_TEXT];
        
        self.overlayView.inTextAnnotationMode = self.inTextAnnotationMode;
        self.pdfView.inAnnotationMode = self.inTextAnnotationMode;
    }
    if (self.inDrawAnnotationMode) {
        self.inDrawAnnotationMode = !self.inDrawAnnotationMode;
        
        [self setupRegularMode:ANNOTATIONMODE_DRAW];

     
        self.overlayView.inTextAnnotationMode = self.inDrawAnnotationMode;
        self.pdfView.inAnnotationMode = self.inDrawAnnotationMode;
    }

}
- (IBAction)textAnnotationTapped:(UIButton *)sender {
    self.inTextAnnotationMode = !self.inTextAnnotationMode;
    if (self.inTextAnnotationMode) {
        [self setupAnnotationMode:ANNOTATIONMODE_TEXT];
    }
    else {
        [self setupRegularMode:ANNOTATIONMODE_TEXT];
    }
    self.overlayView.inTextAnnotationMode = self.inTextAnnotationMode;
    self.pdfView.inAnnotationMode = self.inTextAnnotationMode;
}
- (IBAction)annotationTapped:(UIButton *)sender {
  
    self.inDrawAnnotationMode = !self.inDrawAnnotationMode;
    if (self.inDrawAnnotationMode) {
        [self setupAnnotationMode:ANNOTATIONMODE_DRAW];
    }
    else {
        [self setupRegularMode:ANNOTATIONMODE_DRAW];
    }
    self.overlayView.inDrawAnnotationMode = self.inDrawAnnotationMode;
    self.pdfView.inAnnotationMode = self.inDrawAnnotationMode;
}
@end
