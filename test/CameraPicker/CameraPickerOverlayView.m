//
//  CameraPickerOverlayView.m
//  test
//
//  Created by Gabriela Dobrovat on 18/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//
#import "CameraPickerOverlayView.h"

#import "CameraButton.h"
#import "CameraPickerAppearance.h"
#import "CameraPickerFlashHeaderView.h"
#import "CameraPickerPhotoResizeHeaderView.h"
#import "CameraPickerResourceLoader.h"

@interface CameraPickerOverlayView()<CameraPickerUnfoldableOptionsViewDelegate,
CameraPickerFlashHeaderViewDelegate,
CameraPickerPhotoResizeHeaderViewDelegate>

// Pre Capture Container
@property (weak, nonatomic) UIView *preCaptureContainer;
@property (weak, nonatomic) CameraButton *captureButton;
@property (weak, nonatomic) UIImageView *imageView;
@property (weak, nonatomic) UIButton *switchCameraButton;
@property (weak, nonatomic) UIButton *photoButton;
@property (weak, nonatomic) UIButton *cancelButton;
@property (weak, nonatomic) CameraPickerFlashHeaderView *flashHeaderView;
@property (weak, nonatomic) CameraPickerPhotoResizeHeaderView *photoResizeHeaderView;
@property (strong, nonatomic) NSLayoutConstraint *photoButtonCenterX;

// Post Capture Container
@property (weak, nonatomic) UIView *postCaptureContainer;
@property (weak, nonatomic) UIButton *retakeButton;
@property (weak, nonatomic) UIButton *doneButton;
@property (weak, nonatomic) UIButton *setPhotoSizeButton;
@property (weak, nonatomic) UIButton *editPhotoButton;

@end

@implementation CameraPickerOverlayView

- (instancetype)init {
    
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.cameraPosition = CameraDevicePositionFront;
    self.backgroundColor = [CameraPickerAppearance colorForTransparentBackground];
}

#pragma mark - Public API

- (void)setInteractionWithUIEnabled:(BOOL)interactionWithUIEnabled {
    _interactionWithUIEnabled = interactionWithUIEnabled;
    [self setupUIForInteractionEnabled:interactionWithUIEnabled];
}

- (void)setCameraPosition:(CameraDevicePosition)cameraPosition {
    _cameraPosition = cameraPosition;
    [self setSwithCameraButtonImageForDevicePosition:cameraPosition];
}

- (void)setSwitchCameraButtonAvailable:(BOOL)switchCameraButtonAvailable {
    _switchCameraButtonAvailable = switchCameraButtonAvailable;
    [self setupUIForSwitchCameraAvailable:switchCameraButtonAvailable];
}

- (void)setFlashAvailable:(BOOL)flashAvailable {
    _flashAvailable = flashAvailable;
    [self setupUIForFlashAvailable:flashAvailable];
}

- (void)setFlashMode:(CameraFlashMode)flashMode {
    _flashMode = flashMode;
    self.flashHeaderView.flashMode = flashMode;
}

- (void)setAvailableFlashModes:(NSArray<NSNumber *> *)availableFlashModes {
    _availableFlashModes = availableFlashModes;
    self.flashHeaderView.availableFlashModes = availableFlashModes;
}

- (void)setAllowsPhotoEditing:(BOOL)allowsPhotoEditing {
    
    _allowsPhotoEditing = allowsPhotoEditing;
    
    if (_allowsPhotoEditing) {
        _editPhotoButton.alpha = 1.0f;
    } else {
        _editPhotoButton.alpha = 0.0f;
    }
}

- (void)setCaptureMode:(CameraPickerCaptureMode)captureMode {
    _captureMode = captureMode;
    [self prepareButtonsForCaptureMode:captureMode];
}

- (void)setAvailableCaptureModes:(NSArray<NSNumber *> *)availableCaptureModes {
    _availableCaptureModes = availableCaptureModes;
    [self setupUIForAvailableCaptureModes:availableCaptureModes];
}

- (void)prepareForPreCaptureState {
    
    [self clearSubviews];
    [self setupPreCaptureContainer];
    
    // We need to know the frame of the Photo button to highlight it (set its corner radius) correctly
    [self layoutIfNeeded];
    [self prepareButtonsForCaptureMode:self.captureMode];
}

- (void)prepareForCapturedPhotoState:(UIImage *)previewImage {
    
    self.captureMode = CameraPickerCaptureModePhoto;
    [self prepareForCapturedStateWithImage:previewImage];
}

