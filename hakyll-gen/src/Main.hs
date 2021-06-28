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

wordsPerMinute :: Int
wordsPerMinute = 200

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

-- Main generator
--------------------------------------------------------------------------------
main :: IO ()
main = hakyllWith config $ do
    matchEach staticAssets $ do
        route idRoute
        compile copyFileCompiler

    match (fromList pages) $ do
        route cleanRoute
        compile
            $   pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" baseContext
            >>= relativizeUrls
            >>= cleanIndexUrls

    match "assets/css/style.css" $ do
        route $ setExtension "css"
        compile postCssCompiler

    match "posts/*" $ do
        route cleanRoute
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postContext
            >>= loadAndApplyTemplate "templates/default.html" postContext
            >>= relativizeUrls

    create ["blog.html"] $ do
        route cleanRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let archiveCtx =
                    listField "posts" postContext (return posts)
                 <> constField "title" "Blog"
                 <> baseContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/blog.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls


    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let indexCtx =
                    listField "posts" postContext (return posts) `mappend`
                    baseContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
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
    wrapFolder path = takeDirectory path </> takeBaseName path </> "index.html"

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
