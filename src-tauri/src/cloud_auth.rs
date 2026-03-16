use aes_gcm::{
  aead::{Aead, AeadCore, KeyInit, OsRng},
  Aes256Gcm, Key, Nonce,
};
use argon2::{password_hash::SaltString, Argon2, PasswordHasher};
use base64::{engine::general_purpose, Engine as _};
use chrono::Utc;
use lazy_static::lazy_static;
use rand::RngCore;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use sha2::{Digest, Sha256};
use std::fs;
use std::path::PathBuf;
use std::sync::Arc;
use tokio::sync::Mutex;
use tokio::time::{sleep, Duration};
use url::Url;

use crate::proxy_manager::PROXY_MANAGER;
use crate::settings_manager::{ActiveSyncMode, SettingsManager};
use crate::sync;
use tauri_plugin_opener::OpenerExt;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CloudUser {
  pub id: String,
  pub email: String,
  #[serde(rename = "displayName")]
  pub display_name: Option<String>,
  #[serde(rename = "avatarUrl")]
  pub avatar_url: Option<String>,
  #[serde(rename = "syncPrefix")]
  pub sync_prefix: Option<String>,
  #[serde(rename = "hostedSyncEnabled")]
  pub hosted_sync_enabled: bool,
  #[serde(rename = "lastLoginAt")]
  pub last_login_at: Option<String>,
  pub plan: String,
  #[serde(rename = "planPeriod")]
  pub plan_period: Option<String>,
  #[serde(rename = "subscriptionStatus")]
  pub subscription_status: String,
  #[serde(rename = "profileLimit")]
  pub profile_limit: i64,
  #[serde(rename = "cloudProfilesUsed")]
  pub cloud_profiles_used: i64,
  #[serde(rename = "proxyBandwidthLimitMb")]
  pub proxy_bandwidth_limit_mb: i64,
  #[serde(rename = "proxyBandwidthUsedMb")]
  pub proxy_bandwidth_used_mb: i64,
  #[serde(rename = "proxyBandwidthExtraMb")]
  pub proxy_bandwidth_extra_mb: i64,
  #[serde(rename = "teamId")]
  pub team_id: Option<String>,
  #[serde(rename = "teamName")]
  pub team_name: Option<String>,
  #[serde(rename = "teamRole")]
  pub team_role: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CloudAuthState {
  pub user: CloudUser,
  pub logged_in_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct PendingOauthState {
  state: String,
  code_verifier: String,
  redirect_url: String,
  created_at: String,
}

#[derive(Debug, Deserialize)]
struct SupabaseSessionResponse {
  access_token: String,
  refresh_token: String,
}

#[derive(Debug, Deserialize)]
struct SupabaseAuthUser {
  id: String,
  email: Option<String>,
  #[serde(default)]
  user_metadata: Value,
}

#[derive(Debug, Deserialize)]
struct UserProfileRow {
  id: String,
  email: String,
  #[serde(default)]
  display_name: Option<String>,
  #[serde(default)]
  avatar_url: Option<String>,
  sync_prefix: String,
  #[serde(default)]
  profile_limit: i64,
  #[serde(default)]
  cloud_profiles_used: i64,
  #[serde(default)]
  hosted_sync_enabled: bool,
  #[serde(default)]
  last_login_at: Option<String>,
}

#[derive(Debug, Serialize)]
struct UserProfileUpsertPayload {
  id: String,
  email: String,
  display_name: Option<String>,
  avatar_url: Option<String>,
  last_login_at: String,
}

#[derive(Debug, Serialize)]
struct ToggleHostedSyncPayload {
  hosted_sync_enabled: bool,
}

#[derive(Debug, Serialize)]
struct SyncUsagePayload {
  cloud_profiles_used: i64,
}

#[derive(Debug, Deserialize)]
struct SyncTokenResponse {
  #[serde(rename = "syncToken")]
  sync_token: String,
}

#[derive(Debug, Deserialize)]
struct ErrorEnvelope {
  msg: Option<String>,
  message: Option<String>,
  error: Option<String>,
  error_description: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LocationItem {
  pub code: String,
  pub name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProxyUsage {
  pub used_mb: i64,
  pub limit_mb: i64,
  pub remaining_mb: i64,
  pub recurring_limit_mb: i64,
  pub extra_limit_mb: i64,
}

pub struct CloudAuthManager {
  client: Client,
  state: Mutex<Option<CloudAuthState>>,
  refresh_lock: Mutex<()>,
  wayfern_token: Mutex<Option<String>>,
}

lazy_static! {
  pub static ref CLOUD_AUTH: CloudAuthManager = CloudAuthManager::new();
}

pub fn hosted_cloud_enabled() -> bool {
  crate::runtime_app_config::current().hosted_cloud_enabled()
}

pub fn cloud_sync_url() -> Option<&'static str> {
  crate::runtime_app_config::current()
    .cloud_sync_url
    .as_deref()
}

fn require_supabase_url() -> Result<&'static str, String> {
  crate::runtime_app_config::current()
    .supabase_url
    .as_deref()
    .ok_or_else(|| "Hosted cloud is not configured for this TwitterBrowser build".to_string())
}

fn require_supabase_anon_key() -> Result<&'static str, String> {
  crate::runtime_app_config::current()
    .supabase_anon_key
    .as_deref()
    .ok_or_else(|| "Hosted cloud is not configured for this TwitterBrowser build".to_string())
}

fn require_supabase_redirect_url() -> Result<&'static str, String> {
  crate::runtime_app_config::current()
    .supabase_redirect_url
    .as_deref()
    .ok_or_else(|| "Hosted cloud OAuth redirect URL is not configured".to_string())
}

