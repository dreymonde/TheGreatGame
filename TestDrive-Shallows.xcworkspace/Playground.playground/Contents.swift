import Quartz

let url = URL(fileURLWithPath: "/Users/oleg/Downloads/Modelirovanie.pdf")
let pdf = PDFDocument(url: url)!
let string = pdf.string!
print(string)
let contains = string.contains("Абстракция данных")
let range = string.range(of: "Абстракция данных")!
print(contains)
print(range)

let rangelowered = string.index(range.lowerBound, offsetBy: -100)
let rangehighed = string.index(range.upperBound, offsetBy: +200)
let newRange = Range(uncheckedBounds: (rangelowered, rangehighed))
let sub = string.substring(with: newRange)
print(sub)

