//
//  SBMapViewController.m
//  Shobit
//
//  Created by Uwe Dauernheim on 1/31/13.
//  Copyright (c) 2013 Uwe Dauernheim. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "AFKissXMLRequestOperation.h"
#import "DDTTYLogger.h"
#import "DDXML.h"
#import "MBProgressHUD.h"
#import "SBMapViewController.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_WARN;
#endif

// TODO: Add credit - http://www.openstreetmap.org/copyright
static NSString *OSM_API_URL0 = @"http://djui.de/shobit/api/xapi?node[shop=*][bbox=%f,%f,%f,%f]";
static NSString *OSM_API_URL1 = @"http://www.overpass-api.de/api/xapi?node[shop=*][bbox=%f,%f,%f,%f]";
static NSString *OSM_API_URL2 = @"http://overpass.osm.rambler.ru/cgi/xapi?node[shop=*][bbox=%f,%f,%f,%f]";
static NSString *OSM_API_URL3 = @"http://open.mapquestapi.com/xapi/api/0.6/node[shop=*][bbox=%f,%f,%f,%f]";

@interface SBMapViewController ()

@property (readonly) NSString *OSM_API_URL1;
@property (strong, nonatomic) IBOutlet UIView *shopView;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation SBMapViewController

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
  
  //    if (_detailItem) {
  //        _detailDescriptionLabel.text = [[_detailItem valueForKey:@"timeStamp"] description];
  //    }
}

- (void)viewDidLoad {
  [super viewDidLoad];
	// Do any additional setup after loading the view.
  
  // View
  [_shopView setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
  
  // Map view
  if ([self hasRecentMapRegion])
    // Reset recent location
    [_mapView setRegion:[self retrieveRecentMapRegion] animated:NO];
  [_mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
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
typedef void (^EnumerationBlock)(id, NSUInteger, BOOL *);

- (void)scanRegionForShops {
  AFKissXMLRequestSuccessBlock searchShopsSuccess = ^(NSURLRequest *request, NSHTTPURLResponse *response, DDXMLDocument *xmlDoc) {
    DDLogVerbose(@"xmlDoc: %@", xmlDoc);
    
    // Clean up map annotations
    EnumerationBlock cleanupAnnotations = ^(id<MKAnnotation> annotation, NSUInteger idx, BOOL *stop) {
      // Skip current location annotation
      if (![annotation isKindOfClass:[MKUserLocation class]])
        [_mapView removeAnnotation:annotation];
    };
    [_mapView.annotations enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:cleanupAnnotations];
    
    // Traverse DOM and extract shops
    NSArray *nodes = [xmlDoc.rootElement elementsForName:@"node"];
    NSUInteger amountShops = 0;
    for (DDXMLElement *node in nodes) {
      double shopLatitude = [node attributeForName:@"lat"].stringValue.doubleValue;
      double shopLongitude = [node attributeForName:@"lon"].stringValue.doubleValue;
      NSArray *tags = [node elementsForName:@"tag"];
      for (DDXMLElement *tag in tags) {
        if ([[tag attributeForName:@"k"].stringValue isEqualToString:@"name"]) {
          NSString *shopName = [tag attributeForName:@"v"].stringValue;
          DDLogVerbose(@"shop \"%@\" at: %f,%f", shopName, shopLatitude, shopLongitude);
          amountShops++;
          
          // Add map annotations
          CLLocationCoordinate2D shopCoordinate = CLLocationCoordinate2DMake(shopLatitude, shopLongitude);
          MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
          [annotation setCoordinate:shopCoordinate];
          [annotation setTitle:shopName];
          [_mapView addAnnotation:annotation];
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
    HUD.labelText = @"Can't find shops";
    [HUD showAnimated:YES whileExecutingBlock:^{
      sleep(3);
    }];
  };
  
  // TODO: Fix "wrap-around"
  double bottom = _mapView.region.center.latitude - _mapView.region.span.latitudeDelta;
  double left = _mapView.region.center.longitude - _mapView.region.span.longitudeDelta;
  double top = _mapView.region.center.latitude + _mapView.region.span.latitudeDelta;
  double right = _mapView.region.center.longitude + _mapView.region.span.longitudeDelta;
  
  NSString *wsURL = [NSString stringWithFormat:OSM_API_URL1, left, bottom, right, top];
  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:wsURL]];
  AFKissXMLRequestOperation *operation = [AFKissXMLRequestOperation XMLDocumentRequestOperationWithRequest:request success:searchShopsSuccess failure:searchShopsFailure];
  
  DDLogInfo(@"Searching for shops: %@", wsURL);
  [operation start];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
  [self shopRecentMapRegion:_mapView.region];
}

#pragma mark - IBActions

- (IBAction)forgetshop:(id)sender {
  // TOOD: Implement
  UIActionSheet *deleteShopConfirm = [[UIActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Forget shop" otherButtonTitles:nil];
  [deleteShopConfirm showInView:_shopView];
}

#pragma mark - Map view

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
  static NSString *identifier = @"ShopLocation";
  MKAnnotationView *annotationView = (MKAnnotationView *)[_mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
  if (annotationView == nil) {
    annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
    [annotationView setEnabled:YES];
    [annotationView setCanShowCallout:YES];
  } else {
    annotationView.annotation = annotation;
  }
  
  return annotationView;
  
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

- (void)shopRecentMapRegion:(MKCoordinateRegion)region {
  NSData *data = [NSData dataWithBytes:&region length:sizeof(region)];
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:data forKey:RECENTMAPREGIONKEY];
}

@end