fn auth_endpoint(path: &str) -> Result<String, String> {
  Ok(format!(
    "{}/auth/v1/{}",
    require_supabase_url()?.trim_end_matches('/'),
    path.trim_start_matches('/')
  ))
}

fn rest_endpoint(path: &str) -> Result<String, String> {
  Ok(format!(
    "{}/rest/v1/{}",
    require_supabase_url()?.trim_end_matches('/'),
    path.trim_start_matches('/')
  ))
}

fn function_endpoint(path: &str) -> Result<String, String> {
  Ok(format!(
    "{}/functions/v1/{}",
    require_supabase_url()?.trim_end_matches('/'),
    path.trim_start_matches('/')
  ))
}

fn random_urlsafe_bytes(len: usize) -> String {
  let mut bytes = vec![0u8; len];
  rand::rng().fill_bytes(&mut bytes);
  general_purpose::URL_SAFE_NO_PAD.encode(bytes)
}

fn pkce_code_challenge(code_verifier: &str) -> String {
  let digest = Sha256::digest(code_verifier.as_bytes());
  general_purpose::URL_SAFE_NO_PAD.encode(digest)
}

async fn error_from_response(context: &str, response: reqwest::Response) -> String {
  let status = response.status();
  let body = response.text().await.unwrap_or_default();
  if let Ok(payload) = serde_json::from_str::<ErrorEnvelope>(&body) {
    let message = payload
      .message
      .or(payload.msg)
      .or(payload.error_description)
      .or(payload.error)
      .unwrap_or(body);
    format!("{context} ({status}): {message}")
  } else if body.trim().is_empty() {
    format!("{context} ({status})")
  } else {
    format!("{context} ({status}): {body}")
  }
}

fn derive_display_name(user: &SupabaseAuthUser) -> Option<String> {
  user
    .user_metadata
    .get("full_name")
    .and_then(Value::as_str)
    .or_else(|| user.user_metadata.get("name").and_then(Value::as_str))
    .or(user.email.as_deref())
    .map(str::trim)
    .filter(|value| !value.is_empty())
    .map(str::to_string)
}

fn derive_avatar_url(user: &SupabaseAuthUser) -> Option<String> {
  user
    .user_metadata
    .get("avatar_url")
    .and_then(Value::as_str)
    .map(str::trim)
    .filter(|value| !value.is_empty())
    .map(str::to_string)
}

impl CloudAuthManager {
  fn new() -> Self {
    Self {
      client: Client::new(),
      state: Mutex::new(Self::load_auth_state_from_disk()),
      refresh_lock: Mutex::new(()),
      wayfern_token: Mutex::new(None),
    }
  }

  fn get_settings_dir() -> PathBuf {
    SettingsManager::instance().get_settings_dir()
  }

  fn get_vault_password() -> String {
    env!("TWITTERBROWSER_VAULT_PASSWORD").to_string()
  }

  fn encrypt_and_store(file_path: &PathBuf, header: &[u8; 5], data: &str) -> Result<(), String> {
    if let Some(parent) = file_path.parent() {
      fs::create_dir_all(parent).map_err(|e| format!("Failed to create directory: {e}"))?;
    }

    let vault_password = Self::get_vault_password();
    let salt = SaltString::generate(&mut OsRng);
    let password_hash = Argon2::default()
      .hash_password(vault_password.as_bytes(), &salt)
      .map_err(|e| format!("Argon2 key derivation failed: {e}"))?;
    let hash = password_hash
      .hash
      .ok_or_else(|| "Argon2 key derivation returned no hash".to_string())?;
    let hash_bytes = hash.as_bytes();
    let key_bytes: [u8; 32] = hash_bytes[..32]
      .try_into()
      .map_err(|_| "Invalid key length".to_string())?;
    let cipher = Aes256Gcm::new(&Key::<Aes256Gcm>::from(key_bytes));
    let nonce = Aes256Gcm::generate_nonce(&mut OsRng);
    let ciphertext = cipher
      .encrypt(&nonce, data.as_bytes())
      .map_err(|e| format!("Encryption failed: {e}"))?;

    let mut file_data = Vec::new();
    file_data.extend_from_slice(header);
    file_data.push(2u8);
    let salt_str = salt.as_str();
    file_data.push(salt_str.len() as u8);
    file_data.extend_from_slice(salt_str.as_bytes());
    file_data.extend_from_slice(&nonce);
    file_data.extend_from_slice(&(ciphertext.len() as u32).to_le_bytes());
    file_data.extend_from_slice(&ciphertext);

    fs::write(file_path, file_data).map_err(|e| format!("Failed to write file: {e}"))?;
    Ok(())
  }

