// created by musesum on 2/7/24

import Foundation

public extension Data {
    /**
     Create a new Data object from inputStream
     - Parameter reading: The input stream to read data from.
     - Note: closes input stream
     */
    init(reading input: InputStream) {

        self.init()
        input.open()
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        while input.hasBytesAvailable {
            let read = input.read(buffer, maxLength: bufferSize)
            self.append(buffer, count: read)
        }
        buffer.deallocate()
        input.close()
    }

    /**
     Consumes the specified input stream for up to `byteCount` bytes,
     creating a new Data object with its content.
     - Parameter reading: The input stream to read data from.
     - Parameter byteCount: The maximum number of bytes to read from `reading`.
     - Note: Does _not_ close the specified stream.
     */
    init(reading input: InputStream, for byteCount: Int) {
        
        self.init()
        input.open()

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: byteCount)
        let read = input.read(buffer, maxLength: byteCount)
        self.append(buffer, count: read)
        buffer.deallocate()
    }

    var bytes: [UInt8] {
        
        return [UInt8](self)
    }
}
