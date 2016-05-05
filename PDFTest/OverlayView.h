//
//  OverlayView.h
//  PDFTest
//
//  Created by Christian Utama on 5/5/16.
//  Copyright © 2016 invicara. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OverlayView : UIView

-(id)initWithFrame:(CGRect)frame;
-(void)setElements:(NSMutableArray*)elements;
-(void)drawRect:(CGRect)rect;

@end