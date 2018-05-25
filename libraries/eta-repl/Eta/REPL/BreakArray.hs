{-# OPTIONS_GHC -fno-warn-name-shadowing #-}
{-# LANGUAGE CPP, MagicHash, UnboxedTuples #-}

-------------------------------------------------------------------------------
--
-- (c) The University of Glasgow 2007
--
-- | Break Arrays
--
-- An array of bytes, indexed by a breakpoint number (breakpointId in Tickish)
-- There is one of these arrays per module.
--
-- Each byte is
--   1 if the corresponding breakpoint is enabled
--   0 otherwise
--
-------------------------------------------------------------------------------

module Eta.REPL.BreakArray
    (
      BreakArray
#ifdef ETA_REPL
          (BA) -- constructor is exported only for ByteCodeGen
    , newBreakArray
    , getBreak
    , setBreakOn
    , setBreakOff
    , showBreakArray
#endif
    ) where

#ifdef ETA_REPL
import Control.Monad
import Data.Word
import GHC.Word

import GHC.Exts
import GHC.IO ( IO(..) )
-- import System.IO.Unsafe ( unsafeDupablePerformIO )

data BreakArray = BA (MutableByteArray# RealWorld) Int#

breakOff, breakOn :: Word8
breakOn  = 1
breakOff = 0

showBreakArray :: BreakArray -> IO ()
showBreakArray array = do
    forM_ [0 .. (size array - 1)] $ \i -> do
        val <- readBreakArray array i
        putStr $ ' ' : show val
    putStr "\n"

setBreakOn :: BreakArray -> Int -> IO Bool
setBreakOn array index
    | safeIndex array index = do
          writeBreakArray array index breakOn
          return True
    | otherwise = return False

setBreakOff :: BreakArray -> Int -> IO Bool
setBreakOff array index
    | safeIndex array index = do
          writeBreakArray array index breakOff
          return True
    | otherwise = return False

getBreak :: BreakArray -> Int -> IO (Maybe Word8)
getBreak array index
    | safeIndex array index = do
          val <- readBreakArray array index
          return $ Just val
    | otherwise = return Nothing

safeIndex :: BreakArray -> Int -> Bool
safeIndex array index = index < size array && index >= 0

size :: BreakArray -> Int
size (BA _array sz) = I# sz

allocBA :: Int -> IO BreakArray
allocBA (I# sz) = IO $ \s1 ->
    case newByteArray# sz s1 of { (# s2, array #) -> (# s2, BA array sz #) }

-- create a new break array and initialise elements to zero
newBreakArray :: Int -> IO BreakArray
newBreakArray entries@(I# sz) = do
    ba@(BA array _) <- allocBA entries
    case breakOff of
        W8# off -> do
           let loop n | isTrue# (n ==# sz) = return ()
                      | otherwise = do writeBA# array n off; loop (n +# 1#)
           loop 0#
    return ba

writeBA# :: MutableByteArray# RealWorld -> Int# -> Word# -> IO ()
writeBA# array i word = IO $ \s ->
    case writeWord8Array# array i word s of { s -> (# s, () #) }

writeBreakArray :: BreakArray -> Int -> Word8 -> IO ()
writeBreakArray (BA array _) (I# i) (W8# word) = writeBA# array i word

readBA# :: MutableByteArray# RealWorld -> Int# -> IO Word8
readBA# array i = IO $ \s ->
    case readWord8Array# array i s of { (# s, c #) -> (# s, W8# c #) }

readBreakArray :: BreakArray -> Int -> IO Word8
readBreakArray (BA array _) (I# i) = readBA# array i
#else
data BreakArray
#endif