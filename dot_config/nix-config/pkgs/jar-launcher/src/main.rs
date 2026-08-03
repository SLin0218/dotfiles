use std::collections::{HashMap, HashSet};
use std::env;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::{Duration, Instant};

use crossterm::event::{self, Event, KeyCode};
use crossterm::terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen};
use ratatui::backend::CrosstermBackend;
use ratatui::layout::{Constraint, Direction, Layout, Rect};
use ratatui::style::{Color, Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, Borders, Clear, Paragraph, Row, Table};
use ratatui::Terminal;
use serde::{Deserialize, Serialize};

// Nerd Font Icons
const ICON_JAVA: &str = "\u{e738}";
const ICON_NIX: &str = "\u{f313}";
const ICON_RUN: &str = "\u{f058}";
const ICON_STOP: &str = "\u{f05c}";
const ICON_FOLDER: &str = "\u{f07b}";
const ICON_LOG: &str = "\u{f0f6}";
const ICON_STATUS: &str = "\u{f085}";
const ICON_STATS: &str = "\u{f080}";

#[derive(Serialize, Deserialize, Clone, Default)]
struct GlobalConfig {
    jar_dir: String,
    theme: String,
}

#[derive(Serialize, Deserialize, Clone, Default)]
#[serde(default)]
struct AppConfigItem {
    jvm_args: String,
    nix_enabled: bool,
    nix_jdk_package: String,
    app_args: HashMap<String, String>,
}

#[derive(Clone, PartialEq)]
enum ActiveWindow {
    MainList,
    LogViewer,
    SearchPrompt,
    JvmArgsPrompt,
    JarDirPrompt,
    NixMenu,
    EnvSelectMenu,
    EnvEditor,
    EnvAddKeyPrompt,
    EnvAddValuePrompt,
    EnvActionSubmenu,
    AppArgsEditor,
    AppArgsAddKeyPrompt,
    AppArgsAddValuePrompt,
    AppArgsActionSubmenu,
    ThemeMenu,
    HmViewModal,
}

#[derive(Clone, PartialEq, Copy)]
enum InputMode {
    Normal,
    Insert,
}

struct ProcessInfo {
    pid: u32,
    etime: String,
    rss_mb: f64,
    command: String,
    port: String,
}

struct JarState {
    #[allow(dead_code)]
    path: String,
    basename: String,
    status_text: String,
    status_color: Color,
    pid_str: String,
    uptime_str: String,
    rss_str: String,
    port_str: String,
    is_running: bool,
    jvm_args: String,
    nix_enabled: bool,
    nix_jdk: String,
    app_args: HashMap<String, String>,
}

struct App {
    config_dir: PathBuf,
    config: GlobalConfig,
    apps_config: HashMap<String, AppConfigItem>,
    jars_list: Vec<String>,
    running_processes: HashMap<u32, ProcessInfo>,
    ports_cache: HashMap<u32, String>,
    app_status_cache: HashMap<String, JarState>,

    // TUI States
    selected_idx: usize,
    active_window: ActiveWindow,
    status_message: String,
    status_message_time: Option<Instant>,

    // Inputs & Prompts
    input_value: String,
    input_cursor: usize, // char index into input_value
    input_mode: InputMode,
    input_count: Option<usize>, // for count-prefixed commands like 2h, 3l
    prompt_title: String,
    prompt_label: String,

    // Log Viewer States
    log_lines: Vec<String>,
    log_scroll_offset: usize,
    log_search_query: Option<String>,
    log_match_indices: Vec<usize>,
    log_curr_match_ptr: usize,

    // Nested Menu Indexing
    menu_idx: usize,
    nix_jdk_options: Vec<String>,
    env_keys_list: Vec<String>,
    env_dict_cache: HashMap<String, String>,
    env_selected_key: String,
    app_args_keys_list: Vec<String>,
    app_args_dict_cache: HashMap<String, String>,
    app_args_selected_key: String,
    app_args_temp_idx: usize,
    last_visible_log_height: usize,
}

impl App {
    fn new() -> Self {
        let home = env::var("HOME").unwrap_or_else(|_| "/Users/lin".to_string());
        let config_dir = PathBuf::from(home).join(".config/jar-launcher");

        App {
            config_dir,
            config: GlobalConfig {
                jar_dir: format!("{}/jars", env::var("HOME").unwrap_or_else(|_| "/Users/lin".to_string())),
                theme: "catppuccin-mocha".to_string(),
            },
            apps_config: HashMap::new(),
            jars_list: Vec::new(),
            running_processes: HashMap::new(),
            ports_cache: HashMap::new(),
            app_status_cache: HashMap::new(),
            selected_idx: 0,
            active_window: ActiveWindow::MainList,
            status_message: String::new(),
            status_message_time: None,
            input_value: String::new(),
            input_cursor: 0,
            input_mode: InputMode::Insert,
            input_count: None,
            prompt_title: String::new(),
            prompt_label: String::new(),
            log_lines: Vec::new(),
            log_scroll_offset: 0,
            log_search_query: None,
            log_match_indices: Vec::new(),
            log_curr_match_ptr: 0,
            menu_idx: 0,
            nix_jdk_options: vec![
                "jdk8".to_string(),
                "jdk11".to_string(),
                "jdk17".to_string(),
                "jdk21".to_string(),
                "jdk22".to_string(),
            ],
            env_keys_list: Vec::new(),
            env_dict_cache: HashMap::new(),
            env_selected_key: String::new(),
            app_args_keys_list: Vec::new(),
            app_args_dict_cache: HashMap::new(),
            app_args_selected_key: String::new(),
            app_args_temp_idx: 0,
            last_visible_log_height: 25,
        }
    }

    fn get_apps_config_path(&self) -> PathBuf {
        Path::new(&self.config.jar_dir).join("apps.json")
    }

    fn load_all_configs(&mut self) {
        fs::create_dir_all(&self.config_dir).ok();

        let config_path = self.config_dir.join("config.json");
        if config_path.exists() {
            if let Ok(content) = fs::read_to_string(&config_path) {
                if let Ok(parsed) = serde_json::from_str::<GlobalConfig>(&content) {
                    self.config = parsed;
                }
            }
        } else {
            self.save_global_config();
        }

        let apps_path = self.get_apps_config_path();
        if apps_path.exists() {
            if let Ok(content) = fs::read_to_string(&apps_path) {
                if let Ok(parsed) = serde_json::from_str::<HashMap<String, AppConfigItem>>(&content) {
                    self.apps_config = parsed;
                }
            }
        }
    }

    fn save_global_config(&self) {
        let config_path = self.config_dir.join("config.json");
        if let Ok(content) = serde_json::to_string_pretty(&self.config) {
            fs::write(config_path, content).ok();
        }
    }

    fn save_apps_config(&self) {
        let jar_dir = Path::new(&self.config.jar_dir);
        fs::create_dir_all(jar_dir).ok();
        let apps_path = self.get_apps_config_path();
        if let Ok(content) = serde_json::to_string_pretty(&self.apps_config) {
            fs::write(apps_path, content).ok();
        }
    }

    fn get_log_dir(&self) -> PathBuf {
        Path::new(&self.config.jar_dir).join("logs")
    }

    fn scan_jars(&mut self) {
        let dir = Path::new(&self.config.jar_dir);
        if !dir.exists() {
            self.jars_list.clear();
            return;
        }

        if let Ok(entries) = fs::read_dir(dir) {
            let mut list = Vec::new();
            for entry in entries.flatten() {
                let path = entry.path();
                if path.is_file() && path.extension().map_or(false, |ext| ext == "jar") {
                    if let Some(abs_path) = fs::canonicalize(path).ok() {
                        if let Some(path_str) = abs_path.to_str() {
                            list.push(path_str.to_string());
                        }
                    }
                }
            }
            list.sort();
            self.jars_list = list;
        } else {
            self.jars_list.clear();
        }
    }

    fn get_app_status(&self, jar_path: &str) -> Option<&ProcessInfo> {
        let basename = Path::new(jar_path).file_name()?.to_str()?;
        for proc in self.running_processes.values() {
            if proc.command.contains(jar_path) || proc.command.contains(basename) {
                return Some(proc);
            }
        }
        None
    }

    fn update_status(&mut self) {
        self.running_processes = get_running_processes();

        let active_pids: HashSet<u32> = self.running_processes.keys().copied().collect();
        self.ports_cache.retain(|pid, _| active_pids.contains(pid));

        for (pid, proc) in self.running_processes.iter_mut() {
            let has_valid_port = self.ports_cache.get(pid).map_or(false, |port| port != "-");
            if !has_valid_port {
                let port = get_pid_ports(*pid);
                self.ports_cache.insert(*pid, port);
            }
            proc.port = self.ports_cache.get(pid).cloned().unwrap_or_else(|| "-".to_string());
        }

        let mut next_status = HashMap::new();
        for jar in &self.jars_list {
            let status = self.get_app_status_display_raw(jar);
            next_status.insert(jar.clone(), status);
        }
        self.app_status_cache = next_status;

        // Live Log Follow Mode (Tail -f) inside tick rate update
        if self.active_window == ActiveWindow::LogViewer && !self.jars_list.is_empty() {
            let jar = &self.jars_list[self.selected_idx];
            let log_path = self.get_log_dir().join(format!(
                "{}.log",
                Path::new(jar).file_stem().unwrap().to_string_lossy()
            ));

            let visible_lines = self.last_visible_log_height.max(1);
            let max_offset_before = self.log_lines.len().saturating_sub(visible_lines);
            let was_at_bottom = self.log_scroll_offset >= max_offset_before;

            let mut next_lines = read_last_lines(&log_path.to_string_lossy(), 262144);
            if next_lines.len() > 2000 {
                next_lines.drain(0..next_lines.len() - 2000);
            }
            self.log_lines = next_lines;

            // Re-calculate match indices dynamically when log lines update
            if let Some(ref q) = self.log_search_query {
                let mut matches = Vec::new();
                for (i, line) in self.log_lines.iter().enumerate() {
                    if line.to_lowercase().contains(&q.to_lowercase()) {
                        matches.push(i);
                    }
                }
                self.log_match_indices = matches;
                if !self.log_match_indices.is_empty() {
                    self.log_curr_match_ptr = std::cmp::min(self.log_curr_match_ptr, self.log_match_indices.len() - 1);
                } else {
                    self.log_curr_match_ptr = 0;
                }
            }

            if was_at_bottom && self.log_search_query.is_none() {
                self.log_scroll_offset = 999999;
            }
        }
    }

    fn get_app_status_display_raw(&self, jar_path: &str) -> JarState {
        let app_cfg = self.apps_config.get(jar_path).cloned().unwrap_or_default();
        let jvm_args = if app_cfg.jvm_args.is_empty() {
            "-Xms128m -Xmx512m".to_string()
        } else {
            app_cfg.jvm_args.clone()
        };
        let nix_jdk = if app_cfg.nix_jdk_package.is_empty() {
            "jdk17".to_string()
        } else {
            app_cfg.nix_jdk_package.clone()
        };
        let app_args = app_cfg.app_args.clone();

        let proc = self.get_app_status(jar_path);
        if let Some(p) = proc {
            let mem_limit = parse_xmx(&p.command).or_else(|| parse_xmx(&jvm_args)).unwrap_or_else(|| "N/A".to_string());
            let mem_str = format!("{} ({})", format_memory(p.rss_mb), mem_limit);

            return JarState {
                path: jar_path.to_string(),
                basename: Path::new(jar_path).file_name().unwrap_or_default().to_string_lossy().to_string(),
                status_text: "RUNNING".to_string(),
                status_color: Color::Rgb(166, 227, 161), // Catppuccin Green
                pid_str: p.pid.to_string(),
                uptime_str: p.etime.clone(),
                rss_str: mem_str,
                port_str: p.port.clone(),
                is_running: true,
                jvm_args,
                nix_enabled: app_cfg.nix_enabled,
                nix_jdk,
                app_args,
            };
        }

        let basename = Path::new(jar_path).file_name().unwrap_or_default().to_string_lossy().to_string();
        let name_no_ext = Path::new(&basename).file_stem().unwrap_or_default().to_string_lossy().to_string();
        let exit_code_file = self.get_log_dir().join(format!("{}.exit_code", name_no_ext));

        let mut status_text = "STOPPED".to_string();
        let mut status_color = Color::Rgb(147, 153, 178); // Catppuccin Overlay2 (Muted)

        if exit_code_file.exists() {
            if let Ok(code_str) = fs::read_to_string(exit_code_file) {
                if let Ok(code) = code_str.trim().parse::<i32>() {
                    if code != 0 && code != 143 {
                        status_text = format!("ERROR({})", code);
                        status_color = Color::Rgb(243, 139, 168); // Catppuccin Red
                    }
                }
            }
        }

        let mem_limit = parse_xmx(&jvm_args).unwrap_or_else(|| "N/A".to_string());

        JarState {
            path: jar_path.to_string(),
            basename,
            status_text,
            status_color,
            pid_str: "-".to_string(),
            uptime_str: "-".to_string(),
            rss_str: format!("- ({})", mem_limit),
            port_str: "-".to_string(),
            is_running: false,
            jvm_args,
            nix_enabled: app_cfg.nix_enabled,
            nix_jdk,
            app_args,
        }
    }

