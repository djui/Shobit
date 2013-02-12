//
//  SBListViewController.h
//  Shobit
//
//  Created by Uwe Dauernheim on 1/30/13.
//  Copyright (c) 2013 Uwe Dauernheim. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

@interface SBListViewController : UITableViewController <NSFetchedResultsControllerDelegate, CLLocationManagerDelegate, UITextFieldDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
