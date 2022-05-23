//
//  Styles.swift
//  MTXXBox
//
//  Created by zhangyanshen on 2022/5/6.
//

import SwiftUI

struct MenuStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .menuStyle(.borderlessButton)
            .padding(4)
            .background(.ultraThickMaterial)
            .background(Color.gray)
            .cornerRadius(2)
            .font(.title3)
    }
}
