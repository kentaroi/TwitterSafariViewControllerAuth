Pod::Spec.new do |s|
  s.name         = "TwitterSafariViewControllerAuth"
  s.version      = "0.1.0"
  s.summary      = "Twitter OAuth Login with Safari View Controller"
  s.description  = "TwitterSafariViewControllerAuth lets you integrate with Apple's SFSafariViewController which is safe for your users (say no to WKWebView / UIWebView). Bonus: have access to Safari credentials or use 1password like a boss."
  s.homepage     = "https://github.com/dkhamsing/TwitterSafariViewControllerAuth"
  s.license      = "MIT License"

  s.author           = { 'dkhamsing' => 'dkhamsing8@gmail.com' }
  s.social_media_url = 'http://twitter.com/dkhamsing'

  s.source       = { :git => "https://github.com/dkhamsing/TwitterSafariViewControllerAuth.git", :tag => "0.1.0" }
  s.source_files = "TwitterSafariViewControllerAuth/*.{h,m}"

  s.ios.deployment_target = "9.0"
end
