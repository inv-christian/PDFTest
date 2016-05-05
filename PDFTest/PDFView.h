//
//  PDFView.h
//  PDFTest
//
//  Created by Priya Rajagopal on 4/25/16.
//  Copyright © 2016 invicara. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PDFView;
@protocol PDFViewProtocol <NSObject>

-(void)onDoubleTapped:(PDFView*)view;
-(void)onSingleTapped:(PDFView*)view atLocation:(CGPoint)location;

@end

@interface PDFView : UIView
@property (nonatomic,assign) CGPDFPageRef pdfPage;
@property (nonatomic,assign) CGFloat myScale;
@property (nonatomic,weak)id<PDFViewProtocol> delegate;

- (id)initWithFrame:(CGRect)frame scale:(CGFloat)scale;
- (void)setPage:(CGPDFPageRef)newPage;
- (void)setScale:(CGFloat)scale;

@end
