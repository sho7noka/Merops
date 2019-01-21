# [Merops](https://github.com/sho7noka/Merops)

[English](https://translate.google.com/translate?sl=ja&tl=en&u=https://github.com/sho7noka/Merops)(Google Translate)

Merops は `Pixar USD` と `libgit` をベースにした次世代DCCツールの実験プロジェクトです。

## Concept
シンプル、早い、イテレーションの3軸を基本に考えています。
- Metal2 ベースの Viewport と Modifier (OpenGL deprecate)
- 中ボタンを使わないウィジェットを極力排したジェスチャ、ゲーム画面に近い使用感
- [Pixar USD](https://github.com/PixarAnimationStudios/USD) と [libgit2](https://github.com/libgit2/objective-git) によるパイプライン・イテレーション

### future
- [x] geometry
- [x] scripting
- [ ] shader 

## Why?
1. 3Dソフトの操作は難しく複雑です。中ボタンクリックの多用を回避してシンプルな操作感を実現したいと考えました。
2. [macOS design](https://developer.apple.com/design/human-interface-guidelines/macos/overview/themes/) や iOS に最適化された操作を実現したDCCアプリケーションは数少ないので重点的につくります。
3. 入出力フォーマットで USDZ に対応します。XR、モバイルのコンテンツ制作に特化したツールを目標に開発を進めています。

### Author
[sho7noka](mailto:shosumioka@gmail.com)

### Contribute
[Contribute](../Contribute.md) を一読ください。

### License
[BSD](../License.md) ライセンスです。

----

## TODO
他のソフトのコンテクストを参考に実装を進めますが、Mayaのような統合ソフトを目指しません。

### Editor
- [x] マウスイベントの両立
- [x] [libgit2 (commit以外)](x-source-tag://libgit)
- [x] [TextField からオブジェクトの状態を変更](x-source-tag://TextField)
- [x] [subview 3Dコントローラー](x-source-tag://addSubView) ~~[bug](https://stackoverflow.com/questions/47517902/pixel-format-error-with-scenekit-spritekit-overlay-on-iphone-x) SpriteKit で 透明 HUD の描画~~
- [ ] [point, line, face の DrawOverrideを選択オブジェクトから作る](x-source-tag://DrawOverride) / [primitive override マウス選択の実現](https://cedil.cesa.or.jp/cedil_sessions/view/1828)  動的MSL の[Scenekit 割当で出来る](https://qiita.com/shu223/items/b5729fdf1d95721d07b7)
- [x] Blender like な [imgui Slider](https://github.com/mnmly/Swift-imgui) の実装
- [ ] 背景とグリッドを描画 /[カメラコントロールを同期](https://developer.apple.com/videos/play/wwdc2017/604/?time=789) /設定画面を表示
- [ ] PyRun_SimpleStringFlags と PyObjC の [GIL 回避](x-source-tag://gil)   [1](http://pyobjc-dev.narkive.com/EgqnPAdl/crash-with-pyobjc-1-1-when-i-call-recursively-pyrun-simplestring) [2](https://www.hardcoded.net/articles/)
- [x] [mouseEvent/TouchEvent](https://qiita.com/RichQiitaJp/items/79a52c55c9762b60f292) と Float をマルチプラットフォーム化

### Engine
- [x] [Rendererの分離](x-source-tag://engine)
- [x] [USD 0.85 を組み込む / C++ のビルド](https://github.com/mzyy94/ARKit-Live2D) / [USDKit](https://github.com/superfunc/USDKit)
- [ ] interpolation を [simdベースに変更](https://developer.apple.com/videos/play/wwdc2018/701/) 
- [ ] Metal2 でモディファイヤ テッセレーションとリダクション + ml/noise/lattice/edit 
- [ ] Model I/O で書き出せないgeometryとマテリアル以外を後変更

### Research
- WHLSL to MSL
- intelligent shape (Chainer)
- [tensorflow lite](https://medium.com/tensorflow/tensorflow-lite-now-faster-with-mobile-gpus-developer-preview-e15797e6dee7)
- [iPadPro compatible with pencil](https://developer.apple.com/videos/play/wwdc2016/220/)

## Developper 向け

```bash
python build.py
```

```bash
carthage update --verbose --no-use-binaries --use-ssh
```

https://github.com/libgit2/objective-git/blob/master/README.md


### [Debug](https://developer.apple.com/videos/play/wwdc2018/608/)

1. [スキーマ](https://cocoaengineering.com/2018/01/01/some-useful-url-schemes-in-xcode-9/)
- `/// - Tag: TextField (x-source-tag://TextField)`

2. [break point](https://qiita.com/shu223/items/1e88d19fbb31298146ca)
先に以下の設定が必要。
`Build Settings > Produce Debuging Infomation > YES, include source code`

- [Show Debug the navigator] タブの [FPS] をクリック
- [dependency viewer](https://developer.apple.com/documentation/metal/tools_profiling_and_debugging/seeing_a_frame_s_render_passes_with_the_dependency_viewer)
    - [Show Debug the Navigator] タブ > [View Frame By Call] を選択
- geometry viewer
    - [Capture GPU Frame] を押す
- shader debugger
    - [Debug Shader] > [Debug] の順で押す
- enhanced shader profiler
    - A11 を搭載した実機でのみ確認可能

3. キャプチャ、ラベル、グループ
```swift
renderCommandEncoder.label = "hoge"

// capture
MTLCaptureManager.shared().startCapture(device: device)
// ~~
MTLCaptureManager.shared().stopCapture()

// group
renderCommandEncoder.pushDebugGroup("hoge")
// ~~
renderCommandEncoder.popDebugGroup()
```

### snippets
```swift
metalLayer = self.layer as? CAMetalLayer
if let drawable = metalLayer.nextDrawable()

// https://developer.apple.com/documentation/scenekit/scnnode/1407998-hittestwithsegment
child.hitTestWithSegment(from: <#T##SCNVector3#>, to: <#T##SCNVector3#>, options: <#T##[String : Any]?#>)

func degreesToRadians(_ degrees: Float) -> Float {
return degrees * .pi / 180
}

let sceneKitVertices = vertices.map {
let cube = newNode.flattenedClone()
cube.simdPosition = SCNVector3(x: $0.x, y: $0.y, z: $0.z)
return cube
}

// scenekit で頂点作るパターン
1. ジオメトリから simd vertex position を取得する
2. cube を配置する

scene.rootNode.replaceChildNode(<#T##oldChild: SCNNode##SCNNode#>, with: <#T##SCNNode#>)

let vector:[Float] = [0,1,2,3,4,5,6,7,8,9]   
let byteLength = arr1.count*MemoryLayout<Float>.size
let buffer = metalDevice.makeBuffer(bytes: &vector, length: byteLength, options: MTLResourceOptions())
let vector2:[Float] = [10,20,30,40,50,60,70,80,90]

buffer.contents().copyBytes(from: vector2, count: vector2.count * MemoryLayout<Float>.stride)
```
