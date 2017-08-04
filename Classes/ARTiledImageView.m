//
//  ARTiledImageViewView.m
//  ARTiledImageView
//
//  Created by Orta Therox on 2014/01/29.
//  Copyright (c) 2014 Artsy. All rights reserved.
//

#import "ARTiledImageView.h"
#import "ARTile.h"
#import <QuartzCore/CATiledLayer.h>


// ARTiledImageView responds to rectangle repaint, figures out which tile
// to download from that rectangle and downloads tiles asynchronously.


@interface ARTiledImageView ()
@property (nonatomic, assign) NSInteger maxLevelOfDetail;
@property (atomic, strong, readonly) NSCache *tileCache;

@property (nonatomic, assign) CGSize ios11_tileSize;
@property (nonatomic, assign) CGRect ios11_bounds;
@end

@implementation ARTiledImageView

- (id)initWithDataSource:(NSObject <ARTiledImageViewDataSource> *)dataSource
{
    return [self initWithDataSource:dataSource minimumSize:CGSizeZero];
}

- (id)initWithDataSource:(NSObject <ARTiledImageViewDataSource> *)dataSource minimumSize:(CGSize)minimumSize
{
    self = [super init];
    if (!self) return nil;

    self.backgroundColor = [UIColor clearColor];
    _dataSource = dataSource;

    CATiledLayer *layer = (id) [self layer];
    layer.tileSize = [_dataSource tileSizeForImageView:self];
    _ios11_tileSize = layer.tileSize;
    
    NSInteger min = [_dataSource minimumImageZoomLevelForImageView:self];
    NSInteger max = [_dataSource maximumImageZoomLevelForImageView:self];
    layer.levelsOfDetail = max - min + 1;

    self.maxLevelOfDetail = max;

    CGSize imageSize = [dataSource imageSizeForImageView:self];
    // It's possible the image will be smaller than our minimum size.
    imageSize.width = MAX(imageSize.width, minimumSize.width);
    imageSize.height = MAX(imageSize.height, minimumSize.height);
    self.frame = CGRectMake(0, 0, imageSize.width, imageSize.height);

    _tileCache = [[NSCache alloc] init];

    

    return self;
}


-(void)layoutSubviews {
    [super layoutSubviews];
    
    _ios11_bounds = self.bounds;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    //
    // See http://openradar.appspot.com/8503490
    // Get the scale from the context by getting the current transform matrix, then asking for its "a" component, which is one of the two scale components.
    // We need to also ask for the "d" component as it might not be precisely the same as the "a" component, even at the "same" scale.
    //

    CGFloat _scaleX = CGContextGetCTM(context).a;
    CGFloat _scaleY = CGContextGetCTM(context).d;

    CGSize tileSize = _ios11_tileSize;

    //
    // Even at scales lower than 100%, we are drawing into a rect in the coordinate system of the full
    // image. One tile at 50% covers the width (in original image coordinates) of two tiles at 100%.
    // So at 50% we need to stretch our tiles to double the width and height; at 25% we need to stretch
    // them to quadruple the width and height; and so on.
    //
    // (Note that this means that we are drawing very blurry images as the scale gets low. At 12.5%,
    // our lowest scale, we are stretching about 6 small tiles to fill the entire original image area.
    // But this is okay, because the big blurry image we're drawing here will be scaled way down before
    // it is displayed.)
    //

    tileSize.width /= _scaleX;
    tileSize.height /= -_scaleY;

    NSInteger firstCol = floor(CGRectGetMinX(rect) / tileSize.width);
    NSInteger lastCol = floor((CGRectGetMaxX(rect) - 1) / tileSize.width);
    NSInteger firstRow = floorf(CGRectGetMinY(rect) / tileSize.height);
    NSInteger lastRow = floorf((CGRectGetMaxY(rect) - 1) / tileSize.height);

    NSInteger level = self.maxLevelOfDetail + roundf(log2f(_scaleX));
    _currentZoomLevel = level;

    
    
    
    for (NSInteger row = firstRow; row <= lastRow; row++) {
        for (NSInteger col = firstCol; col <= lastCol; col++) {

            CGRect tileRect = CGRectMake(tileSize.width * col, tileSize.height * row, tileSize.width, tileSize.height);
            UIImage *tileImage = [self.dataSource tiledImageView:self imageTileForLevel:level x:col y:row];

            NSString *tileCacheKey = [NSString stringWithFormat:@"%@/%@_%@", @(level), @(col), @(row)];
            ARTile *tile = [self.tileCache objectForKey:tileCacheKey];
            if (!tile) {
                tileRect = CGRectIntersection(_ios11_bounds, tileRect);
                tile = [[ARTile alloc] initWithImage:tileImage rect:tileRect];
                [self.tileCache setObject:tile forKey:tileCacheKey cost:level];
            }

            if (!tile.tileImage && tileImage) {
                tile.tileImage = tileImage;
            }

            if (!tile.tileImage) {

            } else {
                [tile drawInRect:tile.tileRect blendMode:kCGBlendModeNormal alpha:1];
                if (self.displayTileBorders) {
                    [[UIColor greenColor] set];
                    CGContextSetLineWidth(context, 6.0);
                    CGContextStrokeRect(context, tileRect);
                }
            }
        }
    }

}


+ (Class)layerClass
{
    return [CATiledLayer class];
}


- (void)setContentScaleFactor:(CGFloat)contentScaleFactor
{
    // Make retina perform as expected
    [super setContentScaleFactor:1.f];
}


- (void)dealloc
{
    
    [_tileCache removeAllObjects];
}




@end
