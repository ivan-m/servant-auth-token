{-|
Module      : Servant.Server.Auth.Token.Config
Description : Configuration of auth server
Copyright   : (c) Anton Gushcha, 2016
License     : MIT
Maintainer  : ncrashed@gmail.com
Stability   : experimental
Portability : Portable
-}
module Servant.Server.Auth.Token.Config(
    AuthConfig(..)
  , defaultAuthConfig
  ) where 

import Control.Monad.IO.Class 
import Data.Text (Text)
import Data.Time 
import Data.UUID
import Data.UUID.V4
import Database.Persist.Sql 
import Servant.Server 

import Servant.API.Auth.Token 

-- | Configuration specific for authorisation system
data AuthConfig = AuthConfig {
  -- | Get database connection pool
    getPool :: ConnectionPool
  -- | For authorisation, defines amounts of seconds
  -- when token becomes invalid.
  , defaultExpire :: !NominalDiffTime
  -- | For password restore, defines amounts of seconds
  -- when restore code becomes invalid.
  , restoreExpire :: !NominalDiffTime
  -- | User specified implementation of restore code sending. It could
  -- be a email sender or SMS message or mobile application method, whatever
  -- the implementation needs.
  , restoreCodeSender :: !(RespUserInfo -> RestoreCode -> IO ())
  -- | User specified generator for restore codes. By default the server
  -- generates UUID that can be unacceptable for SMS restoration routine.
  , restoreCodeGenerator :: !(IO RestoreCode)
  -- | Upper bound of expiration time that user can request
  -- for a token.
  , maximumExpire :: !(Maybe NominalDiffTime)
  -- | For authorisation, defines amount of hashing
  -- of new user passwords (should be greater or equal 14).
  -- The passwords hashed 2^strength times. It is needed to 
  -- prevent almost all kinds of brute force attacks, rainbow
  -- tables and dictionary attacks.
  , passwordsStrength :: !Int
  -- | Validates user password at registration / password change.
  -- 
  -- If the function returns 'Just', then a 400 error is raised with
  -- specified text.
  --
  -- Default value doesn't validate passwords at all.
  , passwordValidator :: !(Text -> Maybe Text)
  -- | Transformation of errors produced by the auth server
  , servantErrorFormer :: !(ServantErr -> ServantErr)
  -- | Default size of page for pagination
  , defaultPageSize :: !Word 
  }

-- | Default configuration for authorisation server
defaultAuthConfig :: ConnectionPool -> AuthConfig 
defaultAuthConfig pool = AuthConfig {
    getPool = pool
  , defaultExpire = fromIntegral (600 :: Int)
  , restoreExpire = fromIntegral (3*24*3600 :: Int) -- 3 days
  , restoreCodeSender = const $ const $ return ()
  , restoreCodeGenerator = uuidCodeGenerate
  , maximumExpire = Nothing
  , passwordsStrength = 17
  , passwordValidator = const Nothing
  , servantErrorFormer = id
  , defaultPageSize = 50
  }

-- | Default generator of restore codes
uuidCodeGenerate :: IO RestoreCode
uuidCodeGenerate = toText <$> liftIO nextRandom