    fn get_app_status_display(&self, jar_path: &str) -> Option<&JarState> {
        self.app_status_cache.get(jar_path)
    }

    fn set_status(&mut self, msg: &str) {
        self.status_message = msg.to_string();
        self.status_message_time = Some(Instant::now());
    }

    // Begin a prompt input session: seed value, place cursor at end, enter Normal mode.
    fn begin_input(&mut self, value: String) {
        self.input_value = value;
        self.input_cursor = self.input_value.chars().count();
        self.input_mode = InputMode::Normal;
        self.input_count = None;
    }

    // Cancel/close the current prompt input and return to the previous window.
    fn cancel_input(&mut self) {
        match self.active_window {
            ActiveWindow::SearchPrompt => self.active_window = ActiveWindow::LogViewer,
            ActiveWindow::EnvAddKeyPrompt | ActiveWindow::EnvAddValuePrompt => {
                self.active_window = ActiveWindow::EnvEditor;
                self.menu_idx = 0;
            }
            ActiveWindow::AppArgsAddKeyPrompt | ActiveWindow::AppArgsAddValuePrompt => {
                if !self.jars_list.is_empty() {
                    let jar = self.jars_list[self.selected_idx].clone();
                    self.reload_app_args_keys(&jar);
                }
                self.active_window = ActiveWindow::AppArgsEditor;
                self.menu_idx = 0;
            }
            _ => self.active_window = ActiveWindow::MainList,
        }
    }

    fn input_len(&self) -> usize {
        self.input_value.chars().count()
    }

    // In Normal mode the cursor sits on a char (0..len-1); in Insert mode it sits between chars (0..len).
    fn clamp_cursor(&mut self) {
        let len = self.input_len();
        match self.input_mode {
            InputMode::Normal => {
                if len == 0 {
                    self.input_cursor = 0;
                } else if self.input_cursor >= len {
                    self.input_cursor = len - 1;
                }
            }
            InputMode::Insert => {
                if self.input_cursor > len {
                    self.input_cursor = len;
                }
            }
        }
    }

    // Display width (cells) of the text before the cursor, for terminal cursor positioning.
    fn cursor_screen_offset(&self) -> usize {
        let chars: Vec<char> = self.input_value.chars().collect();
        let head: String = chars[..self.input_cursor.min(chars.len())].iter().collect();
        str_width(&head)
    }

    fn get_merged_env(&self, jar_path: &str) -> HashMap<String, String> {
        let global_env = self.load_env_by_key("__global__");
        let app_env = self.load_env_by_key(jar_path);

        let mut merged = HashMap::new();
        for (k, v) in global_env {
            merged.insert(k, v);
        }
        for (k, v) in app_env {
            merged.insert(k, v);
        }
        merged
    }

    fn load_env_by_key(&self, save_key: &str) -> HashMap<String, String> {
        let env_file = Path::new(&self.config.jar_dir).join(".env.json");
        if !env_file.exists() {
            return HashMap::new();
        }
        let key_name = if save_key == "__global__" {
            "__global__"
        } else {
            Path::new(save_key).file_name().and_then(|n| n.to_str()).unwrap_or(save_key)
        };

        if let Ok(content) = fs::read_to_string(env_file) {
            if let Ok(all_envs) = serde_json::from_str::<HashMap<String, HashMap<String, String>>>(&content) {
                return all_envs.get(key_name).cloned().unwrap_or_default();
            }
        }
        HashMap::new()
    }

    fn save_env_by_key(&self, save_key: &str, env_dict: HashMap<String, String>) {
        let env_file = Path::new(&self.config.jar_dir).join(".env.json");
        let mut all_envs = HashMap::new();
        if env_file.exists() {
            if let Ok(content) = fs::read_to_string(&env_file) {
                if let Ok(parsed) = serde_json::from_str::<HashMap<String, HashMap<String, String>>>(&content) {
                    all_envs = parsed;
                }
            }
        }
        let key_name = if save_key == "__global__" {
            "__global__".to_string()
        } else {
            Path::new(save_key).file_name().and_then(|n| n.to_str()).unwrap_or(save_key).to_string()
        };

        all_envs.insert(key_name, env_dict);
        if let Ok(content) = serde_json::to_string_pretty(&all_envs) {
            fs::write(env_file, content).ok();
        }
    }

    fn start_app(&mut self, jar_path: &str) -> bool {
        if self.get_app_status(jar_path).is_some() {
            let name = Path::new(jar_path).file_name().unwrap_or_default().to_string_lossy();
            self.set_status(&format!("[WARN] {} is already running!", name));
            return false;
        }

        let app_cfg = self.apps_config.get(jar_path).cloned().unwrap_or_default();
        let jvm_args = if app_cfg.jvm_args.is_empty() { "-Xms128m -Xmx512m" } else { &app_cfg.jvm_args };
        let app_args_str = format_app_args_from_dict(&app_cfg.app_args);

        let log_dir = self.get_log_dir();
        fs::create_dir_all(&log_dir).ok();

        let basename = Path::new(jar_path).file_name().unwrap_or_default().to_string_lossy();
        let name_no_ext = Path::new(&*basename).file_stem().unwrap_or_default().to_string_lossy();
        let log_file = log_dir.join(format!("{}.log", name_no_ext));
        let exit_code_file = log_dir.join(format!("{}.exit_code", name_no_ext));

        fs::remove_file(&exit_code_file).ok();

        let java_cmd = if app_cfg.nix_enabled {
            let jdk = if app_cfg.nix_jdk_package.is_empty() { "jdk17" } else { &app_cfg.nix_jdk_package };
            format!(
                "nix shell nixpkgs#{} -c java {} -jar \"{}\" {}",
                jdk, jvm_args, jar_path, app_args_str
            )
        } else {
            format!("java {} -jar \"{}\" {}", jvm_args, jar_path, app_args_str)
        };

        let wrapped = format!("sh -c 'cd \"{}\" && {}; echo $? > \"{}\"'", self.config.jar_dir, java_cmd, exit_code_file.to_string_lossy());
        let cmd = format!("nohup {} > \"{}\" 2>&1", wrapped, log_file.to_string_lossy());

        let run_envs = self.get_merged_env(jar_path);

        #[cfg(unix)]
        {
            use std::os::unix::process::CommandExt;
            let mut spawn_cmd = Command::new("sh");
            spawn_cmd.arg("-c").arg(cmd);
            // 设置工作目录为 scan_dir
            spawn_cmd.current_dir(&self.config.jar_dir);
            for (k, v) in run_envs {
                spawn_cmd.env(k, v);
            }
            // Start detached session
            unsafe {
                spawn_cmd.pre_exec(|| {
                    libc::setsid();
                    Ok(())
                });
            }

            match spawn_cmd.spawn() {
                Ok(_) => {
                    self.set_status(&format!("[INFO] Starting {}...", basename));
                    true
                }
                Err(e) => {
                    self.set_status(&format!("[ERROR] Failed: {}", e));
                    false
                }
            }
        }
        #[cfg(not(unix))]
        {
            self.set_status("[ERROR] Platform not supported");
            false
        }
    }

    fn stop_app(&mut self, jar_path: &str) -> bool {
        let pid = match self.get_app_status(jar_path) {
            Some(p) => p.pid,
            None => {
                let name = Path::new(jar_path).file_name().unwrap_or_default().to_string_lossy();
                self.set_status(&format!("[WARN] {} is not running.", name));
                return false;
            }
        };

        let basename = Path::new(jar_path).file_name().unwrap_or_default().to_string_lossy();
        let name_no_ext = Path::new(&*basename).file_stem().unwrap_or_default().to_string_lossy();
        let exit_code_file = self.get_log_dir().join(format!("{}.exit_code", name_no_ext));

        fs::create_dir_all(self.get_log_dir()).ok();
        fs::write(exit_code_file, "0").ok();

        unsafe {
            if libc::kill(pid as libc::pid_t, libc::SIGTERM) == 0 {
                self.set_status(&format!("[INFO] Sent SIGTERM to PID {}.", pid));
                true
            } else {
                self.set_status("[ERROR] Failed to send kill signal.");
                false
            }
        }
    }

    fn restart_app(&mut self, jar_path: &str) {
        let has_proc = self.get_app_status(jar_path).is_some();
        let basename = Path::new(jar_path).file_name().unwrap_or_default().to_string_lossy().to_string();
        if has_proc {
            self.stop_app(jar_path);
            self.set_status(&format!("[INFO] Waiting for {} to stop...", basename));
            for _ in 0..10 {
                std::thread::sleep(Duration::from_millis(500));
                self.update_status();
                if self.get_app_status(jar_path).is_none() {
                    break;
                }
            }
        }
        self.start_app(jar_path);
    }
}

fn read_last_lines(filepath: &str, max_bytes: u64) -> Vec<String> {
    use std::io::{Seek, Read};
    let path = std::path::Path::new(filepath);
    if !path.exists() {
        return vec!["--- No log output yet ---".to_string()];
    }

    let mut file = match std::fs::File::open(path) {
        Ok(f) => f,
        Err(e) => return vec![format!("[ERROR] Failed to open log: {}", e)],
    };

    let size = match file.metadata() {
        Ok(m) => m.len(),
        Err(e) => return vec![format!("[ERROR] Failed to read metadata: {}", e)],
    };

    if size > max_bytes {
        if file.seek(std::io::SeekFrom::End(-(max_bytes as i64))).is_err() {
            return vec!["[ERROR] Failed to seek log".to_string()];
        }
        let mut discard = [0u8; 1];
        loop {
            match file.read(&mut discard) {
                Ok(0) | Err(_) => break,
                Ok(_) => {
                    if discard[0] == b'\n' {
                        break;
                    }
                }
            }
        }
    }

    let mut buffer = Vec::new();
    if file.read_to_end(&mut buffer).is_err() {
        return vec!["[ERROR] Failed to read log data".to_string()];
    }

    let content = String::from_utf8_lossy(&buffer);
    let mut lines: Vec<String> = content.lines().map(|s| s.to_string()).collect();
    if lines.is_empty() {
        lines.push("--- No log output yet ---".to_string());
    }
    lines
}

// Helpers
fn parse_xmx(command: &str) -> Option<String> {
    let re = regex::Regex::new(r"-Xmx([0-9]+[gGmMkK]?)").ok()?;
    let caps = re.captures(command)?;
    Some(caps.get(1)?.as_str().to_string())
}

fn format_memory(mb: f64) -> String {
    if mb >= 1024.0 {
        format!("{:.1} GB", mb / 1024.0)
    } else {
        format!("{:.1} MB", mb)
    }
}

