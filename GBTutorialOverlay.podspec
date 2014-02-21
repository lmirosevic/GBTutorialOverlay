Pod::Spec.new do |s|
  s.name         = "GBTutorialOverlay"
  s.version      = "0.1.2"
  s.summary      = "A little library to create simple but smart tutorial overlays."
  s.homepage     = "https://github.com/lmirosevic/GBTutorialOverlay"
  s.license      = 'Apache License, Version 2.0'
  s.author       = { "Luka Mirosevic" => "luka@goonbee.com" }
  s.platform     = :ios, '5.0'
  s.source       = { :git => "https://github.com/lmirosevic/GBTutorialOverlay.git", :tag => s.version.to_s }
  s.source_files  = 'GBTutorialOverlay/GBTutorialOverlay.{h,m}'
  s.public_header_files = 'GBTutorialOverlay/GBTutorialOverlay.h'
  s.resource_bundle = { 'GBTutorialOverlayResources' => ['GBTutorialOverlay/GBTutorialOverlayResources.bundle/*'] }
  s.requires_arc = true

  s.dependency 'GBStickyViews'
end
