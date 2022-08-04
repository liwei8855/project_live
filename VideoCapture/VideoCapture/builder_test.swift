//
//  builder_test.swift
//  VideoCapture
//
//  Created by 李威 on 2022/8/2.
//

import Foundation

protocol Drawable {
    func draw() -> String
}

struct Line: Drawable {
    func draw() -> String {
        return elements.map { $0.draw() }.joined(separator: "")
    }
    var elements: [Drawable]
}

struct Space: Drawable {
    func draw() -> String {
        return " "
    }
}

struct Text: Drawable {
    func draw() -> String {
        return content
    }
    init(_ content: String) {
        self.content = content
    }
    var content: String
}

struct Stars: Drawable {
    func draw() -> String {
        return String(repeating: "*", count: length)
    }
    
    var length: Int
}

struct AllCaps: Drawable {
    func draw() -> String {
        content.draw().uppercased()
    }
    var content: Drawable
}

let name: String? = "Ravi Patel"
let manualDrawing = Line(elements: [
    Stars(length: 3),
    Text("Hello"),
    Space(),
    AllCaps(content: Text((name ?? "World") + "!")),
    Stars(length: 2)
])

//print(manualDrawing.draw())
