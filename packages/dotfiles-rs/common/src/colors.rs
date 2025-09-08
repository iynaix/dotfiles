use std::collections::HashMap;

use crate::json;
use serde::{Deserialize, Deserializer};

fn normalize_channel(channel: u8) -> f64 {
    let channel = f64::from(channel) / 255.0;
    if channel <= 0.03928 {
        channel / 12.92
    } else {
        ((channel + 0.055) / 1.055).powf(2.4)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Rgb {
    pub r: u8,
    pub g: u8,
    pub b: u8,
}

impl Rgb {
    /// from wallust theme colors
    pub const fn from_wallust_theme_color(c: u32) -> Self {
        Self {
            r: ((c >> 16) & 0xFF) as u8,
            g: ((c >> 8) & 0xFF) as u8,
            b: (c & 0xFF) as u8,
        }
    }

    /// to i32 RGB tuple
    pub fn to_i64(&self) -> (i64, i64, i64) {
        (i64::from(self.r), i64::from(self.g), i64::from(self.b))
    }

    /// to f64 HSL tuple
    #[allow(clippy::many_single_char_names)]
    fn to_hsl(&self) -> (f64, f64, f64) {
        let r = f64::from(self.r) / 255.0;
        let g = f64::from(self.g) / 255.0;
        let b = f64::from(self.b) / 255.0;

        let max = r.max(g).max(b);
        let min = r.min(g).min(b);
        let delta = max - min;

        let l = f64::midpoint(max, min);

        if delta == 0.0 {
            (0.0, 0.0, l) // Grayscale
        } else {
            let s = if l > 0.5 {
                delta / (2.0 - max - min)
            } else {
                delta / (max + min)
            };

            let h = if (max - r).abs() < f64::EPSILON {
                ((g - b) / delta) % 6.0
            } else if (max - g).abs() < f64::EPSILON {
                (b - r) / delta + 2.0
            } else {
                (r - g) / delta + 4.0
            } * 60.0;

            (if h < 0.0 { h + 360.0 } else { h }, s, l)
        }
    }

    /// from f64 HSL tuple
    #[allow(clippy::many_single_char_names)]
    fn from_hsl(h: f64, s: f64, l: f64) -> Self {
        let c = (1.0 - 2.0f64.mul_add(l, -1.0).abs()) * s;
        let x = c * (1.0 - ((h / 60.0) % 2.0 - 1.0).abs());
        let m = l - c / 2.0;

        let (r1, g1, b1) = if h < 60.0 {
            (c, x, 0.0)
        } else if h < 120.0 {
            (x, c, 0.0)
        } else if h < 180.0 {
            (0.0, c, x)
        } else if h < 240.0 {
            (0.0, x, c)
        } else if h < 300.0 {
            (x, 0.0, c)
        } else {
            (c, 0.0, x)
        };

        Self {
            r: ((r1 + m) * 255.0).round() as u8,
            g: ((g1 + m) * 255.0).round() as u8,
            b: ((b1 + m) * 255.0).round() as u8,
        }
    }

    /// to hex string
    pub fn to_hex_str(&self) -> String {
        format!("#{:02X}{:02X}{:02X}", self.r, self.g, self.b)
    }

    /// to `rgb()` string
    pub fn to_rgb_str(&self) -> String {
        format!("rgb({:02X}{:02X}{:02X})", self.r, self.g, self.b)
    }

    // euclidean distance squared between colos, no sqrt necessary since we're only comparing
    pub fn distance_sq(&self, other: &Self) -> i64 {
        let (r1, g1, b1) = self.to_i64();
        let (r2, g2, b2) = other.to_i64();

        (r1 - r2) * (r1 - r2) + (g1 - g2) * (g1 - g2) + (b1 - b2) * (b1 - b2)
    }

    #[must_use]
    pub const fn inverse(&self) -> Self {
        Self {
            r: 255 - self.r,
            g: 255 - self.g,
            b: 255 - self.b,
        }
    }

    /// relative luminance, as defined by WCAG
    /// <https://www.w3.org/TR/WCAG20/#relativeluminancedef>
    pub fn relative_luminance(&self) -> f64 {
        let r = normalize_channel(self.r);
        let g = normalize_channel(self.g);
        let b = normalize_channel(self.b);

        0.0722_f64.mul_add(b, 0.2126_f64.mul_add(r, 0.7152 * g))
    }

    pub fn contrast_ratio(&self, other: &Self) -> f64 {
        let l1 = self.relative_luminance();
        let l2 = other.relative_luminance();

        if l1 > l2 {
            (l1 + 0.05) / (l2 + 0.05)
        } else {
            (l2 + 0.05) / (l1 + 0.05)
        }
    }

    #[must_use]
    pub fn complementary(&self) -> Self {
        let (h, s, l) = self.to_hsl();
        let comp_h = (h + 180.0) % 360.0; // Complementary hue is 180° away
        Self::from_hsl(comp_h, s, l)
    }
}

// print as hex string by default
impl std::fmt::Display for Rgb {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "#{:02X}{:02X}{:02X}", self.r, self.g, self.b)
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
#[serde(rename_all = "camelCase")]
pub struct NixColors {
    pub wallpaper: String,
    pub special: ColorsSpecial,
    /// color0 - color15
    pub colors: HashMap<String, Rgb>,
    /// for selecting best gtk theme and icon variants for wallpaper
    pub theme_accents: HashMap<String, Rgb>,
}

impl NixColors {
    /// get nix info from ~/.cache after wallust has processed it
    pub fn new() -> Result<Self, Box<dyn std::error::Error>> {
        json::load("~/.cache/wallust/nix.json")
    }

    pub fn filter_colors(&self, names: &[&str]) -> HashMap<String, Rgb> {
        self.colors
            .iter()
            .filter(|&(name, _)| !names.contains(&name.as_str()))
            .map(|(name, color)| (name.to_string(), color.clone()))
            .collect()
    }
}