fn get_pid_ports(pid: u32) -> String {
    let result = Command::new("lsof")
        .args(["-a", "-iTCP", "-sTCP:LISTEN", "-P", "-n", "-p", &pid.to_string()])
        .output();

    if let Ok(output) = result {
        if output.status.success() {
            let stdout = String::from_utf8_lossy(&output.stdout);
            let re = regex::Regex::new(r":(\d+)\s+\(LISTEN\)").unwrap();
            let mut ports = Vec::new();
            for line in stdout.lines() {
                if let Some(caps) = re.captures(line) {
                    if let Some(port) = caps.get(1) {
                        if let Ok(port_num) = port.as_str().parse::<u32>() {
                            ports.push(port_num);
                        }
                    }
                }
            }
            ports.sort();
            ports.dedup();
            if !ports.is_empty() {
                return ports.iter().map(|p| p.to_string()).collect::<Vec<_>>().join(",");
            }
        }
    }

    if cfg!(target_os = "linux") {
        let result = Command::new("ss")
            .args(["-lntp"])
            .output();
        if let Ok(output) = result {
            if output.status.success() {
                let stdout = String::from_utf8_lossy(&output.stdout);
                let pid_pattern = format!("pid={}[,}}]", pid);
                let mut ports = Vec::new();
                for line in stdout.lines() {
                    if line.contains(&pid_pattern) {
                        let parts: Vec<&str> = line.split_whitespace().collect();
                        if parts.len() >= 4 {
                            let local_addr = parts[3];
                            if let Some(idx) = local_addr.rfind(':') {
                                if let Ok(port_num) = local_addr[idx+1..].parse::<u32>() {
                                    ports.push(port_num);
                                }
                            }
                        }
                    }
                }
                ports.sort();
                ports.dedup();
                if !ports.is_empty() {
                    return ports.iter().map(|p| p.to_string()).collect::<Vec<_>>().join(",");
                }
            }
        }
    }

    "-".to_string()
}

fn get_running_processes() -> HashMap<u32, ProcessInfo> {
    let mut map = HashMap::new();
    let output = Command::new("ps")
        .args(["-ax", "-o", "pid,etime,rss,command"])
        .output();

    if let Ok(out) = output {
        let stdout = String::from_utf8_lossy(&out.stdout);
        for line in stdout.lines().skip(1) {
            let line = line.trim();
            if line.is_empty() {
                continue;
            }
            let words: Vec<&str> = line.split_whitespace().collect();
            if words.len() < 4 {
                continue;
            }
            let pid_str = words[0];
            let etime = words[1].to_string();
            let rss_str = words[2];

            // Slice command to preserve any spaces in the Java command arguments
            let rss_pos = match line.find(rss_str) {
                Some(pos) => pos + rss_str.len(),
                None => continue,
            };
            let command = line[rss_pos..].trim().to_string();

            if command.to_lowercase().contains("java") && command.contains(".jar") {
                if command.contains("sh -c") {
                    continue;
                }
                if let Ok(pid) = pid_str.parse::<u32>() {
                    if let Ok(rss_kb) = rss_str.parse::<f64>() {
                        map.insert(pid, ProcessInfo {
                            pid,
                            etime,
                            rss_mb: rss_kb / 1024.0,
                            command,
                            port: "-".to_string(),
                        });
                    }
                }
            }
        }
    }
    map
}

fn parse_etime(etime: &str) -> u64 {
    if etime == "-" || etime.is_empty() {
        return 999999999;
    }
    let mut days = 0;
    let mut time_str = etime.to_string();
    if etime.contains('-') {
        let parts: Vec<&str> = etime.split('-').collect();
        if parts.len() == 2 {
            days = parts[0].parse::<u64>().unwrap_or(0);
            time_str = parts[1].to_string();
        }
    }
    let parts: Vec<&str> = time_str.split(':').collect();
    let mut seconds = 0;
    match parts.len() {
        1 => {
            seconds = parts[0].parse::<u64>().unwrap_or(0);
        }
        2 => {
            let m = parts[0].parse::<u64>().unwrap_or(0);
            let s = parts[1].parse::<u64>().unwrap_or(0);
            seconds = m * 60 + s;
        }
        3 => {
            let h = parts[0].parse::<u64>().unwrap_or(0);
            let m = parts[1].parse::<u64>().unwrap_or(0);
            let s = parts[2].parse::<u64>().unwrap_or(0);
            seconds = h * 3600 + m * 60 + s;
        }
        _ => {}
    }
    days * 86400 + seconds
}

// Nerd Fonts width calculations
fn str_width(s: &str) -> usize {
    let mut width = 0;
    for c in s.chars() {
        let o = c as u32;
        if (0xE000..=0xF8FF).contains(&o) || (0xF0000..=0xFFFFD).contains(&o) {
            width += PUA_WIDTH;
        } else {
            width += 1;
        }
    }
    width
}

// nix code generators
fn gen_shell_nix(jar_path: &str, jdk_ver: &str, run_envs: &HashMap<String, String>) {
    let dir = Path::new(jar_path).parent().unwrap();
    let shell_file = dir.join("shell.nix");
    let jar_name = Path::new(jar_path).file_name().unwrap().to_string_lossy();

    let mut exports = Vec::new();
    for (k, v) in run_envs {
        exports.push(format!("    export {}=\"{}\"", k, v));
    }
    let env_str = exports.join("\n");

    let content = format!(
        "{{ pkgs ? import <nixpkgs> {{}} }}:\n\n\
        pkgs.mkShell {{\n\
        \x20\x20buildInputs = [\n\
        \x20\x20\x20\x20pkgs.{}\n\
        \x20\x20];\n\n\
        \x20\x20shellHook = ''\n\
        \x20\x20\x20\x20echo \"Loaded development environment for Java ({})\"\n\
        \x20\x20\x20\x20echo \"To run this execute: java -jar {}\"\n\
        {}\n\
        \x20\x20'';\n\
        }}",
        jdk_ver, jdk_ver, jar_name, env_str
    );
    fs::write(shell_file, content).ok();
}

fn gen_flake_nix(jar_path: &str, jdk_ver: &str, run_envs: &HashMap<String, String>) {
    let dir = Path::new(jar_path).parent().unwrap();
    let flake_file = dir.join("flake.nix");
    let basename = Path::new(jar_path).file_name().unwrap().to_string_lossy();
    let name_no_ext = Path::new(jar_path).file_stem().unwrap().to_string_lossy();

    let mut exports = Vec::new();
    for (k, v) in run_envs {
        exports.push(format!("          export {}=\"{}\"", k, v));
    }
    let env_str = exports.join("\n");

    let content = format!(
        "{{\n\
        \x20\x20description = \"Nix environment for running {}\";\n\n\
        \x20\x20inputs = {{\n\
        \x20\x20\x20\x20nixpkgs.url = \"github:nixos/nixpkgs/nixos-unstable\";\n\
        \x20\x20\x20\x20flake-utils.url = \"github:numtide/flake-utils\";\n\
        \x20\x20}};\n\n\
        \x20\x20outputs = {{ self, nixpkgs, flake-utils }}:\n\
        \x20\x20\x20\x20flake-utils.lib.eachDefaultSystem (system:\n\
        \x20\x20\x20\x20\x20\x20let\n\
        \x20\x20\x20\x20\x20\x20\x20\x20pkgs = import nixpkgs {{ inherit system; }};\n\
        \x20\x20\x20\x20\x20\x20in\n\
        \x20\x20\x20\x20\x20\x20{{\n\
        \x20\x20\x20\x20\x20\x20\x20\x20devShells.default = pkgs.mkShell {{\n\
        \x20\x20\x20\x20\x20\x20\x20\x20\x20\x20buildInputs = [ pkgs.{} ];\n\
        \x20\x20\x20\x20\x20\x20\x20\x20}};\n\n\
        \x20\x20\x20\x20\x20\x20\x20\x20packages.default = pkgs.writeShellScriptBin \"{}\" ''\n\
        {}\n\
        \x20\x20\x20\x20\x20\x20\x20\x20\x20\x20exec ${{pkgs.{}}}/bin/java -jar {} \"$@\"\n\
        \x20\x20\x20\x20\x20\x20\x20\x20'';\n\
        \x20\x20\x20\x20\x20\x20}}\n\
        \x20\x20\x20\x20);\n\
        }}",
        basename, jdk_ver, name_no_ext, env_str, jdk_ver, jar_path
    );
    fs::write(flake_file, content).ok();
}

fn gen_home_manager(jar_path: &str, jvm_args: &str, jdk_ver: &str, run_envs: &HashMap<String, String>, log_file: &Path, config_dir: &Path) -> (String, PathBuf) {
    let basename = Path::new(jar_path).file_name().unwrap().to_string_lossy();
    let name_no_ext = Path::new(jar_path).file_stem().unwrap().to_string_lossy();
    let clean_name = name_no_ext.chars().filter(|c| c.is_alphanumeric() || *c == '-' || *c == '_').collect::<String>().to_lowercase();

    let is_darwin = cfg!(target_os = "macos");
    let mut env_lines = Vec::new();
    let content = if is_darwin {
        let args_formatted = jvm_args.split_whitespace().map(|a| format!("\"{}\"", a)).collect::<Vec<String>>().join(" ");
        if !run_envs.is_empty() {
            env_lines.push("    EnvironmentVariables = {".to_string());
            for (k, v) in run_envs {
                env_lines.push(format!("      {} = \"{}\";", k, v));
            }
            env_lines.push("    };".to_string());
        }
        let env_nix = env_lines.join("\n");
        format!(
            "# macOS Launchd Agent configuration:\n\n\
            launchd.agents.{} = {{\n\
            \x20\x20enable = true;\n\
            \x20\x20config = {{\n\
            \x20\x20\x20\x20ProgramArguments = [\n\
            \x20\x20\x20\x20\x20\x20\"${{pkgs.{}}}/bin/java\"\n\
            \x20\x20\x20\x20\x20\x20{}\n\
            \x20\x20\x20\x20\x20\x20\"-jar\"\n\
            \x20\x20\x20\x20\x20\x20\"{}\"\n\
            \x20\x20\x20\x20];\n\
            \x20\x20\x20\x20KeepAlive = true;\n\
            \x20\x20\x20\x20RunAtLoad = true;\n\
            \x20\x20\x20\x20StandardOutPath = \"{}\";\n\
            \x20\x20\x20\x20StandardErrorPath = \"{}\";\n\
            {}\n\
            \x20\x20}};\n\
            }};",
            clean_name, jdk_ver, args_formatted, jar_path, log_file.to_string_lossy(), log_file.to_string_lossy(), env_nix
        )
    } else {
        if !run_envs.is_empty() {
            env_lines.push("    Environment = [".to_string());
            for (k, v) in run_envs {
                env_lines.push(format!("      \"{}={}\"", k, v));
            }
            env_lines.push("    ];".to_string());
        }
        let env_nix = env_lines.join("\n");
        format!(
            "# Linux Systemd User Service configuration:\n\n\
            systemd.user.services.{} = {{\n\
            \x20\x20Unit = {{\n\
            \x20\x20\x20\x20Description = \"Java Daemon for {}\";\n\
            \x20\x20\x20\x20After = [ \"network.target\" ];\n\
            \x20\x20}};\n\
            \x20\x20Service = {{\n\
            \x20\x20\x20\x20ExecStart = \"${{pkgs.{}}}/bin/java {} -jar {}\";\n\
            \x20\x20\x20\x20Restart = \"always\";\n\
            \x20\x20\x20\x20RestartSec = 5;\n\
            \x20\x20\x20\x20StandardOutput = \"append:{}\";\n\
            \x20\x20\x20\x20StandardError = \"append:{}\";\n\
            {}\n\
            \x20\x20}};\n\
            \x20\x20Install = {{\n\
            \x20\x20\x20\x20WantedBy = [ \"default.target\" ];\n\
            \x20\x20}};\n\
            }};",
            clean_name, basename, jdk_ver, jvm_args, jar_path, log_file.to_string_lossy(), log_file.to_string_lossy(), env_nix
        )
    };

    let path = config_dir.join(format!("service-{}.nix", clean_name));
    fs::write(&path, &content).ok();
    (content, path)
}