- (void)prepareForCapturedStateWithImage:(UIImage *)previewImage {
    
    [self clearSubviews];
    [self setupPostCaptureContainer];
    self.imageView.image = previewImage;
}

- (void)updateCapturedPhoto:(UIImage *)capturedPhoto
                   withSize:(CameraPickerPhotoSize)photoSize {
    
    [UIView animateWithDuration:[CameraPickerAppearance photoChangeAnimationDuration] animations:^{
        self.imageView.image = capturedPhoto;
    }];
}

- (void)prepareForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    
    [UIView animateWithDuration:[CameraPickerAppearance defaultAnimationDuration] animations:^{
        
        [self.flashHeaderView prepareForDeviceOrientation:deviceOrientation];
        [self.photoResizeHeaderView prepareForDeviceOrientation:deviceOrientation];
        
        switch (deviceOrientation) {
                
            case UIDeviceOrientationLandscapeLeft:
                self.switchCameraButton.transform = CGAffineTransformMakeRotation(M_PI_2);
                break;
            case UIDeviceOrientationLandscapeRight:
                self.switchCameraButton.transform = CGAffineTransformMakeRotation(-M_PI_2);
                break;
            default:
                self.switchCameraButton.transform = CGAffineTransformIdentity;
                break;
        }
    }];
}

#pragma mark - CameraPickerFlashHeaderViewDelegate

- (void)flashHeaderView:(CameraPickerFlashHeaderView *)flashHeaderView
     didChangeFlashMode:(CameraFlashMode)flashMode {
    
    [self.delegate cameraOverlayView:self didChangeCameraFlashMode:flashMode];
}

#pragma mark - CameraPickerPhotoResizeHeaderView;

- (void)photoSizeHeaderView:(CameraPickerPhotoResizeHeaderView *)flashHeaderView
         didChangePhotoSize:(CameraPickerPhotoSize)photoSize {
    
    [self.delegate cameraOverlayView:self didChangePhotoSize:photoSize];
}


#pragma mark - Helpers

- (void)setupFlashHeader {
    
    if (self.preCaptureContainer) {
        
        CameraPickerFlashHeaderView *flashHeaderView = [[CameraPickerFlashHeaderView alloc] init];
        self.flashHeaderView = flashHeaderView;
        flashHeaderView.delegate = self;
        flashHeaderView.foldingDelegate = self;
        flashHeaderView.availableFlashModes = self.availableFlashModes;
        flashHeaderView.translatesAutoresizingMaskIntoConstraints = NO;
        
    
        [self.preCaptureContainer addSubview:flashHeaderView];
    
        NSLayoutConstraint *flashHeaderViewLeading = [flashHeaderView.leadingAnchor constraintEqualToAnchor:flashHeaderView.superview.leadingAnchor];
        NSLayoutConstraint *flashHeaderViewTrailing = [flashHeaderView.trailingAnchor constraintEqualToAnchor:flashHeaderView.superview.trailingAnchor];
        NSLayoutConstraint *flashHeaderViewTop = [flashHeaderView.topAnchor constraintEqualToAnchor:flashHeaderView.superview.topAnchor];
        [NSLayoutConstraint activateConstraints:@[flashHeaderViewLeading, flashHeaderViewTrailing, flashHeaderViewTop]];
        [self.flashHeaderView activateDefaultHeightConstraint:YES];
    }
}

