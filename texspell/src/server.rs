use std::collections::HashMap;
use serde::Serialize;

pub trait Server {

    fn get_check_url(&self) -> &str;
    fn get_languages_url(&self) -> &str;


    #[tokio::main]
    async fn get_text_checked<T: Serialize + ?Sized>(&self, params: &T) -> Result<reqwest::Response, Box<dyn std::error::Error>> {
        let client = reqwest::Client::new();
        let resp = client.post(self.get_check_url())
            .form(&params)
            .send()
            .await?;

        Ok(resp)
    }

    #[tokio::main]
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

    pub async fn parse_checked_text(&self, resp: reqwest::Response) -> Result<(), Box<dyn std::error::Error>> {
        let text = resp.text().await?;
        println!("{:#?}", text);
        Ok(())
    }

    //struct lol(String);

    //pub fn get_languages();

}

impl Server for LanguagueToolServer {
    fn get_check_url(&self) -> &str {
        &self.check_url
    }

    fn get_languages_url(&self) -> &str {
        &self.languages_url
    }

}
