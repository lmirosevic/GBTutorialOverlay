//
//  GBTutorialOverlay.m
//  GBTutorialOverlay
//
//  Created by Luka Mirosevic on 12/02/2014.
//  Copyright (c) 2014 Goonbee. All rights reserved.
//

#import "GBTutorialOverlay.h"

#import <GBToolbox/GBToolbox.h>

#define kDefaultBackgroundColor                                                 [UIColor colorWithWhite:0 alpha:0.75]
static BOOL const kDefaultTapToClose =                                          YES;
#define kDefaultCloseButtonImage                                                [UIImage imageNamed:@"GBTutorialOverlayResources.bundle/GBTutorialOverlayDefaultCloseImage.png"]
static GBTutorialOverlayCloseImagePosition kDefaultCloseButtonPosition =        GBTutorialOverlayCloseImagePositionTopRight;
static CGPoint const kDefaultCloseButtonOffset =                                (CGPoint){10, 30};
#define kDefaultViewForPresentation                                             [[UIApplication sharedApplication] keyWindow]

static NSTimeInterval const kAnimationDuriation =                               0.15;

@interface GBTutorialOverlayManager : NSObject

@property (strong, nonatomic) NSMutableArray                                    *overlays;

+(GBTutorialOverlayManager *)sharedManager;

@end

@implementation GBTutorialOverlayManager

#pragma mark - Memory

+(GBTutorialOverlayManager *)sharedManager {
    static GBTutorialOverlayManager *sharedManager;
    @synchronized(self) {
        if (!sharedManager) {
            sharedManager = [GBTutorialOverlayManager new];
        }
        
        return sharedManager;
    }
}

-(id)init {
    if (self = [super init]) {
        self.overlays = [NSMutableArray new];
    }
    
    return self;
}

#pragma mark - API

-(void)presentOverlay:(GBTutorialOverlay *)overlay animated:(BOOL)animated {
    [self.overlays addObject:overlay];//retain the overlay
    
    overlay.view.frame = overlay.viewForPresentation.bounds;
    overlay.view.alpha = 0.;
    [overlay.viewForPresentation addSubview:overlay.view];
    
    [UIView animateWithDuration:(animated ? kAnimationDuriation : 0.) animations:^{
        overlay.view.alpha = 1.;
    } completion:^(BOOL finished) {
        //noop
    }];
}

-(void)dismissOverlay:(GBTutorialOverlay *)overlay animated:(BOOL)animated {
    [UIView animateWithDuration:(animated ? kAnimationDuriation : 0.) animations:^{
        overlay.view.alpha = 0.;
    } completion:^(BOOL finished) {
        [overlay.view removeFromSuperview];
        [self.overlays removeObject:overlay];//destroy the overlay
    }];
}

@end

@implementation GBTutorialOverlayDefaults

-(id)init {
    if (self = [super init]) {
        //DO NOT EDIT THIS, use the initWithDefaults method instead to set configuration for this object
    }
    
    return self;
}

-(id)initWithDefaults {
    if (self = [self init]) {
        self.backgroundColor = kDefaultBackgroundColor;
        self.isTapToCloseEnabled = kDefaultTapToClose;
        
        self.closeButtonImage = kDefaultCloseButtonImage;
        self.closeButtonOffset = kDefaultCloseButtonOffset;
        self.closeButtonPosition = kDefaultCloseButtonPosition;
        
        self.viewForPresentation = kDefaultViewForPresentation;
    }
    
    return self;
}

@end

@interface GBTutorialOverlay ()

@property (strong, nonatomic, readwrite) UIView                                 *view;
@property (strong, nonatomic) UITapGestureRecognizer                            *tapGestureRecognizer;
@property (strong, nonatomic) UIButton                                          *closeButton;

@end

@implementation GBTutorialOverlay

#pragma mark - Memory

+(GBTutorialOverlayDefaults *)defaults {
    static GBTutorialOverlayDefaults *defaults;
    @synchronized(self) {
        if (!defaults) {
            defaults = [[GBTutorialOverlayDefaults alloc] initWithDefaults];
        }
        
        return defaults;
    }
}

-(id)init {
    if (self = [super init]) {
        //background view
        self.view = [UIView new];
        self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tapHandler:)];
        [self.view addGestureRecognizer:self.tapGestureRecognizer];
        
        //close button (the setters below will configure it)
        self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.closeButton.contentMode = UIViewContentModeCenter;
        [self.closeButton addTarget:self action:@selector(_closeAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.closeButton];
        
        self.backgroundColor = [self.class defaults].backgroundColor;
        self.isTapToCloseEnabled = [self.class defaults].isTapToCloseEnabled;
        self.closeButtonImage = [self.class defaults].closeButtonImage;
        self.closeButtonOffset = [self.class defaults].closeButtonOffset;
        self.closeButtonPosition = [self.class defaults].closeButtonPosition;
        self.viewForPresentation = [self.class defaults].viewForPresentation;
    }
    
    return self;
}

#pragma mark - CA

-(void)setBackgroundColor:(UIColor *)backgroundColor {
    super.backgroundColor = backgroundColor;
    
    [self _updateBackground];
}

-(void)setCloseButtonImage:(UIImage *)closeButtonImage {
    super.closeButtonImage = closeButtonImage;
    
    [self _updateCloseButton];
}

-(void)setCloseButtonOffset:(CGPoint)closeButtonOffset {
    super.closeButtonOffset = closeButtonOffset;
    
    [self _updateCloseButton];
}

-(void)setCloseButtonPosition:(GBTutorialOverlayCloseImagePosition)closeButtonPosition {
    super.closeButtonPosition = closeButtonPosition;
    
    [self _updateCloseButton];
}

