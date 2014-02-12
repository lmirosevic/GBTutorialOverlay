//
//  GBTutorialOverlay.m
//  GBTutorialOverlay
//
//  Created by Luka Mirosevic on 12/02/2014.
//  Copyright (c) 2014 Goonbee. All rights reserved.
//

#import "GBTutorialOverlay.h"

@implementation GBTutorialOverlay

#pragma mark - Memory

@end


@implementation GBTutorialOverlayHintProperties
@end

@implementation GBTutorialOverlayBasicHintView

-(void)setHintText:(NSString *)hintText {
    self.hintLabel.text = hintText;
}

-(NSString *)hintText {
    return self.hintLabel.text;
}

@end