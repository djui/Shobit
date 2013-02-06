//
//  SBStoreViewController.m
//  Shobit
//
//  Created by Uwe Dauernheim on 1/31/13.
//  Copyright (c) 2013 Uwe Dauernheim. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "SBStoreViewController.h"
#import "SBStoreLocation.h"
#import "AFKissXMLRequestOperation.h"
#import "MBProgressHUD.h"
#import "DDXML.h"
#import "DDTTYLogger.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_WARN;
#endif

@interface SBStoreViewController ()

@property (strong, nonatomic) IBOutlet UIView *storeView;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;

@end


@implementation SBStoreViewController

#pragma mark - Framework generals

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setDetailItem:(id)newDetailItem {
//    if (_detailItem != newDetailItem) {
//        _detailItem = newDetailItem;
    
        // Update the view.
        [self configureView];
//    }
}

- (void)configureView {
    // Update the user interface for the detail item.
    
//    if (self.detailItem) {
//        self.detailDescriptionLabel.text = [[self.detailItem valueForKey:@"timeStamp"] description];
//    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    // View
    [self.storeView setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];

    // Map view
    if (self.hasRecentMapRegion)
        // Reset recent location
        [self.mapView setRegion:self.retrieveRecentMapRegion animated:NO];
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    // ...
}

-(void)viewDidAppear:(BOOL)animated {
    // Scan for shops
    [self scanRegionForShops];
}

typedef void (^AFKissXMLRequestSuccessBlock)(NSURLRequest *, NSHTTPURLResponse *, DDXMLDocument *);
typedef void (^AFKissXMLRequestFailureBlock)(NSURLRequest *, NSHTTPURLResponse *, NSError *, DDXMLDocument *);

- (void)scanRegionForShops {
    AFKissXMLRequestSuccessBlock searchShopsSuccess = ^(NSURLRequest *request, NSHTTPURLResponse *response, DDXMLDocument *xmlDoc) {
        DDLogVerbose(@"xmlDoc: %@", xmlDoc);
        
        // Clean up map annotations
        for (id<MKAnnotation> annotation in self.mapView.annotations) {
            [self.mapView removeAnnotation:annotation];
        }
        
        // Traverse DOM and extract shops
        NSArray *nodes = [xmlDoc.rootElement elementsForName:@"node"];
        int amountShops = 0;
        for (DDXMLElement *node in nodes) {
            double storeLatitude = [node attributeForName:@"lat"].stringValue.doubleValue;
            double storeLongitude = [node attributeForName:@"lon"].stringValue.doubleValue;
            NSArray *tags = [node elementsForName:@"tag"];
            for (DDXMLElement *tag in tags) {
                if ([[tag attributeForName:@"k"].stringValue isEqualToString:@"name"]) {
                    NSString *storeName = [tag attributeForName:@"v"].stringValue;
                    DDLogVerbose(@"Store \"%@\" at: %f,%f", storeName, storeLatitude, storeLongitude);
                    amountShops++;
                    
                    // Add map annotations
                    CLLocationCoordinate2D storeCoordinate;
                    storeCoordinate.latitude = storeLatitude;
                    storeCoordinate.longitude = storeLongitude;                    
                    StoreLocation *annotation = [[StoreLocation alloc] initWithName:storeName address:nil coordinate:storeCoordinate];
                    [self.mapView addAnnotation:annotation];
                }
            }
        }
        
        DDLogInfo(@"Found %d shops.", amountShops);
    };
    
    AFKissXMLRequestFailureBlock searchShopsFailure = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, DDXMLDocument *XMLDocument) {
        DDLogError(@"%@", error);
        DDLogWarn(@"Could not search for shops");
        // Progress HUD
        MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:HUD];
        HUD.mode = MBProgressHUDModeCustomView;
        HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUDFailure.png"]];
        HUD.labelText = @"Can't find stores";
        [HUD showAnimated:YES whileExecutingBlock:^{
            sleep(3);
        }];
    };
    double bottom = self.mapView.region.center.latitude - self.mapView.region.span.latitudeDelta;
    double left = self.mapView.region.center.longitude - self.mapView.region.span.longitudeDelta;
    double top = self.mapView.region.center.latitude + self.mapView.region.span.latitudeDelta;
    double right = self.mapView.region.center.longitude + self.mapView.region.span.longitudeDelta;
    NSString *wsURL = [NSString stringWithFormat:@"http://open.mapquestapi.com/xapi/api/0.6/node[shop=*][bbox=%f,%f,%f,%f]", left, bottom, right, top];
    DDLogVerbose(@"%@", wsURL);
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:wsURL]];
    AFKissXMLRequestOperation *operation = [AFKissXMLRequestOperation XMLDocumentRequestOperationWithRequest:request success:searchShopsSuccess failure:searchShopsFailure];
    DDLogInfo(@"Searching for shops...");
    [operation start];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    [self storeRecentMapRegion:self.mapView.region];
}

#pragma mark - IBActions

- (IBAction)forgetStore:(id)sender {
    // TOOD: Implement
    UIActionSheet *deleteShopConfirm = [[UIActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Forget store" otherButtonTitles:nil];
    [deleteShopConfirm showInView:self.storeView];
}

#pragma mark - Map view

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *identifier = @"StoreLocation";
    if ([annotation isKindOfClass:[StoreLocation class]]) {
        MKAnnotationView *annotationView = (MKAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            [annotationView setEnabled:YES];
            [annotationView setCanShowCallout:YES];
        } else {
            annotationView.annotation = annotation;
        }
        
        return annotationView;
    }
    
    return nil;
}

#pragma mark - Privates

#define RECENTMAPREGIONKEY @"recentMapRegion"

- (BOOL)hasRecentMapRegion {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [defaults dataForKey:RECENTMAPREGIONKEY];
    if (data == nil) return NO;
    else return YES;
}

- (MKCoordinateRegion)retrieveRecentMapRegion {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [defaults dataForKey:RECENTMAPREGIONKEY];
    MKCoordinateRegion region;
    [data getBytes:&region length:sizeof(region)];
    return region;
}

- (void)storeRecentMapRegion:(MKCoordinateRegion)region {
    NSData *data = [NSData dataWithBytes:&region length:sizeof(region)];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:data forKey:RECENTMAPREGIONKEY];
}

@end