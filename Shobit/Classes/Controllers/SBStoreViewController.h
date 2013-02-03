//
//  SBStoreViewController.h
//  Shobit
//
//  Created by Uwe Dauernheim on 1/31/13.
//  Copyright (c) 2013 Uwe Dauernheim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface SBStoreViewController : UIViewController <MKMapViewDelegate>

@property (strong, nonatomic) id detailItem; // Receiver of data from list view

@end
