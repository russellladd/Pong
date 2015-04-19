//
//  PGColorPickerView.m
//  Pong
//
//  Created by Russell Ladd on 6/29/14.
//  Copyright (c) 2014 GRL5. All rights reserved.
//

#import "PGColorPickerView.h"

CGFloat const PGColorViewSideLengthLong = 66.0;
CGFloat const PGColorViewSideLengthShort = 44.0;

@interface PGColorPickerView ()

@property (nonatomic, strong) NSArray *colors;

@property (nonatomic, strong) UIButton *colorDropButton;
@property (nonatomic, strong) NSArray *colorButtons;
@property (nonatomic, strong) NSArray *colorButtonConstraints;

@end

@implementation PGColorPickerView

#pragma mark - Object life cycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        
        self.colors = @[[UIColor colorWithRed:1.00 green:0.00 blue:0.35 alpha:1.0], // Red
                        [UIColor colorWithRed:1.00 green:0.56 blue:0.00 alpha:1.0], // Orange
                        [UIColor colorWithRed:1.00 green:0.81 blue:0.00 alpha:1.0], // Yellow
                        [UIColor colorWithRed:0.00 green:0.90 blue:0.23 alpha:1.0], // Green
                        [UIColor colorWithRed:0.00 green:0.67 blue:0.99 alpha:1.0], // Blue
                        [UIColor colorWithRed:0.88 green:0.34 blue:0.88 alpha:1.0]];// Purple
        
        [self createColorViews];
        [self createColorDropView];
    }
    
    return self;
}

- (void)createColorDropView
{
    // Button
    
    UIButton *colorDropButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    colorDropButton.frame = CGRectMake(0.0, 0.0, PGColorViewSideLengthLong, PGColorViewSideLengthLong);
    colorDropButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    UIImage *colorDropImage = [UIImage imageNamed:@"ColorDrop"];
    
    [colorDropButton setImage:colorDropImage forState:UIControlStateNormal];
    
    [colorDropButton addTarget:self action:@selector(colorDropTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:colorDropButton];
    
    // Color drop button
    
    self.colorDropButton = colorDropButton;
}

- (void)createColorViews
{
    NSMutableArray *colorButtons = [NSMutableArray array];
    NSMutableArray *colorButtonConstraints = [NSMutableArray array];
    
    [self.colors enumerateObjectsUsingBlock:^(UIColor *color, NSUInteger index, BOOL *stop) {
        
        // Button
        
        UIButton *colorButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        colorButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        colorButton.alpha = 0.0;
        colorButton.tintColor = color;
        
        UIImage *colorCircleImage = [UIImage imageNamed:@"ColorCircle"];
        UIImage *colorCircleSelectedImage = [UIImage imageNamed:@"ColorCircleSelected"];
        
        [colorButton setImage:colorCircleImage forState:UIControlStateNormal];
        [colorButton setImage:colorCircleSelectedImage forState:UIControlStateHighlighted];
        [colorButton setImage:colorCircleSelectedImage forState:UIControlStateSelected];
        [colorButton setImage:colorCircleSelectedImage forState:UIControlStateHighlighted | UIControlStateSelected];
        
        [colorButton addTarget:self action:@selector(colorButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:colorButton];
        
        // Layout
        
        NSLayoutConstraint *xContraint = [NSLayoutConstraint constraintWithItem:colorButton
                                                                      attribute:NSLayoutAttributeCenterX
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self
                                                                      attribute:NSLayoutAttributeCenterX
                                                                     multiplier:1.0
                                                                       constant:0.0];
        
        NSLayoutConstraint *yConstraint = [NSLayoutConstraint constraintWithItem:colorButton
                                                                       attribute:NSLayoutAttributeTop
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self
                                                                       attribute:NSLayoutAttributeTop
                                                                      multiplier:1.0
                                                                        constant:0.0];
        
        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:colorButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:PGColorViewSideLengthLong];
        
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:colorButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:PGColorViewSideLengthShort];
        
        [colorButtonConstraints addObject:yConstraint];
        
        [self addConstraints:@[xContraint, yConstraint, widthConstraint, heightConstraint]];
        
        // Color buttons
        
        [colorButtons addObject:colorButton];
    }];
    
    self.colorButtons = [colorButtons copy];
    self.colorButtonConstraints = [colorButtonConstraints copy];
}

#pragma mark - Color

- (void)setColor:(UIColor *)color
{
    if (![_color isEqual:color]) {
        
        _color = color;
        
        [self.colors enumerateObjectsUsingBlock:^(UIColor *testColor, NSUInteger index, BOOL *stop) {
            
            UIButton *colorButton = self.colorButtons[index];
            
            colorButton.selected = [_color isEqual:testColor];
        }];
    }
}

#pragma mark - Actions

- (void)colorDropTouchUpInside:(UIButton *)colorDropButton
{
    [self setExpanded:!self.expanded animated:YES];
}

- (void)colorButtonTouchUpInside:(UIButton *)colorButton
{
    NSUInteger index = [self.colorButtons indexOfObject:colorButton];
    
    self.color = self.colors[index];
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

#pragma mark - Expansion

- (void)setExpanded:(BOOL)expanded
{
    [self setExpanded:expanded animated:NO];
}

- (void)setExpanded:(BOOL)expanded animated:(BOOL)animated
{
    [self setExpanded:expanded animated:animated delay:0.0 animations:NULL];
}

- (void)setExpanded:(BOOL)expanded animated:(BOOL)animated delay:(NSTimeInterval)delay animations:(void (^)(void))animations
{
    if (_expanded != expanded) {
        
        _expanded = expanded;
        
        [self invalidateIntrinsicContentSize];
        
        [self.colorButtonConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *constraint, NSUInteger index, BOOL *stop) {
            
            if (_expanded) {
                constraint.constant = PGColorViewSideLengthLong + index * PGColorViewSideLengthShort;
            } else {
                constraint.constant = (PGColorViewSideLengthLong - PGColorViewSideLengthShort) / 2.0;
            }
        }];
        
        [self setNeedsUpdateConstraints];
        
        [UIView animateWithDuration:animated ? 0.5 : 0.0 delay:delay usingSpringWithDamping:0.7 initialSpringVelocity:0.0 options:0 animations:^{
            
            [self layoutIfNeeded];
            
            [self.colorButtons enumerateObjectsUsingBlock:^(UIButton *colorButton, NSUInteger idx, BOOL *stop) {
                
                colorButton.alpha = _expanded ? 1.0 : 0.0;
            }];
            
            if (animations) animations();
            
        } completion:NULL];
    }
}

#pragma mark - Layout

- (CGSize)intrinsicContentSize
{
    CGSize size = CGSizeMake(PGColorViewSideLengthLong, PGColorViewSideLengthLong);
    
    if (self.expanded) size.height += self.colors.count * PGColorViewSideLengthShort;
    
    return size;
}

@end
