//
//  SBShopDatabase.m
//  Shobit
//
//  Created by Uwe Dauernheim on 2/8/13.
//  Copyright (c) 2013 Uwe Dauernheim. All rights reserved.
//

#import <sqlite3.h>
#import "DDTTYLogger.h"
#import "AMLineInputStream.h"
#import "SBShopDatabase.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_WARN;
#endif

static NSString *tableName = @"nodes";

@interface SBShopDatabase ()
@property (nonatomic, readonly, nonatomic) sqlite3 *dbHandle;
@property (nonatomic, readonly, nonatomic) AMLineInputStream *lineReader;
@end

@implementation SBShopDatabase

- (id)init:(NSURL *)databaseUrl {
  if (self = [super init]) {
    [self openDatabase:databaseUrl];
  }
  
  return self;
}

- (BOOL)openDatabase:(NSURL *)databaseUrl {
  if ([databaseUrl checkResourceIsReachableAndReturnError:nil]) {
    DDLogVerbose(@"Database file exists: %@", databaseUrl);
    
    // TODO: Check if really populated. Otherwise delete and rerun (BOOL)initialization
    
    if (sqlite3_open([[databaseUrl path] UTF8String], &_dbHandle) != SQLITE_OK) {
      DDLogError(@"Failed to open database: %s", sqlite3_errmsg(_dbHandle));
      return NO;
    }
    
    return YES;
  }
  
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSError *error = nil;
  [fileManager createDirectoryAtURL:[databaseUrl URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
  if (error) {
    DDLogError(@"%@", error);
    return NO;
  }
  
  if (sqlite3_open([[databaseUrl path] UTF8String], &_dbHandle) != SQLITE_OK) {
    DDLogError(@"Failed to open database: %s", sqlite3_errmsg(_dbHandle));
    return NO;
  }
  
  NSString *createSQL = [NSString stringWithFormat:@"CREATE TABLE %@ (latitude real, longitude real, id integer, name text)", tableName];
  char *errMsg;
  DDLogVerbose(@"Creating database file");
  if (sqlite3_exec(_dbHandle, [createSQL UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
    DDLogError(@"Failed to create table: %s", sqlite3_errmsg(_dbHandle));
    return NO;
  }
  
  error = nil;
  [databaseUrl setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&error];
  if (error) {
    DDLogError(@"%@", error);
    return NO;
  } else {
    DDLogVerbose(@"Database file excluded from backup");
  }
  
  return YES;
}

- (void)importCSV:(NSURL *)csvFileURL {
  _lineReader = [[AMLineInputStream alloc] init];
  [_lineReader processFile:csvFileURL withEncoding:NSUTF8StringEncoding usingBlock:^(NSString *line, NSError *error)  {
    if (error) {
      DDLogError(@"%@", error);
    } else {
      // DDLogInfo(@"line: %@", line);
      // Split'n'glue... ugly, but regex overkill and tokenizer slower
      NSArray *components = [line componentsSeparatedByString:@","];
      if (components.count < 4)
        // Invalid line
        return;
      
      double latitude = [[components objectAtIndex:0] doubleValue];
      double longitude = [[components objectAtIndex:1] doubleValue];
      int id = [[components objectAtIndex:2] intValue];
      NSString *name = [[components objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(3, [components count]-3)]] componentsJoinedByString:@","];
      CLLocationCoordinate2D location = CLLocationCoordinate2DMake(latitude, longitude);
      
      [self insertNodeWithLocation:location id:id name:name];
    }
  }];
}

- (BOOL)insertNodeWithLocation:(CLLocationCoordinate2D)location id:(int)id name:(NSString *)name {
  NSString *insertSQL = [NSString stringWithFormat:@"INSERT INTO %@ VALUES (?, ?, ?, ?)", tableName];
  sqlite3_stmt *statement;
  
  if (sqlite3_prepare_v2(_dbHandle, [insertSQL UTF8String], -1, &statement, NULL) != SQLITE_OK) {
    DDLogError(@"Failed to insert shop to database: %s", sqlite3_errmsg(_dbHandle));
    return NO;
  }

  sqlite3_bind_double(statement, 1, location.latitude);
  sqlite3_bind_double(statement, 2, location.longitude);
  sqlite3_bind_int(statement, 3, id);
  sqlite3_bind_text(statement, 4, [name UTF8String], -1, SQLITE_TRANSIENT);
  if (sqlite3_step(statement) != SQLITE_DONE) {
    DDLogError(@"Failed to insert shop to database: %s", sqlite3_errmsg(_dbHandle));
    return NO;
  }
  
  sqlite3_finalize(statement);
  return YES;
}

- (NSArray *)nodesInRegion:(MKCoordinateRegion)region {
  double bottom = region.center.latitude - region.span.latitudeDelta;
  double left = region.center.longitude - region.span.longitudeDelta;
  double top = region.center.latitude + region.span.latitudeDelta;
  double right = region.center.longitude + region.span.longitudeDelta;
  
  NSString *querySQL = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ? AND longitude NOT BETWEEN ? AND ?", tableName];
  sqlite3_stmt *statement;
  
  if (sqlite3_prepare_v2(_dbHandle, [querySQL UTF8String], -1, &statement, NULL) != SQLITE_OK) {
    DDLogError(@"Failed to read shops from database: %s", sqlite3_errmsg(_dbHandle));
    return nil;
  }

  sqlite3_bind_double(statement, 1, bottom);
  sqlite3_bind_double(statement, 2, top);
  sqlite3_bind_double(statement, 3, left);
  sqlite3_bind_double(statement, 4, right);
  sqlite3_bind_double(statement, 5, right);
  sqlite3_bind_double(statement, 6, left);
  NSMutableArray *nodes = [@[] mutableCopy];
  while (sqlite3_step(statement) == SQLITE_ROW) {
    double latitude = (double)sqlite3_column_double(statement, 0);
    double longitude = (double)sqlite3_column_double(statement, 1);
    NSNumber *id = [[NSNumber alloc] initWithInt:sqlite3_column_int(statement, 2)];
    NSString *name = [[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 3)];
    
    sqlite3_finalize(statement);
    
    CLLocationCoordinate2D location = CLLocationCoordinate2DMake(latitude, longitude);
    NSDictionary *node = @{@"location":[NSValue valueWithMKCoordinate:location], @"id":id, @"name":name};
    
    [nodes addObject:node];
  }
  
  return nodes;
}

- (void)finalize {
  if (sqlite3_close(_dbHandle != SQLITE_OK)) {
    DDLogError(@"Could not close database: %s", sqlite3_errmsg(_dbHandle));
  };
}

@end
