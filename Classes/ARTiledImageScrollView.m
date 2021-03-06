//
//  ARTiledImageViewScrollView.m
//  ARTiledImageView
//
//  Created by Daniel Doubrovkine on 3/10/14.
//  Copyright (c) 2014 Artsy. All rights reserved.
//

#import "ARTiledImageScrollView.h"
#import "ARTiledImageView.h"
#import "ARImageBackedTiledView.h"
#import "ARTiledImageViewDataSource.h"


const CGFloat ARTiledImageScrollViewDefaultZoomStep = 1.5;
const CGFloat ARTiledImageScrollViewDefaultOneFingerZoomFactor = 1.01;

@interface ARTiledImageScrollView ()
@property (nonatomic, weak, readonly) ARImageBackedTiledView *imageBackedTiledImageView;
@end

@implementation ARTiledImageScrollView

- (void)setDataSource:(NSObject <ARTiledImageViewDataSource> *)dataSource
{
    _dataSource = dataSource;
    [self setup];
}


- (void)setup
{
    ARTiledImageView *tiledImageView = [[ARTiledImageView alloc] initWithDataSource:self.dataSource];
    
    ARImageBackedTiledView *imageBackedTileView = [[ARImageBackedTiledView alloc] initWithTiledImageView:tiledImageView];
    [self addSubview:imageBackedTileView];
    _imageBackedTiledImageView = imageBackedTileView;
    
    [self setMaxMinZoomScalesForCurrentBounds];
    
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.delegate = self;
    self.centerOnZoomOut = YES;
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    [doubleTap setNumberOfTapsRequired:2];
    [self addGestureRecognizer:doubleTap];
    _doubleTapGesture = doubleTap;
    
    UITapGestureRecognizer *twoFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerTap:)];
    [twoFingerTap setNumberOfTouchesRequired:2];
    [self addGestureRecognizer:twoFingerTap];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [singleTap setNumberOfTouchesRequired:1];
    [self addGestureRecognizer:singleTap];
    
    [self.panGestureRecognizer addTarget:self action:@selector(mapPanGestureHandler:)];
    
    UIPanGestureRecognizer *oneFingerZoom = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleOneFingerZoom:)];
    oneFingerZoom.delegate = self;
    _oneFingerZoomGesture = oneFingerZoom;
    [self addGestureRecognizer:oneFingerZoom];
    
}

- (void) handleSingleTap:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if (_arScrollViewDelegate && [_arScrollViewDelegate respondsToSelector:@selector(arScrollView_didReceiveTapInView:atMaxZoomInImage:)]) {
            CGPoint locationInScrollView = [gestureRecognizer locationInView:self];
            CGPoint locationInImage = [gestureRecognizer locationInView:_imageBackedTiledImageView];
            
            [_arScrollViewDelegate arScrollView_didReceiveTapInView:locationInScrollView atMaxZoomInImage:locationInImage];
        }
    }
}



- (void)setDisplayTileBorders:(BOOL)displayTileBorders
{
    self.tiledImageView.displayTileBorders = displayTileBorders;
    _displayTileBorders = displayTileBorders;
}


- (void)setMaxMinZoomScalesForCurrentBounds
{
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = [self.dataSource imageSizeForImageView:nil];
    
    // Calculate min/max zoomscale.
    CGFloat xScale = boundsSize.width / imageSize.width; // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / imageSize.height; // the scale needed to perfectly fit the image height-wise
    
    CGFloat minScale = 0;
    if (self.contentMode == UIViewContentModeScaleAspectFit) {
        minScale = MIN(xScale, yScale);
    } else {
        minScale = MAX(xScale, yScale);
    }
    
    CGFloat maxScale = 1.0;
    
    // Don't let minScale exceed maxScale.
    // If the image is smaller than the screen, we don't want to force it to be zoomed.
    if (minScale > maxScale) {
        minScale = maxScale;
    }
    
    self.maximumZoomScale = self.referenceMaximumZoomScale ?: maxScale * 0.6;
    self.minimumZoomScale = self.referenceMinimumZoomScale ?: minScale;

    
    self.originalSize = imageSize;
    self.contentSize = boundsSize;
}


- (void)zoomToFit:(BOOL)animate {
    [self setZoomScale:self.minimumZoomScale animated:animate];
}

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
    if (_arScrollViewDelegate) {
        [_arScrollViewDelegate arScrollView_didScroll];
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self centerContent];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {

}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    BOOL zoomedOut = self.zoomScale == self.minimumZoomScale;
    if (!CGPointEqualToPoint(self.centerPoint, CGPointZero) && !zoomedOut) {
        [self centerOnPoint:self.centerPoint animated:NO];
    }
    [self centerContent];
}

- (void)mapPanGestureHandler:(UIPanGestureRecognizer *)panGesture
{
    if (panGesture.state == UIGestureRecognizerStateBegan) {
        _centerPoint = CGPointZero;
    }
}

- (void)centerOnPoint:(CGPoint)point animated:(BOOL)animate
{
    CGFloat x = (point.x * self.zoomScale) - (self.frame.size.width / 2.0f);
    CGFloat y = (point.y * self.zoomScale) - (self.frame.size.height / 2.0f);
    [self setContentOffset:CGPointMake(round(x), round(y)) animated:animate];
    _centerPoint = point;
}

