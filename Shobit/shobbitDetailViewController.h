//
//  shobbitDetailViewController.h
//  Shobit
//
//  Created by Uwe Dauernheim on 1/30/13.
//  Copyright (c) 2013 Uwe Dauernheim. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface shobbitDetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