- (void)setupPreCaptureContainer {
    
    // Pre Capture Container view
    UIView *preCaptureContainer = [[UIView alloc] init];
    self.preCaptureContainer = preCaptureContainer;
    preCaptureContainer.backgroundColor = [CameraPickerAppearance colorForTransparentBackground];
    preCaptureContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.preCaptureContainer];
    NSLayoutConstraint *preCaptureContainerLeading = [preCaptureContainer.leadingAnchor constraintEqualToAnchor:preCaptureContainer.superview.leadingAnchor];
    NSLayoutConstraint *preCaptureContainerTrailing = [preCaptureContainer.trailingAnchor constraintEqualToAnchor:preCaptureContainer.superview.trailingAnchor];
    NSLayoutConstraint *preCaptureContainerBottom;
    NSLayoutConstraint *preCaptureContainerTop;
    
    if (@available(iOS 11, *)) {
        
        preCaptureContainerBottom = [preCaptureContainer.bottomAnchor constraintEqualToAnchor:preCaptureContainer.superview.safeAreaLayoutGuide.bottomAnchor];
        preCaptureContainerTop = [preCaptureContainer.topAnchor constraintEqualToAnchor:preCaptureContainer.superview.safeAreaLayoutGuide.topAnchor];
        
    } else {
        
        preCaptureContainerBottom = [preCaptureContainer.bottomAnchor constraintEqualToAnchor:preCaptureContainer.superview.bottomAnchor];
        preCaptureContainerTop = [preCaptureContainer.topAnchor constraintEqualToAnchor:preCaptureContainer.superview.topAnchor];
    }
    
    [NSLayoutConstraint activateConstraints:@[preCaptureContainerLeading, preCaptureContainerTrailing, preCaptureContainerBottom, preCaptureContainerTop]];
    
    // Cancel button
    UIButton *cancelButton = [[UIButton alloc] init];
    self.cancelButton = cancelButton;
    [cancelButton setTitle:[CameraPickerResourceLoader localizedStringWithName:@"lCancel"] forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(didTapCancelButton) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Take photo
    CameraButton *cameraButton = [[CameraButton alloc] init];
    cameraButton.style = CameraButtonStylePhotoCapture;
    
    [cameraButton addTarget:self action:@selector(didTapCaptureButton) forControlEvents:UIControlEventTouchUpInside];
    self.captureButton = cameraButton;
    cameraButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Switch camera
    UIButton *switchCameraButton = [[UIButton alloc] init];
    self.switchCameraButton = switchCameraButton;
    switchCameraButton.clipsToBounds = YES;
    switchCameraButton.backgroundColor = [CameraPickerAppearance colorForSemiTransparentButtonBackground];
    [switchCameraButton addTarget:self action:@selector(didTapSwitchCameraButton) forControlEvents:UIControlEventTouchUpInside];
    [self setSwithCameraButtonImageForDevicePosition:self.cameraPosition];
    switchCameraButton.layer.cornerRadius = 20.0f;
    switchCameraButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self setupUIForSwitchCameraAvailable:self.isSwitchCameraButtonAvailable];
    
    CGFloat photoButtonsFontSize = 13.0f;
    
    // Photo button
    UIButton *photoButton = [[UIButton alloc] init];
    self.photoButton = photoButton;
    NSString *photoButtonTitle = [[CameraPickerResourceLoader localizedStringWithName:@"lCameraPickerCaptureModePhoto"] uppercaseString];
    [photoButton addTarget:self action:@selector(didTapPhotoButton) forControlEvents:UIControlEventTouchUpInside];
    [photoButton setTitle:photoButtonTitle forState:UIControlStateNormal];
    photoButton.titleLabel.font = [UIFont systemFontOfSize:photoButtonsFontSize];
    photoButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self setupUIForAvailableCaptureModes:self.availableCaptureModes];
    [self setupUIForFlashAvailable:self.isFlashAvailable];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self setupPreCaptureContainerLayoutForiPad];
    } else {
        [self setupPreCaptureContainerLayoutForiPhone];
    }
    
    // Header
    if (self.isFlashAvailable && !self.flashHeaderView) {
        [self setupFlashHeader];
    }
}

