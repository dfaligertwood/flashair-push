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
  ( forever
  , filterM )
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
  ( takeFileName
  , takeExtension )
import           System.Process
  ( ProcessHandle
  , spawnProcess )
import           System.Posix.Files
  ( fileExist )

--------------------------------------------------------------------------------

data File = File { file :: FilePath
                 , modDate :: Integer
                 } deriving (Generic)
instance FromJSON File where

type UploadRequests = (ByteString, [File])
type UploadRequest = (ByteString, File)

downloadExtension :: File -> Bool
downloadExtension = (== ".JPG") . takeExtension . file

onDownload :: FilePath -> IO ProcessHandle
onDownload f = spawnProcess "/usr/bin/open" ["-a LilyView", takeFileName f]

--------------------------------------------------------------------------------

main :: IO ()
main = do
    downloadQueue <- atomically newTChan
    race_ (download downloadQueue)
          (quickHttpServe $ site downloadQueue)

site :: TChan UploadRequests -> Snap ()
site q = ifTop . method POST $ do
    payload <- reqJSON
    remote <- getsRequest rqRemoteAddr
    _ <- liftIO . atomically $ writeTChan q (remote, payload)
    return ()

download :: TChan UploadRequests -> IO ()
download q = forever $
    atomically
      (do (ip, fs) <- readTChan q
          return $ zip (repeat ip) fs)
    >>= filterM selectRequests
    >>= mapM_ makeRequest
  where
    makeRequest :: UploadRequest -> IO ()
    makeRequest (ip, f) = do
      let fileName = file f
      let url = "http://" ++ unpack ip ++ fileName
      putStrLn $ "Downloading " ++ fileName
      simpleHttp url >>= B.writeFile (takeFileName fileName)
      _ <- onDownload fileName
      putStrLn $ "Finished " ++ fileName
    selectRequests :: UploadRequest -> IO Bool
    selectRequests (_, f)
      = (&& downloadExtension f)
      <$> (fileExist . takeFileName $ file f)
