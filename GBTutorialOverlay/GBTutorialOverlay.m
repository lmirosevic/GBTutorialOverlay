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
static NSTimeInterval const kDefaultPresentAnimationDuration =                  0.25;
static NSTimeInterval const kDefaultDismissAnimationDuration =                  0.15;
static BOOL const kDefaultShouldAllowMultipleOverlays =                         NO;

@interface GBTutorialOverlay ()

@property (strong, nonatomic, readwrite) UIView                                 *view;
@property (strong, nonatomic) UITapGestureRecognizer                            *tapGestureRecognizer;
@property (strong, nonatomic) UIButton                                          *closeButton;

@property (strong, nonatomic) NSArray                                           *stencils;
@property (copy, nonatomic) GBTutorialOverlayDismissBlock                       dismissDidStartBlock;
@property (copy, nonatomic) GBTutorialOverlayDismissBlock                       dismissDidEndBlock;

@end

@interface GBTutorialOverlayManager : NSObject

@property (strong, nonatomic) NSMutableArray                                    *overlays;

@property (assign, nonatomic) BOOL                                              shouldAllowMultipleOverlays;

+ (GBTutorialOverlayManager *)sharedManager;

@end

@implementation GBTutorialOverlayManager

#pragma mark - Memory

+ (GBTutorialOverlayManager *)sharedManager {
    static GBTutorialOverlayManager *sharedManager;
    @synchronized(self) {
        if (!sharedManager) {
            sharedManager = [GBTutorialOverlayManager new];
        }
        
        return sharedManager;
    }
}

- (instancetype)init {
    if (self = [super init]) {
        self.overlays = [NSMutableArray new];
        self.shouldAllowMultipleOverlays = kDefaultShouldAllowMultipleOverlays;
    }
    
    return self;
}

#pragma mark - API

- (void)presentOverlay:(GBTutorialOverlay *)overlay animated:(BOOL)animated {
    if (![GBTutorialOverlay shouldAllowMultipleOverlays]) {
        [self _dismissAllOverlaysAnimated:NO];
    }
    
    [self.overlays addObject:overlay];//retain the overlay
    
    //lm the podspec needs a min iOS version that supports Autolayout
    
    // prepare the sizing behaviour of the whole stencil
    overlay.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    overlay.view.frame = overlay.viewForPresentation.bounds;
    overlay.view.alpha = 0.;
    
    // add the overlay to the screen
    [overlay.viewForPresentation addSubview:overlay.view];
    
    // add the stencils to the overlay (we do it now because we want the ancestry chain to be completed as the anchoring will probably cross boundaries that will only be crossable once everything is added to the screen
    for (GBTutorialOverlayStencil *stencil in overlay.stencils) {
        //get the hint view
        UIView<GBTutorialOverlayHintViewInterface> *hintView = stencil.hintView;
        
        // set the text
        hintView.hintText = stencil.hintText;
        
        //create the properties object
        GBTutorialOverlayHintProperties *properties = stencil.hintProperties;
        
        //add the hint to the overlay with the properties object
        [overlay addHintView:hintView withProperties:properties];
    }
    
    // animate the opacity change
    [UIView animateWithDuration:(animated ? overlay.presentAnimationDuration : 0.) animations:^{
        overlay.view.alpha = 1.;
    } completion:^(BOOL finished) {
        //noop
    }];
}

- (void)dismissOverlay:(GBTutorialOverlay *)overlay animated:(BOOL)animated userInitiated:(BOOL)isUserInitiated {
    // first block
    if (overlay.dismissDidStartBlock) overlay.dismissDidStartBlock(isUserInitiated);
    
    [UIView animateWithDuration:(animated ? overlay.dismissAnimationDuration : 0.) animations:^{
        overlay.view.alpha = 0.;
    } completion:^(BOOL finished) {
        // take it off the screen now
        [overlay.view removeFromSuperview];
        
        // second block
        if (overlay.dismissDidEndBlock) overlay.dismissDidEndBlock(isUserInitiated);
        
        //destroy the overlay
        [self.overlays removeObject:overlay];
    }];
}

