use std::collections::HashMap;
use serde::{Serialize, Deserialize};
use serde_json::Value;
use async_trait::async_trait;
use std::error::Error;

#[derive(Deserialize, Debug)]
pub struct Match {
    message: String,
    value: String,
    offset: i32,
    length: i32,
    replacements: Vec<String>,
}

pub struct LTMatch {
    message: String,
    value: String,
    offset: i32,
    length: i32,
    replacements: Vec<HashMap<String, String>>,
}

pub struct LTResp {
    matches: Vec<LTMatch>
}

#[async_trait]
pub trait Server {

    fn get_check_url(&self) -> &str;
    fn get_languages_url(&self) -> &str;
    async fn parse_checked_text(&self, resp: reqwest::Response) -> Result<Vec<Match>, Box<dyn Error>>;


    async fn check<T: Serialize + Send>(&self, params: T) -> Result<Vec<Match>, Box<dyn Error>> {
        let client = reqwest::Client::new();
        let resp = client.post(self.get_check_url())
            .form(&params)
            .send();

        let result = self.parse_checked_text(resp.await?).await?;
        Ok(result)

    }

    async fn get_languages(&self) -> Result<reqwest::Response, Box<dyn std::error::Error>> {
        let resp = reqwest::get(self.get_languages_url())
            .await?;
        Ok(resp)
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

    async fn parse_checked_text(&self, resp: reqwest::Response) -> Result<Vec<Match>, Box<dyn std::error::Error>> {
        println!("Inside parde");
        let map = resp.json::<HashMap<String, Value>>()
            .await?;

        let matches = match map.get("matches").unwrap() {
            Value::Array(a) => a,
            _ => return Ok(Vec::new()) // todo: update this
        };

        let result: Vec<Match> = Vec::new();
            
        for m in matches {
            let message = m.get("message").unwrap();
            let offset = m.get("offset").unwrap();
            let length = m.get("length").unwrap();
            let mut replacements: Vec<String> = Vec::new();
            for r in m["replacements"] {
                replacements.insert(r["value"]);
            }
            result.insert(
                Match(
                    message,
                    offset,
                    length,
                    replacements
                    )
                );

        }
        Ok(result)
    }

}
