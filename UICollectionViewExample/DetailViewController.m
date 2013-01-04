//
//  DetailViewController.m
//  UICollectionViewExample
//
//  Created by Scott Gardner on 1/3/13.
//  Copyright (c) 2013 Scott Gardner. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()

@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private

- (void)configureView
{
    self.title = self.photo.name;
    self.imageView.image = [UIImage imageWithData:self.photo.imageData];
}

@end
