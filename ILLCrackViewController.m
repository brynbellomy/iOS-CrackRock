//
//  ILLCrackViewController.m
//  ILLCrack in-app purchase framework
//
//  Created by bryn austin bellomy on 6/19/12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import "ILLCrackViewController.h"

@interface ILLCrackViewController ()

@end

@implementation ILLCrackViewController

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
