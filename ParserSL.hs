module ParserSL where

import Lib
import Prelude hiding ((<|>), (<*>), (<$>))
import Data.Char

{- Grupo 1
   Gramática SL -}

data SL = Program String [DeclProg] [Pre] [Decl] [Inst] [Post]
        deriving Show

data Pre = Pre Boolean
         deriving (Show, Eq, Ord)

data Post = Post Boolean
         deriving (Show, Eq, Ord)

data Decl = Atr  TypeDecl String Expr
          | AtrT TypeDecl String
          | AtrS TypeDecl [Expr]
          deriving (Show , Eq , Ord)

data DeclProg = AtrProg TypeDecl String
          deriving (Show , Eq , Ord)

data TypeDecl = Int
              | Char
              | Bool
              deriving (Show , Eq , Ord)

data Inst = Assign      String Expr
          | IfThenElse  Boolean [Inst] [Inst]
          | For         Decl Boolean Expr [Inv] [Inst]
          | While       Boolean [Inv] [Inst]
          | Read        Expr
          | Print       Expr
          | Return      Expr
          deriving (Show , Eq , Ord)

data Inv = Inv Boolean
         deriving (Show, Eq, Ord)

data Expr = Const Integer
          | Var   String
          | Add   Expr Expr
          | Mul   Expr Expr
          | Div   Expr Expr
          | Sub   Expr Expr
          | Same  Expr Expr
          deriving (Show , Eq , Ord)

data Boolean = Greater    Expr Boolean
             | Less       Expr Boolean
             | And        Expr Boolean
             | Orl        Expr Boolean
             | Equal      Expr Boolean
             | Different  Expr Boolean
             | Expr       Expr
             deriving (Show , Eq , Ord)

{- Grupo 2
   Parser SL -}

parser = f <$> token' "pre" <*> pres <*> token' "program" <*> pString <*> symbol' '(' <*> declsProg <*> symbol' ')' <*> symbol' '{' <*> decls
          <*> spaces' <*> insts <*> symbol' '}' <*> token' "post" <*> posts
     where f _ a _ b _ g _ _ c _ d _ _ e = Program b g a c d e

pres = zeroOrMore pre

pre = f <$> boolean <*> symbol' ';'
    where f a _ = Pre a

posts = zeroOrMore post

post = f <$> boolean <*> symbol' ';'
        where f a _ = Post a

varios = oneOrMore vario

vario = f <$> symbol' ',' <*> expr
   where f _ s = s

decls = oneOrMore decl

decl =  f  <$> pTypeInt'  <*> pString <*> symbol' '=' <*> expr <*> symbol' ';'
    <|> g  <$> pTypeChar' <*> pString <*> symbol' '=' <*> expr <*> symbol' ';'
    <|> h  <$> pTypeBool' <*> pString <*> symbol' '=' <*> expr <*> symbol' ';'
    <|> i  <$> pTypeInt'  <*> pString <*> symbol' ';'
    <|> j  <$> pTypeChar' <*> pString <*> symbol' ';'
    <|> k  <$> pTypeBool' <*> pString <*> symbol' ';'
    <|> p1 <$> pTypeInt'  <*> expr <*> varios <*> symbol' ';'
    <|> p2 <$> pTypeChar' <*> expr <*> varios <*> symbol' ';'
    <|> p3 <$> pTypeBool' <*> expr <*> varios <*> symbol' ';'
     where f _ b _ c _ =  Atr Int b c
           g _ b _ c _ =  Atr Char b c
           h _ b _ c _ =  Atr Bool b c
           i _ b _     =  AtrT Int b
           j _ b _     =  AtrT Char b
           k _ b _     =  AtrT Bool b
           p1 _ b c _  =  AtrS Int ([b]++c)
           p2 _ b c _  =  AtrS Char ([b]++c)
           p3 _ b c _  =  AtrS Bool ([b]++c)

declsProg = oneOrMore declProg

declProg = i  <$> pTypeInt'  <*> pString <*> symbol' ';'
    <|> j  <$> pTypeChar' <*> pString <*> symbol' ';'
    <|> k  <$> pTypeBool' <*> pString <*> symbol' ';'
     where i _ b _     =  AtrProg Int b
           j _ b _     =  AtrProg Char b
           k _ b _     =  AtrProg Bool b

insts = oneOrMore inst

inst =  f  <$> token' "print"  <*> expr <*> symbol' ';'
     <|> g <$> pString <*> symbol' '=' <*> expr <*> symbol' ';'
     <|> h <$> token' "if" <*> symbol' '(' <*> boolean <*> symbol' ')' <*> token' "then" <*> symbol' '{'
         <*> insts <*> symbol' '}' <*> token' "else" <*> symbol' '{' <*> insts <*> symbol' '}'
     <|> i <$> token' "if" <*> symbol' '(' <*> boolean <*> symbol' ')' <*> token' "then" <*> symbol' '{'
         <*> insts <*> symbol' '}'
     <|> j <$> token' "return" <*> expr <*> symbol' ';'
     <|> k <$> token' "read" <*> expr <*> symbol' ';'
     <|> l <$> token' "for" <*> symbol' '(' <*> decl <*> boolean <*> symbol' ';' <*> expr <*> symbol' ')'
         <*> symbol' '{' <*> token' "inv" <*> invs <*> insts <*> symbol' '}'
     <|> m <$> token' "while" <*> symbol' '(' <*> boolean <*> symbol' ')' <*> symbol' '{' <*> token' "inv"
         <*> invs <*> insts <*> symbol' '}'
   where f _ b _ =                   Print b
         g a _ c _ =                 Assign a c
         h _ _ a _ _ _ b _ _ _ c _ = IfThenElse a b c
         i _ _ a _ _ _ b _ =         IfThenElse a b []
         j _ a _ =                   Return a
         k _ a _ =                   Read a
         l _ _ a b _ c _ _ _ d e _ = For a b c d e
         m _ _ a _ _ _ b c _ =       While a b c

