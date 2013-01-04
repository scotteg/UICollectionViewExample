//
//  DetailViewController.h
//  UICollectionViewExample
//
//  Created by Scott Gardner on 1/3/13.
//  Copyright (c) 2013 Scott Gardner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo.h"

@interface DetailViewController : UIViewController

@property (strong, nonatomic) Photo *photo;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end