// App Logic & Navigation Key Handles
impl App {
    fn handle_key_main(&mut self, key: KeyCode) {
        match key {
            KeyCode::Up | KeyCode::Char('k') => {
                if self.selected_idx > 0 {
                    self.selected_idx -= 1;
                }
            }
            KeyCode::Down | KeyCode::Char('j') => {
                if !self.jars_list.is_empty() && self.selected_idx < self.jars_list.size() - 1 {
                    self.selected_idx += 1;
                }
            }
            KeyCode::Enter | KeyCode::Char('s') => {
                if !self.jars_list.is_empty() {
                    let jar = self.jars_list[self.selected_idx].clone();
                    let is_running = self.get_app_status(&jar).is_some();
                    if is_running {
                        self.stop_app(&jar);
                    } else {
                        self.start_app(&jar);
                    }
                    self.update_status();
                }
            }
            KeyCode::Char('r') => {
                if !self.jars_list.is_empty() {
                    let jar = self.jars_list[self.selected_idx].clone();
                    self.restart_app(&jar);
                    self.update_status();
                }
            }
            KeyCode::Char('c') => {
                if !self.jars_list.is_empty() {
                    let jar = self.jars_list[self.selected_idx].clone();
                    let log_path = self.get_log_dir().join(format!(
                        "{}.log",
                        Path::new(&jar).file_stem().unwrap().to_string_lossy()
                    ));
                    let mut lines = read_last_lines(&log_path.to_string_lossy(), 262144);
                    if lines.len() > 2000 {
                        lines.drain(0..lines.len() - 2000);
                    }
                    self.log_lines = lines;
                    self.log_scroll_offset = 999999;
                    self.log_search_query = None;
                    self.log_match_indices.clear();
                    self.log_curr_match_ptr = 0;
                    self.active_window = ActiveWindow::LogViewer;
                }
            }
            KeyCode::Char('n') => {
                if !self.jars_list.is_empty() {
                    self.menu_idx = 0;
                    self.active_window = ActiveWindow::NixMenu;
                }
            }
            KeyCode::Char('v') => {
                if !self.jars_list.is_empty() {
                    self.menu_idx = 0;
                    self.active_window = ActiveWindow::EnvSelectMenu;
                }
            }
            KeyCode::Char('t') => {
                self.menu_idx = 0;
                self.active_window = ActiveWindow::ThemeMenu;
            }
            KeyCode::Char('e') => {
                if !self.jars_list.is_empty() {
                    let jar = &self.jars_list[self.selected_idx];
                    let app_cfg = self.apps_config.get(jar).cloned().unwrap_or_default();
                    let val = if app_cfg.jvm_args.is_empty() { "-Xms128m -Xmx512m".to_string() } else { app_cfg.jvm_args };
                    self.prompt_title = format!("JVM Options: {}", Path::new(jar).file_name().unwrap().to_string_lossy());
                    self.prompt_label = "Enter JVM args (e.g. -Xms256m -Xmx1024m):".to_string();
                    self.begin_input(val);
                    self.active_window = ActiveWindow::JvmArgsPrompt;
                }
            }
            KeyCode::Char('a') => {
                if !self.jars_list.is_empty() {
                    let jar = self.jars_list[self.selected_idx].clone();
                    self.reload_app_args_keys(&jar);
                    self.menu_idx = 0;
                    self.active_window = ActiveWindow::AppArgsEditor;
                }
            }
            KeyCode::Char('d') => {
                self.prompt_title = "Global Scan Directory".to_string();
                self.prompt_label = "Enter JAR absolute path:".to_string();
                self.begin_input(self.config.jar_dir.clone());
                self.active_window = ActiveWindow::JarDirPrompt;
            }
            _ => {}
        }
    }
}

// table sizing helpers
trait SizeTrait {
    fn size(&self) -> usize;
}
impl<T> SizeTrait for Vec<T> {
    fn size(&self) -> usize { self.len() }
}

const PUA_WIDTH: usize = 2;

// The main loop event router
fn run_app<B: ratatui::backend::Backend>(terminal: &mut Terminal<B>, mut app: App) -> io::Result<()> {
    let tick_rate = Duration::from_millis(1000);
    let mut last_tick = Instant::now();

    loop {
        // Sticky Selection Sorting before frame render
        if !app.jars_list.is_empty() {
            let selected_jar = app.jars_list.get(app.selected_idx).cloned();

            // Build status map to decouple from mutable borrow of app.jars_list
            let status_map: HashMap<String, (bool, String)> = app.jars_list.iter()
                .map(|j| {
                    let state = app.get_app_status_display(j);
                    let is_running = state.map_or(false, |s| s.is_running);
                    let uptime = state.map_or("-".to_string(), |s| s.uptime_str.clone());
                    (j.clone(), (is_running, uptime))
                })
                .collect();

            // Dynamic priority sorting
            app.jars_list.sort_by(|a, b| {
                let (running_a, uptime_a) = status_map.get(a).unwrap();
                let (running_b, uptime_b) = status_map.get(b).unwrap();

                let run_a_val = if *running_a { 0 } else { 1 };
                let run_b_val = if *running_b { 0 } else { 1 };

                let c1 = run_a_val.cmp(&run_b_val);
                if c1 != std::cmp::Ordering::Equal {
                    return c1;
                }

                if *running_a && *running_b {
                    let time_a = parse_etime(uptime_a);
                    let time_b = parse_etime(uptime_b);
                    let c2 = time_a.cmp(&time_b); // Newest uptime (smallest) first
                    if c2 != std::cmp::Ordering::Equal {
                        return c2;
                    }
                }

                let basename_a = Path::new(a).file_name()
                    .unwrap_or_default().to_string_lossy().to_lowercase();
                let basename_b = Path::new(b).file_name()
                    .unwrap_or_default().to_string_lossy().to_lowercase();
                basename_a.cmp(&basename_b)
            });

            if let Some(jar) = selected_jar {
                if let Some(pos) = app.jars_list.iter().position(|x| x == &jar) {
                    app.selected_idx = pos;
                }
            }
        }

        // Draw TUI
        terminal.draw(|f| draw_ui(f, &mut app))?;

        // Refresh stats timer (1 second ticks)
        let timeout = tick_rate
            .checked_sub(last_tick.elapsed())
            .unwrap_or_else(|| Duration::from_secs(0));

        if event::poll(timeout)? {
            if let Event::Key(key) = event::read()? {
                if key.kind == event::KeyEventKind::Release {
                    continue;
                }
                if app.active_window == ActiveWindow::MainList && (key.code == KeyCode::Char('q') || key.code == KeyCode::Esc) {
                    break;
                }
                handle_keys(&mut app, key)?;
            }
        }

        if last_tick.elapsed() >= tick_rate {
            app.update_status();
            last_tick = Instant::now();
        }
    }
    Ok(())
}

