//
//  ViewController.m
//  test
//
//  Created by Gabriela Dobrovat on 15/03/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapDeblurButton)];
    [self.button setUserInteractionEnabled:YES];
    [self.button addGestureRecognizer:tapGesture];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.image.image = [UIImage imageNamed:@"blurredImage"];
}

- (void)didTapDeblurButton {
    
}

@end
