//
//  WZButton.m
//  Hackers
//
//  Created by Weiran Zhang on 02/05/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZButton.h"

@interface WZButton ()
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *mainColor;
@end

@implementation WZButton

- (void)awakeFromNib {
    self.backgroundColor = [UIColor clearColor];
    self.mainColor = [WZTheme segmentBackgroundColor];
    
    [self setTitleColor:self.mainColor forState:UIControlStateNormal];
    [self setTitleColor:[UIColor clearColor] forState:UIControlStateHighlighted];
    
    self.titleLabel.font = [UIFont fontWithName:kBodyFontName size:kBodyFontSize];
}

- (void)setHighlighted:(BOOL)highlighted {
    if (self.highlighted != highlighted) {
        [super setHighlighted:highlighted];
        
        UIColor *temp = self.mainColor;
        self.mainColor = self.backgroundColor;
        self.backgroundColor = temp;
        
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect {
    UIBezierPath* roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectInset(rect, 1, 1) cornerRadius: 5];
    [self.backgroundColor setFill];
    [roundedRectanglePath fill];
    [self.mainColor setStroke];
    roundedRectanglePath.lineWidth = 1;
    [roundedRectanglePath stroke];
}

@end