invs = zeroOrMore inv

inv = f <$> boolean <*> symbol' ';'
    where f a _ = Inv a

expr = id <$> expressao
    <|> f <$> expressao <*> symbol' '*' <*> expr
    <|> g <$> expressao <*> symbol' '+' <*> expr
    <|> h <$> expressao <*> symbol' '/' <*> expr
    <|> i <$> expressao <*> symbol' '-' <*> expr
    <|> j <$> expressao <*> symbol' '=' <*> expr
  where f l _ r = Mul l r
        g l _ r = Add l r
        h l _ r = Div l r
        i l _ r = Sub l r
        j l _ r = Same l r

expressao =  f <$> pString
         <|> g <$> pInt
  where f a = Var a
        g a = Const (read a :: Integer)

boolean = (\a -> Expr a) <$> expr
        <|> (\a _ b -> Less a b)      <$> expr <*> symbol' '<' <*> boolean
        <|> (\a _ b -> Greater a b)   <$> expr <*> symbol' '>' <*> boolean
        <|> (\a _ b -> Equal a b)     <$> expr <*> token' "==" <*> boolean
        <|> (\a _ b -> Different a b) <$> expr <*> token' "!=" <*> boolean
        <|> (\a _ b -> And a b)       <$> expr <*> token' "&&" <*> boolean
        <|> (\a _ b -> Orl a b)       <$> expr <*> token' "||" <*> boolean


{- Grupo 3
   Programas Sl -}

sl1 = x
   where ((x,y):xs) = parser "pre a>c; b>c; program a (bool x; int y;){ int aux; int b; print aux; print r; } post a==5;"

sl2 = x
   where ((x,y):xs) = parser "program a { int aux;int b; if(a>e) then {print aux;} else{r=r;} }"

sl3 = x
   where ((x,y):xs) = parser "program a {int aux=4;int b=t;aux= 10;print aux; print 10+5;if(x>5) then {b=5;} else{b=6;} }"

sl4 = x
   where ((x,y):xs) = parser "pre a>c; b>c; program a (int x; int y;) {int aux=4;int b=t;aux= 10;print aux; while(a>3){ inv a>c; aux=10;print t;} print t; } post a==5;"

sl5 = x
   where ((x,y):xs) = parser "program a {int aux=4;int b=t;aux= 10;print aux; for(int a=1;a>3;a=4){aux=10;print t;}print t; }"

sl6 = x
   where ((x,y):xs) = parser "program a {int aux=4;int b=t;aux= 10;print aux; for(int a=1;a>3;a=4){while(a>4){r=t;}aux=10;print t;}print t; }"
