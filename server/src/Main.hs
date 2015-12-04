--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings, DeriveGeneric #-}
--------------------------------------------------------------------------------

module Main where

import           Control.Concurrent.Async
  ( race_ )
import           Control.Concurrent.STM
  ( atomically
  , TChan
  , newTChan
  , readTChan
  , writeTChan )
import           Control.Monad
  ( forever )
import           Control.Monad.IO.Class
  ( liftIO )
import           Data.Aeson
  ( FromJSON )
import qualified Data.ByteString.Lazy as B
import           Data.ByteString.Char8
  ( ByteString
  , unpack )
import           GHC.Generics
  ( Generic )
import           Network.HTTP.Conduit
  ( simpleHttp )
import           Snap.Core
import           Snap.Http.Server
import           Snap.Extras.JSON
import           System.FilePath
  ( takeFileName )

--------------------------------------------------------------------------------

data File = File { file :: FilePath
                 , mod_date :: Integer
                 } deriving (Generic)
instance FromJSON File where

type Request = (ByteString, [File])

--------------------------------------------------------------------------------

main :: IO ()
main = do
    downloadQueue <- atomically newTChan
    race_ (download downloadQueue)
          (quickHttpServe $ site downloadQueue)

site :: TChan Request -> Snap ()
site q = ifTop . method POST $ do
    payload <- reqJSON
    remote <- getsRequest rqRemoteAddr
    _ <- liftIO . atomically $ writeTChan q (remote, payload)
    return ()

download :: TChan Request -> IO ()
download q = forever $ do
    (u, f) <- atomically $ do
        (ip, f) <- readTChan q
        let fileName = file f
        let url = "http://" ++ unpack ip ++ fileName
        return (url, fileName)
    putStrLn $ "Downloading " ++ f
    simpleHttp u >>= B.writeFile (takeFileName f)
    putStrLn $ "Finished " ++ f
