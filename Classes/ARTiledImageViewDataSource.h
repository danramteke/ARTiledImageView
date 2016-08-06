//
//  ARTiledImageViewDataSource.h
//  ARTiledImageView
//
//  Created by Daniel Doubrovkine on 3/10/14.
//  Copyright (c) 2014 Artsy. All rights reserved.
//

@class ARTiledImageView;

/**
 *  An ARTiledMapView data source.
 */
@protocol ARTiledImageViewDataSource

/**
 *  Return a UIImage for a tile, if available, for example from local storage.
 *
 *  @param imageView Tiled image view.
 *  @param level     Zoom level.
 *  @param x         X coordinate of the tile.
 *  @param y         Y coordinate of the tile.
 *
 *  @return A UIImage of the tile, when available, otherwise nil.
 */
- (UIImage *)tiledImageView:(ARTiledImageView *)imageView imageTileForLevel:(NSInteger)level x:(NSInteger)x y:(NSInteger)y;

/**
 *  Tile size.
 *
 *  @param imageView Tiled image view.
 *
 *  @return CGSize of a single tile.
 */
- (CGSize)tileSizeForImageView:(ARTiledImageView *)imageView;

/**
 *  Size of the full, zoomed in, tiled image.
 *
 *  @param imageView Tiled image view.
 *
 *  @return CGSize of a full image.
 */
- (CGSize)imageSizeForImageView:(ARTiledImageView *)imageView;

/**
 *  Minimum zoom level.
 *
 *  @param imageView Tiled image view.
 *
 *  @return Minimum zoom level.
 */
- (NSInteger)minimumImageZoomLevelForImageView:(ARTiledImageView *)imageView;

/**
 *  Maximum zoom level.
 *
 *  @param imageView Tiled image view.
 *
 *  @return Maximum zoom level.
 */
- (NSInteger)maximumImageZoomLevelForImageView:(ARTiledImageView *)imageView;

@end

