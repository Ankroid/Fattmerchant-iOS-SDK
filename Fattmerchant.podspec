Pod::Spec.new do |s|
  s.name = 'Fattmerchant'
  s.version = '3.0.0-beta.0'
  s.license = { :type => 'Apache License, Version 2.0', :text => "© #{ Date.today.year } Fattmerchant, inc" }
  s.summary = 'Fattmerchant iOS SDK'
  s.homepage = 'https://github.com/fattmerchantorg/Fattmerchant-iOS-SDK'
  s.authors = { 'Fattmerchant' => 'techteam@fattmerchant.com' }
  s.source = { :git => 'https://github.com/fattmerchantorg/Fattmerchant-iOS-SDK.git', :tag => s.version }

  s.ios.deployment_target = '15.0'
  s.swift_version = '5'  
  s.source_files = "FattmerchantSDK/**/*.{h,m,swift}"
  s.exclude_files = "FattmerchantSDK/ThirdParty/AnyPay/**/*.{h,m}"
  s.frameworks = 'UIKit', 'AVFoundation', 'MediaPlayer', 'CoreAudio', 'ExternalAccessory', 'CoreBluetooth', 'AudioToolbox'
  s.library = 'sqlite3'
  s.vendored_libraries = 'FattmerchantSDK/ThirdParty/ChipDnaMobile/libChipDnaMobileAPI.a', 'fattmerchant-ios-sdk/ThirdParty/ChipDnaMobile/libCardEaseXml.a', 'fattmerchant-ios-sdk/ThirdParty/ChipDnaMobile/SQLCipher/libsqlcipher-4.5.0.a'
  s.vendored_frameworks = 'FattmerchantSDK/ThirdParty/AnyPay/AnyPay.framework'

  s.pod_target_xcconfig = { 
    'ENABLE_BITCODE' => 'NO',
    'OTHER_LDFLAGS' => '-lz',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }

  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

end