- (void)setupPreCaptureContainerLayoutForiPad {
    
    UIView *sideView = [[UIView alloc] init];
    sideView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.preCaptureContainer addSubview:sideView];
    NSLayoutConstraint *sideViewTrailing = [sideView.trailingAnchor constraintEqualToAnchor:sideView.superview.trailingAnchor];
    sideViewTrailing.constant = -[CameraPickerAppearance defaultHorizontalMargin];
    NSLayoutConstraint *sideViewTop = [sideView.topAnchor constraintEqualToAnchor:sideView.superview.topAnchor];
    NSLayoutConstraint *sideViewBottom = [sideView.bottomAnchor constraintEqualToAnchor:sideView.superview.bottomAnchor];
    sideViewBottom.constant = -[CameraPickerAppearance defaultVerticalMargin];
    NSLayoutConstraint *sideViewWidth = [sideView.widthAnchor constraintEqualToConstant:70.0];
    
    // Cancel button
    [sideView addSubview:self.cancelButton];
    NSLayoutConstraint *cancelButtonBottom = [self.cancelButton.bottomAnchor constraintEqualToAnchor:self.cancelButton.superview.bottomAnchor];
    NSLayoutConstraint *cancelButtonLeading = [self.cancelButton.leadingAnchor constraintEqualToAnchor:self.cancelButton.superview.leadingAnchor];
    NSLayoutConstraint *cancelButtonTrailing = [self.cancelButton.trailingAnchor constraintEqualToAnchor:self.cancelButton.superview.trailingAnchor];
    
    // Take photo button
    [sideView addSubview:self.captureButton];
    NSLayoutConstraint *cameraButtonCenterY = [self.captureButton.centerYAnchor constraintEqualToAnchor:self.captureButton.superview.centerYAnchor];
    NSLayoutConstraint *cameraButtonCenterX = [self.captureButton.centerXAnchor constraintEqualToAnchor:self.captureButton.superview.centerXAnchor];
    
    // Switch camera
    [sideView addSubview:self.switchCameraButton];
    NSLayoutConstraint *switchCameraButtonBottom = [self.switchCameraButton.bottomAnchor constraintEqualToAnchor:self.captureButton.topAnchor];
    switchCameraButtonBottom.constant = -80.0f;
    NSLayoutConstraint *switchCameraButtonWidth = [self.switchCameraButton.widthAnchor constraintEqualToConstant:[CameraPickerAppearance defaultButtonSize].width];
    NSLayoutConstraint *switchCameraButtonHeight = [self.switchCameraButton.heightAnchor constraintEqualToConstant:[CameraPickerAppearance defaultButtonSize].height];
    NSLayoutConstraint *switchCameraButtonCenterX = [self.switchCameraButton.centerXAnchor constraintEqualToAnchor:self.captureButton.centerXAnchor];
    
    // Photo button
    [sideView addSubview:self.photoButton];
    NSLayoutConstraint *photoButtonTop = [self.photoButton.topAnchor constraintEqualToAnchor:self.captureButton.bottomAnchor];
    photoButtonTop.constant = 120.0f;
    NSLayoutConstraint *photoButtonLeading = [self.photoButton.leadingAnchor constraintEqualToAnchor:self.photoButton.superview.leadingAnchor];
    NSLayoutConstraint *photoButtonTrailing = [self.photoButton.trailingAnchor constraintEqualToAnchor:self.photoButton.superview.trailingAnchor];
    
    [NSLayoutConstraint activateConstraints:@[
                                              sideViewTrailing, sideViewTop, sideViewBottom, sideViewWidth,
                                              cancelButtonBottom, cancelButtonLeading, cancelButtonTrailing,
                                              cameraButtonCenterX, cameraButtonCenterY,
                                              switchCameraButtonBottom, switchCameraButtonWidth, switchCameraButtonHeight, switchCameraButtonCenterX,
                                              photoButtonTop, photoButtonLeading, photoButtonTrailing
                                              ]];
}

