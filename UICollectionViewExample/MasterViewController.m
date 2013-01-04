//
//  MasterViewController.m
//  UICollectionViewExample
//
//  Created by Scott Gardner on 1/3/13.
//  Copyright (c) 2013 Scott Gardner. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "CollectionViewCell.h"
#import "Photo.h"

@interface MasterViewController ()
@property (nonatomic, strong) NSMutableArray *sectionChanges;
@property (nonatomic, strong) NSMutableArray *objectChanges;
@end

@implementation MasterViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Popular on 500px";
    
    // Queue changes to be made to the collection view
    self.sectionChanges = [NSMutableArray new];
    self.objectChanges = [NSMutableArray new];
    
    [PXRequest setConsumerKey:@"___" consumerSecret:@"___"];
    /*
     There are two ways to use this library. The first is to use the PXAPIHelper class methods to generate NSURLRequest objects to use directly (either with NSURLConnection or ASIHTTPRequest. The other way is to use the built-in PXRequest class methods to create requests against the 500px API; they provide a completion block that is executed after the request returns, and they also post notifications to the default NSNotificationCenter.
     */
    [PXRequest requestForPhotoFeature:PXAPIHelperPhotoFeaturePopular completion:^(NSDictionary *results, NSError *error) {
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Couldn't fetch from 500px" message:error.localizedDescription delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
            return;
        }
        
        NSArray *photosArray = [results valueForKey:@"photos"];
        
        [photosArray enumerateObjectsUsingBlock:^(NSDictionary *photosDictionary, NSUInteger idx, BOOL *stop) {
            Photo *photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:self.managedObjectContext];
            photo.rating = photosDictionary[@"rating"];
            photo.name = photosDictionary[@"name"];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                NSString *urlString = photosDictionary[@"images"][0][@"url"];
                NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    photo.imageData = imageData;
                });
            });
        }];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowPhoto"]) {
        NSIndexPath *indexPath = [[self.collectionView indexPathsForSelectedItems] lastObject];
        Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [segue.destinationViewController setPhoto:photo];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CollectionViewCell *cell = (CollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"CollectionViewCell" forIndexPath:indexPath];
    Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.imageView.image = [UIImage imageWithData:photo.imageData];
    return cell;
}

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) return _fetchedResultsController;    
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Photo" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"AllPhotos"];
    aFetchedResultsController.delegate = self;
    _fetchedResultsController = aFetchedResultsController;
	NSError *error;
    
	if (![_fetchedResultsController performFetch:&error]) {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}    

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    NSMutableDictionary *change = [NSMutableDictionary new];
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = @(sectionIndex);
            break;
            
        case NSFetchedResultsChangeDelete:
            change[@(type)] = @(sectionIndex);
            break;
    }
    
    [self.sectionChanges addObject:change];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    NSMutableDictionary *change = [NSMutableDictionary new];
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = newIndexPath;
            break;
            
        case NSFetchedResultsChangeDelete:
            change[@(type)] = indexPath;
            break;
            
        case NSFetchedResultsChangeUpdate:
            change[@(type)] = indexPath;
            break;
            
        case NSFetchedResultsChangeMove:
            change[@(type)] = @[indexPath, newIndexPath];
            break;
    }
    
    [self.objectChanges addObject:change];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // Batch process the queued changes to be made to the collection view
    
    if ([self.sectionChanges count]) {
        [self.collectionView performBatchUpdates:^{
            [self.sectionChanges enumerateObjectsUsingBlock:^(NSDictionary *changes, NSUInteger idx, BOOL *stop) {
                [changes enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, NSNumber *index, BOOL *stop) {
                    
                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                    NSUInteger sectionIndex = [index unsignedIntegerValue];
                    
                    switch (type) {
                        case NSFetchedResultsChangeInsert:
                            [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
                            break;
                            
                        case NSFetchedResultsChangeDelete:
                            [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
                            break;
                            
                        case NSFetchedResultsChangeUpdate:
                            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
                            break;
                            
                        default:
                            break;
                    }
                }];
            }];
        } completion:nil];
    } else if ([self.objectChanges count]) { // No section changes
        [self.collectionView performBatchUpdates:^{
            [self.objectChanges enumerateObjectsUsingBlock:^(NSDictionary *changes, NSUInteger idx, BOOL *stop) {
                [changes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                    // obj is either an NSIndexPath or an array of two NSIndexPath's
                    
                    switch (type) {
                        case NSFetchedResultsChangeInsert:
                            [self.collectionView insertItemsAtIndexPaths:@[obj]];
                            break;
                            
                        case NSFetchedResultsChangeDelete:
                            [self.collectionView deleteItemsAtIndexPaths:@[obj]];
                            break;
                            
                        case NSFetchedResultsChangeUpdate:
                            [self.collectionView reloadItemsAtIndexPaths:@[obj]];
                            break;
                            
                        case NSFetchedResultsChangeMove:
                            [self.collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                            break;
                            
                        default:
                            break;
                    }
                }];
            }];
        } completion:nil];
    }
    
    [self.sectionChanges removeAllObjects];
    [self.objectChanges removeAllObjects];
}

@end