fn handle_keys(app: &mut App, key_event: event::KeyEvent) -> io::Result<()> {
    let key = key_event.code;
    match app.active_window {
        ActiveWindow::MainList => {
            app.handle_key_main(key);
        }
        ActiveWindow::LogViewer => {
            if key_event.modifiers.contains(event::KeyModifiers::CONTROL) {
                match key {
                    KeyCode::Char('u') | KeyCode::Char('b') => {
                        app.log_scroll_offset = app.log_scroll_offset.saturating_sub(25);
                        return Ok(());
                    }
                    KeyCode::Char('d') | KeyCode::Char('f') => {
                        app.log_scroll_offset = std::cmp::min(app.log_lines.len().saturating_sub(5), app.log_scroll_offset + 25);
                        return Ok(());
                    }
                    _ => {}
                }
            }

            match key {
                KeyCode::Esc | KeyCode::Char('q') => {
                    app.active_window = ActiveWindow::MainList;
                }
                KeyCode::Up | KeyCode::Char('k') => {
                    if app.log_scroll_offset > 0 {
                        app.log_scroll_offset -= 1;
                    }
                }
                KeyCode::Down | KeyCode::Char('j') => {
                    let height = 30; // Layout dependent, fallback limit
                    if !app.log_lines.is_empty() && app.log_scroll_offset < app.log_lines.len().saturating_sub(height) {
                        app.log_scroll_offset += 1;
                    }
                }
                KeyCode::PageUp => {
                    app.log_scroll_offset = app.log_scroll_offset.saturating_sub(25);
                }
                KeyCode::PageDown => {
                    app.log_scroll_offset = std::cmp::min(app.log_lines.len().saturating_sub(5), app.log_scroll_offset + 25);
                }
                KeyCode::Char('g') => {
                    app.log_scroll_offset = 0;
                }
                KeyCode::Char('G') => {
                    app.log_scroll_offset = app.log_lines.len().saturating_sub(20);
                }
                KeyCode::Char('/') => {
                    app.prompt_title = "🔍 Search Logs".to_string();
                    app.prompt_label = "Enter search term (case-insensitive):".to_string();
                    app.begin_input(String::new());
                    app.active_window = ActiveWindow::SearchPrompt;
                }
                KeyCode::Char('n') => {
                    if app.log_search_query.is_some() && !app.log_match_indices.is_empty() {
                        app.log_curr_match_ptr = (app.log_curr_match_ptr + 1) % app.log_match_indices.len();
                        let target = app.log_match_indices[app.log_curr_match_ptr];
                        app.log_scroll_offset = target.saturating_sub(10);
                    }
                }
                KeyCode::Char('N') => {
                    if app.log_search_query.is_some() && !app.log_match_indices.is_empty() {
                        app.log_curr_match_ptr = (app.log_curr_match_ptr + app.log_match_indices.len() - 1) % app.log_match_indices.len();
                        let target = app.log_match_indices[app.log_curr_match_ptr];
                        app.log_scroll_offset = target.saturating_sub(10);
                    }
                }
                _ => {}
            }
        }
        ActiveWindow::SearchPrompt => {
            handle_vim_input(app, key, |app, val| {
                if !val.is_empty() {
                    app.log_search_query = Some(val.clone());
                    let mut matches = Vec::new();
                    for (i, line) in app.log_lines.iter().enumerate() {
                        if line.to_lowercase().contains(&val.to_lowercase()) {
                            matches.push(i);
                        }
                    }
                    app.log_match_indices = matches;
                    app.log_curr_match_ptr = 0;
                    if !app.log_match_indices.is_empty() {
                        app.log_scroll_offset = app.log_match_indices[0].saturating_sub(10);
                    } else {
                        app.log_search_query = None;
                        app.set_status(&format!("[WARN] No matches found for: {}", val));
                    }
                } else {
                    app.log_search_query = None;
                    app.log_match_indices.clear();
                }
                app.active_window = ActiveWindow::LogViewer;
            });
        }
        ActiveWindow::JvmArgsPrompt => {
            handle_vim_input(app, key, |app, val| {
                if !app.jars_list.is_empty() {
                    let jar = app.jars_list[app.selected_idx].clone();
                    let mut app_cfg = app.apps_config.get(&jar).cloned().unwrap_or_default();
                    app_cfg.jvm_args = val;
                    app.apps_config.insert(jar, app_cfg);
                    app.save_apps_config();
                    app.update_status();
                }
                app.active_window = ActiveWindow::MainList;
            });
        }
        ActiveWindow::AppArgsEditor => {
            let options_cnt = app.app_args_keys_list.len() + 2;
            match key {
                KeyCode::Esc | KeyCode::Char('q') => {
                    app.active_window = ActiveWindow::MainList;
                    app.menu_idx = 0;
                }
                KeyCode::Up | KeyCode::Char('k') => {
                    app.menu_idx = (app.menu_idx + options_cnt - 1) % options_cnt;
                }
                KeyCode::Down | KeyCode::Char('j') => {
                    app.menu_idx = (app.menu_idx + 1) % options_cnt;
                }
                KeyCode::Enter => {
                    if app.menu_idx == 0 {
                        app.prompt_title = "Add App Argument".to_string();
                        app.prompt_label = "Enter argument key (e.g. server.port):".to_string();
                        app.begin_input(String::new());
                        app.active_window = ActiveWindow::AppArgsAddKeyPrompt;
                    } else if app.menu_idx == options_cnt - 1 {
                        app.active_window = ActiveWindow::MainList;
                        app.menu_idx = 0;
                    } else {
                        app.app_args_temp_idx = app.menu_idx;
                        app.menu_idx = 0;
                        app.active_window = ActiveWindow::AppArgsActionSubmenu;
                    }
                }
                _ => {}
            }
        }
        ActiveWindow::AppArgsAddKeyPrompt => {
            handle_vim_input(app, key, |app, val| {
                if !val.is_empty() {
                    let clean_key = val.trim_start_matches('-').to_string();
                    app.prompt_title = format!("Add Value for {}", clean_key);
                    app.prompt_label = format!("Enter value for {}:", clean_key);
                    app.app_args_selected_key = clean_key;
                    app.begin_input(String::new());
                    app.active_window = ActiveWindow::AppArgsAddValuePrompt;
                } else if !app.jars_list.is_empty() {
                    let jar = app.jars_list[app.selected_idx].clone();
                    app.reload_app_args_keys(&jar);
                    app.active_window = ActiveWindow::AppArgsEditor;
                    app.menu_idx = 0;
                }
            });
        }
        ActiveWindow::AppArgsAddValuePrompt => {
            handle_vim_input(app, key, |app, val| {
                if !app.jars_list.is_empty() {
                    let jar = app.jars_list[app.selected_idx].clone();
                    let mut app_cfg = app.apps_config.get(&jar).cloned().unwrap_or_default();
                    app_cfg.app_args.insert(app.app_args_selected_key.clone(), val);
                    app.apps_config.insert(jar.clone(), app_cfg);
                    app.save_apps_config();
                    app.reload_app_args_keys(&jar);
                    app.set_status("[INFO] App argument saved");
                }
                app.active_window = ActiveWindow::AppArgsEditor;
                app.menu_idx = 0;
            });
        }
        ActiveWindow::AppArgsActionSubmenu => {
            let options_cnt = 3;
            match key {
                KeyCode::Esc | KeyCode::Char('q') => {
                    app.active_window = ActiveWindow::AppArgsEditor;
                    app.menu_idx = app.app_args_temp_idx;
                }
                KeyCode::Up | KeyCode::Char('k') => {
                    app.menu_idx = (app.menu_idx + options_cnt - 1) % options_cnt;
                }
                KeyCode::Down | KeyCode::Char('j') => {
                    app.menu_idx = (app.menu_idx + 1) % options_cnt;
                }
                KeyCode::Enter => {
                    if !app.jars_list.is_empty() {
                        let jar = app.jars_list[app.selected_idx].clone();
                        let key_idx = app.app_args_temp_idx - 1;
                        if key_idx < app.app_args_keys_list.len() {
                            let target_key = app.app_args_keys_list[key_idx].clone();
                            match app.menu_idx {
                                0 => {
                                    let curr_val = app.app_args_dict_cache.get(&target_key).cloned().unwrap_or_default();
                                    app.prompt_title = format!("Edit {}", target_key);
                                    app.prompt_label = format!("Enter value for {}:", target_key);
                                    app.app_args_selected_key = target_key;
                                    app.begin_input(curr_val);
                                    app.active_window = ActiveWindow::AppArgsAddValuePrompt;
                                }
                                1 => {
                                    let mut app_cfg = app.apps_config.get(&jar).cloned().unwrap_or_default();
                                    app_cfg.app_args.remove(&target_key);
                                    app.apps_config.insert(jar.clone(), app_cfg);
                                    app.save_apps_config();
                                    app.reload_app_args_keys(&jar);
                                    app.set_status("[INFO] App argument deleted");
                                    app.active_window = ActiveWindow::AppArgsEditor;
                                    app.menu_idx = 0;
                                }
                                2 => {
                                    app.active_window = ActiveWindow::AppArgsEditor;
                                    app.menu_idx = app.app_args_temp_idx;
                                }
                                _ => {}
                            }
                        } else {
                            app.active_window = ActiveWindow::AppArgsEditor;
                            app.menu_idx = 0;
                        }
                    }
                }
                _ => {}
            }
        }
        ActiveWindow::JarDirPrompt => {
            handle_vim_input(app, key, |app, val| {
                if Path::new(&val).is_dir() {
                    app.config.jar_dir = val;
                    app.save_global_config();
                    app.load_all_configs();
                    app.scan_jars();
                    app.selected_idx = 0;
                    app.update_status();
                }
                app.active_window = ActiveWindow::MainList;
            });
        }
        ActiveWindow::NixMenu => {
            let options_cnt = 6;
            match key {
                KeyCode::Esc | KeyCode::Char('q') => {
                    app.active_window = ActiveWindow::MainList;
                }
                KeyCode::Up | KeyCode::Char('k') => {
                    app.menu_idx = (app.menu_idx + options_cnt - 1) % options_cnt;
                }
                KeyCode::Down | KeyCode::Char('j') => {
                    app.menu_idx = (app.menu_idx + 1) % options_cnt;
                }
                KeyCode::Enter => {
                    let jar = app.jars_list[app.selected_idx].clone();
                    let mut app_cfg = app.apps_config.get(&jar).cloned().unwrap_or_default();
                    match app.menu_idx {
                        0 => {
                            app_cfg.nix_enabled = !app_cfg.nix_enabled;
                            app.apps_config.insert(jar, app_cfg);
                            app.save_apps_config();
                        }
                        1 => {
                            let curr_idx = app.nix_jdk_options.iter().position(|x| x == &app_cfg.nix_jdk_package).unwrap_or(2);
                            app_cfg.nix_jdk_package = app.nix_jdk_options[(curr_idx + 1) % app.nix_jdk_options.len()].clone();
                            app.apps_config.insert(jar, app_cfg);
                            app.save_apps_config();
                        }
                        2 => {
                            let run_envs = app.get_merged_env(&jar);
                            let jdk = if app_cfg.nix_jdk_package.is_empty() { "jdk17" } else { &app_cfg.nix_jdk_package };
                            gen_shell_nix(&jar, jdk, &run_envs);
                            app.set_status("[INFO] Generated shell.nix");
                            app.active_window = ActiveWindow::MainList;
                        }
                        3 => {
                            let run_envs = app.get_merged_env(&jar);
                            let jdk = if app_cfg.nix_jdk_package.is_empty() { "jdk17" } else { &app_cfg.nix_jdk_package };
                            let basename = Path::new(&jar).file_name().unwrap().to_string_lossy();
                            let name_no_ext = Path::new(&*basename).file_stem().unwrap().to_string_lossy();
                            let log_file = app.get_log_dir().join(format!("{}.log", name_no_ext));

                            let (code, file_path) = gen_home_manager(&jar, &app_cfg.jvm_args, jdk, &run_envs, &log_file, &app.config_dir);
                            app.prompt_title = format!("Nix Code - {}", file_path.file_name().unwrap().to_string_lossy());
                            app.input_value = code; // Used to store HM code viewer text
                            app.active_window = ActiveWindow::HmViewModal; // HM View mode
                        }
                        4 => {
                            let run_envs = app.get_merged_env(&jar);
                            let jdk = if app_cfg.nix_jdk_package.is_empty() { "jdk17" } else { &app_cfg.nix_jdk_package };
                            gen_flake_nix(&jar, jdk, &run_envs);
                            app.set_status("[INFO] Generated flake.nix");
                            app.active_window = ActiveWindow::MainList;
                        }
                        5 => {
                            app.active_window = ActiveWindow::MainList;
                        }
                        _ => {}
                    }
                }
                _ => {}
            }
        }
        ActiveWindow::HmViewModal => {
            // Home manager view mode scroll, press any key to return
            match key {
                _ => {
                    app.active_window = ActiveWindow::MainList;
                }
            }
        }
        ActiveWindow::EnvSelectMenu => {
            let options_cnt = 3;
            match key {
                KeyCode::Esc | KeyCode::Char('q') => {
                    app.active_window = ActiveWindow::MainList;
                }
                KeyCode::Up | KeyCode::Char('k') => {
                    app.menu_idx = (app.menu_idx + options_cnt - 1) % options_cnt;
                }
                KeyCode::Down | KeyCode::Char('j') => {
                    app.menu_idx = (app.menu_idx + 1) % options_cnt;
                }
                KeyCode::Enter => {
                    match app.menu_idx {
                        0 => {
                            let jar = app.jars_list[app.selected_idx].clone();
                            app.env_selected_key = jar;
                            app.reload_env_keys();
                            app.menu_idx = 0;
                            app.active_window = ActiveWindow::EnvEditor;
                        }
                        1 => {
                            app.env_selected_key = "__global__".to_string();
                            app.reload_env_keys();
                            app.menu_idx = 0;
                            app.active_window = ActiveWindow::EnvEditor;
                        }
                        2 => {
                            app.active_window = ActiveWindow::MainList;
                        }
                        _ => {}
                    }
                }
                _ => {}
            }
        }
        ActiveWindow::EnvEditor => {
            let options_cnt = app.env_keys_list.len() + 2; // +1 Add key, +1 Back
            match key {
                KeyCode::Esc | KeyCode::Char('q') => {
                    app.active_window = ActiveWindow::EnvSelectMenu;
                    app.menu_idx = 0;
                }
                KeyCode::Up | KeyCode::Char('k') => {
                    app.menu_idx = (app.menu_idx + options_cnt - 1) % options_cnt;
                }
                KeyCode::Down | KeyCode::Char('j') => {
                    app.menu_idx = (app.menu_idx + 1) % options_cnt;
                }
                KeyCode::Enter => {
                    if app.menu_idx == 0 {
                        app.prompt_title = "Add Env Key".to_string();
                        app.prompt_label = "Enter variable key (e.g. PORT):".to_string();
                        app.begin_input(String::new());
                        app.active_window = ActiveWindow::EnvAddKeyPrompt;
                    } else if app.menu_idx == options_cnt - 1 {
                        app.active_window = ActiveWindow::EnvSelectMenu;
                        app.menu_idx = 0;
                    } else {
                        app.active_window = ActiveWindow::EnvActionSubmenu;
                        app.selected_idx = app.menu_idx; // Temporarily cache selected key position
                        app.menu_idx = 0;
                    }
                }
                _ => {}
            }
        }
        ActiveWindow::EnvAddKeyPrompt => {
            handle_vim_input(app, key, |app, val| {
                if !val.is_empty() {
                    app.prompt_title = format!("Add Value for {}", val);
                    app.prompt_label = format!("Enter value for {}:", val);
                    app.env_selected_key = val; // Temp store new key in selected_key
                    app.begin_input(String::new());
                    app.active_window = ActiveWindow::EnvAddValuePrompt;
                } else {
                    app.active_window = ActiveWindow::EnvEditor;
                    app.menu_idx = 0;
                }
            });
        }
        ActiveWindow::EnvAddValuePrompt => {
            handle_vim_input(app, key, |app, val| {
                let jar = app.jars_list[app.selected_idx].clone();
                let save_key = if app.env_selected_key == "__global__" { "__global__" } else { &jar };
                let mut envs = app.load_env_by_key(save_key);
                envs.insert(app.env_selected_key.clone(), val);
                app.save_env_by_key(save_key, envs);

                app.reload_env_keys();
                app.active_window = ActiveWindow::EnvEditor;
                app.menu_idx = 0;
            });
        }
        ActiveWindow::EnvActionSubmenu => {
            let options_cnt = 3; // Edit, Delete, Cancel
            match key {
                KeyCode::Esc | KeyCode::Char('q') => {
                    app.active_window = ActiveWindow::EnvEditor;
                    app.menu_idx = app.selected_idx;
                }
                KeyCode::Up | KeyCode::Char('k') => {
                    app.menu_idx = (app.menu_idx + options_cnt - 1) % options_cnt;
                }
                KeyCode::Down | KeyCode::Char('j') => {
                    app.menu_idx = (app.menu_idx + 1) % options_cnt;
                }
                KeyCode::Enter => {
                    let key_idx = app.selected_idx - 1;
                    let target_key = app.env_keys_list[key_idx].clone();
                    let jar = app.jars_list[app.selected_idx].clone();
                    let save_key = if app.env_selected_key == "__global__" { "__global__" } else { &jar };

                    match app.menu_idx {
                        0 => {
                            let curr_val = app.env_dict_cache.get(&target_key).cloned().unwrap_or_default();
                            app.prompt_title = format!("Edit {}", target_key);
                            app.prompt_label = format!("Enter value for {}:", target_key);
                            app.env_selected_key = target_key; // Temp cache key
                            app.begin_input(curr_val);
                            app.active_window = ActiveWindow::EnvAddValuePrompt;
                        }
                        1 => {
                            let mut envs = app.load_env_by_key(save_key);
                            envs.remove(&target_key);
                            app.save_env_by_key(save_key, envs);
                            app.reload_env_keys();
                            app.active_window = ActiveWindow::EnvEditor;
                            app.menu_idx = 0;
                        }
                        2 => {
                            app.active_window = ActiveWindow::EnvEditor;
                            app.menu_idx = app.selected_idx;
                        }
                        _ => {}
                    }
                }
                _ => {}
            }
        }
        ActiveWindow::ThemeMenu => {
            let options_cnt = 2;
            match key {
                KeyCode::Esc | KeyCode::Char('q') => {
                    app.active_window = ActiveWindow::MainList;
                }
                KeyCode::Up | KeyCode::Char('k') => {
                    app.menu_idx = (app.menu_idx + options_cnt - 1) % options_cnt;
                }
                KeyCode::Down | KeyCode::Char('j') => {
                    app.menu_idx = (app.menu_idx + 1) % options_cnt;
                }
                KeyCode::Enter => {
                    match app.menu_idx {
                        0 => {
                            app.config.theme = "catppuccin-mocha".to_string();
                        }
                        1 => {
                            app.config.theme = "default-curses".to_string();
                        }
                        _ => {}
                    }
                    app.save_global_config();
                    app.active_window = ActiveWindow::MainList;
                }
                _ => {}
            }
        }
    }
    Ok(())
}

