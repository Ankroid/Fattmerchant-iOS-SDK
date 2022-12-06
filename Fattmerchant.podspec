Pod::Spec.new do |s|
  s.name = 'Fattmerchant'
  s.version = '2.3.0'
  s.license = { :type => 'Apache License, Version 2.0', :text => "© #{ Date.today.year } Fattmerchant, inc" }
  s.summary = 'Fattmerchant iOS SDK'
  s.homepage = 'https://github.com/fattmerchantorg/Fattmerchant-iOS-SDK'
  s.authors = { 'Fattmerchant' => 'techteam@fattmerchant.com' }
  s.source = { :git => 'https://github.com/fattmerchantorg/Fattmerchant-iOS-SDK.git', :tag => s.version }

  s.ios.deployment_target = '9.0'
  s.swift_versions = ['4.0', '4.2', '5.2']  
  s.source_files = "fattmerchant-ios-sdk/**/*.{h,m,swift}", "fattmerchant-ios-sdk/Vendored-Frameworks/AnyPay/**/*.{h,m}"

  s.frameworks = 'UIKit', 'AVFoundation', 'MediaPlayer', 'CoreAudio', 'ExternalAccessory', 'CoreBluetooth', 'AudioToolbox'

  s.library = 'sqlite3'

  s.vendored_libraries = 
  'fattmerchant-ios-sdk/Cardpresent/ChipDnaMobile/libChipDnaMobileAPI.a',
  'fattmerchant-ios-sdk/Cardpresent/ChipDnaMobile/libCardEaseXml.a',
  'fattmerchant-ios-sdk/Cardpresent/ChipDnaMobile/SQLCipher/libsqlcipher-4.5.0.a'
  
  s.vendored_frameworks = 'Vendored-Frameworks/AnyPay/AnyPay.framework'

  s.pod_target_xcconfig = { 
    'ENABLE_BITCODE' => 'NO',
    'OTHER_LDFLAGS' => '-lz',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }

  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

end
