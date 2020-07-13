Pod::Spec.new do |s|
  s.name             = 'ChatLayout'
  s.version          = '0.1.0'
  s.summary          = 'Custom UICollectionViewLayout to support a Chat0like layout of the cells.'

  s.description      = <<-DESC
    Custom UICollectionViewLayout to support a Chat0like layout of the cells.
                       DESC

  s.homepage         = 'https://github.com/Eugene Kazaev/ChatLayout'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Eugene Kazaev' => 'eugene.kazaev@gmail.com' }
  s.source           = { :git => 'https://github.com/Eugene Kazaev/ChatLayout.git', :tag => s.version.to_s }

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

  s.frameworks = 'UIKit'
end
