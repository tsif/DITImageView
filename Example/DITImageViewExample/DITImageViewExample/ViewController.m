//
//  ViewController.m
//  DITImageViewExample
//
//  Created by Dimitris Tsiflitzis on 6/16/14.
//  Copyright (c) 2014 sprimp. All rights reserved.
//


#import "DITImageView.h"
#import "ViewController.h"

@interface ViewController ()

@property(nonatomic, strong) IBOutlet DITImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.imageView.customProgress = YES;
    self.imageView.url            = @"http://i.imgur.com/1YQ4cy3.jpg";
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
