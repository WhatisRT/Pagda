module Test where

open import Data.Product
open import Data.List
open import Tactic.Defaults
open import Tactic.Derive.DecEq

data Test : Set where
  t1 t2 t3 : Test

unquoteDecl DecEq-Test = derive-DecEq ((quote Test , DecEq-Test) ∷ [])