/// focus a point by centering on point horizontally, and upper third vertically
- (void)focusOnPoint:(CGPoint)point animated:(BOOL)animate
{
    CGFloat x = (point.x * self.zoomScale) - (self.frame.size.width / 2.0f);
    CGFloat y = (point.y * self.zoomScale) - (self.frame.size.height / 3.0f);
    [self setContentOffset:CGPointMake(round(x), round(y)) animated:animate];
    _centerPoint = point;
}


- (CGPoint)zoomRelativePoint:(CGPoint)point
{
    CGFloat x = (self.contentSize.width / self.originalSize.width) * point.x;
    CGFloat y = (self.contentSize.height / self.originalSize.height) * point.y;
    return CGPointMake(round(x), round(y));
}



#pragma mark - Orientation

- (void)centerContent {
    if (!self.centerOnZoomOut) { return; }
    
    CGFloat top = 0, left = 0;
    if (self.contentSize.width < self.bounds.size.width) {
        left = (self.bounds.size.width-self.contentSize.width) * 0.5f;
    }
    if (self.contentSize.height < self.bounds.size.height) {
        top = (self.bounds.size.height-self.contentSize.height) * 0.5f;
    }
    self.contentInset = UIEdgeInsetsMake(top, left, top, left);
}


#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageBackedTiledImageView;
}

-(void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    if (_arScrollViewDelegate && [_arScrollViewDelegate respondsToSelector:@selector(arScrollView_willBeginZooming)]) {
        [_arScrollViewDelegate arScrollView_willBeginZooming];
    }
}

- (CGFloat)zoomLevel
{
    return self.zoomScale / self.maximumZoomScale;
}


#pragma mark - Tap to Zoom

- (void)handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer
{
    
    if (self.zoomScale >= self.maximumZoomScale) {
        [self setZoomScale:self.maximumZoomScale animated:YES];
    } else {
        // The location tapped becomes the new center
        CGPoint tapCenter = [gestureRecognizer locationInView:self.tiledImageView];
        CGFloat newScale = MIN(self.zoomScale * (self.zoomStep ? : ARTiledImageScrollViewDefaultZoomStep), self.maximumZoomScale);
        CGRect maxZoomRect = [self rectAroundPoint:tapCenter atZoomScale:newScale];
        [self zoomToRect:maxZoomRect animated:YES];
    }
}


- (CGRect)rectAroundPoint:(CGPoint)point atZoomScale:(CGFloat)zoomScale
{
    // Define the shape of the zoom rect.
    CGSize boundsSize = self.bounds.size;
    
    // Modify the size according to the requested zoom level.
    // For example, if we're zooming in to 0.5 zoom, then this will increase the bounds size by a factor of two.
    CGSize scaledBoundsSize = CGSizeMake(boundsSize.width / zoomScale, boundsSize.height / zoomScale);
    
    return CGRectMake(point.x - scaledBoundsSize.width / 2,
                      point.y - scaledBoundsSize.height / 2,
                      scaledBoundsSize.width,
                      scaledBoundsSize.height);
}


- (void)handleTwoFingerTap:(UIGestureRecognizer *)gestureRecognizer
{
    CGFloat newScale = self.zoomScale <= self.minimumZoomScale ? self.minimumZoomScale : self.zoomScale / (self.zoomStep ? : ARTiledImageScrollViewDefaultZoomStep);
    [self setZoomScale:newScale animated:YES];
}

#pragma mark -
#pragma mark one finger zoom

- (void)handleOneFingerZoom:(UIPanGestureRecognizer *)gestureRecognizer {
    CGFloat localOneFingerZoomFactor = self.oneFingerZoomFactor ? : ARTiledImageScrollViewDefaultOneFingerZoomFactor;
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        //Set initial translation to reflect the current zoomScale
        
        CGFloat logZoom = log(self.zoomScale) / log(localOneFingerZoomFactor);
        [gestureRecognizer setTranslation: CGPointMake(0, logZoom) inView: gestureRecognizer.view];
    } else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        CGFloat logZoom = [gestureRecognizer translationInView: gestureRecognizer.view].y;
        CGFloat t = pow(localOneFingerZoomFactor, logZoom);
        
        if (_arScrollViewDelegate && [_arScrollViewDelegate respondsToSelector:@selector(arScrollView_willBeginZooming)]) {
            [_arScrollViewDelegate arScrollView_willBeginZooming];
        }
        
        if (t > self.referenceMaximumZoomScale && t <= self.bounceMaximumZoomScale) {
            self.maximumZoomScale = t;
            self.zoomScale = t;
        } else if (t < self.referenceMinimumZoomScale && t >= self.bounceMinimumZoomScale) {
            self.minimumZoomScale = t;
            self.zoomScale = t;
        } else {
            self.zoomScale = t;
        }
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {

        if (self.zoomScale > self.referenceMaximumZoomScale) {
            [self setZoomScale:self.referenceMaximumZoomScale animated:true];
        } else if (self.zoomScale < self.referenceMinimumZoomScale) {
            [self setZoomScale:self.referenceMinimumZoomScale animated:true];
        }
        
        self.maximumZoomScale = self.referenceMaximumZoomScale;
        self.minimumZoomScale = self.referenceMinimumZoomScale;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer == _oneFingerZoomGesture) {
        return touch.tapCount == 2;
    } else {
        return true;
    }
}

#pragma mark -

- (ARTiledImageView *)tiledImageView
{
    return self.imageBackedTiledImageView.tiledImageView;
}


- (UIImageView *)backgroundImageView
{
    return self.imageBackedTiledImageView.imageView;
}


@end