  fn decrypt_from_file(file_path: &PathBuf, header: &[u8; 5]) -> Result<Option<String>, String> {
    if !file_path.exists() {
      return Ok(None);
    }

    let file_data = fs::read(file_path).map_err(|e| format!("Failed to read file: {e}"))?;
    if file_data.len() < 6 || &file_data[0..5] != header {
      return Ok(None);
    }
    if file_data[5] != 2 {
      return Ok(None);
    }

    let mut offset = 6;
    let salt_len = *file_data
      .get(offset)
      .ok_or_else(|| "Corrupted encrypted file".to_string())? as usize;
    offset += 1;

    let salt_bytes = file_data
      .get(offset..offset + salt_len)
      .ok_or_else(|| "Corrupted encrypted file".to_string())?;
    let salt_str = std::str::from_utf8(salt_bytes).map_err(|_| "Invalid salt encoding")?;
    let salt = SaltString::from_b64(salt_str).map_err(|_| "Invalid salt format")?;
    offset += salt_len;

    let nonce_bytes: [u8; 12] = file_data
      .get(offset..offset + 12)
      .ok_or_else(|| "Corrupted encrypted file".to_string())?
      .try_into()
      .map_err(|_| "Invalid nonce length".to_string())?;
    offset += 12;

    let ciphertext_len = u32::from_le_bytes(
      file_data
        .get(offset..offset + 4)
        .ok_or_else(|| "Corrupted encrypted file".to_string())?
        .try_into()
        .map_err(|_| "Invalid ciphertext length".to_string())?,
    ) as usize;
    offset += 4;

    let ciphertext = file_data
      .get(offset..offset + ciphertext_len)
      .ok_or_else(|| "Corrupted encrypted file".to_string())?;

    let vault_password = Self::get_vault_password();
    let password_hash = Argon2::default()
      .hash_password(vault_password.as_bytes(), &salt)
      .map_err(|e| format!("Argon2 key derivation failed: {e}"))?;
    let hash = password_hash
      .hash
      .ok_or_else(|| "Argon2 key derivation returned no hash".to_string())?;
    let hash_bytes = hash.as_bytes();
    let key_bytes: [u8; 32] = hash_bytes[..32]
      .try_into()
      .map_err(|_| "Invalid key length".to_string())?;
    let cipher = Aes256Gcm::new(&Key::<Aes256Gcm>::from(key_bytes));
    let plaintext = cipher
      .decrypt(&Nonce::from(nonce_bytes), ciphertext)
      .map_err(|_| "Decryption failed".to_string())?;

    Ok(String::from_utf8(plaintext).ok())
  }

  fn access_token_path() -> PathBuf {
    Self::get_settings_dir().join("hosted_access_token.dat")
  }

  fn refresh_token_path() -> PathBuf {
    Self::get_settings_dir().join("hosted_refresh_token.dat")
  }

  fn sync_token_path() -> PathBuf {
    Self::get_settings_dir().join("hosted_sync_token.dat")
  }

  fn auth_state_path() -> PathBuf {
    Self::get_settings_dir().join("hosted_auth_state.json")
  }

  fn oauth_state_path() -> PathBuf {
    Self::get_settings_dir().join("hosted_oauth_pkce.json")
  }

  fn store_access_token(token: &str) -> Result<(), String> {
    Self::encrypt_and_store(&Self::access_token_path(), b"TBHAT", token)
  }

  pub(crate) fn load_access_token() -> Result<Option<String>, String> {
    Self::decrypt_from_file(&Self::access_token_path(), b"TBHAT")
  }

  fn store_refresh_token(token: &str) -> Result<(), String> {
    Self::encrypt_and_store(&Self::refresh_token_path(), b"TBHRT", token)
  }

  fn load_refresh_token() -> Result<Option<String>, String> {
    Self::decrypt_from_file(&Self::refresh_token_path(), b"TBHRT")
  }

  fn store_sync_token(token: &str) -> Result<(), String> {
    Self::encrypt_and_store(&Self::sync_token_path(), b"TBHST", token)
  }

  fn load_sync_token() -> Result<Option<String>, String> {
    Self::decrypt_from_file(&Self::sync_token_path(), b"TBHST")
  }

  fn clear_sync_token_cache() {
    let path = Self::sync_token_path();
    if path.exists() {
      let _ = fs::remove_file(path);
    }
  }

  fn store_auth_state(state: &CloudAuthState) -> Result<(), String> {
    let path = Self::auth_state_path();
    if let Some(parent) = path.parent() {
      fs::create_dir_all(parent).map_err(|e| format!("Failed to create directory: {e}"))?;
    }
    let json =
      serde_json::to_string_pretty(state).map_err(|e| format!("Failed to serialize: {e}"))?;
    fs::write(path, json).map_err(|e| format!("Failed to write auth state: {e}"))?;
    Ok(())
  }

  fn load_auth_state_from_disk() -> Option<CloudAuthState> {
    let path = Self::auth_state_path();
    if !path.exists() {
      return None;
    }
    let content = fs::read_to_string(path).ok()?;
    serde_json::from_str(&content).ok()
  }

  fn store_pending_oauth_state(pending: &PendingOauthState) -> Result<(), String> {
    let path = Self::oauth_state_path();
    if let Some(parent) = path.parent() {
      fs::create_dir_all(parent).map_err(|e| format!("Failed to create directory: {e}"))?;
    }
    let json =
      serde_json::to_string_pretty(pending).map_err(|e| format!("Failed to serialize: {e}"))?;
    fs::write(path, json).map_err(|e| format!("Failed to write pending oauth state: {e}"))?;
    Ok(())
  }

  fn load_pending_oauth_state() -> Result<Option<PendingOauthState>, String> {
    let path = Self::oauth_state_path();
    if !path.exists() {
      return Ok(None);
    }
    let content =
      fs::read_to_string(path).map_err(|e| format!("Failed to read pending oauth state: {e}"))?;
    let pending = serde_json::from_str(&content)
      .map_err(|e| format!("Failed to parse pending oauth state: {e}"))?;
    Ok(Some(pending))
  }

  fn clear_pending_oauth_state() {
    let path = Self::oauth_state_path();
    if path.exists() {
      let _ = fs::remove_file(path);
    }
  }

  fn delete_all_auth_files() {
    for path in [
      Self::access_token_path(),
      Self::refresh_token_path(),
      Self::sync_token_path(),
      Self::auth_state_path(),
      Self::oauth_state_path(),
    ] {
      if path.exists() {
        let _ = fs::remove_file(path);
      }
    }
  }

