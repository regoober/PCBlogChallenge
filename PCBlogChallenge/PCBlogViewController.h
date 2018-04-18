//
//  ViewController.h
//  PCBlogChallenge
//
//  Created by Brian Goo on 4/9/18.
//  Copyright © 2018 Brian Goo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PCBlogViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) UICollectionView *collectionView;

@end

