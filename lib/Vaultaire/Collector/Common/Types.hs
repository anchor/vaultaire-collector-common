{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Vaultaire.Collector.Common.Types where

import           Control.Applicative
import           Control.Monad.Catch
import           Control.Monad.Reader
import           Control.Monad.RWS
import           Data.Word
import           System.Log.Handler
import           System.Log.Logger

import           Marquise.Client
import           Vaultaire.Types

data CommonOpts = CommonOpts
  { optLogLevel        :: Priority
  , optNamespace       :: String
  , optNumThreads      :: Int
  , optRotateThreshold :: Word64
  , optContinueOnError :: Bool
  }

data CommonState = CommonState
  { collectorSpoolName   :: SpoolName
  , collectorSpoolFiles  :: SpoolFiles
  , collectorCache       :: SourceDictCache
  , pointsBytesWritten   :: Word64
  , contentsBytesWritten :: Word64
  }

type CollectorOpts o = (CommonOpts, o)

type CollectorState s = (CommonState, s)

newtype Collector o s m a = Collector {
    unCollector :: RWST (CollectorOpts o) () (CollectorState s) m a
} deriving (Functor, Applicative, Monad, MonadIO, MonadThrow, MonadCatch, MonadMask, MonadReader (CollectorOpts o), MonadState (CollectorState s), MonadTrans)

-- | Nervous log handler. Terminates calling process if used to handle a
--   log message of `ERROR` or greater severity.
data CrashLogHandler = CrashLogHandler

instance LogHandler CrashLogHandler where
    setLevel x _ = x
    getLevel _ = ERROR
    handle _ (p, m) _  = when (p >= ERROR) (error m)
    emit _ _ _ = return ()
    close _ = return ()
