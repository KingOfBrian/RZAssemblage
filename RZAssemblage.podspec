Pod::Spec.new do |s|
  s.name = "RZAssemblage"
  s.version = "0.4"
  s.summary = "A framework for organizing and filtering data to be bound to application views."
  s.homepage = "http://github.com/KingOfBrian/RZAssemblage"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.authors = { "Brian King" => "brianaking@gmail.com" }
  s.source = { :git => "https://github.com/KingOfBrian/RZAssemblage.git", :tag => s.version.to_s }
  s.requires_arc = true
  s.platform = :ios, '6.0'

  s.default_subspec = 'Core'

  s.subspec "Core" do |core|
    core.source_files = "RZAssemblage/**/*.{h,m}"
    core.public_header_files = "RZAssemblage/*.h"
  end

  s.subspec "UIKit" do |uikit|
    uikit.dependency "RZAssemblage/Core"
    uikit.source_files = "RZAssemblageUIKit/**/*.{h,m}"
    uikit.public_header_files = "RZAssemblageUIKit/**/*.h"
  end

end
