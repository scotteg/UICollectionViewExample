//
//  DetailViewController.h
//  UICollectionViewExample
//
//  Created by Scott Gardner on 1/3/13.
//  Copyright (c) 2013 Scott Gardner. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