#pragma mark - Util

- (void)_dismissAllOverlaysAnimated:(BOOL)animated {
    for (GBTutorialOverlay *overlay in self.overlays) {
        [overlay dismissAnimated:animated];
    }
    
    [self.overlays removeAllObjects];
}

@end

@implementation GBTutorialOverlayDefaults

+ (GBTutorialOverlayDefaults *)defaults {
    static GBTutorialOverlayDefaults *_defaults;
    @synchronized(self) {
        if (!_defaults) {
            _defaults = [[self alloc] initWithDefaults];
        }
        
        return _defaults;
    }
}

- (instancetype)init {
    if (self = [super init]) {
        //DO NOT EDIT THIS, use the initWithDefaults method instead to set configuration for this object
    }
    
    return self;
}

- (instancetype)initWithDefaults {
    if (self = [self init]) {
        self.backgroundColor = kDefaultBackgroundColor;
        self.isTapToCloseEnabled = kDefaultTapToClose;
        
        self.closeButtonImage = kDefaultCloseButtonImage;
        self.closeButtonOffset = kDefaultCloseButtonOffset;
        self.closeButtonPosition = kDefaultCloseButtonPosition;
        
        self.viewForPresentation = kDefaultViewForPresentation;
        
        self.presentAnimationDuration = kDefaultPresentAnimationDuration;
        self.dismissAnimationDuration = kDefaultDismissAnimationDuration;
    }
    
    return self;
}

@end

@implementation GBTutorialOverlay

#pragma mark - CA

+ (BOOL)shouldAllowMultipleOverlays {
    return [GBTutorialOverlayManager sharedManager].shouldAllowMultipleOverlays;
}

+ (void)setShouldAllowMultipleOverlays:(BOOL)shouldAllowMultipleOverlays {
    [GBTutorialOverlayManager sharedManager].shouldAllowMultipleOverlays = shouldAllowMultipleOverlays;
}

#pragma mark - Memory

- (instancetype)init {
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
        
        self.backgroundColor = [GBTutorialOverlayDefaults defaults].backgroundColor;
        self.isTapToCloseEnabled = [GBTutorialOverlayDefaults defaults].isTapToCloseEnabled;
        self.closeButtonImage = [GBTutorialOverlayDefaults defaults].closeButtonImage;
        self.closeButtonOffset = [GBTutorialOverlayDefaults defaults].closeButtonOffset;
        self.closeButtonPosition = [GBTutorialOverlayDefaults defaults].closeButtonPosition;
        self.viewForPresentation = [GBTutorialOverlayDefaults defaults].viewForPresentation ?: kDefaultViewForPresentation;//if the defaults singleton is initialised before the window is created, then this will end up as nil, but the user might have just been configuring the defaults in the application:didFinishLaunchingWithOptions: method with the hope of displaying the overlay on the window, so this defers the updating until later
        self.presentAnimationDuration = [GBTutorialOverlayDefaults defaults].presentAnimationDuration;
        self.dismissAnimationDuration = [GBTutorialOverlayDefaults defaults].dismissAnimationDuration;
    }
    
    return self;
}

#pragma mark - CA

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    super.backgroundColor = backgroundColor;
    
    [self _updateBackground];
}

- (void)setCloseButtonImage:(UIImage *)closeButtonImage {
    super.closeButtonImage = closeButtonImage;
    
    [self _updateCloseButton];
}

- (void)setCloseButtonOffset:(CGPoint)closeButtonOffset {
    super.closeButtonOffset = closeButtonOffset;
    
    [self _updateCloseButton];
}

- (void)setCloseButtonPosition:(GBTutorialOverlayCloseImagePosition)closeButtonPosition {
    super.closeButtonPosition = closeButtonPosition;
    
    [self _updateCloseButton];
}