- (void)setupPreCaptureContainerLayoutForiPhone {
    
    // Footer
    UIView *preCaptureFooter = [[UIView alloc] init];
    preCaptureFooter.translatesAutoresizingMaskIntoConstraints = NO;
    [self.preCaptureContainer addSubview:preCaptureFooter];
    NSLayoutConstraint *preCaptureFooterLeading = [preCaptureFooter.leadingAnchor constraintEqualToAnchor:preCaptureFooter.superview.leadingAnchor];
    NSLayoutConstraint *preCaptureFooterTrailing = [preCaptureFooter.trailingAnchor constraintEqualToAnchor:preCaptureFooter.superview.trailingAnchor];
    NSLayoutConstraint *preCaptureFooterBottom = [preCaptureFooter.bottomAnchor constraintEqualToAnchor:preCaptureFooter.superview.bottomAnchor];
    NSLayoutConstraint *preCaptureFooterHeight = [preCaptureFooter.heightAnchor constraintEqualToConstant:120.0f];
    
    // Action buttons container
    UIView *actionButtonsContainer = [[UIView alloc] init];
    actionButtonsContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [preCaptureFooter addSubview:actionButtonsContainer];
    NSLayoutConstraint *actionButtonsContainerLeading = [actionButtonsContainer.leadingAnchor constraintEqualToAnchor:actionButtonsContainer.superview.leadingAnchor];
    actionButtonsContainerLeading.constant = [CameraPickerAppearance defaultHorizontalMargin];
    NSLayoutConstraint *actionButtonsContainerTrailing = [actionButtonsContainer.trailingAnchor constraintEqualToAnchor:actionButtonsContainer.superview.trailingAnchor];
    actionButtonsContainerTrailing.constant = -[CameraPickerAppearance defaultHorizontalMargin];
    NSLayoutConstraint *actionButtonsContainerBottom = [actionButtonsContainer.bottomAnchor constraintEqualToAnchor:actionButtonsContainer.superview.bottomAnchor];
    actionButtonsContainerBottom.constant = -[CameraPickerAppearance defaultVerticalMargin];
    NSLayoutConstraint *actionButtonsContainerHeight = [actionButtonsContainer.heightAnchor constraintEqualToConstant:66.0];
    
    // Cancel button
    [actionButtonsContainer addSubview:self.cancelButton];
    NSLayoutConstraint *cancelButtonLeading = [self.cancelButton.leadingAnchor constraintEqualToAnchor:self.cancelButton.superview.leadingAnchor];
    NSLayoutConstraint *cancelButtonCenterY = [self.cancelButton.centerYAnchor constraintEqualToAnchor:self.cancelButton.superview.centerYAnchor];
    
    // Take photo button
    [actionButtonsContainer addSubview:self.captureButton];
    NSLayoutConstraint *cameraButtonCenterX = [self.captureButton.centerXAnchor constraintEqualToAnchor:self.captureButton.superview.centerXAnchor];
    NSLayoutConstraint *cameraButtonCenterY = [self.captureButton.centerYAnchor constraintEqualToAnchor:self.captureButton.superview.centerYAnchor];
    
    // Switch camera
    [actionButtonsContainer addSubview:self.switchCameraButton];
    NSLayoutConstraint *switchCameraButtonTrailing = [self.switchCameraButton.trailingAnchor constraintEqualToAnchor:self.switchCameraButton.superview.trailingAnchor];
    NSLayoutConstraint *switchCameraButtonCenterY = [self.switchCameraButton.centerYAnchor constraintEqualToAnchor:self.switchCameraButton.superview.centerYAnchor];
    NSLayoutConstraint *switchCameraButtonWidth = [self.switchCameraButton.widthAnchor constraintEqualToConstant:[CameraPickerAppearance defaultButtonSize].width];
    NSLayoutConstraint *switchCameraButtonHeight = [self.switchCameraButton.heightAnchor constraintEqualToConstant:[CameraPickerAppearance defaultButtonSize].height];
    
    // Photo button container
    UIView *captureModeContainer = [[UIView alloc] init];
    captureModeContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [preCaptureFooter addSubview:captureModeContainer];
    NSLayoutConstraint *captureModeContainerLeading = [captureModeContainer.leadingAnchor constraintEqualToAnchor:captureModeContainer.superview.leadingAnchor];
    NSLayoutConstraint *captureModeContainerTrailing = [captureModeContainer.trailingAnchor constraintEqualToAnchor:captureModeContainer.superview.trailingAnchor];
    NSLayoutConstraint *captureModeContainerTop = [captureModeContainer.topAnchor constraintEqualToAnchor:captureModeContainer.superview.topAnchor];
    NSLayoutConstraint *captureModeContainerBottom = [captureModeContainer.bottomAnchor constraintEqualToAnchor:actionButtonsContainer.topAnchor];
    captureModeContainerBottom.constant = -[CameraPickerAppearance defaultVerticalMargin];
    
    
    // Photo button
    NSString *photoButtonTitle = self.photoButton.currentTitle;
    CGRect photoButtonRect = [photoButtonTitle boundingRectWithSize:CGSizeMake(0, 0)
                                                            options:NSStringDrawingUsesLineFragmentOrigin
                                                         attributes:@{NSFontAttributeName:self.photoButton.titleLabel.font}
                                                            context:nil];
    
    [captureModeContainer addSubview:self.photoButton];
    CGFloat horizontalPaddingForBiggerRoundedRect = 20.0f;
    NSLayoutConstraint *photoButtonWidth = [self.photoButton.widthAnchor constraintEqualToConstant:photoButtonRect.size.width +
                                            horizontalPaddingForBiggerRoundedRect];
    NSLayoutConstraint *photoButtonTop = [self.photoButton.topAnchor constraintEqualToAnchor:self.photoButton.superview.topAnchor];
    NSLayoutConstraint *photoButtonBottom = [self.photoButton.bottomAnchor constraintEqualToAnchor:self.photoButton.superview.bottomAnchor];
    
    [NSLayoutConstraint activateConstraints:@[
                                              preCaptureFooterLeading, preCaptureFooterTrailing, preCaptureFooterBottom, preCaptureFooterHeight,
                                              actionButtonsContainerLeading, actionButtonsContainerTrailing, actionButtonsContainerBottom, actionButtonsContainerHeight,
                                              cancelButtonLeading, cancelButtonCenterY,
                                              cameraButtonCenterX,cameraButtonCenterY,
                                              switchCameraButtonTrailing, switchCameraButtonWidth, switchCameraButtonHeight, switchCameraButtonCenterY,
                                              captureModeContainerLeading, captureModeContainerTrailing, captureModeContainerTop, captureModeContainerBottom,
                                              photoButtonWidth, photoButtonTop, photoButtonBottom
                                              ]];
    self.photoButtonCenterX = [self.photoButton.centerXAnchor constraintEqualToAnchor:self.captureButton.centerXAnchor];
}