// Vim-style modal input handler for prompt windows.
//  - Insert mode: type to insert at cursor; arrows/Home/End/Backspace move & edit;
//    Esc drops to Normal mode; Enter submits.
//  - Normal mode: hjkl/0/^/$/w/b move (with count prefix like 2h); x deletes;
//    i/a/A/I enter Insert; q cancels; Enter submits.
fn handle_vim_input<F>(app: &mut App, key: KeyCode, on_submit: F)
where
    F: FnOnce(&mut App, String),
{
    match app.input_mode {
        InputMode::Insert => match key {
            KeyCode::Esc => {
                app.input_mode = InputMode::Normal;
                app.input_count = None;
                app.clamp_cursor();
            }
            KeyCode::Enter => {
                let val = app.input_value.clone();
                on_submit(app, val);
            }
            KeyCode::Backspace => {
                if app.input_cursor > 0 {
                    let pos = app.input_cursor - 1;
                    app.input_cursor = pos;
                    let mut chars: Vec<char> = app.input_value.chars().collect();
                    chars.remove(pos);
                    app.input_value = chars.into_iter().collect();
                }
            }
            KeyCode::Delete => {
                let len = app.input_len();
                if app.input_cursor < len {
                    let mut chars: Vec<char> = app.input_value.chars().collect();
                    chars.remove(app.input_cursor);
                    app.input_value = chars.into_iter().collect();
                }
            }
            KeyCode::Left => {
                if app.input_cursor > 0 {
                    app.input_cursor -= 1;
                }
            }
            KeyCode::Right => {
                if app.input_cursor < app.input_len() {
                    app.input_cursor += 1;
                }
            }
            KeyCode::Home => app.input_cursor = 0,
            KeyCode::End => app.input_cursor = app.input_len(),
            KeyCode::Char(c) => {
                if app.input_len() < 256 {
                    let mut chars: Vec<char> = app.input_value.chars().collect();
                    chars.insert(app.input_cursor, c);
                    app.input_value = chars.into_iter().collect();
                    app.input_cursor += 1;
                }
            }
            _ => {}
        },
        InputMode::Normal => match key {
            KeyCode::Esc => { app.input_count = None; }
            KeyCode::Char('q') => app.cancel_input(),
            KeyCode::Enter => {
                let val = app.input_value.clone();
                on_submit(app, val);
            }
            // Count prefix: accumulate digits (0 acts as "home" when alone)
            KeyCode::Char(d @ '1'..='9') => {
                let digit = d as usize - '1' as usize + 1;
                app.input_count = Some(match app.input_count {
                    Some(count) => count * 10 + digit,
                    None => digit,
                });
            }
            KeyCode::Char('0') => {
                // In vim: 0 alone moves to first column; 0 as count prefix is ignored
                if app.input_count.is_some() {
                    // Already building a count: multiply by 10 (e.g., 20 → 200)
                    app.input_count = Some(app.input_count.unwrap() * 10);
                } else {
                    // Standalone 0: move to first column
                    app.input_cursor = 0;
                }
            }
            KeyCode::Home => {
                app.input_cursor = 0;
                app.input_count = None;
            }
            // Enter Insert mode
            KeyCode::Char('i') => {
                app.input_count = None;
                app.input_mode = InputMode::Insert;
            }
            KeyCode::Char('a') => {
                app.input_count = None;
                if app.input_cursor < app.input_len() {
                    app.input_cursor += 1;
                }
                app.input_mode = InputMode::Insert;
            }
            KeyCode::Char('A') => {
                app.input_count = None;
                app.input_cursor = app.input_len();
                app.input_mode = InputMode::Insert;
            }
            KeyCode::Char('I') => {
                app.input_count = None;
                app.input_cursor = 0;
                app.input_mode = InputMode::Insert;
            }
            // Movement (with count support)
            KeyCode::Char('h') | KeyCode::Left => {
                let count = app.input_count.unwrap_or(1);
                app.input_cursor = app.input_cursor.saturating_sub(count);
                app.input_count = None;
            }
            KeyCode::Char('l') | KeyCode::Right => {
                let count = app.input_count.unwrap_or(1);
                let len = app.input_len();
                if len > 0 {
                    app.input_cursor = (app.input_cursor + count).min(len - 1);
                }
                app.input_count = None;
            }
            KeyCode::Char('^') => {
                // First non-whitespace
                let chars: Vec<char> = app.input_value.chars().collect();
                app.input_cursor = chars.iter().position(|c| !c.is_whitespace()).unwrap_or(0);
                app.input_count = None;
            }
            KeyCode::Char('$') | KeyCode::End => {
                if app.input_len() > 0 {
                    app.input_cursor = app.input_len() - 1;
                }
                app.input_count = None;
            }
            KeyCode::Char('w') => {
                let count = app.input_count.unwrap_or(1);
                let mut cur = app.input_cursor;
                for _ in 0..count {
                    cur = next_word(&app.input_value, cur);
                }
                app.input_cursor = cur;
                app.clamp_cursor();
                app.input_count = None;
            }
            KeyCode::Char('b') => {
                let count = app.input_count.unwrap_or(1);
                let mut cur = app.input_cursor;
                for _ in 0..count {
                    cur = prev_word(&app.input_value, cur);
                }
                app.input_cursor = cur;
                app.input_count = None;
            }
            // Editing
            KeyCode::Char('x') | KeyCode::Delete => {
                let count = app.input_count.unwrap_or(1);
                let len = app.input_len();
                let mut chars: Vec<char> = app.input_value.chars().collect();
                for _ in 0..count.min(len - app.input_cursor) {
                    if app.input_cursor < chars.len() {
                        chars.remove(app.input_cursor);
                    }
                }
                app.input_value = chars.into_iter().collect();
                app.clamp_cursor();
                app.input_count = None;
            }
            _ => { app.input_count = None; }
        },
    }
}

fn next_word(s: &str, cursor: usize) -> usize {
    let chars: Vec<char> = s.chars().collect();
    let len = chars.len();
    let mut i = cursor;
    while i < len && !chars[i].is_whitespace() {
        i += 1;
    }
    while i < len && chars[i].is_whitespace() {
        i += 1;
    }
    i
}

fn prev_word(s: &str, cursor: usize) -> usize {
    let chars: Vec<char> = s.chars().collect();
    let mut i = cursor;
    while i > 0 && chars[i - 1].is_whitespace() {
        i -= 1;
    }
    while i > 0 && !chars[i - 1].is_whitespace() {
        i -= 1;
    }
    i
}

impl App {
    fn reload_env_keys(&mut self) {
        let jar = self.jars_list[self.selected_idx].clone();
        let save_key = if self.env_selected_key == "__global__" { "__global__" } else { &jar };
        self.env_dict_cache = self.load_env_by_key(save_key);
        let mut keys: Vec<String> = self.env_dict_cache.keys().cloned().collect();
        keys.sort();
        self.env_keys_list = keys;
    }

    fn reload_app_args_keys(&mut self, jar_path: &str) {
        let app_cfg = self.apps_config.get(jar_path).cloned().unwrap_or_default();
        self.app_args_dict_cache = app_cfg.app_args.clone();
        let mut keys: Vec<String> = self.app_args_dict_cache.keys().cloned().collect();
        keys.sort();
        self.app_args_keys_list = keys;
    }
}


fn format_app_args_from_dict(dict: &HashMap<String, String>) -> String {
    let mut keys: Vec<&String> = dict.keys().collect();
    keys.sort();
    let mut parts = Vec::new();
    for k in keys {
        let v = &dict[k];
        let pref_key = if k.starts_with('-') { k.clone() } else { format!("--{}", k) };
        if v.is_empty() {
            parts.push(pref_key);
        } else {
            parts.push(format!("{}={}", pref_key, v));
        }
    }
    parts.join(" ")
}