#pragma mark - API

-(void)addHintView:(UIView<GBTutorialOverlayHintViewInterface> *)hintView withProperties:(GBTutorialOverlayHintProperties *)hintProperties {
    //add the hint view
    [self.view addSubview:hintView];
    
    //configure the hint view
    [hintView attachToView:hintProperties.targetView masterAnchor:hintProperties.masterAnchor slaveAnchor:hintProperties.hintAnchor offset:hintProperties.offset track:YES];
}

-(void)present {
    [self presentAnimated:YES];
}

-(void)dismiss {
    [self dismissAnimated:YES];
}

-(void)presentAnimated:(BOOL)animated {
    [[GBTutorialOverlayManager sharedManager] presentOverlay:self animated:animated];
    
    [self _updateCloseButton];
}

-(void)dismissAnimated:(BOOL)animated {
    [[GBTutorialOverlayManager sharedManager] dismissOverlay:self animated:animated];
    
    [self _updateCloseButton];
}

+(GBTutorialOverlay *)overlayViewWithStencils:(NSArray *)hintViews {
    GBTutorialOverlay *overlay = [GBTutorialOverlay new];
    
    for (GBTutorialOverlayStencil *stencil in hintViews) {
        if (![stencil isKindOfClass:GBTutorialOverlayStencil.class]) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Must pass in array of objects with type of GBTutorialOverlayStencil" userInfo:nil];
        
        //create the hint view
        UIView<GBTutorialOverlayHintViewInterface> *hintView = v(stencil.hintViewNibName);
        hintView.hintText = stencil.hintText;
        
        //create the properties object
        GBTutorialOverlayHintProperties *properties = stencil.hintProperties;
        
        //add the hint to the overlay
        [overlay addHintView:hintView withProperties:properties];
    }
    
    return overlay;
}

#pragma mark - UITapGestureRecognizer

-(void)_tapHandler:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (self.isTapToCloseEnabled) {
            [self dismiss];
        }
        else {
            //noop
        }
    }
}

#pragma mark - UIButton

-(void)_closeAction:(UIButton *)sender {
    [self dismiss];
}

#pragma mark - Util

-(void)_updateCloseButton {
    CGSize buttonSize = self.closeButtonImage.size;
    CGPoint buttonPosition;
    UIViewAutoresizing resizingMask;
    
    switch (self.closeButtonPosition) {
        case GBTutorialOverlayCloseImagePositionTopRight: {
            buttonPosition = CGPointMake(self.view.bounds.origin.x + self.view.bounds.size.width - buttonSize.width - self.closeButtonOffset.x,
                                         self.view.bounds.origin.y + self.closeButtonOffset.y);
            resizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
        } break;
        
        case GBTutorialOverlayCloseImagePositionBottomRight: {
            buttonPosition = CGPointMake(self.view.bounds.origin.x + self.view.bounds.size.width - buttonSize.width - self.closeButtonOffset.x,
                                         self.view.bounds.origin.y + self.view.bounds.size.height - buttonSize.height - self.closeButtonOffset.y);
            resizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
        } break;
        
        case GBTutorialOverlayCloseImagePositionBottomLeft: {
            buttonPosition = CGPointMake(self.view.bounds.origin.x + self.closeButtonOffset.x,
                                         self.view.bounds.origin.y + self.view.bounds.size.height - buttonSize.height - self.closeButtonOffset.y);
            resizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
        } break;
        
        case GBTutorialOverlayCloseImagePositionTopLeft: {
            buttonPosition = CGPointMake(self.view.bounds.origin.x + self.closeButtonOffset.x,
                                         self.view.bounds.origin.y + self.closeButtonOffset.y);
            resizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        } break;
    }
    
    [self.closeButton setImage:self.closeButtonImage forState:UIControlStateNormal];
    self.closeButton.frame = CGRectMake(buttonPosition.x, buttonPosition.y, buttonSize.width, buttonSize.height);
}

-(void)_updateBackground {
    self.view.backgroundColor = self.backgroundColor;
}

@end

@implementation GBTutorialOverlayHintProperties
@end

@implementation GBTutorialOverlayStencil

GBTutorialOverlayStencil * GBTutorialStencilMake(NSString *hintViewNibName, NSString *hintText, UIView *targetView, GBStickyViewsAnchor masterAnchor, GBStickyViewsAnchor hintAnchor, CGPoint offset) {
    return [GBTutorialOverlayStencil stencilWithNibName:hintViewNibName hintText:hintText targetView:targetView masterAnchor:masterAnchor hintAnchor:hintAnchor offset:offset];
}

+(GBTutorialOverlayStencil *)stencilWithNibName:(NSString *)hintViewNibName hintText:(NSString *)hintText targetView:(UIView *)targetView masterAnchor:(GBStickyViewsAnchor)masterAnchor hintAnchor:(GBStickyViewsAnchor)hintAnchor offset:(CGPoint)offset {
    GBTutorialOverlayStencil *stencil = [GBTutorialOverlayStencil new];

    stencil.hintText = hintText;
    stencil.hintViewNibName = hintViewNibName;
    
    GBTutorialOverlayHintProperties *hintProperties = [GBTutorialOverlayHintProperties new];
    hintProperties.targetView = targetView;
    hintProperties.masterAnchor = masterAnchor;
    hintProperties.hintAnchor = hintAnchor;
    hintProperties.offset = offset;
    stencil.hintProperties = hintProperties;
    
    return stencil;
}

@end

@implementation GBTutorialOverlayBasicHintView

-(void)setHintText:(NSString *)hintText {
    self.hintLabel.text = hintText;
}

-(NSString *)hintText {
    return self.hintLabel.text;
}

@end