#pragma mark - API

+ (GBTutorialOverlayDefaults *)defaults {
    return [GBTutorialOverlayDefaults defaults];
}

- (void)addHintView:(UIView<GBTutorialOverlayHintViewInterface> *)hintView withProperties:(GBTutorialOverlayHintProperties *)hintProperties {
    //add the hint view
    [self.view addSubview:hintView];
    
    //configure the hint view
    [hintView attachToView:hintProperties.targetView masterAnchor:hintProperties.masterAnchor slaveAnchor:hintProperties.hintAnchor offset:hintProperties.offset];
}

- (void)present {
    [self presentAnimated:YES];
}

- (void)dismiss {
    [self dismissAnimated:YES];
}

- (void)presentAnimated:(BOOL)animated {
    [self _presentAnimated:animated];
}

- (void)dismissAnimated:(BOOL)animated {
    [self _dismissAnimated:animated userInitiated:NO];
}

+ (GBTutorialOverlay *)overlayViewWithStencils:(NSArray *)stencilViews {
    return [self overlayViewWithStencils:stencilViews dismissDidStartBlock:nil dismissDidEndBlock:nil];
}

+ (GBTutorialOverlay *)overlayViewWithStencils:(NSArray *)stencilViews dismissDidStartBlock:(GBTutorialOverlayDismissBlock)dismissDidStartBlock dismissDidEndBlock:(GBTutorialOverlayDismissBlock)dismissDidEndBlock {
    GBTutorialOverlay *overlay = [GBTutorialOverlay new];
    
    // just check the stencils to make sure they're OK
    for (GBTutorialOverlayStencil *stencil in stencilViews) {
        if (![stencil isKindOfClass:GBTutorialOverlayStencil.class]) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Must pass in array of objects with type of GBTutorialOverlayStencil" userInfo:nil];
        
        //get the hint view
        UIView<GBTutorialOverlayHintViewInterface> *stencilView = stencil.hintView;
        
        //check it to make sure no garbage is passed in
        if (![stencilView conformsToProtocol:@protocol(GBTutorialOverlayHintViewInterface)]) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Must pass in a stencilView that conforms to the GBTutorialOverlayHintViewInterface protocol" userInfo:nil];
    }
    
    // store the stencils, and dismissBlock, they will be needed when we display the view
    overlay.stencils = stencilViews;
    overlay.dismissDidStartBlock = dismissDidStartBlock;
    overlay.dismissDidEndBlock = dismissDidEndBlock;
    
    return overlay;
}

#pragma mark - UITapGestureRecognizer

- (void)_tapHandler:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (self.isTapToCloseEnabled) {
            [self _dismissAnimated:YES userInitiated:YES];
        }
        else {
            //noop
        }
    }
}

#pragma mark - UIButton

- (void)_closeAction:(UIButton *)sender {
    [self _dismissAnimated:YES userInitiated:YES];
}

#pragma mark - Util

- (void)_presentAnimated:(BOOL)animated {
    [[GBTutorialOverlayManager sharedManager] presentOverlay:self animated:animated];
    
    [self _updateCloseButton];
}

- (void)_dismissAnimated:(BOOL)animated userInitiated:(BOOL)userInitiated {
    [[GBTutorialOverlayManager sharedManager] dismissOverlay:self animated:animated userInitiated:NO];
    
    [self _updateCloseButton];
}

