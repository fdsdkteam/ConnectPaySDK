Pod::Spec.new do |s|
    s.name         = 'ConnectPaySDK'
    s.version      = '1.0.10'
    s.homepage    = 'https://fiserv.com'
    s.summary      = 'ConnectPay iOS SDK for enrolling and managing a User on the ConnectPay platform'
    s.license      = { :type => 'Apache License, Version 2.0', :text => <<-LICENSE
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    LICENSE
  }
    s.author       = { 'Gershon Lev' => 'gershon.lev@fiserv.com' }
    s.source       = { :git => 'https://github.com/fdsdkteam/ConnectPaySDK_iOS.git', :tag => '1.0.10' }
    s.public_header_files = 'PaymentSDK.framework/Headers/*.h'
    s.source_files = 'PaymentSDK.framework/Headers/*.h', 'PayWithMyBank.framework/Headers/*.h', 'TMXProfiling.framework/Headers/*.h'
    s.vendored_frameworks = 'PaymentSDK.framework', 'PayWithMyBank.framework', 'TMXProfiling.framework'
    s.platform = :ios
    s.swift_version = '5.0'
    s.ios.deployment_target = '11.0'
end