// GUI Drawing Component Implementation
fn draw_ui(f: &mut ratatui::Frame, app: &mut App) {
    let size = f.size();

    // Base Colors
    let (bg_color, accent_color, muted_color, border_color) = if app.config.theme == "catppuccin-mocha" {
        (
            Color::Rgb(30, 30, 46),     // Mocha Base
            Color::Rgb(180, 190, 254), // Mocha Lavender
            Color::Rgb(147, 153, 178), // Mocha Overlay2
            Color::Rgb(69, 71, 90),     // Mocha Surface1
        )
    } else {
        (Color::Reset, Color::Cyan, Color::DarkGray, Color::Gray)
    };

    let main_block = Block::default()
        .style(Style::default().bg(bg_color).fg(Color::White));
    f.render_widget(main_block, size);

    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(4), // Header info
            Constraint::Min(5),    // Table list
            Constraint::Length(4), // Footer / warning status
        ])
        .split(size);

    // 1. Render Header Layout
    let scan_info = format!("{} Scan Path: {}", ICON_FOLDER, app.config.jar_dir);
    let logs_info = format!("{} Logs Path: {}", ICON_LOG, app.get_log_dir().to_string_lossy());

    let active_count = app.jars_list.iter().filter(|j| app.get_app_status(j).is_some()).count();
    let stats_str = format!(
        "{} Total Jars: {}  |  Running: {}  |  Stopped: {}",
        ICON_STATS, app.jars_list.len(), active_count, app.jars_list.len() - active_count
    );

    let header_lines = vec![
        Line::from(Span::styled(format!("{} JAVA JAR INTERACTIVE LAUNCHER", ICON_JAVA), Style::default().fg(accent_color).add_modifier(Modifier::BOLD))),
        if size.width > (str_width(&scan_info) + str_width(&logs_info) + 10) as u16 {
            Line::from(vec![
                Span::styled(&scan_info, Style::default().fg(muted_color)),
                Span::styled(" ".repeat(size.width as usize - str_width(&scan_info) - str_width(&logs_info) - 4), Style::default()),
                Span::styled(logs_info, Style::default().fg(muted_color)),
            ])
        } else {
            Line::from(Span::styled(&scan_info, Style::default().fg(muted_color)))
        },
        Line::from(Span::styled(stats_str, Style::default().add_modifier(Modifier::BOLD))),
    ];

    let header_widget = Paragraph::new(header_lines)
        .block(Block::default().borders(Borders::BOTTOM).border_style(Style::default().fg(border_color)));
    f.render_widget(header_widget, chunks[0]);

    // 2. Render Columns & Data Rows
    let widths = [
        Constraint::Length(4),      // ID
        Constraint::Length(1),      // │
        Constraint::Length(32),     // Jar File Name
        Constraint::Length(1),      // │
        Constraint::Length(18),     // Port
        Constraint::Length(1),      // │
        Constraint::Length(14),     // Status
        Constraint::Length(1),      // │
        Constraint::Length(7),      // PID
        Constraint::Length(1),      // │
        Constraint::Length(16),     // Memory
        Constraint::Length(1),      // │
        Constraint::Length(10),     // Uptime
        Constraint::Length(1),      // │
        Constraint::Percentage(50), // JVM / App Args / Nix Environment
    ];

    let mut rows = Vec::new();
    for (i, jar) in app.jars_list.iter().enumerate() {
        let state = app.get_app_status_display(jar);
        let default_state = JarState {
            path: jar.clone(),
            basename: Path::new(jar).file_name().unwrap_or_default().to_string_lossy().to_string(),
            status_text: "STOPPED".to_string(),
            status_color: muted_color,
            pid_str: "-".to_string(),
            uptime_str: "-".to_string(),
            rss_str: "-".to_string(),
            port_str: "-".to_string(),
            is_running: false,
            jvm_args: "-Xms128m -Xmx512m".to_string(),
            nix_enabled: false,
            nix_jdk: "jdk17".to_string(),
            app_args: HashMap::new(),
        };
        let s = state.unwrap_or(&default_state);

        let row_style = if i == app.selected_idx {
            Style::default().bg(Color::Rgb(203, 166, 247)).fg(Color::Rgb(30, 30, 46)).add_modifier(Modifier::BOLD) // Mauve
        } else if s.is_running {
            Style::default().fg(Color::White)
        } else {
            Style::default().fg(muted_color).add_modifier(Modifier::DIM) // Dim stopped items
        };

        let env_tag = if s.nix_enabled {
            format!("{} nix:{}", ICON_NIX, s.nix_jdk)
        } else {
            format!("{} default", ICON_JAVA)
        };

        // Align column separator style with selection highlight
        let sep_style = if i == app.selected_idx {
            Style::default().fg(Color::Rgb(30, 30, 46))
        } else {
            Style::default().fg(border_color)
        };
        let sep_cell = ratatui::widgets::Cell::from(Span::styled("│", sep_style));

        // Bold status colors for inactive/running state when row not selected
        let status_style = if i == app.selected_idx {
            Style::default()
        } else {
            Style::default().fg(s.status_color).add_modifier(Modifier::BOLD)
        };

        let args_formatted = format_app_args_from_dict(&s.app_args);

        let args_display = if args_formatted.is_empty() {
            s.jvm_args.clone()
        } else {
            format!("{} | args: {}", s.jvm_args, args_formatted)
        };

        let cells = vec![
            ratatui::widgets::Cell::from(Span::raw(format!(" {:02} ", i + 1))),
            sep_cell.clone(),
            ratatui::widgets::Cell::from(Span::raw(format!(" {}", s.basename))),
            sep_cell.clone(),
            ratatui::widgets::Cell::from(Span::raw(format!(" {}", s.port_str))),
            sep_cell.clone(),
            ratatui::widgets::Cell::from(Span::styled(
                format!(" {} {}", if s.is_running { ICON_RUN } else { ICON_STOP }, s.status_text),
                status_style
            )),
            sep_cell.clone(),
            ratatui::widgets::Cell::from(Span::raw(format!(" {}", s.pid_str))),
            sep_cell.clone(),
            ratatui::widgets::Cell::from(Span::raw(format!(" {}", s.rss_str))),
            sep_cell.clone(),
            ratatui::widgets::Cell::from(Span::raw(format!(" {}", s.uptime_str))),
            sep_cell.clone(),
            ratatui::widgets::Cell::from(Span::raw(format!(" ({}) {}", env_tag, args_display))),
        ];

        rows.push(Row::new(cells).style(row_style));
    }

    let header_style = Style::default().fg(accent_color).add_modifier(Modifier::BOLD);
    let header_sep_style = Style::default().fg(border_color);
    let header_cells = vec![
        ratatui::widgets::Cell::from(Span::styled(" ID ", header_style)),
        ratatui::widgets::Cell::from(Span::styled("│", header_sep_style)),
        ratatui::widgets::Cell::from(Span::styled(" Jar File Name", header_style)),
        ratatui::widgets::Cell::from(Span::styled("│", header_sep_style)),
        ratatui::widgets::Cell::from(Span::styled(" Port ", header_style)),
        ratatui::widgets::Cell::from(Span::styled("│", header_sep_style)),
        ratatui::widgets::Cell::from(Span::styled(" Status ", header_style)),
        ratatui::widgets::Cell::from(Span::styled("│", header_sep_style)),
        ratatui::widgets::Cell::from(Span::styled(" PID ", header_style)),
        ratatui::widgets::Cell::from(Span::styled("│", header_sep_style)),
        ratatui::widgets::Cell::from(Span::styled(" Memory ", header_style)),
        ratatui::widgets::Cell::from(Span::styled("│", header_sep_style)),
        ratatui::widgets::Cell::from(Span::styled(" Uptime ", header_style)),
        ratatui::widgets::Cell::from(Span::styled("│", header_sep_style)),
        ratatui::widgets::Cell::from(Span::styled(" JVM / App Args / Nix Environment", header_style)),
    ];
    let table_header = Row::new(header_cells).style(Style::default().add_modifier(Modifier::BOLD));

    let table = Table::new(rows, widths)
        .header(table_header)
        .block(Block::default().borders(Borders::NONE))
        .column_spacing(0)
        .style(Style::default().bg(bg_color).fg(Color::White));

    f.render_widget(table, chunks[1]);

    // 3. Render Status Warning Line & Shortcuts Footer
    let now = Instant::now();
    let status_line = if let Some(t) = app.status_message_time {
        if now.duration_since(t) < Duration::from_secs(5) {
            Span::styled(&app.status_message, Style::default().fg(Color::Rgb(243, 139, 168)).add_modifier(Modifier::BOLD)) // Mocha Red
        } else {
            Span::styled(format!("{} System Status: Monitoring processes...", ICON_STATUS), Style::default().fg(muted_color))
        }
    } else {
        Span::styled(format!("{} System Status: Monitoring processes...", ICON_STATUS), Style::default().fg(muted_color))
    };

    // Render footer
    let mut footer_spans = Vec::new();
    let shortcuts = [
        ("Enter/s", "Start/Stop"),
        ("r", "Restart"),
        ("c", "Console"),
        ("n", "Nix Manage"),
        ("v", "Env Var"),
        ("t", "Theme"),
        ("e", "Edit JVM"),
        ("a", "App Args"),
        ("d", "Set Jar Dir"),
        ("q", "Quit"),
    ];

    let mut accum_x = 2;
    for (k, d) in shortcuts {
        let key_str = format!("[{}]", k);
        let desc_str = format!(" {}  ", d);
        let block_w = str_width(&key_str) + str_width(&desc_str) + 2;

        if accum_x + block_w >= size.width as usize {
            footer_spans.push(Span::styled("...", Style::default().fg(muted_color)));
            break;
        }

        footer_spans.push(Span::styled(key_str, Style::default().fg(accent_color).add_modifier(Modifier::BOLD)));
        footer_spans.push(Span::styled(desc_str, Style::default().fg(muted_color)));
        accum_x += block_w;
    }

    let footer = Paragraph::new(vec![
        Line::from(status_line),
        Line::from(footer_spans),
    ])
    .block(Block::default().borders(Borders::TOP).border_style(Style::default().fg(border_color)));
    f.render_widget(footer, chunks[2]);

    // 4. Render Modals & Popups based on ActiveWindow state
    match app.active_window {
        ActiveWindow::LogViewer => draw_log_viewer(f, app, bg_color, accent_color, muted_color, border_color),
        ActiveWindow::SearchPrompt => {
            draw_log_viewer(f, app, bg_color, accent_color, muted_color, border_color);
            draw_input_modal(f, app, border_color, accent_color);
        }
        ActiveWindow::NixMenu => draw_menu_modal(f, app, "Nix Environment Manager", &["Nix Integration", "Select Nix JDK Package", "Generate Nix 'shell.nix' dev shell", "Generate Home-Manager Module", "Generate Nix Flake template (flake.nix)", "Back to Main Menu"], border_color, accent_color),
        ActiveWindow::EnvSelectMenu => draw_menu_modal(f, app, "🌱 Select Environment Mode", &["1. App-Specific Env Variables", "2. Global Env Variables (All Jars)", "3. Back to Main Menu"], border_color, accent_color),
        ActiveWindow::EnvEditor => {
            let mut opts = vec!["+ Add New Environment Variable".to_string()];
            for k in &app.env_keys_list {
                let v = app.env_dict_cache.get(k).cloned().unwrap_or_default();
                opts.push(format!("{} = {}", k, v));
            }
            opts.push("Back to Menu".to_string());
            let opts_refs: Vec<&str> = opts.iter().map(|s| s.as_str()).collect();
            draw_menu_modal(f, app, "🌱 Environment Variables Manager", &opts_refs, border_color, accent_color);
        }
        ActiveWindow::EnvActionSubmenu => draw_menu_modal(f, app, "Manage Variable", &["Edit Value", "Delete Variable", "Cancel"], border_color, accent_color),
        ActiveWindow::AppArgsEditor => {
            let mut opts = vec!["+ Add New App Argument".to_string()];
            for k in &app.app_args_keys_list {
                let v = app.app_args_dict_cache.get(k).cloned().unwrap_or_default();
                if v.is_empty() {
                    opts.push(k.clone());
                } else {
                    opts.push(format!("{} = {}", k, v));
                }
            }
            opts.push("Back to Main Menu".to_string());
            let opts_refs: Vec<&str> = opts.iter().map(|s| s.as_str()).collect();
            draw_menu_modal(f, app, "📦 App Arguments Manager", &opts_refs, border_color, accent_color);
        }
        ActiveWindow::AppArgsActionSubmenu => draw_menu_modal(f, app, "Manage Argument", &["Edit Value", "Delete Argument", "Cancel"], border_color, accent_color),
        ActiveWindow::ThemeMenu => draw_menu_modal(f, app, "🎨 Switch Theme Profile", &["Catppuccin Mocha", "Default Curses System"], border_color, accent_color),
        ActiveWindow::JvmArgsPrompt | ActiveWindow::JarDirPrompt | ActiveWindow::EnvAddKeyPrompt | ActiveWindow::EnvAddValuePrompt | ActiveWindow::AppArgsAddKeyPrompt | ActiveWindow::AppArgsAddValuePrompt => {
            draw_input_modal(f, app, border_color, accent_color);
        }
        ActiveWindow::HmViewModal => {
            draw_text_modal(f, app, border_color, accent_color);
        }
        _ => {}
    }
}

// Modal popups render utilities
fn centered_fixed_rect(width: u16, height: u16, r: Rect) -> Rect {
    let popup_layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(r.height.saturating_sub(height) / 2),
            Constraint::Length(height),
            Constraint::Min(0),
        ])
        .split(r);

    Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Length(r.width.saturating_sub(width) / 2),
            Constraint::Length(width),
            Constraint::Min(0),
        ])
        .split(popup_layout[1])[1]
}

fn centered_rect(percent_x: u16, percent_y: u16, r: Rect) -> Rect {
    let popup_layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Percentage((100 - percent_y) / 2),
            Constraint::Percentage(percent_y),
            Constraint::Percentage((100 - percent_y) / 2),
        ])
        .split(r);

    Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage((100 - percent_x) / 2),
            Constraint::Percentage(percent_x),
            Constraint::Percentage((100 - percent_x) / 2),
        ])
        .split(popup_layout[1])[1]
}

fn draw_menu_modal(f: &mut ratatui::Frame, app: &App, title: &str, options: &[&str], border_color: Color, accent_color: Color) {
    let area = centered_rect(60, 45, f.size());
    f.render_widget(Clear, area);

    let mut lines = vec![
        Line::from(Span::styled(title, Style::default().fg(accent_color).add_modifier(Modifier::BOLD))),
        Line::from("─".repeat(area.width as usize - 4)).style(Style::default().fg(border_color)),
    ];

    for (i, opt) in options.iter().enumerate() {
        if i == app.menu_idx {
            lines.push(Line::from(Span::styled(format!("▶  {}", opt), Style::default().fg(Color::Rgb(203, 166, 247)).add_modifier(Modifier::BOLD))));
        } else {
            lines.push(Line::from(Span::styled(format!("   {}", opt), Style::default().fg(Color::White))));
        }
    }

    let block = Block::default()
        .borders(Borders::ALL)
        .border_style(Style::default().fg(border_color));
    let paragraph = Paragraph::new(lines).block(block);
    f.render_widget(paragraph, area);
}

