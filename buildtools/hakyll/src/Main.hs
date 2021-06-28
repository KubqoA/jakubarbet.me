--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Control.Monad (forM_)
import Data.Char (isSpace)
import Data.List (dropWhileEnd, isSuffixOf)
import Data.Monoid (mappend)
import Hakyll
import System.Exit (ExitCode (ExitSuccess))
import System.FilePath.Posix (takeBaseName, takeDirectory, (</>))
import System.Process (readProcessWithExitCode)

-- Config
--------------------------------------------------------------------------------
domain, root :: String
domain = "jakubarbet.me"
root = "https://" ++ domain

config :: Configuration
config =
  defaultConfiguration
    { destinationDirectory = "dist",
      ignoreFile = const False,
      previewHost = "127.0.0.1",
      previewPort = 8000,
      providerDirectory = "src",
      storeDirectory = "buildtools/_cache",
      tmpDirectory = "buildtools/_tmp"
    }

feedConfig :: FeedConfiguration
feedConfig =
  FeedConfiguration
    { feedTitle = "Jakub Arbet",
      feedDescription = "Blog posts from my personal site",
      feedAuthorName = "Jakub Arbet",
      feedAuthorEmail = "hi@jakubarbet.me",
      feedRoot = root
    }

postsPath :: Pattern
postsPath = "posts/*"

staticAssets :: [Pattern]
staticAssets =
  [ "manifest.json",
    "assets/images/*",
    "pubkey.txt"
  ]

pages :: [Identifier]
pages = ["about.md"]

-- Compilers
--------------------------------------------------------------------------------
postCssCompiler :: Compiler (Item String)
postCssCompiler = getResourceFilePath >>= unsafeCompiler . runPostCss >>= makeItem
  where
    runPostCss file = runCommand "postcss" [file]

type FeedRender = FeedConfiguration -> Context String -> [Item String] -> Compiler (Item String)

feedCompiler :: FeedRender -> Compiler (Item String)
feedCompiler render = loadAllSnapshots postsPath "posts-content" >>= recentFirst >>= render feedConfig feedContext

-- Fields
--------------------------------------------------------------------------------
gitField :: GitInformation -> Context String
gitField information = field ("git" ++ show information) $ const $ unsafeCompiler $ getGitInformation information

estimatedReadingTimeField :: Context String
estimatedReadingTimeField = field "estimatedReadingTime" $ return . show . (`roundDiv` wordsPerMinute) . length . words . itemBody
  where
    wordsPerMinute = 200

-- Adapted from hakyll's urlField
prettyUrlField :: Context String
prettyUrlField =
  field "prettyUrl" $
    fmap (removeSuffix "/index.html" . maybe "" toUrl) . getRoute . itemIdentifier

-- Contexts
--------------------------------------------------------------------------------
baseContext :: Context String
baseContext =
  gitField Hash
    <> gitField Commit
    <> constField "root" root
    <> prettyUrlField
    <> defaultContext

postContext :: Context String
postContext =
  dateField "date" "%B %e, %Y"
    <> estimatedReadingTimeField
    <> baseContext

postList :: Context String
postList = listField "posts" postContext (recentFirst =<< loadAll postsPath)

indexes :: [(Identifier, Context String)]
indexes =
  [ ( "index.html",
      postList <> baseContext
    ),
    ( "blog.html",
      postList <> baseContext
    ),
    ( "projects.html",
      baseContext
    )
  ]

feedContext :: Context String
feedContext = baseContext

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
    compile $
      pandocCompiler
        >>= loadAndApplyTemplate "templates/default.html" baseContext
        >>= relativizeUrls
        >>= cleanIndexUrls

  match postsPath $ do
    route cleanRoute
    compile $
      pandocCompiler
        >>= loadAndApplyTemplate "templates/post.html" postContext
        >>= saveSnapshot "posts-content"
        >>= loadAndApplyTemplate "templates/default.html" postContext
        >>= relativizeUrls
        >>= cleanIndexUrls

  forM_ indexes $ \(idx, context) -> create [idx] $ do
    route cleanRoute
    compile $
      getResourceBody
        >>= applyAsTemplate context
        >>= loadAndApplyTemplate "templates/default.html" context
        >>= relativizeUrls
        >>= cleanIndexUrls

  create ["rss.xml"] $ do
    route idRoute
    compile $ feedCompiler renderRss

  create ["atom.xml"] $ do
    route idRoute
    compile $ feedCompiler renderAtom

  create ["sitemap.xml"] $ do
    route idRoute
    compile $ do
      let indexPages = filter (/= "index.html") $ map fst indexes

      posts <- recentFirst =<< loadAll postsPath
      singlePages <- loadAll (fromList $ indexPages ++ pages)

      let pages = posts <> singlePages
          siteMapContext = listField "pages" postContext (return pages) <> baseContext

      makeItem ""
        >>= loadAndApplyTemplate "templates/sitemap.xml" siteMapContext

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
    wrapFolder path = wrapper "index.html"
      where
        -- Don't create index/index.html
        wrapper = let baseName = takeBaseName path in if baseName == "index" then id else (baseName </>)

cleanIndexUrls :: Item String -> Compiler (Item String)
cleanIndexUrls = return . fmap (withUrls $ removeSuffix "/index.html")

removeSuffix :: String -> String -> String
removeSuffix suffix str =
  if suffix `isSuffixOf` str
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
getGitInformation x = rtrim <$> runCommand "git" ["log", "-1", "--format=" ++ getFormat x]

roundDiv :: Int -> Int -> Int
x `roundDiv` y = round (fromIntegral x / fromIntegral y)
