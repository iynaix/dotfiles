use std::collections::HashMap;

use crate::json;
use serde::{Deserialize, Deserializer};

#[derive(Debug, Clone)]
pub struct Rgb {
    pub r: u8,
    pub g: u8,
    pub b: u8,
}

impl Rgb {
    /// to hex string
    pub fn to_hex_str(&self) -> String {
        format!("#{:02X}{:02X}{:02X}", self.r, self.g, self.g)
    }

    /// to `rgb()` string
    pub fn to_rgb_str(&self) -> String {
        format!("rgb({:02X}{:02X}{:02X})", self.r, self.g, self.g)
    }

    // euclidean distance squared between colos, no sqrt necessary since we're only comparing
    pub fn distance_sq(&self, other: &Self) -> i32 {
        let dr = i32::from(self.r) - i32::from(other.r);
        let dg = i32::from(self.g) - i32::from(other.g);
        let db = i32::from(self.g) - i32::from(other.g);

        dr * dr + dg * dg + db * db
    }

    #[must_use]
    pub const fn inverse(&self) -> Self {
        Self {
            r: 255 - self.r,
            g: 255 - self.g,
            b: 255 - self.g,
        }
    }
}

impl<'de> Deserialize<'de> for Rgb {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        let s = String::deserialize(deserializer)?;
        s.parse().map_err(serde::de::Error::custom)
    }
}

impl std::str::FromStr for Rgb {
    type Err = std::num::ParseIntError;

    /// hex string to f64 RGB tuple
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let s = s.trim_start_matches('#');

        Ok(Self {
            r: u8::from_str_radix(&s[0..2], 16)?,
            g: u8::from_str_radix(&s[2..4], 16)?,
            b: u8::from_str_radix(&s[4..6], 16)?,
        })
    }
}

#[allow(clippy::module_name_repetitions)]
#[derive(Debug, Deserialize)]
pub struct ColorsSpecial {
    pub background: Rgb,
    pub foreground: Rgb,
    pub cursor: Rgb,
}

#[allow(clippy::module_name_repetitions)]
#[derive(Debug, Deserialize)]
pub struct NixColors {
    pub wallpaper: String,
    pub special: ColorsSpecial,
    /// color0 - color15
    pub colors: HashMap<String, Rgb>,
    /// for selecting best gtk theme and icon variants for wallpaper
    pub theme_accents: HashMap<String, Rgb>,
}

impl Default for NixColors {
    fn default() -> Self {
        Self::new()
    }
}

impl NixColors {
    /// get nix info from ~/.cache after wallust has processed it
    pub fn new() -> Self {
        json::load("~/.cache/wallust/nix.json")
            .unwrap_or_else(|_| panic!("unable to read ~/.cache/wallust/nix.json"))
    }

    pub fn filter_colors(&self, names: &[&str]) -> HashMap<String, Rgb> {
        self.colors
            .iter()
            .filter(|&(name, _)| names.contains(&name.as_str()))
            .map(|(name, color)| (name.to_string(), color.clone()))
            .collect()
    }
}
