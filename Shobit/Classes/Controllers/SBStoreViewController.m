//
//  SBStoreViewController.m
//  Shobit
//
//  Created by Uwe Dauernheim on 1/31/13.
//  Copyright (c) 2013 Uwe Dauernheim. All rights reserved.
//

#import "SBStoreViewController.h"
#import <MapKit/MapKit.h>
#import "AFKissXMLRequestOperation.h"
#import "DDXML.h"

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
    if (self.hasRecentMapRegion) {
        MKCoordinateRegion region = self.retrieveRecentMapRegion;
        [self.mapView setRegion:region animated:NO];
    }
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    // ...
}

-(void)viewDidAppear:(BOOL)animated {
    [self scanRegionForShops];
}

typedef void (^AFKissXMLRequestSuccessBlock)(NSURLRequest *, NSHTTPURLResponse *, DDXMLDocument *);
typedef void (^AFKissXMLRequestFailureBlock)(NSURLRequest *, NSHTTPURLResponse *, NSError *, DDXMLDocument *);

- (void)scanRegionForShops {
    AFKissXMLRequestSuccessBlock searchShopsSuccess = ^(NSURLRequest *request, NSHTTPURLResponse *response, DDXMLDocument *xmlDoc) {
        // NSLog(@"xmlDoc: %@", xmlDoc);
        
        // Traverse DOM and extract shops
        NSArray *nodes = [xmlDoc.rootElement elementsForName:@"node"];
        for (DDXMLElement *node in nodes) {
            double lat = [node attributeForName:@"lat"].stringValue.doubleValue;
            double lon = [node attributeForName:@"lon"].stringValue.doubleValue;
            NSArray *tags = [node elementsForName:@"tag"];
            for (DDXMLElement *tag in tags) {
                if ([[tag attributeForName:@"k"].stringValue isEqualToString:@"name"]) {
                    NSString *name = [tag attributeForName:@"v"].stringValue;
                    NSLog(@"Shop \"%@\" at: %f,%f", name, lat, lon);
                }
            }
        }
    };
    
    AFKissXMLRequestFailureBlock searchShopsFailure = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, DDXMLDocument *XMLDocument) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    };
    double bottom = self.mapView.region.center.latitude;
    double left = self.mapView.region.center.longitude;
    double top = bottom + self.mapView.region.span.latitudeDelta;
    double right = left + self.mapView.region.span.longitudeDelta;
    NSString *wsURL = [NSString stringWithFormat:@"http://open.mapquestapi.com/xapi/api/0.6/node[shop=*][bbox=%f,%f,%f,%f]", left, bottom, right, top];
    // NSLog(@"%@", wsURL);
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:wsURL]];
    AFKissXMLRequestOperation *operation = [AFKissXMLRequestOperation XMLDocumentRequestOperationWithRequest:request success:searchShopsSuccess failure:searchShopsFailure];
    NSLog(@"Searching for shops...");
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


#pragma mark - Privates

#define RECENTMAPREGIONKEY @"recentMapRegion"

- (Boolean)hasRecentMapRegion {
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

// #define RECENTMAPREGIONKEY @"recentMapRegion"
// #define LATKEY @"lat"
// #define LONKEY @"lon"
// #define LATDELTAKEY @"latDelta"
// #define LONDELTAKEY @"lonDelta"
//
//- (Boolean)hasRecentMapRegion {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    return [defaults boolForKey:RECENTMAPREGIONKEY];
//}
//
//- (MKCoordinateRegion)recentMapRegion {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    MKCoordinateRegion region;
//    region.center.latitude = [defaults doubleForKey:LATKEY];
//    region.center.longitude = [defaults doubleForKey:LONKEY];
//    region.span.latitudeDelta = [defaults doubleForKey:LATDELTAKEY];
//    region.span.longitudeDelta = [defaults doubleForKey:LONDELTAKEY];
//    return region;
//}
//
//- (void)setRecentMapRegion:(MKCoordinateRegion)region {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setDouble:region.center.latitude forKey:LATKEY];
//    [defaults setDouble:region.center.longitude forKey:LONKEY];
//    [defaults setDouble:regionsetDouble:region.span.latitudeDelta forKey:LATDELTAKEY];
//    [defaults setDouble:region.span.longitudeDelta forKey:LONDELTAKEY];
//    [defaults setBool:YES forKey:RECENTMAPREGIONKEY];
//}

// #define RECENTMAPREGIONKEY @"recentMapRegion"
// #define LATKEY @"lat"
// #define LONKEY @"lon"
// #define LATDELTAKEY @"latDelta"
// #define LONDELTAKEY @"lonDelta"
//
//- (Boolean)hasRecentMapRegion {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    return [defaults dictionaryForKey:RECENTMAPREGIONKEY] != nil;
//}
//
//- (MKCoordinateRegion)recentMapRegion {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSDictionary *dict = [defaults dictForKey:RECENTMAPREGIONKEY];
//    MKCoordinateRegion region;
//    region.center.latitude = [[dict objectForKey:LATKEY] doubleValue];
//    region.center.longitude = [[dict objectForKey:LONKEY] doubleValue];
//    region.span.latitudeDelta = [[dict objectForKey:LATDELTAKEY] doubleValue];
//    region.span.longitudeDelta = [[dict objectForKey:LONDELTAKEY] doubleValue];
//    return region;
//}
//
//- (void)setRecentMapRegion:(MKCoordinateRegion)region {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSNumber *lat = [NSNumber numberWithDouble:region.center.latitude];
//    NSNumber *lon = [NSNumber numberWithDouble:region.center.longitude];
//    NSNumber *latDelta = [NSNumber numberWithDouble:region.span.latitudeDelta];
//    NSNumber *lonDelta = [NSNumber numberWithDouble:region.span.longitudeDelta];
//    NSDictionary *region = [NSDictionary dictionaryWithObjectsAndKeys:lat, LATKEY, lon, LONKEY, latDelta, LATDELTAKEY, lonDelta, LONDELTAKEY, nil];
//    [defaults addObject:region ForKey:RECENTMAPREGIONKEY];
//}

@end