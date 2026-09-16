#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'adyen_checkout'
  s.version          = '0.1.0'
  s.summary          = 'Config-driven Adyen Sessions Flutter plugin.'
  s.description      = <<-DESC
Config-driven Flutter plugin for Adyen Sessions card, Google Pay, and Apple Pay.
                       DESC
  s.homepage         = 'https://example.com/adyen_checkout'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'adyen_checkout' => 'dev@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'adyen_checkout/Sources/adyen_checkout/**/*'
  s.dependency 'Flutter'
  s.dependency 'Adyen', '~> 5.22.2'
  s.dependency 'Adyen/Card', '~> 5.22.2'
  s.dependency 'Adyen/Actions', '~> 5.22.2'
  s.dependency 'Adyen/Session', '~> 5.22.2'
  s.platform = :ios, '13.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
