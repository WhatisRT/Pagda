-- | A drop-in @agda@ for the current pagda project, suitable as agda2-mode's
-- @agda2-program-name@. It builds the project's agda (with its dependencies)
-- via the shared 'genAgda' and execs it, so the running process IS agda and its
-- stdout carries only the interaction protocol — no nix or pagda chatter.
-- Untracked files are used and all arguments are forwarded to agda.
module Main (main) where

import System.Environment (getArgs)
import System.Posix.Process (executeFile)

import Pagda (Config (..), UseUntracked (..), genAgda)

main :: IO ()
main = do
  agdaBin <-
    genAgda
      Config
        { useUntracked = UseUntrackedTrue
        , warnUntracked = False
        , quiet = True
        }
  args <- getArgs
  executeFile agdaBin False args Nothing
