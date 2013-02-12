//
//  SBShopDatabase.h
//  Shobit
//
//  Created by Uwe Dauernheim on 2/8/13.
//  Copyright (c) 2013 Uwe Dauernheim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface SBShopDatabase : NSObject
- (id)init:(NSURL *)databaseUrl;
- (void)importCSV:(NSURL *)csvUrl;
- (NSArray *)nodesInRegion:(MKCoordinateRegion)region;
@end
