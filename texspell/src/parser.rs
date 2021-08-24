use crate::lexer::Token;
use logos::Lexer;

pub fn parse(mut lexer: Lexer) {
    for token in lexer {
        match token {
            None => ()
        }
    }
}
