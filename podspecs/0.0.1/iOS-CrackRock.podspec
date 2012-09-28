Pod::Spec.new do |s|
  s.name         = "iOS-CrackRock"
  s.version      = "0.0.1"

  s.summary      = "In-app purchase helper classes."
  s.homepage     = "http://brynbellomy.github.com/iOS-CrackRock"
  s.author       = { "bryn austin bellomy" => "bryn.bellomy@gmail.com" }
  s.license      = "WTFPL"

  s.source       = { :git => "https://github.com/brynbellomy/iOS-CrackRock.git", :commit => "37ff4709cc14bcf4898808f2cfb47f5fb7ddf9ba" }
  s.source_files = "iOS-CrackRock/*.{h,m}"

  s.platform     = :ios, "5.0"
  s.requires_arc = true
  s.xcconfig = { "PUBLIC_HEADERS_FOLDER_PATH" => "include/$(TARGET_NAME)" }

  s.framework   = "StoreKit"

  s.dependency "BrynKit", ">= 0.0.1"
  s.dependency "iOS-BlingLord", ">= 0.0.1"
  s.dependency "ObjC-StatelyNotificationRobot", ">= 0.0.1"

end