fn draw_input_modal(f: &mut ratatui::Frame, app: &App, border_color: Color, accent_color: Color) {
    let area = centered_fixed_rect(64, 9, f.size());
    f.render_widget(Clear, area);

    // Create title with mode status right-aligned, with border line spanning full width
    let mode_str = match app.input_mode {
        InputMode::Insert => "INSERT",
        InputMode::Normal => "NORMAL",
    };
    let mode_span = Span::styled(mode_str, Style::default().fg(accent_color).add_modifier(Modifier::BOLD));

    // Calculate available width and positions
    let title_area_width = area.width as usize - 4; // Account for borders
    let title_text = format!(" {}", app.prompt_title);
    let mode_text = format!(" {}", mode_str);

    let title_width = str_width(&title_text);
    let mode_width = str_width(&mode_text);

    let title_line = if title_width + mode_width + 1 <= title_area_width {
        // Enough space: title, border line, mode
        let border_width = title_area_width - title_width - mode_width - 1; // -1 for spacing
        let border_span = Span::styled("─".repeat(border_width), Style::default().fg(border_color));

        Line::from(vec![
            Span::styled(title_text, Style::default().fg(accent_color).add_modifier(Modifier::BOLD)),
            Span::styled(" ", Style::default()), // Space before border
            border_span,
            Span::styled(" ", Style::default()), // Space before mode
            mode_span,
        ])
    } else {
        // Not enough space: truncate title
        let available = title_area_width - mode_width - 3; // -3 for border line and spaces
        if available > 3 {
            let mut truncated_chars = app.prompt_title.chars().collect::<Vec<_>>();
            truncated_chars.truncate(available);
            let truncated_title = format!("{}...", truncated_chars.iter().collect::<String>());
            let title_with_padding = format!(" {}", truncated_title);

            let title_width = str_width(&title_with_padding);
            let border_width = title_area_width - title_width - mode_width - 2; // -2 for spaces
            let border_span = Span::styled("─".repeat(border_width), Style::default().fg(border_color));

            Line::from(vec![
                Span::styled(title_with_padding, Style::default().fg(accent_color).add_modifier(Modifier::BOLD)),
                Span::styled(" ", Style::default()), // Space before border
                border_span,
                Span::styled(" ", Style::default()), // Space before mode
                mode_span,
            ])
        } else {
            // Very narrow: just show mode
            Line::from(vec![
                Span::styled(" ".repeat(title_area_width / 2), Style::default()),
                mode_span,
                Span::styled(" ".repeat(title_area_width / 2), Style::default()),
            ])
        }
    };

    // Modal outer block
    let block = Block::default()
        .title(title_line)
        .borders(Borders::ALL)
        .border_style(Style::default().fg(border_color));
    f.render_widget(block, area);

    // Inner content area (within borders)
    let inner = Rect {
        x: area.x + 1,
        y: area.y + 1,
        width: area.width - 2,
        height: area.height - 2,
    };

    let field_bg = Color::Rgb(49, 50, 68); // Catppuccin Surface0
    let cursor_bg = Color::Rgb(203, 166, 247); // Catppuccin Mauve
    let cursor_fg = Color::Rgb(30, 30, 46); // Mocha Base

    // Box layout: "│  content  │"
    // Field content area width = inner.width - 2 (borders) - 2 (padding spaces)
    let field_content_width = inner.width.saturating_sub(4) as usize;
    let dash_len = inner.width.saturating_sub(2) as usize; // full width between corners
    let field_spans = input_field_spans(app, field_content_width, field_bg, cursor_bg, cursor_fg);

    // Render content: label, input box (3 lines with borders), mode indicator
    let mut lines = vec![
        Line::from(Span::styled(format!(" {}", app.prompt_label), Style::default().fg(Color::White))),
        Line::from(""), // spacer
    ];

    // Input box top border (rounded corners)
    lines.push(Line::from(Span::styled(
        format!("┌{}┐", "─".repeat(dash_len)),
        Style::default().fg(border_color),
    )));

    // Input field line
    let mut field_line_spans = vec![
        Span::styled("│", Style::default().fg(border_color)),
        Span::styled(" ", Style::default().fg(Color::White)), // padding
    ];
    field_line_spans.extend(field_spans);
    field_line_spans.push(Span::styled(" ", Style::default().fg(Color::White))); // padding
    field_line_spans.push(Span::styled("│", Style::default().fg(border_color)));
    lines.push(Line::from(field_line_spans));

    // Input box bottom border (rounded corners)
    lines.push(Line::from(Span::styled(
        format!("└{}┘", "─".repeat(dash_len)),
        Style::default().fg(border_color),
    )));

    let paragraph = Paragraph::new(lines);
    f.render_widget(paragraph, inner);
}

// Build the styled input field line: a filled "text box" with the vim block cursor
// rendered on the current char (or a trailing block when the cursor is at the end).
fn input_field_spans(app: &App, width: usize, field_bg: Color, cursor_bg: Color, cursor_fg: Color) -> Vec<Span<'_>> {
    let chars: Vec<char> = app.input_value.chars().collect();
    let cursor = app.input_cursor.min(chars.len());
    let normal = Style::default().bg(field_bg).fg(Color::White);
    let cur = Style::default().bg(cursor_bg).fg(cursor_fg).add_modifier(Modifier::BOLD);
    let mut spans: Vec<Span> = Vec::new();
    let mut used = 0usize;

    if cursor > 0 {
        let s: String = chars[..cursor].iter().collect();
        used += str_width(&s);
        spans.push(Span::styled(s, normal));
    }
    if cursor < chars.len() {
        let cs: String = chars[cursor].to_string();
        used += str_width(&cs);
        spans.push(Span::styled(cs, cur));
        if cursor + 1 < chars.len() {
            let s: String = chars[cursor + 1..].iter().collect();
            used += str_width(&s);
            spans.push(Span::styled(s, normal));
        }
    } else {
        // Cursor past the last char: render a block on an empty cell.
        used += 1;
        spans.push(Span::styled(" ", cur));
    }

    if used < width {
        spans.push(Span::styled(" ".repeat(width - used), normal));
    }
    spans
}

fn draw_text_modal(f: &mut ratatui::Frame, app: &App, border_color: Color, _accent_color: Color) {
    let area = centered_rect(85, 80, f.size());
    f.render_widget(Clear, area);

    let block = Block::default()
        .title(app.prompt_title.as_str())
        .borders(Borders::ALL)
        .border_style(Style::default().fg(border_color));

    let paragraph = Paragraph::new(app.input_value.as_str()).block(block);
    f.render_widget(paragraph, area);
}

fn draw_log_viewer(f: &mut ratatui::Frame, app: &mut App, bg_color: Color, accent_color: Color, muted_color: Color, border_color: Color) {
    let size = f.size();
    f.render_widget(Clear, size);

    let main_block = Block::default().style(Style::default().bg(bg_color));
    f.render_widget(main_block, size);

    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3), // Info Header
            Constraint::Min(5),    // Logging console
            Constraint::Length(2), // Navigation footer
        ])
        .split(size);

    let visible_lines = chunks[1].height as usize;
    app.last_visible_log_height = visible_lines;

    let max_offset = app.log_lines.len().saturating_sub(visible_lines);
    if app.log_scroll_offset > max_offset {
        app.log_scroll_offset = max_offset;
    }

    // Meta header
    let jar = &app.jars_list[app.selected_idx];
    let basename = Path::new(jar).file_name().unwrap_or_default().to_string_lossy();
    let name_no_ext = Path::new(jar).file_stem().unwrap_or_default().to_string_lossy();
    let log_file = app.get_log_dir().join(format!("{}.log", name_no_ext));

    let mut meta_str = format!("Path: {}", log_file.to_string_lossy());
    if let Some(ref q) = app.log_search_query {
        let match_cnt = app.log_match_indices.len();
        let pos = if match_cnt > 0 { app.log_curr_match_ptr + 1 } else { 0 };
        meta_str += &format!("  |  🔍 Search: \"{}\" ({}/{})", q, pos, match_cnt);
    }

    let header_lines = vec![
        Line::from(Span::styled(format!("📂 Log Viewer - {}", basename), Style::default().fg(accent_color).add_modifier(Modifier::BOLD))),
        Line::from(Span::styled(meta_str, Style::default().fg(muted_color))),
    ];
    let header_widget = Paragraph::new(header_lines).block(Block::default().borders(Borders::BOTTOM).border_style(Style::default().fg(border_color)));
    f.render_widget(header_widget, chunks[0]);

    // Console logs rendering with word regex highlights
    let visible_lines = chunks[1].height as usize;
    let mut log_spans_list = Vec::new();

    for idx in 0..visible_lines {
        let l_idx = app.log_scroll_offset + idx;
        if l_idx < app.log_lines.len() {
            let line_content = app.log_lines[l_idx].replace('\t', "    ");

            if let Some(ref q) = app.log_search_query {
                if line_content.to_lowercase().contains(&q.to_lowercase()) {
                    let re = regex::Regex::new(&format!("(?i)({})", regex::escape(q))).unwrap();
                    let mut spans = Vec::new();
                    let mut last_pos = 0;

                    let is_curr_line = !app.log_match_indices.is_empty() && l_idx == app.log_match_indices[app.log_curr_match_ptr];

                    for mat in re.find_iter(&line_content) {
                        let start = mat.start();
                        let end = mat.end();
                        if start > last_pos {
                            spans.push(Span::styled(line_content[last_pos..start].to_string(), Style::default()));
                        }

                        let matched_word = &line_content[start..end];
                        let highlight_style = if is_curr_line {
                            Style::default().bg(Color::Rgb(203, 166, 247)).fg(Color::Rgb(30, 30, 46)).add_modifier(Modifier::BOLD)
                        } else {
                            Style::default().fg(Color::Rgb(203, 166, 247)).add_modifier(Modifier::BOLD)
                        };
                        spans.push(Span::styled(matched_word.to_string(), highlight_style));
                        last_pos = end;
                    }
                    if last_pos < line_content.len() {
                        spans.push(Span::styled(line_content[last_pos..].to_string(), Style::default()));
                    }
                    log_spans_list.push(Line::from(spans));
                } else {
                    log_spans_list.push(Line::from(Span::styled(line_content.clone(), Style::default())));
                }
            } else {
                log_spans_list.push(Line::from(Span::styled(line_content.clone(), Style::default())));
            }
        }
    }

    let logs_paragraph = Paragraph::new(log_spans_list).block(Block::default().borders(Borders::NONE));
    f.render_widget(logs_paragraph, chunks[1]);

    // Navigation footer
    let pct = if app.log_lines.is_empty() { 100 } else { (app.log_scroll_offset * 100) / app.log_lines.len().max(1) };
    let lines_info = format!(
        " [Lines: {}-{}/{} ({}%)]  ",
        app.log_scroll_offset + 1,
        std::cmp::min(
            app.log_lines.len(),
            app.log_scroll_offset + visible_lines
        ),
        app.log_lines.len(),
        pct
    );

    let help_info = "Press [q/ESC] to return | [/] Search | [n/N] Nav | [j/k] Scroll | [g/G] Top/Bottom";
    let footer_text = vec![
        Line::from("━".repeat(size.width as usize)).style(Style::default().fg(border_color)),
        Line::from(vec![
            Span::styled(lines_info, Style::default().fg(accent_color).add_modifier(Modifier::BOLD)),
            Span::styled(help_info, Style::default().fg(Color::White)),
        ]),
    ];
    let footer_widget = Paragraph::new(footer_text).block(Block::default().borders(Borders::NONE));
    f.render_widget(footer_widget, chunks[2]);
}

fn main() -> Result<(), io::Error> {
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    crossterm::execute!(stdout, EnterAlternateScreen)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let mut app = App::new();
    app.load_all_configs();
    app.scan_jars();
    app.update_status();

    let res = run_app(&mut terminal, app);

    disable_raw_mode()?;
    crossterm::execute!(terminal.backend_mut(), LeaveAlternateScreen)?;
    // Don't show terminal cursor

    if let Err(err) = res {
        println!("[TUI ERROR] {}", err);
    }
    Ok(())
}