  fn is_jwt_expiring_soon(token: &str) -> bool {
    let parts: Vec<&str> = token.split('.').collect();
    if parts.len() != 3 {
      return true;
    }

    let payload = match general_purpose::URL_SAFE_NO_PAD.decode(parts[1]) {
      Ok(bytes) => bytes,
      Err(_) => return true,
    };

    let json: Value = match serde_json::from_slice(&payload) {
      Ok(v) => v,
      Err(_) => return true,
    };

    let exp = match json.get("exp").and_then(Value::as_i64) {
      Some(exp) => exp,
      None => return true,
    };

    exp - Utc::now().timestamp() < 120
  }

  async fn fetch_auth_user(&self, access_token: &str) -> Result<SupabaseAuthUser, String> {
    let url = auth_endpoint("user")?;
    let response = self
      .client
      .get(&url)
      .header("apikey", require_supabase_anon_key()?)
      .header("Authorization", format!("Bearer {access_token}"))
      .send()
      .await
      .map_err(|e| format!("Failed to fetch current user: {e}"))?;

    if !response.status().is_success() {
      return Err(error_from_response("Failed to fetch current user", response).await);
    }

    response
      .json::<SupabaseAuthUser>()
      .await
      .map_err(|e| format!("Failed to parse current user: {e}"))
  }

  async fn ensure_user_profile(
    &self,
    access_token: &str,
    auth_user: &SupabaseAuthUser,
  ) -> Result<UserProfileRow, String> {
    let email = auth_user
      .email
      .clone()
      .ok_or_else(|| "Supabase user is missing an email address".to_string())?;
    let payload = UserProfileUpsertPayload {
      id: auth_user.id.clone(),
      email,
      display_name: derive_display_name(auth_user),
      avatar_url: derive_avatar_url(auth_user),
      last_login_at: Utc::now().to_rfc3339(),
    };
    let url = format!(
      "{}?select=id,email,display_name,avatar_url,sync_prefix,profile_limit,cloud_profiles_used,hosted_sync_enabled,last_login_at",
      rest_endpoint("user_profiles")?
    );

    let response = self
      .client
      .post(&url)
      .header("apikey", require_supabase_anon_key()?)
      .header("Authorization", format!("Bearer {access_token}"))
      .header(
        "Prefer",
        "resolution=merge-duplicates,return=representation",
      )
      .json(&vec![payload])
      .send()
      .await
      .map_err(|e| format!("Failed to upsert user profile: {e}"))?;

    if !response.status().is_success() {
      return Err(error_from_response("Failed to upsert user profile", response).await);
    }

    let mut rows = response
      .json::<Vec<UserProfileRow>>()
      .await
      .map_err(|e| format!("Failed to parse user profile: {e}"))?;
    rows
      .pop()
      .ok_or_else(|| "Supabase returned no user profile row".to_string())
  }

  fn build_cloud_user(auth_user: &SupabaseAuthUser, row: &UserProfileRow) -> CloudUser {
    CloudUser {
      id: row.id.clone(),
      email: row.email.clone(),
      display_name: row
        .display_name
        .clone()
        .or_else(|| derive_display_name(auth_user)),
      avatar_url: row
        .avatar_url
        .clone()
        .or_else(|| derive_avatar_url(auth_user)),
      sync_prefix: Some(row.sync_prefix.clone()),
      hosted_sync_enabled: row.hosted_sync_enabled,
      last_login_at: row.last_login_at.clone(),
      plan: "hosted".to_string(),
      plan_period: None,
      subscription_status: "active".to_string(),
      profile_limit: row.profile_limit,
      cloud_profiles_used: row.cloud_profiles_used,
      proxy_bandwidth_limit_mb: 0,
      proxy_bandwidth_used_mb: 0,
      proxy_bandwidth_extra_mb: 0,
      team_id: None,
      team_name: None,
      team_role: None,
    }
  }

  async fn fetch_profile_with_access_token(&self, access_token: &str) -> Result<CloudUser, String> {
    let auth_user = self.fetch_auth_user(access_token).await?;
    let row = self.ensure_user_profile(access_token, &auth_user).await?;
    Ok(Self::build_cloud_user(&auth_user, &row))
  }

  async fn apply_session(
    &self,
    session: SupabaseSessionResponse,
  ) -> Result<CloudAuthState, String> {
    Self::store_access_token(&session.access_token)?;
    Self::store_refresh_token(&session.refresh_token)?;
    Self::clear_sync_token_cache();

    let user = self
      .fetch_profile_with_access_token(&session.access_token)
      .await?;
    let auth_state = CloudAuthState {
      user,
      logged_in_at: Utc::now().to_rfc3339(),
    };
    Self::store_auth_state(&auth_state)?;

    let mut state = self.state.lock().await;
    *state = Some(auth_state.clone());

    Ok(auth_state)
  }

  pub async fn request_email_otp(&self, email: &str) -> Result<String, String> {
    let url = auth_endpoint("otp")?;
    let response = self
      .client
      .post(&url)
      .header("apikey", require_supabase_anon_key()?)
      .json(&serde_json::json!({
        "email": email,
        "create_user": true
      }))
      .send()
      .await
      .map_err(|e| format!("Failed to request email code: {e}"))?;

    if !response.status().is_success() {
      return Err(error_from_response("Failed to request email code", response).await);
    }

    Ok("Verification code sent".to_string())
  }

  pub async fn verify_email_otp(&self, email: &str, code: &str) -> Result<CloudAuthState, String> {
    let url = auth_endpoint("verify")?;
    let response = self
      .client
      .post(&url)
      .header("apikey", require_supabase_anon_key()?)
      .json(&serde_json::json!({
        "email": email,
        "token": code,
        "type": "email"
      }))
      .send()
      .await
      .map_err(|e| format!("Failed to verify email code: {e}"))?;

    if !response.status().is_success() {
      return Err(error_from_response("Failed to verify email code", response).await);
    }

    let session = response
      .json::<SupabaseSessionResponse>()
      .await
      .map_err(|e| format!("Failed to parse Supabase session: {e}"))?;
    self.apply_session(session).await
  }

