use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::error::Error;

#[derive(Deserialize, Debug)]
pub struct Match {
    message: String,
    word: String,
    offset: usize,
    length: usize,
    replacements: Vec<String>,
}

#[derive(Deserialize, Debug)]
pub struct LanguageToolContext {
    text: String,
    offset: usize,
    length: usize,
}

#[derive(Deserialize, Debug)]
pub struct LanguageToolMatch {
    message: String,
    context: LanguageToolContext,
    offset: usize,
    length: usize,
    replacements: Vec<HashMap<String, String>>,
}

#[derive(Deserialize, Debug)]
pub struct LanguageToolResp {
    matches: Vec<LanguageToolMatch>,
}

#[derive(Deserialize, Debug)]
pub struct Lang {
    name: String,
    code: String,
}

#[derive(Deserialize, Debug)]
pub struct LanguageToolLang {
    name: String,
    longCode: String,
}

#[async_trait]
pub trait Server {
    fn get_check_url(&self) -> &str;
    fn get_languages_url(&self) -> &str;
    async fn parse_checked_text(
        &self,
        resp: reqwest::Response,
    ) -> Result<Vec<Match>, Box<dyn Error>>;
    async fn parse_languages(&self, resp: reqwest::Response) -> Result<Vec<Lang>, Box<dyn Error>>;

    async fn check<T: Serialize + Send>(&self, params: T) -> Result<Vec<Match>, Box<dyn Error>> {
        let client = reqwest::Client::new();
        let resp = client.post(self.get_check_url()).form(&params).send();

        let result = self.parse_checked_text(resp.await?).await?;
        Ok(result)
    }

    async fn get_languages(&self) -> Result<Vec<Lang>, Box<dyn std::error::Error>> {
        let resp = reqwest::get(self.get_languages_url());

        let result = self.parse_languages(resp.await?).await?;
        Ok(result)
    }
}

#[derive(Debug)]
pub struct LanguagueToolServer {
    base_url: String,
    check_url: String,
    languages_url: String,
}

impl LanguagueToolServer {
    pub fn new(base_url: &str) -> Self {
        let base_url = base_url.to_string();
        let check_url = format!("{}/{}", base_url, "v2/check");
        let languages_url = format!("{}/{}", base_url, "v2/languages");

        LanguagueToolServer {
            base_url,
            check_url,
            languages_url,
        }
    }
}

#[async_trait]
impl Server for LanguagueToolServer {
    fn get_check_url(&self) -> &str {
        &self.check_url
    }

    fn get_languages_url(&self) -> &str {
        &self.languages_url
    }

    async fn parse_checked_text(
        &self,
        resp: reqwest::Response,
    ) -> Result<Vec<Match>, Box<dyn std::error::Error>> {
        let map: LanguageToolResp = resp.json::<LanguageToolResp>().await?;

        let mut matches: Vec<Match> = Vec::new();

        for m in map.matches {
            matches.push(Match {
                message: m.message,
                word: m
                    .context
                    .text
                    .chars()
                    .into_iter()
                    .skip(m.context.offset)
                    .take(m.context.length)
                    .collect(),
                offset: m.offset,
                length: m.length,
                replacements: m
                    .replacements
                    .iter()
                    .map(|x| x.get("value").unwrap().to_owned())
                    .collect(),
            });
        }

        Ok(matches)
    }

    async fn parse_languages(
        &self,
        resp: reqwest::Response,
    ) -> Result<Vec<Lang>, Box<dyn std::error::Error>> {
        let langs: Vec<LanguageToolLang> = resp.json::<Vec<LanguageToolLang>>().await?;

        Ok(langs
            .into_iter()
            .map(|x| Lang {
                name: x.name,
                code: x.longCode,
            })
            .collect())
    }
}