- (void)setupPostCaptureContainer {
    
    // Post Capture Container view
    UIView *postCaptureContainer = [[UIView alloc] init];
    self.postCaptureContainer = postCaptureContainer;
    postCaptureContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:postCaptureContainer];
    NSLayoutConstraint *postCaptureContainerTop = [postCaptureContainer.topAnchor constraintEqualToAnchor:postCaptureContainer.superview.topAnchor];
    NSLayoutConstraint *postCaptureContainerBottom = [postCaptureContainer.bottomAnchor constraintEqualToAnchor:postCaptureContainer.superview.bottomAnchor];
    NSLayoutConstraint *postCaptureContainerLeading = [postCaptureContainer.leadingAnchor constraintEqualToAnchor:postCaptureContainer.superview.leadingAnchor];
    NSLayoutConstraint *postCaptureContainerTrailing = [postCaptureContainer.trailingAnchor constraintEqualToAnchor:postCaptureContainer.superview.trailingAnchor];
    
    // Retake button
    UIButton *retakeButton = [[UIButton alloc] init];
    self.retakeButton = retakeButton;
    [retakeButton setTitle:@"Please retake photo" forState:UIControlStateNormal];
    [retakeButton addTarget:self action:@selector(didTapRetakeButton) forControlEvents:UIControlEventTouchUpInside];
    [postCaptureContainer addSubview:retakeButton];
    retakeButton.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *retakeButtonLeading = [retakeButton.leadingAnchor constraintEqualToAnchor:retakeButton.superview.leadingAnchor];
    retakeButtonLeading.constant = [CameraPickerAppearance defaultHorizontalMargin];
    NSLayoutConstraint *retakeButtonBottom = [retakeButton.bottomAnchor constraintEqualToAnchor:retakeButton.superview.bottomAnchor];
    retakeButtonBottom.constant = -[CameraPickerAppearance defaultVerticalMargin];
    
    // Done button
    UIButton *doneButton = [[UIButton alloc] init];
    self.doneButton = doneButton;
    [doneButton setTitle:@"Use photo" forState:UIControlStateNormal];
    
    [doneButton addTarget:self action:@selector(didtapDoneButton) forControlEvents:UIControlEventTouchUpInside];
    doneButton.translatesAutoresizingMaskIntoConstraints = NO;
    [postCaptureContainer addSubview:doneButton];
    NSLayoutConstraint *doneButtonTrailing = [doneButton.trailingAnchor constraintEqualToAnchor:doneButton.superview.trailingAnchor];
    doneButtonTrailing.constant = -[CameraPickerAppearance defaultHorizontalMargin];
    NSLayoutConstraint *doneButtonBottom = [doneButton.bottomAnchor constraintEqualToAnchor:doneButton.superview.bottomAnchor];
    doneButtonBottom.constant = -[CameraPickerAppearance defaultVerticalMargin];
    
    // ImageView to preview captured photo
    UIImageView *imageView = [[UIImageView alloc] init];
    self.imageView = imageView;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.backgroundColor = [CameraPickerAppearance colorForPhotoPreviewBackground];
    [postCaptureContainer insertSubview:imageView atIndex:0];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *imageViewTop = [imageView.topAnchor constraintEqualToAnchor:imageView.superview.topAnchor];
    NSLayoutConstraint *imageViewBottom = [imageView.bottomAnchor constraintEqualToAnchor:imageView.superview.bottomAnchor];
    NSLayoutConstraint *imageViewLeading = [imageView.leadingAnchor constraintEqualToAnchor:imageView.superview.leadingAnchor];
    NSLayoutConstraint *imageViewTrailing = [imageView.trailingAnchor constraintEqualToAnchor:imageView.superview.trailingAnchor];
    
    [NSLayoutConstraint activateConstraints:@[postCaptureContainerTop, postCaptureContainerBottom, postCaptureContainerLeading, postCaptureContainerTrailing,
                                              retakeButtonLeading, retakeButtonBottom,
                                              doneButtonTrailing, doneButtonBottom,
                                              imageViewTop, imageViewBottom, imageViewLeading, imageViewTrailing
                                              ]];
    
    if (self.captureMode == CameraPickerCaptureModePhoto) {
        
        // Set Photo Resize Header View
        [self setupPhotoResizeHeaderView];
        
        // Edit Photo button
        UIButton *editPhotoButton = [[UIButton alloc] init];
        self.editPhotoButton = editPhotoButton;
        [editPhotoButton setImage:[CameraPickerResourceLoader imageNamed:@"editIcon"] forState:UIControlStateNormal];
        [editPhotoButton addTarget:self action:@selector(didTapEditPhotobutton) forControlEvents:UIControlEventTouchUpInside];
        editPhotoButton.translatesAutoresizingMaskIntoConstraints = NO;
        [postCaptureContainer addSubview:editPhotoButton];
        CGSize editButtonSize = [CameraPickerAppearance defaultSizeForHeaderButton];
        NSLayoutConstraint *editPhotoButtonTrailing = [editPhotoButton.trailingAnchor constraintEqualToAnchor:editPhotoButton.superview.trailingAnchor];
        editPhotoButtonTrailing.constant = -[CameraPickerAppearance horizontalMarginForButtonWithSize:editButtonSize imageSize:CGSizeMake(22.0f, 22.0f)];
        NSLayoutConstraint *editPhotoButtonHeight = [editPhotoButton.heightAnchor constraintEqualToConstant:editButtonSize.height];
        NSLayoutConstraint *editPhotoButtonWidth = [editPhotoButton.widthAnchor constraintEqualToConstant:editButtonSize.width];
        NSLayoutConstraint *editPhotoButtonCenterY = [editPhotoButton.centerYAnchor constraintEqualToAnchor:self.photoResizeHeaderView.centerYAnchor];
        [NSLayoutConstraint activateConstraints:@[
                                                  editPhotoButtonTrailing, editPhotoButtonHeight, editPhotoButtonWidth, editPhotoButtonCenterY
                                                  ]];
        if (self.allowsPhotoEditing) {
            self.editPhotoButton.alpha = 1.0f;
        } else {
            self.editPhotoButton.alpha = 0.0f;
        }
    }
    
}

