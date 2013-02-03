//
//  SBStoreLocation.h
//  Shobit
//
//  Created by Uwe Dauernheim on 2/3/13.
//  Copyright (c) 2013 Uwe Dauernheim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface StoreLocation : NSObject <MKAnnotation>

- (id)initWithName:(NSString*)name address:(NSString*)address coordinate:(CLLocationCoordinate2D)coordinate;
- (MKMapItem*)mapItem;

@end
