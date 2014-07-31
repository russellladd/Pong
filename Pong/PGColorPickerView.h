//
//  PGColorPickerView.h
//  Pong
//
//  Created by Russell Ladd on 6/29/14.
//  Copyright (c) 2014 GRL5. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PGColorPickerView : UIControl

@property (nonatomic, strong) UIColor *color;

@property (nonatomic) BOOL expanded;

- (void)setExpanded:(BOOL)expanded animated:(BOOL)animated;
- (void)setExpanded:(BOOL)expanded animated:(BOOL)animated delay:(NSTimeInterval)delay animations:(void(^)(void))animations;

@end
