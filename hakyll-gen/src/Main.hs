--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
module Main (main) where
import Control.Monad (forM_)
import Data.List (isSuffixOf)
import Data.Monoid (mappend)
import Hakyll
import System.FilePath.Posix (takeBaseName,takeDirectory,(</>))


-- Config
--------------------------------------------------------------------------------
siteName :: String
siteName = "Jakub Arbet"

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
staticAssets = [ "favicon.ico"
               , "favicon.svg"
               , "mask-icon.svg"
               , "apple-touch-icon.png"
               , "manifest.json"
               , "google-touch-icon.png"
               , "images/*"
               ]

pages :: [Identifier]
pages = [ "about.md", "contact.md" ]

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
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls
            >>= cleanIndexUrls

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "posts/*" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    create ["archive.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let archiveCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Archives"            `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls


    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let indexCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls
                >>= cleanIndexUrls

    match "templates/*" $ compile templateBodyCompiler


-- Utils
--------------------------------------------------------------------------------
postCtx :: Context String
postCtx = dateField "date" "%B %e, %Y" <> defaultContext

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

