//
//	FileHandle+Z.swift
//	ZKit
//
//	The MIT License (MIT)
//
//	Copyright (c) 2016 Electricwoods LLC, Kaz Yoshikawa.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy 
//	of this software and associated documentation files (the "Software"), to deal 
//	in the Software without restriction, including without limitation the rights 
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
//	copies of the Software, and to permit persons to whom the Software is 
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in 
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.
//

import Foundation

	extension FileHandle {

		func enumerateLines(_ block: @escaping (String, UnsafeMutablePointer<Bool>) -> Void) {

			// find the end of file
			var offset = self.offsetInFile
			let eof = self.seekToEndOfFile()
			self.seek(toFileOffset: offset)
			let blockSize = 1024
			var buffer = Data()

			// process to the end of file
			while offset + UInt64(buffer.count) < eof {
				var found = false

				// make sure buffer contains at least one CR, LF or null
				while !found && offset + UInt64(buffer.count) < eof {
					let block = self.readData(ofLength: blockSize)
					buffer.append(block)
					for byte in block {
						if [0x0d, 0x0a, 0x00].contains(byte) {
							found = true ; break
						}
					}
				}

				// retrieve lines within the buffer
				var index = 0
				var head = 0 // head of line
				var done = false
				buffer.enumerateBytes({ (pointer, count, stop) in
					while index < count {
						// find a line terminator
						if [0x0d, 0x0a, 0x00].contains(pointer[index]) {
							let lineData = Data(pointer[head ..< index])
							if let line = String(bytes: lineData, encoding: .utf8) {
								block(line, &stop)
								if pointer[index] == 0x0d && index+1 < count && pointer[index+1] == 0x0a {
									index += 2 ; head = index
								}
								else { index += 1 ; head = index }
								if stop { done = true ; return } // stop requested
							}
							else { return } // end of enumerateLines
						}
						else { index += 1 }
					}
				})

				offset += UInt64(head)
				buffer.replaceSubrange(0 ..< head, with: Data())
				if done { // stop requested
					self.seek(toFileOffset: offset)
					return
				}
			}
		}

}
