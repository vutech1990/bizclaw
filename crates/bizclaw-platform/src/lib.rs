//! # BizClaw Platform
//!
//! Multi-tenant management platform — run multiple BizClaw agents on a single VPS.
//! Includes admin dashboard, tenant lifecycle management, pairing security,
//! subdomain routing, resource monitoring, and audit logging.

pub mod db;
pub mod tenant;
pub mod auth;
pub mod admin;
pub mod config;

pub use db::PlatformDb;
pub use tenant::TenantManager;
pub use admin::AdminServer;
