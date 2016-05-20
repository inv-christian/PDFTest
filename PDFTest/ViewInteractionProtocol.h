//
//  ViewInteractionProtocol.h
//  PDFTest
//
//  Created by Priya Rajagopal on 5/13/16.
//  Copyright © 2016 invicara. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ViewInteractionProtocol <NSObject>
@optional
-(void)onDoubleTapped:(UIView*)view;
-(void)onSingleTapped:(UIView*)view atLocation:(CGPoint)location;
-(void)onSwipe:(UIView*)view withDirection:(UISwipeGestureRecognizerDirection)swipeDirection;

@end
