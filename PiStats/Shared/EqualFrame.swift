//
//  EqualFrame.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 02/08/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

//Credits to: https://finestructure.co/blog/2020/1/20/swiftui-equal-widths-view-constraints
import SwiftUI

struct GeometryPreferenceReader<K: PreferenceKey, V> where K.Value == V {
    let key: K.Type
    let value: (GeometryProxy) -> V
}

extension GeometryPreferenceReader: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(GeometryReader {
                Color.clear.preference(key: self.key,
                                       value: self.value($0))
            })
    }
}

protocol Preference {}

struct AppendValue<T: Preference>: PreferenceKey {
    static var defaultValue: [CGFloat] { [] }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.append(contentsOf: nextValue())
    }
    typealias Value = [CGFloat]
}

extension View {
    func assignMaxPreference<K: PreferenceKey>(
        for key: K.Type,
        to binding: Binding<CGFloat?>) -> some View where K.Value == [CGFloat] {

        return self.onPreferenceChange(key.self) { prefs in
            let maxPref = prefs.reduce(0, max)
            if maxPref > 0 {
                // only set value if > 0 to avoid pinning sizes to zero
                binding.wrappedValue = maxPref
            }
        }
    }

    func read<K: PreferenceKey, V>(_ preference: GeometryPreferenceReader<K, V>) -> some View {
        modifier(preference)
    }
}
