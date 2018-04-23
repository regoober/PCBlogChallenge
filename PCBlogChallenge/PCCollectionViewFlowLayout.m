//
//  PCCollectionViewFlowLayout.m
//  PCBlogChallenge
//
//  Created by Brian Goo on 4/20/18.
//  Copyright © 2018 Brian Goo. All rights reserved.
//

#import "PCCollectionViewFlowLayout.h"

@implementation PCCollectionViewFlowLayout

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    CGRect oldBounds = self.collectionView.bounds;
    // check if bounds width actually changed to avoid excessive invalidations
    if (CGRectGetWidth(newBounds) != CGRectGetWidth(oldBounds)) {
        return YES;
    }
    return NO;
}

@end
