//
//  ScratchCardView.swift
//  scratch
//
//  Created by SHIRAISHI HIROYUKI on 2024/10/07.
//

import UIKit

class ScratchCardView: UIView {
    /// あたりの画像関連
    private var imageView: UIImageView?

    /// あたりの上に被せる画像関連
    private var maskImageView: UIImageView?
    private var maskContext: CGContext?
    private var maskImage: UIImage?

    /// スクラッチが完了したときのクロージャ
    var scratchCompletionHandler: (() -> Void)?

    /// コールバックが一度だけ呼ばれるようにするためのフラグ
    private var isThresholdReached: Bool = false

    // MARK: - ライフサイクル

    override init(frame: CGRect) {
        super.init(frame: frame)
        /// あたりの時の画像
        let scratchImage: UIImage = .scratchSecondView
        configureScratchCardView(image: scratchImage)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - メソッド

    /// スクラッチ関連構築
    /// - Parameter image: あたり画像
    private func configureScratchCardView(image: UIImage) {
        /// 背景に表示する画像
        let imageView = UIImageView(frame: self.bounds)
        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        self.addSubview(imageView)
        self.imageView = imageView

        /// マスク用のコンテキスト
        let scale = UIScreen.main.scale
        let size = CGSize(width: self.bounds.width * scale, height: self.bounds.height * scale)
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(data: nil,
                                      width: Int(size.width), height: Int(size.height),
                                      bitsPerComponent: 8, bytesPerRow: Int(size.width) * 4,
                                      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo) else { return }

        /// 座標系を反転
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)

        /// あたりの画像の上に被せるImageViewを灰色で塗りつぶす
        context.setFillColor(UIColor.lightGray.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        self.maskContext = context

        /// あたりの画像構築
        if let cgImage = maskContext?.makeImage() {
            let maskImage = UIImage(cgImage: cgImage, scale: scale, orientation: .up)
            let maskImageView = UIImageView(frame: self.bounds)
            maskImageView.image = maskImage
            self.addSubview(maskImageView)
            self.maskImageView = maskImageView
        }
    }

    // MARK: - タッチイベント

    /// タッチイベントを検知
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        scratch(touches: touches)
    }

    /// スクラッチ
    private func scratch(touches: Set<UITouch>) {
        guard let touch = touches.first,
              let maskImageView = maskImageView,
              let maskContext = maskContext else { return }

        let scale = UIScreen.main.scale
        let location = touch.location(in: maskImageView)
        let previousLocation = touch.previousLocation(in: maskImageView)

        /// 拡大縮小率を考慮した座標変換
        let adjustedLocation = CGPoint(x: location.x * scale, y: location.y * scale)
        let adjustedPreviousLocation = CGPoint(x: previousLocation.x * scale, y: previousLocation.y * scale)

        maskContext.setBlendMode(.clear)
        maskContext.setLineCap(.round)
        maskContext.setLineWidth(40.0 * scale)
        maskContext.move(to: adjustedPreviousLocation)
        maskContext.addLine(to: adjustedLocation)
        maskContext.strokePath()

        /// あたりの上のViewを更新
        if let cgImage = maskContext.makeImage() {
            let maskImage = UIImage(cgImage: cgImage, scale: scale, orientation: .up)
            maskImageView.image = maskImage
        }

        /// 削られた面積を計算
        if !isThresholdReached {
            let scratchedPercentage = calculateScratchedPercentage()
            if scratchedPercentage >= 40.0 {
                isThresholdReached = true
                scratchCompletionHandler?()
            }
        }
    }

    /// スクラッチされた面積の割合を計算(ある程度削ったら次のアクション表示させるため)
    private func calculateScratchedPercentage() -> CGFloat {
        guard let maskContext = maskContext,
              let data = maskContext.data else { return 0.0 }

        let width = Int(maskContext.width)
        let height = Int(maskContext.height)
        let bytesPerPixel = 4
        let buffer = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)

        var totalPixels = 0
        var clearPixels = 0

        /// 全体の50％の中央部分の矩形を設定
        let centerRect = CGRect(x: CGFloat(width) * 0.25, y: CGFloat(height) * 0.25, width: CGFloat(width) * 0.5, height: CGFloat(height) * 0.5)

        /// 各行のピクセルを処理
        for y in Int(centerRect.minY)..<Int(centerRect.maxY) {
            /// 各列のピクセルを処理
            for x in Int(centerRect.minX)..<Int(centerRect.maxX) {

                /// ピクセルのバッファ内のオフセットを計算
                let offset = (y * width + x) * bytesPerPixel
                let alpha = buffer[offset + 3]

                /// 総ピクセル数をカウント
                totalPixels += 1

                if alpha == 0 {
                    /// 透明なピクセル数をカウント
                    clearPixels += 1
                }
            }
        }

        /// 総ピクセル数が0の場合は0を返す
        if totalPixels == 0 {
            return 0.0
        }

        /// 削られたピクセルの割合を計算して返す
        let percentage = (CGFloat(clearPixels) / CGFloat(totalPixels)) * 100.0
        return percentage
    }
}
