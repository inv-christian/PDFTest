//
//  OverlayView.h
//  PDFTest
//
//  Created by Christian Utama on 5/5/16.
//  Copyright © 2016 invicara. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewInteractionProtocol.h"

@class PDFGeometryViewModel;
@class Element;

@interface OverlayView : UIView
@property (nonatomic, copy) NSArray<Element*>* elements;
@property (nonatomic) float scale;
@property (nonatomic, assign)BOOL inDrawAnnotationMode;
@property (nonatomic, assign)BOOL inTextAnnotationMode;

@property (nonatomic, readonly)NSArray<UIBezierPath*>* annotationPaths;
@property (nonatomic, readonly)NSArray<UITextView*>* annotationTexts;
@property (nonatomic,weak)id<ViewInteractionProtocol> delegate;

-(instancetype)initWithFrame:(CGRect)frame andPDFGeomViewModel:(PDFGeometryViewModel*)viewModel;
-(void)drawRect:(CGRect)rect;


@end