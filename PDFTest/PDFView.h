//
//  PDFView.h
//  PDFTest
//
//  Created by Priya Rajagopal on 4/25/16.
//  Copyright © 2016 invicara. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewInteractionProtocol.h"

@class PDFView;

@interface PDFView : UIView
@property (nonatomic,assign) CGPDFPageRef pdfPage;
@property (nonatomic,assign) CGFloat scale;
@property (nonatomic,weak)id<ViewInteractionProtocol> delegate;
@property (nonatomic, assign)BOOL inAnnotationMode;

-(id)initWithFrame:(CGRect)frame scale:(CGFloat)scale;
-(void)setPage:(CGPDFPageRef)newPage;
-(void)drawPdfToFileWithAnnotations:(NSArray<UIBezierPath*>*)annotations  ;
@end
