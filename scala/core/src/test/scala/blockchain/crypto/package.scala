package blockchain

package object crypto {
  extension (hexString: String)
    def hexStringToBytes: Array[Byte] =
      hexString.replaceAll("[^0-9A-Fa-f]", "").sliding(2, 2).toArray.map(Integer.parseInt(_, 16).toByte)
}
