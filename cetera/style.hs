{-# LANGUAGE OverloadedStrings #-}


----------------------------------------------------------------------- IMPORTS

import Clay hiding (yellow, orange, red, magenta, violet, blue, cyan, green)
import Data.Monoid


--------------------------------------------------------------- SOLARIZED & PHI


base03  = rgb   0  43  54 --          backgnd
base02  = rgb   7  54  66 --          hilight
base01  = rgb  88 110 117 -- emph     comment
base00  = rgb 101 123 131 -- body
base0   = rgb 131 148 150 --          body
base1   = rgb 147 161 161 -- comment  emph
base2   = rgb 238 232 213 -- hilight
base3   = rgb 253 246 227 -- backgnd
yellow  = rgb 181 137   0
orange  = rgb 203  75  22
red     = rgb 220  50  47
magenta = rgb 211  54 130
violet  = rgb 108 113 196
blue    = rgb  38 139 210
cyan    = rgb  42 161 152
green   = rgb 133 153   0

phi    n = (Prelude.**)(1.6180339887498948482)(fromInteger n)
emPhi  n = em $  phi n
emPhiN n = em $ (phi n)*(-1)


-------------------------------------------------------------------------- MAIN

main = putCss $ do
     styleCommon
     styleLayout
     styleHeadings
--     styleFigures
     styleIndices
     styleMathematics


------------------------------------------------------------------------ COMMON

{-
ol, ul
  { text-align    : justify
  ; margin-bottom : '`f -1`'em
  ; margin-left   : '`f  3`'em
  }
-}

styleCommon = do

{-
  star ? do
    color      base00
    fontSize   $ emPhi 0
    lineHeight $ emPhi 1
    fontFamily ["Old Standars TT"] [serif]
-}

  html ? do
    color      base00
    background base2
    fontSize   $ px 22
    lineHeight $ emPhi 1
    fontFamily ["Old Standard TT"] [serif]

  a # link    ? color red
  a # visited ? color yellow
  a # hover   ? color green

  "::selection" ?
    do background base03
       color      base0

  p ? do
    textAlign  justify
    textIndent (indent $ emPhi 1)
--  p |+ p ? marginTop (emPhi $ -1)
  (h5 <> h6) |+ p ? textIndent (indent $ emPhi 0)

  strong ? fontWeight bold
  "em" ? fontStyle italic

{-
  pre ?
    do fontFamily [] [monospace]
       fontSize (emPhi $ -1)
       background base2
       margin (emPhi 0)(emPhiN $ -1)(emPhi 0)(emPhiN $ -1)
-}


---------------------------------------------------------------------- HEADINGS

styleHeadings = do
  (h1 <> h2 <> h3 <> h4 <> h5 <> h6) ? do
    fontWeight bold
    lineHeight   (emPhi 0)
    marginTop    (emPhi 1)
    marginBottom (emPhi 0)
  (h1 <> h2      ) ? fontSize (emPhi 2)
  (            h3) ? fontSize (emPhi 1)
  (h4 <> h5 <> h6) ? fontSize (emPhi 0)
  h1 ? do
    -- textTransform uppercase
    textAlign (alignSide sideCenter)
  (h5 <> h6) ? do
    "margin" -:"0"
    float floatLeft
  h6 ? textIndent (indent $ emPhi 1)


------------------------------------------------------------------------ LAYOUT

styleLayout = do

  body ? do
    width        (emPhi 7)
    "margin"     -:"auto"
    marginTop    (emPhi 1)
    marginBottom (emPhi 6)
    padding      (emPhi 1)(emPhi 1)(emPhi 1)(emPhi 1)
    background base3
    header <? do
      height (emPhi 2)
      borderBottom dotted (emPhi $ -4) base2

  nav ?
    do textAlign    (alignSide sideRight)
--       borderBottom solid (emPhi $ -4) base1
--       marginBottom (emPhi 2)
  
  "#logo" ? do
    fontSize (emPhi 2)
    "font-variant"    -:"small-caps"
    float floatLeft

  "#metadata" ? do
    fontSize (emPhi $ -1)
    textAlign (alignSide sideRight)

{-
  hr ?
    do border solid (emPhi $ -4) base1
       margin (emPhi 1)(emPhi 1)(emPhi 1)(emPhi 1)
       -- oppure padding?
-}

--  header  ? tmp
--  article ? tmp
--  section ? tmp
--  where tmp = do --marginTop    (emPhi 1)
--                 marginBottom (emPhi 2)


----------------------------------------------------------------------- FIGURES

{-
styleFigures = do
  ".diagram" ?
    do display block
       textAlign (alignSide sideCenter)
       img    <? margin (emPhi $ -1)(emPhi $ -1)(emPhi $ -1)(emPhi $ -1)
  figure ?
    do margin (emPhi 0)(emPhi 0)(emPhi 0)(emPhi 0)
       figcaption <? 
         do marginTop (em $ -1)
            textAlign (alignSide sideCenter)
       object <? margin (emPhi $ -1)(emPhi $ -1)(emPhi $ -1)(emPhi $ -1)
       img    <? margin (emPhi $ -1)(emPhi $ -1)(emPhi $ -1)(emPhi $ -1)
       ".diagram" & margin (em 0)(em 0)(em 0)(em 0)
       ".left"   &
         do float floatLeft
            marginLeft  (em 0)
       ".right"  &
         do float floatRight
            marginRight (em 0)
       ".center" &
         do textAlign (alignSide sideCenter)
            star <? textAlign inherit
       ".tiny"   & object <? width (emPhi 4)
       ".small"  & object <? width (emPhi 5)
       ".medium" & object <? width (emPhi 6)
       ".big"    & object <? width (emPhi 7)
-}


------------------------------------------------------------------------- INDEX

styleIndices = do
  ".post-list" |> ul ?
    do "list-style" -: "none"
       "padding" -: "0px"
       li ?
         do paddingLeft (emPhi $ -1)
            paddingRight (emPhi $ -1)
       li # nthChild "odd" ? background base2
       li Clay.** "date" ? float floatRight
  ".tag-list" ? textAlign (alignSide sideCenter)

------------------------------------------------------------------- MATHEMATICS

styleMathematics = do
  ".display-math" ? do
    display block
    "margin"     -:"auto"
    marginTop    (emPhi $ -2)
    marginBottom (emPhi $ -2)
{-  ".definition"  # before ?
    do fontWeight bold
       content (stringContent "Definition.")
  ".theorem"     # before ?
    do fontWeight bold
       content (stringContent "Theorem.")
  ".proposition" # before ?
    do fontWeight bold
       content (stringContent "Proposition.")
  ".corollary"   # before ?
    do fontWeight bold
       content (stringContent "Corollary.")
  ".proof"       # before ?
    do fontStyle italic
       content (stringContent "Proof.")
  ".proof"       # after ?
    do float floatRight
       content (stringContent "□")
  ".remark"      # before ?
    do fontWeight bold
       content (stringContent "Remark.")
  ".proof" ?
    do marginTop  (em 0)
       textIndent (indent $ em 0)
       background base2
-}


------------------------------------------------------------------------ OTHERS

{--
    COMPATIBILITY
      noscript
    VARIOUS
      details summary abbr address
    SECTIONING
      article aside hgroup footer section hr
    OBJECTS
      audio canvas embed figcaption figure iframe img object video
    FORMATTING
      b cite i mark pre small sub sup time u em strong dfn code samp kbd var
    QUOTATIONS
      blockquote q
    LISTS
      dd dl dt li ol ul
    DOCUMENT REVISION
      del ins s
    TABLES
      caption col colgroup table tbody td tfoot th thead tr
    FORMS
      button command datalist fieldset form input keygen
      label legend optgroup option output select textarea
    SCARCELY SUPPORTED
      menu meter progress
    EXOTIC
      rp rt ruby
--}
