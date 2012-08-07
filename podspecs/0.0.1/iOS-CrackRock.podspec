Pod::Spec.new do |s|
  s.name         = "iOS-CrackRock"
  s.version      = "0.0.1"

  # s.summary      = "A short description of BrynKit."
  # s.homepage     = "http://github.com/brynbellomy/BrynKit"
  # s.author       = { "Bryn Austin Bellomy" => "bryn@signals.io" }

  s.platform     = :ios, '4.3'
  s.source       = { :git => "/Users/bryn/repo/iOS-CrackRock.git", :branch => "develop" }
  s.source_files = 'iOS-CrackRock/*.{h,m}'
  s.requires_arc = true
  s.xcconfig = { 'PUBLIC_HEADERS_FOLDER_PATH' => 'include/$(TARGET_NAME)' }

  s.dependency 'BrynKit', '>= 0.0.1'
  s.dependency 'iOS-BlingLord', '>= 0.0.1'
  s.dependency 'ObjC-StatelyNotificationRobot', '>= 0.0.1'

end
