//
//  SBMapViewController.h
//  Shobit
//
//  Created by Uwe Dauernheim on 1/31/13.
//  Copyright (c) 2013 Uwe Dauernheim. All rights reserved.
//

#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>

@interface SBMapViewController : UIViewController <MKMapViewDelegate>

@property (strong, nonatomic) id detailItem; // Receiver of data from list view

@end
