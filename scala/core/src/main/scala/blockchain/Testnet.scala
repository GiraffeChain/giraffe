package blockchain

import blockchain.models.{SignatureKesProduct as _, *}
import blockchain.codecs.{*, given}
import blockchain.utility.*
import blockchain.crypto.{*, given}
import cats.data.OptionT
import cats.effect.{Async, Sync}
import cats.effect.std.Random
import cats.implicits.*
import com.google.common.primitives.{Ints, Longs}
import com.google.protobuf.ByteString
import fs2.io.file.{Files, Path}
import fs2.{Chunk, Stream}

object Testnet:

  def init[F[_]: Async: Files: Random: CryptoResources](outputDir: Path, testnetString: String): F[FullBlock] =
    Async[F]
      .delay(
        testnetString.split(":") match {
          case Array("")           => (none[Long], none[List[Long]])
          case Array(timestampStr) => (timestampStr.toLong.some, none[List[Long]])
          case Array(timestampStr, stakesStr) =>
            (timestampStr.toLong.some, stakesStr.split(",").map(_.toLong).toList.some)
          case _ => throw IllegalArgumentException("Invalid testnet string")
        }
      )
      .flatMap((timestamp, stakes) => init(outputDir, timestamp, stakes))

  def init[F[_]: Async: Files: Random: CryptoResources](
      outputDir: Path,
      timestamp: Option[Timestamp] = None,
      stakes: Option[List[Long]] = None
  ): F[FullBlock] =
    for {
      timestampValue <- OptionT.fromOption[F](timestamp).getOrElseF(Async[F].realTime.map(_.toMillis))
      stakesValue = stakes.getOrElse(List(10000000L))
      accounts <- stakesValue.traverseWithIndexM((quantity, index) =>
        TestnetAccount.generate((9, 9), quantity, Longs.toByteArray(timestampValue) ++ Ints.toByteArray(index))
      )
      registrationTransactions = accounts.map(_.transaction)
      otherTransactions = List(
        Transaction()
          .withOutputs(
            List(
              TransactionOutput(lockAddress, Value(1_000_000_000L))
            )
          )
      )
      transactions = (registrationTransactions ++ otherTransactions).map(_.withEmbeddedId)
      fullBlock <- Genesis.init(timestampValue, transactions)
      dir = outputDir / fullBlock.header.id.show
      _ <- Files[F]
        .exists(dir)
        .ifM(
          ().pure[F],
          accounts.traverseWithIndexM((account, index) =>
            account.save(dir / "stakers" / index.toString)
          ) *> BlockLoading.save(dir / "genesis")(fullBlock)
        )
    } yield fullBlock

  val sk: Array[Byte] = Array.fill(32)(0)
  val vk: Array[Byte] = Array[Byte](59, 106, 39, -68, -50, -74, -92, 45, 98, -93, -88, -48, 42, 111, 13, 115, 101, 50,
    21, 119, 29, -30, 67, -90, 58, -64, 72, -95, -117, 89, -38, 41)
  val lock: Lock = Lock().withEd25519(Lock.Ed25519(ByteString.copyFrom(vk)))
  val lockAddress: LockAddress = lock.address

class TestnetAccount(
    val operatorSk: Array[Byte],
    val operatorVk: Array[Byte],
    val vrfSk: Array[Byte],
    val vrfVk: Array[Byte],
    val kesSk: SecretKeyKesProduct,
    val registrationSignature: SignatureKesProduct,
    val quantity: Long
):
  val stakingAddress =
    StakingAddress(ByteString.copyFrom(operatorVk))
  val stakingRegistration =
    StakingRegistration(registrationSignature, stakingAddress)
  val transaction =
    Transaction(
      outputs = List(
        TransactionOutput(
          Testnet.lockAddress,
          Value(quantity, AccountRegistration(Testnet.lockAddress, stakingRegistration.some).some)
        )
      )
    )
  val account =
    TransactionOutputReference(transaction.id)
  def save[F[_]: Async: Files](dir: Path): F[Unit] =
    for {
      _ <- Files[F].createDirectories(dir)
      _ <- Stream.chunk(Chunk.array(vrfSk)).through(Files[F].writeAll(dir / "vrf")).compile.drain
      _ <- Stream.chunk(Chunk.array(operatorSk)).through(Files[F].writeAll(dir / "operator")).compile.drain
      _ <- Stream.chunk(Chunk.array(account.toByteArray)).through(Files[F].writeAll(dir / "account")).compile.drain
      _ <- Stream.chunk(Chunk.array(kesSk.toByteArray)).through(Files[F].writeAll(dir / "kes")).compile.drain
    } yield ()

object TestnetAccount:
  def generate[F[_]: Sync: Random: CryptoResources](
      kesTreeHeight: (Int, Int),
      quantity: Long,
      seed: Array[Byte]
  ): F[TestnetAccount] =
    for {
      operatorSk <- CryptoResources[F].blake2b256.useSync(_.hash(seed, Array(0)))
      operatorVk <- CryptoResources[F].ed25519.useSync(_.getVerificationKey(operatorSk))
      vrfSk <- CryptoResources[F].blake2b256.useSync(_.hash(seed, Array(1)))
      vrfVk <- CryptoResources[F].ed25519VRF.useSync(_.getVerificationKey(vrfSk))
      (kesSk, kesVk) <- CryptoResources[F].blake2b256
        .useSync(_.hash(seed, Array(2)))
        .flatMap(seed => CryptoResources[F].kesProduct.useSync(_.createKeyPair(seed, kesTreeHeight, 0)))
      registrationMessageToSign <- CryptoResources[F].blake2b256.useSync(_.hash(vrfVk, operatorVk))
      registrationSignature <- CryptoResources[F].kesProduct.useSync(_.sign(kesSk, registrationMessageToSign))
      signatureIsValid <- CryptoResources[F].kesProduct.useSync(
        _.verify(registrationSignature, registrationMessageToSign, kesVk)
      )
      _ <- Sync[F].raiseWhen(!signatureIsValid)(new IllegalStateException("Signature invalid"))
    } yield new TestnetAccount(operatorSk, operatorVk, vrfSk, vrfVk, kesSk, registrationSignature, quantity)
