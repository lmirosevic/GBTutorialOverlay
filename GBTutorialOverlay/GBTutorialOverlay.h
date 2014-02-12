//
//  GBTutorialOverlay.h
//  GBTutorialOverlay
//
//  Created by Luka Mirosevic on 12/02/2014.
//  Copyright (c) 2014 Goonbee. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GBStickyViews/GBStickyViews.h>

@protocol GBTutorialOverlayHintViewInterface;

@interface GBTutorialOverlay : UIView

@property (strong, nonatomic) UIColor       *backgroundColor;           //default: black with opacity 0.4
@property (assign, nonatomic) BOOL          isTapToCloseEnabled;        //default: YES
@property (assign, nonatomic) BOOL          shouldShowCloseButton;      //defautt: YES

+(GBTutorialOverlay *)generateOverlayViewWithHintViewsProperties:(NSArray *)hintViews;//must be an array of GBTutorialOverlayHintProperties objects
-(void)addHintView:(UIView<GBTutorialOverlayHintViewInterface> *)hintView;
-(void)present;
-(void)dismiss;

@end

@interface GBTutorialOverlayHintProperties : NSObject

@property (copy, nonatomic) UIView                      *targetView;
@property (copy, nonatomic) NSString                    *hintText;
@property (assign, nonatomic) GBStickyViewsAnchor       masterAnchor;
@property (assign, nonatomic) GBStickyViewsAnchor       hintAnchor;
@property (assign, nonatomic) CGPoint                   offset;
@property (copy, nonatomic) NSString                    *hintViewNibName;

+(GBTutorialOverlayHintProperties *)propertiesWithTargetView:(UIView *)targerView hintText:(NSString *)hintText masterAnchor:(GBStickyViewsAnchor)masterAnchor hintAnchor:(GBStickyViewsAnchor)hintAnchor offset:(CGPoint)offset hintViewNibName:(NSString *)hintViewNibName;

@end

@protocol GBTutorialOverlayHintViewInterface <NSObject>

@property (copy, nonatomic) NSString                    *hintText;

@end

@interface GBTutorialOverlayBasicHintView : UIView <GBTutorialOverlayHintViewInterface>

@property (weak, nonatomic) IBOutlet UILabel            *hintLabel;

@property (copy, nonatomic) NSString                    *hintText;

@end
