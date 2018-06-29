//
//  ARTiledImageViewScrollView.h
//  ARTiledImageView
//
//  Created by Daniel Doubrovkine on 3/10/14.
//  Copyright (c) 2014 Artsy. All rights reserved.
//

#import "ARTiledImageViewDataSource.h"

@protocol ARScrollViewDelegate <NSObject>
-(void)arScrollView_didReceiveTapInView:(CGPoint)tapInView atMaxZoomInImage:(CGPoint)tapInImage;
-(void)arScrollView_willBeginZooming;
-(void)arScrollView_didScroll;
@end

@interface ARTiledImageScrollView : UIScrollView <UIScrollViewDelegate, UIGestureRecognizerDelegate>

//Object that receives tap information
@property (readwrite, nonatomic, weak) NSObject<ARScrollViewDelegate> *arScrollViewDelegate;

/// Current tile zoom level.
@property (nonatomic, readonly, assign) NSInteger tileZoomLevel;

/// Convert a point at full zoom scale to the same one at the current zoom scale.
- (CGPoint)zoomRelativePoint:(CGPoint)point;

/// Center image on a given point.
- (void)centerOnPoint:(CGPoint)point animated:(BOOL)animate;

/// Zoom the image to fit the current display.
- (void)zoomToFit:(BOOL)animate;

/// The data source for image.
@property (readwrite, nonatomic, weak) NSObject <ARTiledImageViewDataSource> *dataSource;

/// Display tile borders, usually for debugging purposes.
@property (readwrite, nonatomic, assign) BOOL displayTileBorders;


/// Point on which to center the map by default, removed when panned.
@property (nonatomic, assign) CGPoint centerPoint;

/// Size of the view, typically the full size of the background image.
@property (nonatomic, assign) CGSize originalSize;

/// Amount by which to zoom in or zoom out with every double-tap, default is 1.5f.
@property (nonatomic, assign) CGFloat zoomStep;

/// During a pinch zoom, default is YES.
@property (nonatomic, assign) BOOL centerOnZoomOut;

/// Exposed double tap gesture for zooming.
@property (nonatomic, strong, readonly) UITapGestureRecognizer *doubleTapGesture;

@property (nonatomic, strong, readonly) UIPanGestureRecognizer *oneFingerZoomGesture;
@property (nonatomic, assign) CGFloat oneFingerZoomFactor;
@property (nonatomic, assign) CGFloat referenceMaximumZoomScale;
@property (nonatomic, assign) CGFloat referenceMinimumZoomScale;
@property (nonatomic, assign) CGFloat bounceMaximumZoomScale;
@property (nonatomic, assign) CGFloat bounceMinimumZoomScale;

/// Automatically sets the zoom min & max for current bounds.
- (void)setMaxMinZoomScalesForCurrentBounds;


/// center point horizontally, upper third vertically
- (void)focusOnPoint:(CGPoint)point animated:(BOOL)animate;
@end