  pub async fn sign_in_with_password(
    &self,
    email: &str,
    password: &str,
  ) -> Result<CloudAuthState, String> {
    let url = format!("{}?grant_type=password", auth_endpoint("token")?);
    let response = self
      .client
      .post(&url)
      .header("apikey", require_supabase_anon_key()?)
      .json(&serde_json::json!({
        "email": email,
        "password": password
      }))
      .send()
      .await
      .map_err(|e| format!("Failed to sign in with password: {e}"))?;

    if !response.status().is_success() {
      return Err(error_from_response("Failed to sign in with password", response).await);
    }

    let session = response
      .json::<SupabaseSessionResponse>()
      .await
      .map_err(|e| format!("Failed to parse Supabase session: {e}"))?;
    self.apply_session(session).await
  }

  pub async fn start_google_sign_in(&self, app_handle: tauri::AppHandle) -> Result<(), String> {
    let redirect_url = require_supabase_redirect_url()?.to_string();
    let code_verifier = random_urlsafe_bytes(64);
    let code_challenge = pkce_code_challenge(&code_verifier);
    let state = random_urlsafe_bytes(32);
    let pending = PendingOauthState {
      state: state.clone(),
      code_verifier,
      redirect_url: redirect_url.clone(),
      created_at: Utc::now().to_rfc3339(),
    };
    Self::store_pending_oauth_state(&pending)?;

    let mut authorize_url = Url::parse(&auth_endpoint("authorize")?)
      .map_err(|e| format!("Failed to construct Google sign-in URL: {e}"))?;
    authorize_url
      .query_pairs_mut()
      .append_pair("provider", "google")
      .append_pair("redirect_to", &redirect_url)
      .append_pair("code_challenge", &code_challenge)
      .append_pair("code_challenge_method", "S256")
      .append_pair("state", &state)
      .append_pair("access_type", "offline")
      .append_pair("prompt", "consent")
      .append_pair("scopes", "email profile");

    app_handle
      .opener()
      .open_url(authorize_url.to_string(), None::<&str>)
      .map_err(|e| format!("Failed to open Google sign-in: {e}"))?;

    Ok(())
  }

  pub fn is_oauth_callback_url(url: &str) -> bool {
    let Ok(callback_url) = Url::parse(url) else {
      return false;
    };
    let Ok(configured) = Url::parse(require_supabase_redirect_url().unwrap_or_default()) else {
      return false;
    };

    callback_url.scheme() == configured.scheme()
      && callback_url.host_str() == configured.host_str()
      && callback_url.path() == configured.path()
  }

  pub async fn handle_oauth_callback(
    &self,
    _app_handle: tauri::AppHandle,
    url: &str,
  ) -> Result<(), String> {
    let callback_url = Url::parse(url).map_err(|e| format!("Invalid auth callback URL: {e}"))?;
    let params = callback_url.query_pairs().collect::<Vec<_>>();

    if let Some(error) = params.iter().find_map(|(key, value)| {
      if key == "error" {
        Some(value.to_string())
      } else {
        None
      }
    }) {
      Self::clear_pending_oauth_state();
      let description = params
        .iter()
        .find_map(|(key, value)| {
          if key == "error_description" {
            Some(value.to_string())
          } else {
            None
          }
        })
        .unwrap_or_else(|| error.clone());
      let _ = crate::events::emit("cloud-auth-error", description.clone());
      return Err(description);
    }

    let code = params
      .iter()
      .find_map(|(key, value)| {
        if key == "code" {
          Some(value.to_string())
        } else {
          None
        }
      })
      .ok_or_else(|| "Missing OAuth authorization code".to_string())?;
    let state = params
      .iter()
      .find_map(|(key, value)| {
        if key == "state" {
          Some(value.to_string())
        } else {
          None
        }
      })
      .ok_or_else(|| "Missing OAuth state".to_string())?;

    let pending = Self::load_pending_oauth_state()?
      .ok_or_else(|| "No pending OAuth state found. Please retry sign-in.".to_string())?;
    if pending.state != state {
      Self::clear_pending_oauth_state();
      return Err("OAuth state mismatch. Please retry sign-in.".to_string());
    }

    let token_url = format!("{}?grant_type=pkce", auth_endpoint("token")?);
    let response = self
      .client
      .post(&token_url)
      .header("apikey", require_supabase_anon_key()?)
      .json(&serde_json::json!({
        "auth_code": code,
        "code_verifier": pending.code_verifier
      }))
      .send()
      .await
      .map_err(|e| format!("Failed to exchange Google sign-in code: {e}"))?;

    Self::clear_pending_oauth_state();

    if !response.status().is_success() {
      let message = error_from_response("Failed to exchange Google sign-in code", response).await;
      let _ = crate::events::emit("cloud-auth-error", message.clone());
      return Err(message);
    }

    let session = response
      .json::<SupabaseSessionResponse>()
      .await
      .map_err(|e| format!("Failed to parse Supabase session: {e}"))?;
    let _ = self.apply_session(session).await?;
    let _ = crate::events::emit_empty("cloud-auth-changed");
    Ok(())
  }

