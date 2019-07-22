Pod::Spec.new do |spec|

  spec.name         = "AppPurchaseManager"
  spec.version      = "1.0.0"
  spec.summary      = "iOS 内购"
  spec.homepage     = "https://github.com/lqIphone/LQPurchaseManger"
  spec.swift_version = "4.2"
  spec.license      = "MIT"
  spec.author       = { "Quan Li" => "1083099465@qq.com" }
  spec.platform     = :ios, "9.0"
  spec.source       = { :git => "https://github.com/lqIphone/LQPurchaseManger.git", :tag => "1.0.0" }
  spec.source_files  = "LQPurchaseManger", "AppPurchaseManager.swift"
  spec.framework  = "StoreKit"
  spec.requires_arc = true
end
