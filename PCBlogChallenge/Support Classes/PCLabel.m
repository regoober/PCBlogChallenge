//
//  PCLabel.m
//  PCBlogChallenge
//
//  Created by Brian Goo on 4/21/18.
//  Copyright © 2018 Brian Goo. All rights reserved.
//

#import "PCLabel.h"

@implementation PCLabel

- (void)setTextInsets:(UIEdgeInsets)textInsets
{
    _textInsets = textInsets;
    [self invalidateIntrinsicContentSize];
}

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines
{
    UIEdgeInsets insets = self.textInsets;
    CGRect rect = [super textRectForBounds:UIEdgeInsetsInsetRect(bounds, insets)
                    limitedToNumberOfLines:numberOfLines];
    
    rect.origin.x    -= insets.left;
    rect.origin.y    -= insets.top;
    rect.size.width  += (insets.left + insets.right);
    rect.size.height += (insets.top + insets.bottom);
    
    return rect;
}

- (void)drawTextInRect:(CGRect)rect
{
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.textInsets)];
}

@end
