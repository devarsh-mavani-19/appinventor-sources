// -*- mode: swift; swift-mode:basic-offset: 2; -*-
// Copyright © 2018 Massachusetts Institute of Technology, All rights reserved.

import Foundation

class CsvParseError: Error {

}

class CsvParser {
  let input: String
  var pos: String.Index
  var line = 0
  var col = 0

  init(input: String) {
    self.input = input
    pos = input.startIndex
  }

  public func hasNext() -> Bool {
    return pos < input.endIndex
  }

  private func unquotify(cell: String) -> String {
    return cell.replacingOccurrences(of: "\"\"", with: "\"")
  }

  public func next() throws -> [String] {
    var result = [String]()
    var start = pos
    var quoted = false
    var cr = false
    var cellStart = true
    while pos < input.endIndex {
      if input[pos] == "\n" || input[pos] == "\r\n" {
        if !cr {
          if quoted {
            result.append(unquotify(cell: String(input[start..<input.index(before: pos)])))
          } else {
            result.append(unquotify(cell: String(input[start..<pos])))
          }
        }
        pos = input.index(after: pos)
        return result
      } else if cr {
        // CSV possibly has only CR line endings (classic Mac style) assume this is the end of line
        return result
      } else if input[pos] == "\r" {
        if quoted {
          result.append(unquotify(cell: String(input[start..<input.index(before: pos)])))
        } else {
          result.append(unquotify(cell: String(input[start..<pos])))
        }
        cr = true
        cellStart = true
        quoted = false
      } else if input[pos] == "," {
        if quoted {
          result.append(unquotify(cell: String(input[start..<input.index(before: pos)])))
        } else {
          result.append(unquotify(cell: String(input[start..<pos])))
        }
        cellStart = true
        quoted = false
      } else if input[pos] == "\"" {
        if cellStart {
          // Start of quoted cell
          quoted = true
          start = input.index(after: pos)
        }
        cellStart = false
      }
      pos = input.index(after: pos)
    }
    if !cr && start != pos {
      if quoted {
        result.append(unquotify(cell: String(input[start..<input.index(before: pos)])))
      } else {
        result.append(unquotify(cell: String(input[start..<pos])))
      }
    }
    return result
  }
}

@objc class CsvUtil: NSObject {
  public class func toCsvRow(_ csvRow: [Any]) -> String {
    var row = ""
    if csvRow.count == 0 {
      return row
    } else {
      row = "\"" + String(describing: csvRow[0]).replacingOccurrences(of: "\"", with: "\"\"")
      var it = csvRow.makeIterator()
      _ = it.next()
      while let o = it.next() {
        row.append("\",\"")
        row.append(String(describing: o).replacingOccurrences(of: "\"", with: "\"\""))
      }
      return row + "\""
    }
  }

  public class func toCsvTable(_ csvList: [[Any]]) -> String {
    var table = ""
    for row in csvList {
      table.append(toCsvRow(row))
      table.append("\r\n")
    }
    return table
  }

  public class func fromCsvRow(_ csvString: String) throws -> [String] {
    let parser = CsvParser(input: csvString)
    if parser.hasNext() {
      return try parser.next()
    } else {
      return [String]()
    }
  }

  public class func fromCsvTable(_ csvString: String) throws -> [[String]] {
    let parser = CsvParser(input: csvString)
    var result = [[String]]()
    while parser.hasNext() {
      result.append(try parser.next())
    }
    return result
  }
}
