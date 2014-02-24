//
//  GBTutorialOverlay.h
//  GBTutorialOverlay
//
//  Created by Luka Mirosevic on 12/02/2014.
//  Copyright (c) 2014 Goonbee. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GBStickyViews/GBStickyViews.h>

typedef enum {
    GBTutorialOverlayCloseImagePositionTopRight,
    GBTutorialOverlayCloseImagePositionBottomRight,
    GBTutorialOverlayCloseImagePositionBottomLeft,
    GBTutorialOverlayCloseImagePositionTopLeft,
} GBTutorialOverlayCloseImagePosition;

@protocol GBTutorialOverlayHintViewInterface;
@class GBTutorialOverlayHintProperties;

//class for setting default properties for newly generated overlays
@interface GBTutorialOverlayDefaults : NSObject

@property (strong, nonatomic) UIColor                                               *backgroundColor;           //default: black with opacity 0.75
@property (assign, nonatomic) BOOL                                                  isTapToCloseEnabled;        //default: YES
@property (strong, nonatomic) UIImage                                               *closeButtonImage;          //default: GBTutorialOverlayResources.bundle/GBTutorialOverlayDefaultCloseImage.png
@property (assign, nonatomic) CGPoint                                               closeButtonOffset;          //default: {10,30}
@property (assign, nonatomic) GBTutorialOverlayCloseImagePosition                   closeButtonPosition;        //default: GBTutorialOverlayCloseImagePositionTopRight
@property (weak, nonatomic) UIView                                                  *viewForPresentation;       //default: [[UIApplication sharedApplication] keyWindow]
@property (assign, nonatomic) NSTimeInterval                                        presentAnimationDuration;   //default: 0.3
@property (assign, nonatomic) NSTimeInterval                                        dismissAnimationDuration;   //default: 0.15

@end

//the actual overlay class
@interface GBTutorialOverlay : GBTutorialOverlayDefaults

@property (strong, nonatomic, readonly) UIView                                      *view;//the view with all the hints on it

+(GBTutorialOverlayDefaults *)defaults;

+(GBTutorialOverlay *)overlayViewWithStencils:(NSArray *)hintViews;//must be an array of GBTutorialOverlayStencil objects
-(void)addHintView:(UIView<GBTutorialOverlayHintViewInterface> *)hintView withProperties:(GBTutorialOverlayHintProperties *)hintProperties;
-(void)present;
-(void)dismiss;
-(void)presentAnimated:(BOOL)animated;
-(void)dismissAnimated:(BOOL)animated;

@end

//properties which encode where and how to display a view
@interface GBTutorialOverlayHintProperties : NSObject

@property (weak, nonatomic) UIView                                                  *targetView;
@property (assign, nonatomic) GBStickyViewsAnchor                                   masterAnchor;
@property (assign, nonatomic) GBStickyViewsAnchor                                   hintAnchor;
@property (assign, nonatomic) CGPoint                                               offset;

@end

//custom hints must conform to this protocol
@protocol GBTutorialOverlayHintViewInterface <NSObject>

@property (copy, nonatomic) NSString                                                *hintText;

@end

//a stencil for creating views easily
@interface GBTutorialOverlayStencil : NSObject

@property (strong, nonatomic) GBTutorialOverlayHintProperties                       *hintProperties;
@property (copy, nonatomic) NSString                                                *hintText;
@property (strong, nonatomic) UIView<GBTutorialOverlayHintViewInterface>            *hintView;

GBTutorialOverlayStencil * GBTutorialStencilMake(UIView<GBTutorialOverlayHintViewInterface> *hintView, NSString *hintText, UIView *targetView, GBStickyViewsAnchor masterAnchor, GBStickyViewsAnchor hintAnchor, CGPoint offset);//just a convenience that makes for better readability in client code
+(GBTutorialOverlayStencil *)stencilWithHintView:(UIView<GBTutorialOverlayHintViewInterface> *)hintView hintText:(NSString *)hintText targetView:(UIView *)targetView masterAnchor:(GBStickyViewsAnchor)masterAnchor hintAnchor:(GBStickyViewsAnchor)hintAnchor offset:(CGPoint)offset;

@end

//a stencil subclass to create views from nibs
@interface GBTutorialOverlayNibStencil : GBTutorialOverlayStencil

@property (copy, nonatomic, readonly) NSString                                      *hintViewNibName;//the view in this nib at position 0 must conform to GBTutorialOverlayHintViewInterface

GBTutorialOverlayStencil * GBTutorialStencilMakeFromNib(NSString *hintViewNibName, NSString *hintText, UIView *targetView, GBStickyViewsAnchor masterAnchor, GBStickyViewsAnchor hintAnchor, CGPoint offset);//just a convenience that makes for better readability in client code
+(GBTutorialOverlayStencil *)stencilWithNibName:(NSString *)hintViewNibName hintText:(NSString *)hintText targetView:(UIView *)targetView masterAnchor:(GBStickyViewsAnchor)masterAnchor hintAnchor:(GBStickyViewsAnchor)hintAnchor offset:(CGPoint)offset;

@end

//a stencil subclass to create views from UIView subclasses
@interface GBTutorialOverlayClassStencil : GBTutorialOverlayStencil

@property (copy, nonatomic, readonly) Class<GBTutorialOverlayHintViewInterface>     hintViewClass;

GBTutorialOverlayStencil * GBTutorialStencilMakeFromClass(Class<GBTutorialOverlayHintViewInterface> hintViewClass, NSString *hintText, UIView *targetView, GBStickyViewsAnchor masterAnchor, GBStickyViewsAnchor hintAnchor, CGPoint offset);//just a convenience that makes for better readability in client code
+(GBTutorialOverlayStencil *)stencilWithClass:(Class<GBTutorialOverlayHintViewInterface>)hintViewClass hintText:(NSString *)hintText targetView:(UIView *)targetView masterAnchor:(GBStickyViewsAnchor)masterAnchor hintAnchor:(GBStickyViewsAnchor)hintAnchor offset:(CGPoint)offset;

@end

//this is a basic class skeleton for a hint view where the hint text is displayed in a label. Use this as the class in XIB UIView's
@interface GBTutorialOverlayBasicHintView : UIView <GBTutorialOverlayHintViewInterface>

@property (weak, nonatomic) IBOutlet UILabel                                        *hintLabel;

@property (copy, nonatomic) NSString                                                *hintText;

@end