- (void)setupPhotoResizeHeaderView {
    
    if (self.postCaptureContainer) {
        
        CameraPickerPhotoResizeHeaderView *photoResizeHeaderView = [[CameraPickerPhotoResizeHeaderView alloc] init];
        self.photoResizeHeaderView = photoResizeHeaderView;
        photoResizeHeaderView.delegate = self;
        photoResizeHeaderView.foldingDelegate = self;
        photoResizeHeaderView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.postCaptureContainer addSubview:photoResizeHeaderView];
        NSLayoutConstraint *photoResizeHeaderViewTop;
        if (@available(iOS 11, *)) {
            photoResizeHeaderViewTop = [photoResizeHeaderView.topAnchor constraintEqualToAnchor:photoResizeHeaderView.superview.safeAreaLayoutGuide.topAnchor];
        } else {
            photoResizeHeaderViewTop = [photoResizeHeaderView.topAnchor constraintEqualToAnchor:photoResizeHeaderView.superview.topAnchor];
        }
        NSLayoutConstraint *photoResizeHeaderViewLeading = [photoResizeHeaderView.leadingAnchor constraintEqualToAnchor:photoResizeHeaderView.superview.leadingAnchor];
        NSLayoutConstraint *photoResizeHeaderViewTrailing = [photoResizeHeaderView.trailingAnchor constraintEqualToAnchor:photoResizeHeaderView.superview.trailingAnchor];
        [NSLayoutConstraint activateConstraints:@[photoResizeHeaderViewTop, photoResizeHeaderViewLeading, photoResizeHeaderViewTrailing]];
        [self.photoResizeHeaderView activateDefaultHeightConstraint:YES];
        
        [self.flashHeaderView collapseOptionsAnimated:NO];
    }
}

