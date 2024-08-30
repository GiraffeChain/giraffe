package com.giraffechain.ledger

import com.giraffechain.models.FullBlockBody

trait BlockPacker[F[_]]:
  def streamed: fs2.Stream[F, FullBlockBody]
