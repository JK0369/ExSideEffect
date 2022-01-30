//
//  API.swift
//  ExSideEffect
//
//  Created by 김종권 on 2022/01/30.
//

import RxSwift

enum API {
  static func signIn(
    email: String?,
    password: String?
  ) -> Observable<Int> {
    Observable.just((0...2).randomElement() ?? -1)
  }
}