- (void)_updateCloseButton {
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

- (void)_updateBackground {
    self.view.backgroundColor = self.backgroundColor;
}

@end

@implementation GBTutorialOverlayHintProperties
@end

@implementation GBTutorialOverlayStencil

GBTutorialOverlayStencil * GBTutorialStencilMake(UIView<GBTutorialOverlayHintViewInterface> *hintView, NSString *hintText, UIView *targetView, GBStickyViewsAnchor masterAnchor, GBStickyViewsAnchor hintAnchor, CGPoint offset) {
    return [GBTutorialOverlayStencil stencilWithHintView:hintView hintText:hintText targetView:targetView masterAnchor:masterAnchor hintAnchor:hintAnchor offset:offset];
}

+ (GBTutorialOverlayStencil *)stencilWithHintView:(UIView<GBTutorialOverlayHintViewInterface> *)hintView hintText:(NSString *)hintText targetView:(UIView *)targetView masterAnchor:(GBStickyViewsAnchor)masterAnchor hintAnchor:(GBStickyViewsAnchor)hintAnchor offset:(CGPoint)offset {
    GBTutorialOverlayStencil *stencil = [GBTutorialOverlayStencil new];

    stencil.hintText = hintText;
    stencil.hintView = hintView;
    
    GBTutorialOverlayHintProperties *hintProperties = [GBTutorialOverlayHintProperties new];
    hintProperties.targetView = targetView;
    hintProperties.masterAnchor = masterAnchor;
    hintProperties.hintAnchor = hintAnchor;
    hintProperties.offset = offset;
    stencil.hintProperties = hintProperties;
    
    return stencil;
}

@end

@implementation GBTutorialOverlayNibStencil

GBTutorialOverlayStencil * GBTutorialStencilMakeFromNib(NSString *hintViewNibName, NSString *hintText, UIView *targetView, GBStickyViewsAnchor masterAnchor, GBStickyViewsAnchor hintAnchor, CGPoint offset) {
    return [GBTutorialOverlayNibStencil stencilWithNibName:hintViewNibName hintText:hintText targetView:targetView masterAnchor:masterAnchor hintAnchor:hintAnchor offset:offset];
}

+ (GBTutorialOverlayStencil *)stencilWithNibName:(NSString *)hintViewNibName hintText:(NSString *)hintText targetView:(UIView *)targetView masterAnchor:(GBStickyViewsAnchor)masterAnchor hintAnchor:(GBStickyViewsAnchor)hintAnchor offset:(CGPoint)offset {
    
    UIView<GBTutorialOverlayHintViewInterface> *hintView = v(hintViewNibName);
    
    return [self stencilWithHintView:hintView hintText:hintText targetView:targetView masterAnchor:masterAnchor hintAnchor:hintAnchor offset:offset];
}

@end

@implementation GBTutorialOverlayClassStencil

GBTutorialOverlayStencil * GBTutorialStencilMakeFromClass(Class<GBTutorialOverlayHintViewInterface> hintViewClass, NSString *hintText, UIView *targetView, GBStickyViewsAnchor masterAnchor, GBStickyViewsAnchor hintAnchor, CGPoint offset) {
    return [GBTutorialOverlayClassStencil stencilWithClass:hintViewClass hintText:hintText targetView:targetView masterAnchor:masterAnchor hintAnchor:hintAnchor offset:offset];
}

+ (GBTutorialOverlayStencil *)stencilWithClass:(Class<GBTutorialOverlayHintViewInterface>)hintViewClass hintText:(NSString *)hintText targetView:(UIView *)targetView masterAnchor:(GBStickyViewsAnchor)masterAnchor hintAnchor:(GBStickyViewsAnchor)hintAnchor offset:(CGPoint)offset {
    if (![hintViewClass.class isSubclassOfClass:UIView.class]) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"hintViewClass must be a subclass of UIView" userInfo:nil];
    
    UIView<GBTutorialOverlayHintViewInterface> *hintView = [hintViewClass.class new];
    
    return [self stencilWithHintView:hintView hintText:hintText targetView:targetView masterAnchor:masterAnchor hintAnchor:hintAnchor offset:offset];
}

@end

@implementation GBTutorialOverlayBasicHintView

- (void)setHintText:(NSString *)hintText {
    self.hintLabel.text = hintText;
}

- (NSString *)hintText {
    return self.hintLabel.text;
}

@end
