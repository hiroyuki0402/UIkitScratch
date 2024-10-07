//
//  ViewController.swift
//  scratch
//
//  Created by SHIRAISHI HIROYUKI on 2024/10/07.
//

import UIKit

extension UIScreen {
    /// 画面サイズ
    static var screenSize: CGRect {
        guard let window = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return .zero }
        return window.screen.bounds
    }
}


class ViewController: UIViewController {

    private let screenSize: CGRect = UIScreen.screenSize

    override func viewDidLoad() {
        super.viewDidLoad()

        /// ScratchCardView
        let widthPercentage: CGFloat = 0.5
        let width = screenSize.width * widthPercentage
        let x = (screenSize.width - width) / 2
        let rect = CGRect(x: x, y: 100, width: width, height: width)
        let scratchCardView = ScratchCardView(frame: rect)
        self.view.addSubview(scratchCardView)

        /// スクラッチ完了時のクロージャ
         scratchCardView.scratchCompletionHandler = { [weak self] in
             DispatchQueue.main.async {
                 self?.showNextButton(below: scratchCardView)
             }
         }
    }
     /// ラベルを表示するメソッド
    private func showNextButton(below view: UIView) {
        /// ボタンの構築
        let button = UIButton(type: .system)
        button.setTitle("次へ", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)

        /// 背景色
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.green.cgColor, UIColor.darkGray.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientLayer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)

        /// ボタンの制約
        button.frame = CGRect(x: view.frame.minX, y: view.frame.maxY + 10, width: view.frame.width, height: 50)
        button.layer.cornerRadius = button.frame.height / 2
        button.clipsToBounds = true

        /// 背景色をボタンに追加
        button.layer.insertSublayer(gradientLayer, at: 0)

        /// ボタンのアクション
        button.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        self.view.addSubview(button)
    }

    @objc private func nextButtonTapped() {
        print("次へ")
    }

}