- (void)prepareButtonsForCaptureMode:(CameraPickerCaptureMode)captureMode {
    
    __weak __typeof(self) weakSelf = self;
    [UIView animateWithDuration:[CameraPickerAppearance captureModeHighlightAnimationDuration] animations:^ {
    
        /* Photo capture mode */
        weakSelf.captureButton.style = CameraButtonStylePhotoCapture;
        [CameraPickerAppearance highlightButton:weakSelf.photoButton withSemiTransparentRoundedCornersBackground:YES];
        
        if (weakSelf.captureButton) {
            weakSelf.photoButtonCenterX.active = YES;
            [weakSelf layoutIfNeeded];
        }
    }];
}

- (void)setSwithCameraButtonImageForDevicePosition:(CameraDevicePosition)devicePosition {
    
    if (!self.switchCameraButton) {
        return;
    }
    
    UIImage *image;
    switch (devicePosition) {
        case CameraDevicePositionBack:
            image = [CameraPickerResourceLoader imageNamed:@"frontCameraIcon"];
            break;
        case CameraDevicePositionFront:
        case CameraDevicePositionUnspecified:
            image = [CameraPickerResourceLoader imageNamed:@"rearCameraIcon"];
            break;
            
    }
    
    if (image) {
        [self.switchCameraButton setImage:image forState:UIControlStateNormal];
    }
}

- (void)setupUIForAvailableCaptureModes:(NSArray<NSNumber *> *)availableCaptureModes {
    
    if (self.photoButton && [availableCaptureModes containsObject:@(CameraPickerCaptureModePhoto)]) {
        self.photoButton.alpha = 1.0f;
    } else {
        self.photoButton.alpha = 0.0f;
    }
}

- (void)setupUIForSwitchCameraAvailable:(BOOL)isSwitchCameraButtonAvailable {
    
    if (isSwitchCameraButtonAvailable) {
        self.switchCameraButton.alpha = 1.0f;
    } else {
        self.switchCameraButton.alpha = 0.0f;
    }
}

- (void)setupUIForFlashAvailable:(BOOL)isFlashAvailable {
    
    if (!isFlashAvailable) {
        [self.flashHeaderView removeFromSuperview];
    } else {
        
        if (!self.flashHeaderView) {
            [self setupFlashHeader];
        }
    }
}

- (void)setupUIForInteractionEnabled:(BOOL)interactionEnabled {
    
    self.photoButton.enabled = interactionEnabled;
    self.captureButton.enabled = interactionEnabled;
    self.switchCameraButton.enabled = interactionEnabled;
    self.flashHeaderView.userInteractionEnabled = interactionEnabled;
}

- (void)clearSubviews {
    
    for (UIView *subview in self.subviews) {
        [subview removeFromSuperview];
    }
    self.preCaptureContainer = nil;
    self.postCaptureContainer = nil;
    self.flashHeaderView = nil;;
    self.photoResizeHeaderView = nil;
}

#pragma mark - Actions

- (void)didSwipeToChangeCaptureMode:(UISwipeGestureRecognizer *)swipeGestureRecognizer {
    
    if (swipeGestureRecognizer.direction == UISwipeGestureRecognizerDirectionRight ||
        swipeGestureRecognizer.direction == UISwipeGestureRecognizerDirectionUp) {
        
        [self didTapPhotoButton];
    } else if (swipeGestureRecognizer.direction == UISwipeGestureRecognizerDirectionLeft ||
               swipeGestureRecognizer.direction == UISwipeGestureRecognizerDirectionDown) {
        
//        [self didTapVideoButton];
    }
}

- (void)didTapCancelButton {
    [self.delegate cameraOverlayViewDidTapCancelButton:self];
}

- (void)didTapSwitchCameraButton {
    [self.delegate cameraOverlayViewDidTapSwitchCameraButton:self];
}

- (void)didTapPhotoButton {
    [self.delegate cameraOverlayView:self didChangeCaptureMode:CameraPickerCaptureModePhoto];
}

- (void)didTapCaptureButton {
    [self.delegate cameraOverlayViewDidTapCaptureButton:self];
}

- (void)didTapRetakeButton {
    [self.delegate cameraOverlayViewDidTapRetakeButton:self];
}

- (void)didTapEditPhotobutton {
    [self.delegate cameraOverlayViewDidTapEditPhotoButton:self];
}

- (void)didtapDoneButton {
    [self.delegate cameraOverlayViewDidTapDoneButton:self];
}

@end

