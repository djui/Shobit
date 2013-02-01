//
//  SBStoreViewController.m
//  Shobit
//
//  Created by Uwe Dauernheim on 1/31/13.
//  Copyright (c) 2013 Uwe Dauernheim. All rights reserved.
//

#import "SBStoreViewController.h"
#import <MapKit/MapKit.h>

@interface SBStoreViewController ()
@property (strong, nonatomic) IBOutlet UIView *storeView;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@end

#define METERS_PER_MILE 1609.344

@implementation SBStoreViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    // View
    [self.storeView setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
    
    // Map view
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    MKCoordinateRegion viewRegion = [self.mapView region];
    NSLog(@"Center: %f,%f", viewRegion.center.latitude, viewRegion.center.longitude);
    NSLog(@"Center: %f,%f", viewRegion.span.latitudeDelta, viewRegion.span.longitudeDelta);
    NSLog(@"Center: %f,%f %f x %f", self.mapView.visibleMapRect.origin.x, self.mapView.visibleMapRect.origin.y, self.mapView.visibleMapRect.size.width, self.mapView.visibleMapRect.size.height);

    // TODO: Download XML
    // curl -o shops.xml -g "http://open.mapquestapi.com/xapi/api/0.6/node[shop=*][bbox=18.05404,59.308895,18.066475,59.315499]"

    // TODO: Create annotations
    // xpath = './node/tag[@k="name"]'
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)forgetStore:(id)sender {
    // TOOD: Implement
    UIActionSheet *deleteShopConfirm = [[UIActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Forget store" otherButtonTitles:nil];
    [deleteShopConfirm showInView:self.storeView];
}

@end