  pub async fn refresh_access_token(&self) -> Result<(), String> {
    let _guard = self.refresh_lock.lock().await;
    let refresh_token =
      Self::load_refresh_token()?.ok_or_else(|| "No refresh token stored".to_string())?;
    let url = format!("{}?grant_type=refresh_token", auth_endpoint("token")?);
    let response = self
      .client
      .post(&url)
      .header("apikey", require_supabase_anon_key()?)
      .json(&serde_json::json!({
        "refresh_token": refresh_token
      }))
      .send()
      .await
      .map_err(|e| format!("Failed to refresh session: {e}"))?;

    if !response.status().is_success() {
      return Err(error_from_response("Failed to refresh session", response).await);
    }

    let session = response
      .json::<SupabaseSessionResponse>()
      .await
      .map_err(|e| format!("Failed to parse Supabase session: {e}"))?;
    self.apply_session(session).await.map(|_| ())
  }

  pub async fn fetch_profile(&self) -> Result<CloudUser, String> {
    let access_token = Self::load_access_token()?.ok_or_else(|| "Not logged in".to_string())?;
    let user = self.fetch_profile_with_access_token(&access_token).await?;

    let mut state = self.state.lock().await;
    if let Some(auth_state) = state.as_mut() {
      auth_state.user = user.clone();
      let _ = Self::store_auth_state(auth_state);
    }

    Ok(user)
  }

  pub async fn api_call_with_retry<F, Fut, T>(&self, make_request: F) -> Result<T, String>
  where
    F: Fn(String) -> Fut + Send,
    Fut: std::future::Future<Output = Result<T, String>> + Send,
  {
    let access_token = Self::load_access_token()?.ok_or_else(|| "Not logged in".to_string())?;

    match make_request(access_token.clone()).await {
      Ok(result) => Ok(result),
      Err(e) if e.contains("(401") || e.contains("Unauthorized") => {
        let current_token = Self::load_access_token()?.unwrap_or_default();
        if current_token != access_token && !current_token.is_empty() {
          return make_request(current_token).await;
        }

        self.refresh_access_token().await?;
        let new_token =
          Self::load_access_token()?.ok_or_else(|| "Not logged in after refresh".to_string())?;
        make_request(new_token).await
      }
      Err(e) => Err(e),
    }
  }

  pub async fn get_or_refresh_sync_token(&self) -> Result<Option<String>, String> {
    if !self.is_hosted_sync_active().await {
      return Ok(None);
    }

    if let Ok(Some(token)) = Self::load_sync_token() {
      if !Self::is_jwt_expiring_soon(&token) {
        return Ok(Some(token));
      }
    }

    let endpoint = function_endpoint("issue-sync-token")?;
    let sync_token = self
      .api_call_with_retry(|access_token| {
        let endpoint = endpoint.clone();
        let client = self.client.clone();
        async move {
          let response = client
            .post(&endpoint)
            .header("apikey", require_supabase_anon_key().unwrap_or_default())
            .header("Authorization", format!("Bearer {access_token}"))
            .send()
            .await
            .map_err(|e| format!("Failed to issue hosted sync token: {e}"))?;

          if !response.status().is_success() {
            return Err(error_from_response("Failed to issue hosted sync token", response).await);
          }

          let result = response
            .json::<SyncTokenResponse>()
            .await
            .map_err(|e| format!("Failed to parse hosted sync token response: {e}"))?;
          Ok(result.sync_token)
        }
      })
      .await?;

    Self::store_sync_token(&sync_token)?;
    Ok(Some(sync_token))
  }

  pub async fn is_logged_in(&self) -> bool {
    if !hosted_cloud_enabled() {
      return false;
    }
    self.state.lock().await.is_some()
  }

  pub async fn is_hosted_sync_active(&self) -> bool {
    if !self.is_logged_in().await {
      return false;
    }
    matches!(
      SettingsManager::instance().get_active_sync_mode(),
      Ok(ActiveSyncMode::Hosted)
    )
  }

  pub async fn has_active_paid_subscription(&self) -> bool {
    false
  }

  pub fn has_active_paid_subscription_sync(&self) -> bool {
    false
  }

  pub async fn is_fingerprint_os_allowed(&self, fingerprint_os: Option<&str>) -> bool {
    let host_os = crate::profile::types::get_host_os();
    match fingerprint_os {
      None => true,
      Some(os) if os == host_os => true,
      Some(_) => crate::runtime_app_config::current().cross_os_profiles_enabled(),
    }
  }

  pub async fn is_on_team_plan(&self) -> bool {
    false
  }

  pub async fn get_user(&self) -> Option<CloudAuthState> {
    if !hosted_cloud_enabled() {
      return None;
    }
    self.state.lock().await.clone()
  }

  async fn clear_auth(&self) {
    let mut state = self.state.lock().await;
    *state = None;
    Self::delete_all_auth_files();
  }

  async fn fallback_sync_mode_after_logout() -> ActiveSyncMode {
    let manager = SettingsManager::instance();
    if manager.has_self_hosted_sync_config_unchecked() {
      ActiveSyncMode::SelfHosted
    } else {
      ActiveSyncMode::None
    }
  }

  pub async fn logout(&self) -> Result<(), String> {
    self.clear_wayfern_token().await;
    crate::team_lock::TEAM_LOCK.disconnect().await;

    if let Ok(Some(access_token)) = Self::load_access_token() {
      let url = auth_endpoint("logout")?;
      let _ = self
        .client
        .post(&url)
        .header("apikey", require_supabase_anon_key()?)
        .header("Authorization", format!("Bearer {access_token}"))
        .send()
        .await;
    }

    if self.is_hosted_sync_active().await {
      let fallback_mode = Self::fallback_sync_mode_after_logout().await;
      let _ = SettingsManager::instance().save_active_sync_mode(fallback_mode);
    }

    PROXY_MANAGER.remove_cloud_proxy();
    self.clear_auth().await;
    Ok(())
  }

  pub async fn refresh_profile(&self) -> Result<CloudUser, String> {
    self.fetch_profile().await
  }

