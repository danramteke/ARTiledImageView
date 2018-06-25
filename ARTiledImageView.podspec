Pod::Spec.new do |s|
  s.name             = "ARTiledImageView"
  s.version          = "2.1"
  s.summary          = "Display, pan and deep zoom with tiled images."
  s.description      = "Display, pan and deep zoom with tiled images on iOS."
  s.homepage         = "https://github.com/danramteke/ARTiledImageView"
  s.screenshots      = "https://raw.github.com/dblock/ARTiledImageView/master/Screenshots/goya1.png", "https://raw.github.com/dblock/ARTiledImageView/master/Screenshots/goya2.png"
  s.license          = "MIT"
  s.author           = { "dblock" => "dblock@dblock.org", "orta" => "orta.therox@gmail.com" }
  s.source           = { :git => "https://github.com/danramteke/ARTiledImageView.git", :tag => s.version.to_s }
  s.platform         = :ios, '10.0'
  s.requires_arc     = true
  s.source_files     = 'Classes'
  s.frameworks       = 'Foundation', 'UIKit', 'CoreGraphics'

end
