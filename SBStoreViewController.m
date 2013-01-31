//
//  SBStoreViewController.m
//  Shobit
//
//  Created by Uwe Dauernheim on 1/31/13.
//  Copyright (c) 2013 Uwe Dauernheim. All rights reserved.
//

#import "SBStoreViewController.h"

@interface SBStoreViewController ()
@property (strong, nonatomic) IBOutlet UIView *storeView;
@property (strong, nonatomic) IBOutlet UIButton *deleteStoreButton;
@end

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
    
    // Delete button
    UIImage *redButtonImage = [UIImage imageNamed:@"button-red.png"];
    [self.deleteStoreButton setBackgroundImage:redButtonImage forState:UIControlStateNormal];
    [self.deleteStoreButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
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
