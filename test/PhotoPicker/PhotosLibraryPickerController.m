//
//  PhotosLibraryPickerController.m
//  test
//
//  Created by Gabriela Dobrovat on 21/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "PhotosLibraryPickerController.h"
#import "UIViewController+PSANotificationNavigatable.h"

@implementation PhotosLibraryPickerController

- (BOOL)hasNonPersistentInputData {
    return self.selectedAssets.count != 0;
}

@end
