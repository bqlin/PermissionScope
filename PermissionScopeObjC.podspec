Pod::Spec.new do |s|

  s.name         = "PermissionScopeObjC"
  s.version      = "1.1.2"
  s.summary      = "PermissionScope 原项目 Objective-C 复刻版"

  s.description  = <<-DESC
  PermissionScope 原项目 Objective-C 复刻版。使用 Objective-C 重写了一遍 PermissionScope 库，保留了原有的接口与注释。依然可以使用原有项目的示例 Demo 调用复刻版。
                   DESC

  s.homepage     = "https://github.com/bqlin/PermissionScope-ObjC"
  s.screenshots  = "http://raquo.net/images/permissionscope.gif"

  s.license      = { :type => "MIT", :text => <<-LICENSE
    MIT License

Copyright (c) 2018

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
    LICENSE
  }

  s.author             = { "bqlin" => "bqlins@163.com" }

  s.requires_arc = true
  s.platform = :ios, "8.0"

  s.source       = { :git => "https://github.com/bqlin/PermissionScope-ObjC.git", :tag => "#{s.version}" }
  s.source_files  = "PermissionScope-ObjC/PermissionScopeObjC/PermissionScope/*.{h,m}"
  s.xcconfig = { "OTHER_LDFLAGS" => "-ObjC" }

end
