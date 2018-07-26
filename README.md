# [Merops](https://github.com/sho7noka/Merops)

[English](https://translate.google.com/translate?sl=ja&tl=en&u=https://github.com/sho7noka/Merops)

`Pixar USD`と`libgit`をエディタ内に組み込んだ、次世代型DCCツールの実験プロジェクトです。
USDZ export に対応する事でXR作成に適したモバイル特化型DCCツールになることを目標にしています。


## Concept
シンプル、早い、イテレーションの3軸を指針

- ジェスチャを生かした、ウィジェットレスなゲーム画面に近い使用感
- Metal2 ベースの Viewport と Modifier の実装
- [Pixar USD](https://github.com/PixarAnimationStudios/USD) と [libgit2](https://github.com/libgit2/objective-git) によるイテレーション

### Support
- [x] geometry
- [ ] animation
- [ ] layout/shot

### Not support
- lookDev
- Simulation
- Rendering

### Contribute
[Contribute](../Contribute.md) を一読ください。

## Author
[sho7noka](shosumioka@gmail.com)

### License
[BSD](../License.md) ライセンスです。


## TODO
他のソフトが気になることはよくありますが、それならMayaを使えば良いという考えの下、
統合ソフトにできない機能を積極的に実装しています。将来的にiPad Proで動くアプリケーションも目指しています。
primitive override 表示の実現、primitive override マウス選択の実現

### Editor
- [x] マウスイベントの両立
- [x] [libgit2 (commit以外)](x-source-tag://libgit)
- [x] [TextField からオブジェクトの状態を変更](x-source-tag://TextField)
- [x] [subview 3Dコントローラー](x-source-tag://addSubView) ~~[bug](https://stackoverflow.com/questions/47517902/pixel-format-error-with-scenekit-spritekit-overlay-on-iphone-x) SpriteKit で 透明 HUD の描画~~
- [ ] [point, line, face の DrawOverrideを選択オブジェクトから作る](x-source-tag://DrawOverride)
- [ ] Blender like な [Slider](https://github.com/mnmly/Swift-imgui) の実装

### Engine
- [ ] Rendererの分離
- [ ] Metal2 でテッセレーションとリダクション
- [ ] Metal2 でモディファイヤ ml/noise/lattice/edit 
- [ ] Model I/O で書き出せないgeometryとマテリアル以外を後変更
- [ ] USD 0.85 を組み込む / C++ のビルド



#### future
- intelligent shape (Swift for TensorFlow) 
- USD + Alembic の2枚構成を実現(add json)
- iPadPro compatible

http://appleengine.hatenablog.com/search?q=bitmask


### [Debug](https://developer.apple.com/videos/play/wwdc2018/608/)
先に以下の設定が必要。
`Build Settings > Produce Debuging Infomation > YES, include source code`

- [dependency viewer](https://developer.apple.com/documentation/metal/tools_profiling_and_debugging/seeing_a_frame_s_render_passes_with_the_dependency_viewer)
    - [Show Debug the Navigator] タブ > [View Frame By Call] を選択
- geometry viewer
    - [Capture GPU Frame] を押す
- shader debugger
    - [Debug Shader] > [Debug] の順で押す
- enhanced shader profiler
    - A11 を搭載した実機でのみ確認可能 
    
- `/// - Tag: TextField (x-source-tag://TextField)`
- render 内で thorows 使うと render 使えない(オーバーロード扱いされない)
- Mojave と carthage の相性悪い(秋以降の対応)


----


#### snippets

```swift
metalLayer = self.layer as? CAMetalLayer
if let drawable = metalLayer.nextDrawable() 


descriptor = MTLRenderPipelineDescriptor.init()
descriptor.depthAttachmentPixelFormat = gameView.depthPixelFormat
descriptor.stencilAttachmentPixelFormat = gameView.stencilPixelFormat
var library = device.makeDefaultLibrary()
descriptor.vertexFunction = library?.makeFunction(name: "vertexShader")
do {
try device.makeRenderPipelineState(descriptor: descriptor)
} catch {

}
```
