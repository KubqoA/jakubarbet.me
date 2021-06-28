--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
module Main (main) where
import Control.Monad (forM_)
import Data.Char (isSpace)
import Data.List (dropWhileEnd, isSuffixOf)
import Data.Monoid (mappend)
import qualified Data.Text as T
import Hakyll
import System.Exit (ExitCode(ExitSuccess))
import System.Process (readProcessWithExitCode)
import System.FilePath.Posix (takeBaseName,takeDirectory,(</>))


-- Config
--------------------------------------------------------------------------------
config :: Configuration
config = defaultConfiguration
    { destinationDirectory = "dist"
    , ignoreFile = const False
    , previewHost = "127.0.0.1"
    , previewPort = 8000
    , providerDirectory = "src"
    , storeDirectory = "hakyll-gen/_cache"
    , tmpDirectory = "hakyll-gen/_tmp"
    }

staticAssets :: [Pattern]
staticAssets = [ "manifest.json"
               , "assets/images/*"
               , "pubkey.txt"
               ]

pages :: [Identifier]
pages = [ "about.md" ]

-- Compilers
--------------------------------------------------------------------------------
postCssCompiler :: Compiler (Item String)
postCssCompiler = getResourceFilePath >>= unsafeCompiler . runPostCss >>= makeItem

runPostCss :: FilePath -> IO String
runPostCss file = runCommand "./node_modules/.bin/postcss" [ file ]


-- Fields
--------------------------------------------------------------------------------
gitField :: GitInformation -> Context String
gitField information = field ("git" ++ show information) $ const $ unsafeCompiler $ getGitInformation information

estimatedReadingTimeField :: Context String
estimatedReadingTimeField = field "estimatedReadingTime" $ return . show . (`roundDiv` wordsPerMinute) . length . words . itemBody
    where wordsPerMinute = 200

-- Contexts
--------------------------------------------------------------------------------
baseContext :: Context String
baseContext = gitField Hash
           <> gitField Commit
           <> defaultContext

postContext :: Context String
postContext = dateField "date" "%B %e, %Y"
           <> estimatedReadingTimeField
           <> baseContext

postsList :: Context String
postsList = listField "posts" postContext (recentFirst =<< loadAll "posts/*")

indexes :: [(Pattern, Context String)]
indexes = [ ("index.html",
             postsList <> baseContext
            )
          , ("blog.html",
             postsList <> titleField "Blog" <> baseContext
            )
          , ("projects.html",
             titleField "Projects" <> baseContext
            )
          ]


-- Main generator
--------------------------------------------------------------------------------
main :: IO ()
main = hakyllWith config $ do
    matchEach staticAssets $ do
        route idRoute
        compile copyFileCompiler

    match "assets/css/style.css" $ do
        route $ setExtension "css"
        compile postCssCompiler

    match (fromList pages) $ do
        route cleanRoute
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" baseContext
            >>= relativizeUrls
            >>= cleanIndexUrls

    match "posts/*" $ do
        route cleanRoute
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postContext
            >>= loadAndApplyTemplate "templates/default.html" postContext
            >>= relativizeUrls
            >>= cleanIndexUrls

    forM_ indexes $ \(idx, context) -> match idx $ do
        route cleanRoute
        compile $ getResourceBody
            >>= applyAsTemplate context
            >>= loadAndApplyTemplate "templates/default.html" context
            >>= relativizeUrls
            >>= cleanIndexUrls

    match "templates/*" $ compile templateBodyCompiler


-- Utils
--------------------------------------------------------------------------------
matchEach :: [Pattern] -> Rules () -> Rules ()
matchEach patterns = forM_ staticAssets . flip match

-- Inspired by: https://www.rohanjain.in/hakyll-clean-urls/
cleanRoute :: Routes
cleanRoute = customRoute $ wrapFolder . toFilePath
  where
    wrapFolder :: FilePath -> FilePath
    wrapFolder path = takeDirectory path </> wrapper </> "index.html"
      -- Don't create index/index.html
      where wrapper = let baseName = takeBaseName path in if baseName == "index" then "." else baseName

cleanIndexUrls :: Item String -> Compiler (Item String)
cleanIndexUrls = return . fmap (withUrls $ removeSuffix "index.html")

removeSuffix :: String -> String -> String
removeSuffix suffix str = if suffix `isSuffixOf` str
                             then take (length str - length suffix) str
                             else str

runCommand :: FilePath -> [String] -> IO String
runCommand cmd args = do
    (exitCode, stdout, stderr) <- readProcessWithExitCode cmd args ""
    if exitCode == ExitSuccess then return stdout else error stderr

rtrim :: String -> String
rtrim = dropWhileEnd isSpace

data GitInformation = Hash | Commit deriving (Show)

getFormat :: GitInformation -> String
getFormat Hash = "%h"
getFormat Commit = "%s"

getGitInformation :: GitInformation -> IO String
getGitInformation x = rtrim <$> runCommand "git" [ "log", "-1", "--format=" ++ getFormat x ]

roundDiv :: Int -> Int -> Int
x `roundDiv` y = round (fromIntegral x / fromIntegral y)
