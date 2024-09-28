package com.giraffechain.p2p

import cats.Show

case class PeerAddress(host: String, port: Int):
  override def toString: String = s"$host:$port"

object PeerAddress:
  given Show[PeerAddress] = Show.fromToString
