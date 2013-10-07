{-# LANGUAGE OverloadedStrings #-}


----------------------------------------------------------------------- IMPORTS

import Hakyll
import Hakyll.Web.Tags
import qualified Data.Map as M (lookup) 
import qualified Data.Set as S (insert)
import           Data.List     (intersperse, isSuffixOf)
import           Data.Monoid   ((<>), mconcat)
import System.Cmd            (system)
import System.FilePath       (replaceExtension, takeDirectory)
import System.FilePath.Posix (takeBaseName, takeDirectory, (</>))
import qualified Text.Blaze.Html5                as H (Html, a)
import qualified Text.Blaze.Html5.Attributes     as A (href)
import           Text.Blaze.Html                      (toHtml, toValue, (!))
import Text.Pandoc (HTMLMathMethod(..), WriterOptions(..))
import Text.Pandoc.Options

-------------------------------------------------------------------------- MAIN

main :: IO ()
main = hakyllWith hakyllConf $ do

    match "templates/*" $ do
      compile templateCompiler

    match "cetera/style.hs" $ do
      route   $ setExtension "css"
      compile $ clayCompiler

    match ("cetera/**" .&&. (complement "cetera/style.hs")) $ do
      route   idRoute
      compile copyFileCompiler

    tags    <- buildTags    "posts/*.tex" (fromCapture "tags/*.html")
    authors <- buildAuthors "posts/*.tex" (fromCapture "authors/*.html")

    let postContext = postContextWith tags authors

    match "drafts/*" $ do
      route   $ setExtension ".html"
      compile $ draftCompiler

    match "posts/*.tex" $ do
      route     niceRoute
      compile $ postCompiler postContext
      version "tex" $ do
        route     idRoute
        compile   getResourceBody
      version "pdf" $ do
        route   $ setExtension ".pdf"
        compile $ pdflatexCompiler

    create ["posts.html"] $ do
        route     niceRoute
        compile $ postListCompiler "Posts" ("posts/*.tex" .&&. hasNoVersion)

    create ["tags.html"] $ do
        route     niceRoute
        compile $ tagListCompilerWith "Tags"    (renderTagCloud 75 175) tags
    create ["authors.html"] $ do
        route     niceRoute
        compile $ tagListCompilerWith "Authors" renderTagList authors

    tagsRules tags    $ tagRule (\tag   ->("Posts tagged " ++ tag)) "content"
    tagsRules authors $ tagRule (\author->("Posts by "  ++ author)) "content"

    match (fromList ["index.markdown","about.markdown"]) $ do
      route   $ setExtension "html"
      compile $ pandoc
            >>= loadAndApplyTemplate "templates/default.html" defaultContext'
            >>= relativizeUrls >>= cleanIndexUrls

    create ["rss.xml"] $ do
        route     idRoute
        compile $ rssCompiler (codename ++ " - All posts")
                              ("posts/*.tex" .&&. hasNoVersion)
                              "content"


------------------------------------------------------------------------ ROUTES

niceRoute :: Routes
niceRoute = customRoute createIndexRoute
  where createIndexRoute id = takeDirectory p
                          </> takeBaseName p
                          </> "index.html"
          where p = toFilePath id


--------------------------------------------------------------------- COMPILERS

clayCompiler :: Compiler (Item String)
clayCompiler = getResourceString >>= withItemBody ( unixFilter "runghc" [] )

pandoc :: Compiler (Item String)
pandoc = pandocCompilerWith defaultHakyllReaderOptions hakyllWriterOpt

pdflatexCompiler :: Compiler (Item TmpFile)
pdflatexCompiler = getResourceBody >>= pdflatex

pdflatex :: Item String -> Compiler (Item TmpFile)
pdflatex item = do
    TmpFile texPath <- newTmpFile "pdflatex.tex"
    let tmpDir  = takeDirectory texPath
        pdfPath = replaceExtension texPath "pdf"
    unsafeCompiler $ do
        writeFile texPath $ itemBody item
        _ <- system $ unwords ["pdflatex",
            "-output-directory", tmpDir, texPath, ">/dev/null", "2>&1"]
        return ()
    makeItem $ TmpFile pdfPath

draftCompiler :: Compiler (Item String)
draftCompiler = pandoc
            >>= loadAndApplyTemplate "templates/post.html"    defaultContext'
            >>= loadAndApplyTemplate "templates/default.html" defaultContext'
            >>= relativizeUrls >>= cleanIndexUrls

postCompiler :: Context String -> Compiler (Item String)
postCompiler context = pandoc
            >>= saveSnapshot "content"
            >>= return . fmap demoteHeaders
            >>= loadAndApplyTemplate "templates/post.html"    context
            >>= loadAndApplyTemplate "templates/default.html" defaultContext'
            >>= relativizeUrls >>= cleanIndexUrls

postListCompiler :: String -> Pattern -> Compiler (Item String)
postListCompiler title pattern = do
            posts <- recentFirst =<< loadAll pattern
            let ctx = constField "title" title
                   <> listField "posts" defaultContext' (return posts)
                   <> defaultContext'
            makeItem ""
                >>= loadAndApplyTemplate "templates/post-list.html" ctx
                >>= loadAndApplyTemplate "templates/default.html" ctx
                >>= relativizeUrls >>= cleanIndexUrls

tagListCompilerWith :: String -> (t -> Compiler String) -> t
                              -> Compiler (Item String)
tagListCompilerWith title render tags = do
            let ctx = constField "title" title
                   <> field "tags" (\_ -> render tags)
                   <> defaultContext'
            makeItem ""
                >>= loadAndApplyTemplate "templates/tag-list.html" ctx
                >>= loadAndApplyTemplate "templates/default.html" ctx
                >>= relativizeUrls >>= cleanIndexUrls

rssCompiler :: String -> Pattern -> Snapshot -> Compiler (Item String)
rssCompiler title pattern snapshots = do
  loadAllSnapshots pattern snapshots
    >>= recentFirst
    >>= renderAtom (feedConf title) feedCtx

cleanIndexUrls :: Item String -> Compiler (Item String)
cleanIndexUrls = return . fmap (withUrls clean)
    where clean url = if ("index.html" `isSuffixOf` url )
                        then ( take (length url - 10) url )
                        else ( url )

------------------------------------------------------------------------- RULES

tagRule :: (t -> String) -> Snapshot -> t -> Pattern -> Rules ()
tagRule title snapshot = \tag pattern -> do
        route     niceRoute
        compile $ postListCompiler (title tag) pattern
        version "rss" $ do
            route   $ setExtension "xml"
            compile $ rssCompiler (title tag) pattern snapshot


---------------------------------------------------------------------- METADATA

getAuthors :: MonadMetadata m => Identifier -> m [String]
getAuthors identifier = do
    metadata <- getMetadata identifier
    return $ maybe [] (map trim . splitAll ",") $ M.lookup "authors" metadata

buildAuthors :: Pattern -> (String -> Identifier) -> Rules Tags
buildAuthors = buildTagsWith getAuthors

authorsField :: String -> Tags -> Context a
authorsField =
  tagsFieldWith getAuthors simpleRenderLink (mconcat . intersperse ", ")

simpleRenderLink :: String -> (Maybe FilePath) -> Maybe H.Html
simpleRenderLink _   Nothing         = Nothing
simpleRenderLink tag (Just filePath) =
  Just $ H.a ! A.href (toValue $ toUrl filePath) $ toHtml tag


---------------------------------------------------------------- CONFIGURATIONS

codename = "nEspresso"

hakyllConf :: Configuration
hakyllConf = defaultConfiguration
  { {-deployCommand        = "../source/deploy.sh" 
  , -}destinationDirectory = "./master"
  , storeDirectory       = "./.cache"
  , tmpDirectory         = "./.cache/tmp"
  , providerDirectory    = "./"
  }

feedConf :: String -> FeedConfiguration
feedConf title = FeedConfiguration
    { feedTitle       = title
    , feedDescription = "Feed description"
    , feedAuthorName  = "Feed author name"
    , feedAuthorEmail = "Feed author email"
    , feedRoot        = "Feed root"
    }

hakyllWriterOpt :: WriterOptions
hakyllWriterOpt = defaultHakyllWriterOptions
    { writerHtml5          = True
    , writerHTMLMathMethod = MathJax ""
    , writerExtensions     = S.insert Ext_raw_tex (writerExtensions defaultHakyllWriterOptions)
    }

---------------------------------------------------------------------- CONTEXTS


siteCtx :: Context String
siteCtx = constField "root" "http://n-espresso.github.io"
       <> constField "gaId" "google analytics id"
       <> constField "feedTitle" "Posts"
       <> constField "feedUrl" "/rss.xml"
--       <> constField "gMapsApiScript" ""
       <> defaultContext'

defaultContext' :: Context String
defaultContext' = constField "codename" "n-Espresso"
               <> defaultContext

postContextWith :: Tags -> Tags -> Context String
postContextWith tags authors = dateField      "date"    "%B %e, %Y"
                            <> tagsField      "tags"    tags
                            <> authorsField   "authors" authors
--                            <> modificationTimeField "mtime" "%U"
                            <> defaultContext'

feedCtx :: Context String
feedCtx = bodyField "description"
       <> defaultContext'


------------------------------------------------------------------------ CETERA
