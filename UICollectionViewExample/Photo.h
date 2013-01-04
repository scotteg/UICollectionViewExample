//
//  Photo.h
//  UICollectionViewExample
//
//  Created by Scott Gardner on 1/3/13.
//  Copyright (c) 2013 Scott Gardner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Photo : NSManagedObject

@property (nonatomic, retain) NSData * imageData;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * rating;

@end