  pub async fn enable_hosted_sync(&self) -> Result<(), String> {
    let access_token = Self::load_access_token()?.ok_or_else(|| "Not logged in".to_string())?;
    self
      .update_hosted_sync_flag(&access_token, true)
      .await
      .map_err(|e| format!("Failed to enable hosted sync: {e}"))?;
    SettingsManager::instance()
      .save_active_sync_mode(ActiveSyncMode::Hosted)
      .map_err(|e| format!("Failed to save active sync mode: {e}"))?;
    Self::clear_sync_token_cache();
    Ok(())
  }

  pub async fn disable_hosted_sync(&self, app_handle: &tauri::AppHandle) -> Result<(), String> {
    if let Ok(Some(access_token)) = Self::load_access_token() {
      let _ = self.update_hosted_sync_flag(&access_token, false).await;
    }

    let fallback_mode = if SettingsManager::instance()
      .has_self_hosted_sync_config(app_handle)
      .await
      .unwrap_or(false)
    {
      ActiveSyncMode::SelfHosted
    } else {
      ActiveSyncMode::None
    };

    SettingsManager::instance()
      .save_active_sync_mode(fallback_mode)
      .map_err(|e| format!("Failed to save active sync mode: {e}"))?;
    Self::clear_sync_token_cache();
    Ok(())
  }

  async fn update_hosted_sync_flag(&self, access_token: &str, enabled: bool) -> Result<(), String> {
    let user_id = self
      .get_user()
      .await
      .map(|state| state.user.id)
      .ok_or_else(|| "Not logged in".to_string())?;
    let url = format!("{}?id=eq.{}", rest_endpoint("user_profiles")?, user_id);
    let response = self
      .client
      .patch(&url)
      .header("apikey", require_supabase_anon_key()?)
      .header("Authorization", format!("Bearer {access_token}"))
      .header("Prefer", "return=representation")
      .json(&ToggleHostedSyncPayload {
        hosted_sync_enabled: enabled,
      })
      .send()
      .await
      .map_err(|e| format!("Failed to update hosted sync preference: {e}"))?;

    if !response.status().is_success() {
      return Err(error_from_response("Failed to update hosted sync preference", response).await);
    }

    let rows = response
      .json::<Vec<UserProfileRow>>()
      .await
      .map_err(|e| format!("Failed to parse hosted sync preference response: {e}"))?;

    if let Some(row) = rows.first() {
      let mut state = self.state.lock().await;
      if let Some(current) = state.as_mut() {
        current.user.hosted_sync_enabled = row.hosted_sync_enabled;
        current.user.cloud_profiles_used = row.cloud_profiles_used;
        current.user.last_login_at = row.last_login_at.clone();
        let _ = Self::store_auth_state(current);
      }
    }

    Ok(())
  }

  pub async fn report_sync_profile_count(&self, count: i64) -> Result<(), String> {
    let access_token = match Self::load_access_token()? {
      Some(token) => token,
      None => return Ok(()),
    };
    let user_id = match self.get_user().await {
      Some(state) => state.user.id,
      None => return Ok(()),
    };
    let url = format!("{}?id=eq.{}", rest_endpoint("user_profiles")?, user_id);
    let response = self
      .client
      .patch(&url)
      .header("apikey", require_supabase_anon_key()?)
      .header("Authorization", format!("Bearer {access_token}"))
      .header("Prefer", "return=representation")
      .json(&SyncUsagePayload {
        cloud_profiles_used: count,
      })
      .send()
      .await
      .map_err(|e| format!("Failed to report hosted sync usage: {e}"))?;

    if !response.status().is_success() {
      return Err(error_from_response("Failed to report hosted sync usage", response).await);
    }

    let rows = response
      .json::<Vec<UserProfileRow>>()
      .await
      .map_err(|e| format!("Failed to parse hosted sync usage response: {e}"))?;
    if let Some(row) = rows.first() {
      let mut state = self.state.lock().await;
      if let Some(current) = state.as_mut() {
        current.user.cloud_profiles_used = row.cloud_profiles_used;
        let _ = Self::store_auth_state(current);
      }
    }

    Ok(())
  }

  pub async fn sync_cloud_proxy(&self) {}

  pub async fn request_wayfern_token(&self) -> Result<(), String> {
    Err("Wayfern hosted token is not available in this build".to_string())
  }

  pub async fn clear_wayfern_token(&self) {
    let mut token = self.wayfern_token.lock().await;
    *token = None;
  }

  pub async fn get_wayfern_token(&self) -> Option<String> {
    self.wayfern_token.lock().await.clone()
  }

  pub async fn start_sync_token_refresh_loop(_app_handle: tauri::AppHandle) {
    loop {
      sleep(Duration::from_secs(300)).await;

      if !hosted_cloud_enabled() || !CLOUD_AUTH.is_logged_in().await {
        continue;
      }

      if let Ok(Some(access_token)) = Self::load_access_token() {
        if Self::is_jwt_expiring_soon(&access_token) {
          if let Err(e) = CLOUD_AUTH.refresh_access_token().await {
            log::warn!("Failed to refresh hosted session: {e}");
            let _ = CLOUD_AUTH.logout().await;
            let _ = crate::events::emit_empty("cloud-auth-expired");
            continue;
          }
        }
      }

      if CLOUD_AUTH.is_hosted_sync_active().await {
        if let Err(e) = CLOUD_AUTH.get_or_refresh_sync_token().await {
          log::warn!("Failed to refresh hosted sync token: {e}");
        }
      }
    }
  }
}

impl SettingsManager {
  fn has_self_hosted_sync_config_unchecked(&self) -> bool {
    match self.load_settings() {
      Ok(settings) => settings.self_hosted_sync_server_url.is_some(),
      Err(_) => false,
    }
  }
}

