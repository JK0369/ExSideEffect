//
//  ViewController.swift
//  ExSideEffect
//
//  Created by 김종권 on 2022/01/30.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

class ViewController: UIViewController {
  private let emailTextField = UITextField().then {
    $0.borderStyle = .roundedRect
    $0.placeholder = "abcd@google.com"
    $0.textColor = .black
  }
  private let passwordTextField = UITextField().then {
    $0.borderStyle = .roundedRect
    $0.placeholder = "password"
    $0.isSecureTextEntry = true
  }
  private let confirmButton = UIButton().then {
    $0.setTitle("확인", for: .normal)
    $0.setTitleColor(.white, for: .normal)
    $0.setTitleColor(.blue, for: .highlighted)
    $0.setBackgroundImage(UIColor.systemBlue.asImage(), for: .normal)
    $0.setBackgroundImage(UIColor.gray.asImage(), for: .disabled)
    $0.isEnabled = false
  }
  private let resultLabel = UILabel().then {
    $0.textColor = .blue
  }
  
  private let disposeBag = DisposeBag()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view.addSubview(self.emailTextField)
    self.view.addSubview(self.confirmButton)
    self.view.addSubview(self.passwordTextField)
    self.view.addSubview(self.resultLabel)
    
    self.emailTextField.snp.makeConstraints {
      $0.top.left.equalTo(self.view.safeAreaLayoutGuide)
      $0.width.equalTo(self.view.safeAreaLayoutGuide).multipliedBy(2/3.0)
    }
    self.confirmButton.snp.makeConstraints {
      $0.top.right.equalTo(self.view.safeAreaLayoutGuide)
      $0.width.equalTo(self.view.safeAreaLayoutGuide).multipliedBy(1/3.0)
    }
    self.passwordTextField.snp.makeConstraints {
      $0.top.equalTo(self.emailTextField.snp.bottom)
      $0.left.equalTo(self.view.safeAreaLayoutGuide)
      $0.width.equalTo(self.view.safeAreaLayoutGuide).multipliedBy(2/3.0)
    }
    self.resultLabel.snp.makeConstraints {
      $0.top.equalTo(self.passwordTextField.snp.bottom).offset(12)
      $0.centerX.equalToSuperview()
    }
    
    Observable
      .combineLatest(
        self.emailTextField.rx.text,
        self.passwordTextField.rx.text
      )
      .map { $0?.count ?? 0 >= 4 && $1?.count ?? 0 >= 4 }
      .bind(to: self.confirmButton.rx.isEnabled)
      .disposed(by: self.disposeBag)
    
    self.confirmButton.rx.tap
      .withLatestFrom(
        Observable.combineLatest(
          self.emailTextField.rx.text.asObservable(),
          self.passwordTextField.rx.text.asObservable()
        )
      )
      .map {
        guard !($0 ?? "").contains("?") else { throw UserState.abuser }
        return ($0, $1)
      }
      .flatMap { API.signIn(email: $0, password: $1) }
      .map { intValue in
        switch intValue {
        case 0:
          throw UserState.block
        case 1:
          throw UserState.noUser
        default:
          break
        }
        return Void()
      }
      .catch { [weak self] error -> Observable<Void> in
        switch error {
        case UserState.abuser:
          self?.resultLabel.text = "어뷰져 유저"
        case UserState.block:
          self?.resultLabel.text = "block 유저"
        case UserState.noUser:
          self?.resultLabel.text = "회원가입이 필요한 유저"
        default:
          break
        }
        return .empty()
      }
      .do(onNext: { [weak self] in self?.resultLabel.text = "로그인 성공" })
      .subscribe()
      .disposed(by: self.disposeBag)
  }
}

extension UIColor {
  func asImage(_ width: CGFloat = UIScreen.main.bounds.width, _ height: CGFloat = 1.0) -> UIImage {
    let size: CGSize = CGSize(width: width, height: height)
    let image: UIImage = UIGraphicsImageRenderer(size: size).image { context in
      setFill()
      context.fill(CGRect(origin: .zero, size: size))
    }
    
    return image
  }
}
