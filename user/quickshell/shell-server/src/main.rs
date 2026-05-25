use axum::{
    routing::get,
    Router,
};
use std::env;
use std::path::{PathBuf};

fn get_application_dirs() -> Result<Vec<PathBuf>, String> {
    let xdg_data_dirs = env::var("XDG_DATA_DIRS").map_err(|e| e.to_string())?;
    let paths = env::split_paths(&xdg_data_dirs)
        .map(|dir| dir.join("applications"))
        .collect();
    Ok(paths)
}

fn get_applications(dirs: Vec<PathBuf>) -> Vec<PathBuf> {
    dirs
}

#[tokio::main]
async fn main() {
    let application_dirs = get_application_dirs();
    println!("{application_dirs:?}");
    // TODO read a list of apps and transform it into JSON keys.
    let app = Router::new().route("/apps/search", get(|| async { "Hello, World!" }));
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
