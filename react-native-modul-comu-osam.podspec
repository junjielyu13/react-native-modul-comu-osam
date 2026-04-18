require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-modul-comu-osam"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"].to_s.empty? ? { "Barcelona City Council" => "opensource@bcn.cat" } : package["author"]
  s.platforms    = { :ios => "13.0" }
  s.source       = { :git => "https://github.com/junjielyu13/react-native-modul-comu-osam.git", :tag => "v#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,swift}"
  s.swift_version = "5.0"

  s.dependency "React-Core"
  s.dependency "OSAMCommon", "~> 3.1.0"

  # Firebase default wrappers. Consumers who want to avoid Firebase can
  # swap `OSAMConfiguration.wrappersProvider` at runtime — but these pods
  # will still be linked. To drop them entirely, fork the podspec.
  s.dependency "FirebaseAnalytics"
  s.dependency "FirebaseCrashlytics"
  s.dependency "FirebasePerformance"
  s.dependency "FirebaseMessaging"
end
