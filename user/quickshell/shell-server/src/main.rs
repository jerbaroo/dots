use axum::{extract::{Path, State}, Router};
use axum::routing as routing;
use freedesktop_entry_parser as Desktop;
use fuzzy_matcher::FuzzyMatcher;
use fuzzy_matcher::skim::SkimMatcherV2;
use serde::Serialize;
use serde_json;
use std::env;
use std::path::{PathBuf};
use std::sync::{Arc, Mutex};
use walkdir::WalkDir;

#[derive(Eq, Ord, PartialEq, PartialOrd, Serialize)]
pub struct App {
    pub name: String,
    pub exec: String,
    pub comment: Option<String>,
    pub icon: Option<String>,
}

enum Level {
    Debug,
    Error,
    #[allow(dead_code)]
    Info,
}

fn background_refresh(cache: Arc<Mutex<Option<Vec<Desktop::Section>>>>) {
    tokio::spawn(async move {
        match get_desktop_entries() {
            Ok(entries) => {
                match cache.lock() {
                    Ok(mut guard) => *guard = Some(entries),
                    Err(err) => log(Level::Error, &err.to_string())
                }
            },
            Err(err) => log(Level::Error, &err)
        }
    });
}

pub fn filter_sections(sections: Vec<Desktop::Section>, query: String) -> Vec<Desktop::Section> {
    let matcher = SkimMatcherV2::default();
    let mut scored_matches: Vec<(i64, Desktop::Section)> = Vec::new();
    for section in sections {
        if let Some(app_name) = section.attr("Name").get(0) {
            if query.is_empty() {
                scored_matches.push((0, section));
            } else if let Some(score) = matcher.fuzzy_match(app_name, &query) {
                scored_matches.push((score, section));
            }
        }
    }
    scored_matches.sort_by(|a, b| b.0.cmp(&a.0));
    scored_matches.into_iter().map(|(_score, section)| section).collect()
}

fn get_application_dirs() -> Result<Vec<PathBuf>, String> {
    let xdg_data_dirs = env::var("XDG_DATA_DIRS").map_err(|e| e.to_string())?;
    let paths = env::split_paths(&xdg_data_dirs)
        .map(|dir| dir.join("applications"))
        .collect();
    Ok(paths)
}

fn get_application_paths() -> Result<Vec<PathBuf>, String> {
    let dirs = get_application_dirs()?;
    let mut paths = Vec::new();
    for r_entry in dirs.iter().map(WalkDir::new).flatten() {
        match r_entry {
            Ok(entry) => {
                let path = entry.path();
                if path.extension().map_or(false, |ext| ext == "desktop") {
                    paths.push(path.to_path_buf());
                } else {
                    log(Level::Debug, &format!("Doesn't match {entry:?}"));
                }
            }
            Err(err) => {
                log(Level::Error, &err.to_string())
            }
        }
    }
    Ok(paths)
}

fn get_desktop_entries() -> Result<Vec<Desktop::Section>, String> {
    let application_paths = get_application_paths()?;
    let mut sections = Vec::new();
    for application_path in application_paths {
        let entry = Desktop::Entry::parse_file(&application_path)
            .map_err(|err| err.to_string())?;
        match entry.section("Desktop Entry") {
            None => log(Level::Error, &format!("No Desktop Entry in {application_path:?}")),
            Some(section) => sections.push(section.clone()),
        }
    }
    Ok(sections)
}

fn log(level: Level, message: &str) -> () {
    match level {
        Level::Debug => println!{"DBUG: {message}"},
        Level::Error => eprintln!{"EROR: {message}"},
        Level::Info => println!{"INFO: {message}"},
    }
}

#[tokio::main]
async fn main() {
    let cache: Arc<Mutex<Option<Vec<Desktop::Section>>>> = Arc::new(Mutex::new(None));
    background_refresh(Arc::clone(&cache));
    let app = Router::new().route(
        "/apps/search/{query}",
        routing::get(|Path(query): Path<String>, State(cache): State<Arc<Mutex<Option<Vec<Desktop::Section>>>>>| async move {
            background_refresh(Arc::clone(&cache));
            let entries = cache.lock().unwrap().clone().unwrap_or_default();
            match serialize_sections(filter_sections(entries, query)) {
                Ok(json_sections) => json_sections,
                Err(err) => err
            }
        }).with_state(cache)
    );
    let listener = tokio::net::TcpListener::bind("0.0.0.0:1235").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

pub fn serialize_sections(sections: Vec<Desktop::Section>) -> Result<String, String> {
    let mut apps = Vec::new();
    for section in sections {
        let name = section.attr("Name").get(0).ok_or("No app name found")?;
        let exec = section.attr("Exec").get(0).ok_or("No app exec found")?;
        let comment = section.attr("Comment").get(0);
        let icon = section.attr("Icon").get(0);
        apps.push(App { name: name.to_string(), exec: exec.to_string(), comment: comment.cloned(), icon: icon.cloned() });
    }
    apps.sort();
    apps.dedup();
    serde_json::to_string(&apps).map_err(|err| err.to_string())
}
