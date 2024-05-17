Pod::Spec.new do |s|
  s.name             = 'ChatLayout'
  s.version          = '2.0.9'
  s.summary          = 'Chat UI Library. It uses custom UICollectionViewLayout to provide you full control over the presentation.'
  s.swift_version    = '5.8'

  s.description      = <<-DESC
ChatLayout is a Chat UI Library. It uses custom UICollectionViewLayout to provide you full control over the
presentation as well as all the tools available in UICollectionView. It supports dynamic cells and
supplementary view sizes.
                       DESC

  s.homepage         = 'https://github.com/ekazaev/ChatLayout'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Eugene Kazaev' => 'eugene.kazaev@gmail.com' }
  s.source           = { :git => 'https://github.com/ekazaev/ChatLayout.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'

  s.default_subspec = "Ultimate"

  s.subspec "Ultimate" do |complete|
      complete.dependency "ChatLayout/Core"
      complete.dependency "ChatLayout/Extras"
  end
  
  s.subspec "Core" do |core|
    core.source_files = 'ChatLayout/Classes/Core/**/*'
  end

  s.subspec "Extras" do |extras|
      extras.source_files = 'ChatLayout/Classes/Extras/**/*'
      extras.dependency "ChatLayout/Core"
  end

  s.frameworks = 'UIKit'
end
