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
    return YES;
}

@end
