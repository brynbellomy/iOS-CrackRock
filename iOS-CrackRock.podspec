Pod::Spec.new do |s|
  s.name         = "iOS-CrackRock"
  s.version      = "0.2.0"

  s.summary      = "In-app purchase helper classes."
  s.homepage     = "http://brynbellomy.github.com/iOS-CrackRock"
  s.author       = { "bryn austin bellomy" => "bryn.bellomy@gmail.com" }
  s.license      = "WTFPL"

  s.source       = { :git => "https://github.com/brynbellomy/iOS-CrackRock.git", :tag => "v#{s.version}" }
  s.source_files = "iOS-CrackRock/*.{h,m}"

  s.platform     = :ios, "5.1"
  s.requires_arc = true
  s.xcconfig = { "PUBLIC_HEADERS_FOLDER_PATH" => "include/$(TARGET_NAME)" }

  s.framework   = "StoreKit"

  s.dependency "BrynKit/Main", :local => "~/projects/BrynKit/master"
  s.dependency "BrynKit/GCDThreadsafe", :local => "~/projects/BrynKit/master"
  s.dependency "BrynKit/EDColor", :local => "~/projects/BrynKit/master"
  s.dependency "BrynKit/CocoaLumberjack", :local => "~/projects/BrynKit/master"

  s.dependency "ReactiveCocoa", ">= 1.0.0"
  s.dependency "StateMachine", :local => "~/projects/_obj-c/StateMachine"
  s.dependency "Underscore.m", ">= 0.2.0"
  s.dependency "libextobjc/EXTBlockMethod"
  s.dependency "libextobjc/EXTScope"
  s.dependency "libextobjc/EXTSynthesize"
  s.dependency "libextobjc/NSMethodSignature+EXT"


end