#[tauri::command]
pub async fn hosted_auth_request_email_otp(email: String) -> Result<String, String> {
  if !hosted_cloud_enabled() {
    return Err("Hosted cloud is not configured for this TwitterBrowser build".to_string());
  }
  CLOUD_AUTH.request_email_otp(&email).await
}

#[tauri::command]
pub async fn hosted_auth_verify_email_otp(
  email: String,
  code: String,
) -> Result<CloudAuthState, String> {
  let state = CLOUD_AUTH.verify_email_otp(&email, &code).await?;
  let _ = crate::events::emit_empty("cloud-auth-changed");
  Ok(state)
}

#[tauri::command]
pub async fn hosted_auth_sign_in_with_password(
  email: String,
  password: String,
) -> Result<CloudAuthState, String> {
  let state = CLOUD_AUTH.sign_in_with_password(&email, &password).await?;
  let _ = crate::events::emit_empty("cloud-auth-changed");
  Ok(state)
}

#[tauri::command]
pub async fn hosted_auth_start_google_sign_in(app_handle: tauri::AppHandle) -> Result<(), String> {
  CLOUD_AUTH.start_google_sign_in(app_handle).await
}

#[tauri::command]
pub async fn hosted_auth_get_user() -> Result<Option<CloudAuthState>, String> {
  Ok(CLOUD_AUTH.get_user().await)
}

#[tauri::command]
pub async fn hosted_auth_logout(app_handle: tauri::AppHandle) -> Result<(), String> {
  CLOUD_AUTH.logout().await?;
  let _ = restart_sync_service(app_handle.clone()).await;
  let _ = crate::events::emit_empty("cloud-auth-changed");
  Ok(())
}

#[tauri::command]
pub async fn hosted_sync_enable(app_handle: tauri::AppHandle) -> Result<(), String> {
  CLOUD_AUTH.enable_hosted_sync().await?;
  restart_sync_service(app_handle).await?;
  let _ = crate::events::emit_empty("cloud-auth-changed");
  Ok(())
}

#[tauri::command]
pub async fn hosted_sync_disable(app_handle: tauri::AppHandle) -> Result<(), String> {
  CLOUD_AUTH.disable_hosted_sync(&app_handle).await?;
  restart_sync_service(app_handle).await?;
  let _ = crate::events::emit_empty("cloud-auth-changed");
  Ok(())
}

#[tauri::command]
pub async fn cloud_refresh_profile() -> Result<CloudUser, String> {
  let user = CLOUD_AUTH.refresh_profile().await?;
  let _ = crate::events::emit_empty("cloud-auth-changed");
  Ok(user)
}

#[tauri::command]
pub async fn cloud_get_countries() -> Result<Vec<LocationItem>, String> {
  Ok(Vec::new())
}

#[tauri::command]
pub async fn cloud_get_regions(_country: String) -> Result<Vec<LocationItem>, String> {
  Ok(Vec::new())
}

#[tauri::command]
pub async fn cloud_get_cities(
  _country: String,
  _region: Option<String>,
) -> Result<Vec<LocationItem>, String> {
  Ok(Vec::new())
}

#[tauri::command]
pub async fn cloud_get_isps(
  _country: String,
  _region: Option<String>,
  _city: Option<String>,
) -> Result<Vec<LocationItem>, String> {
  Ok(Vec::new())
}

#[tauri::command]
pub async fn create_cloud_location_proxy(
  _app_handle: tauri::AppHandle,
  _name: String,
  _country: String,
  _region: Option<String>,
  _city: Option<String>,
  _isp: Option<String>,
) -> Result<(), String> {
  Err("Hosted proxy features are not available in this build".to_string())
}

#[tauri::command]
pub async fn cloud_get_wayfern_token() -> Result<Option<String>, String> {
  Ok(CLOUD_AUTH.get_wayfern_token().await)
}

#[tauri::command]
pub async fn cloud_refresh_wayfern_token() -> Result<Option<String>, String> {
  CLOUD_AUTH.request_wayfern_token().await?;
  Ok(CLOUD_AUTH.get_wayfern_token().await)
}

#[tauri::command]
pub async fn restart_sync_service(app_handle: tauri::AppHandle) -> Result<(), String> {
  if let Some(scheduler) = sync::get_global_scheduler() {
    scheduler.stop();
  }

  let app_handle_sync = app_handle.clone();
  tauri::async_runtime::spawn(async move {
    let mut subscription_manager = sync::SubscriptionManager::new();
    let work_rx = subscription_manager.take_work_receiver();

    if let Err(e) = subscription_manager.start(app_handle_sync.clone()).await {
      log::warn!("Failed to start sync subscription: {e}");
      return;
    }

    if let Some(work_rx) = work_rx {
      let scheduler = Arc::new(sync::SyncScheduler::new());
      sync::set_global_scheduler(scheduler.clone());

      scheduler.sync_all_enabled_profiles(&app_handle_sync).await;

      match sync::SyncEngine::create_from_settings(&app_handle_sync).await {
        Ok(engine) => {
          if let Err(e) = engine
            .check_for_missing_synced_profiles(&app_handle_sync)
            .await
          {
            log::warn!("Failed to check for missing profiles: {}", e);
          }
          if let Err(e) = engine
            .check_for_missing_synced_entities(&app_handle_sync)
            .await
          {
            log::warn!("Failed to check for missing entities: {}", e);
          }
        }
        Err(e) => {
          log::debug!("Sync not configured, skipping missing profile check: {}", e);
        }
      }

      scheduler
        .clone()
        .start(app_handle_sync.clone(), work_rx)
        .await;
      log::info!("Sync scheduler restarted");
    }
  });

  Ok(())
}
