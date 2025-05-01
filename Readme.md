# 📱 Nostalgia-fy

---

## 📖 App Overview

**Nostalgia-fy** is an iOS app that lets users rediscover memories by combining their **Spotify listening history** with **photos taken on the same calendar date**, regardless of year.

- Select a date using a calendar UI
- View the songs you listened to on that day (from Spotify history)
- Tap a song to generate a photo montage from any past years that share the same month/day

It’s a memory lane powered by music and moments.

---

## ✅ App Evaluation

### 📱 Mobile
- Uses iOS-exclusive capabilities: PhotoKit, calendar UI, and Spotify’s OAuth + API
- Strong mobile-first experience combining gestures, music, and photos

### 🎯 Story
- Strong nostalgic appeal — music meets memory
- Easy for users to understand and emotionally resonate with
- Great for reflecting on the past and reliving moments tied to songs

### 📊 Market
- Targets Spotify users with photo libraries
- Appeals to Gen Z and Millennials
- Niche product, but highly relevant for people who tie emotion to music/photos

### 🔁 Habit
- Each day has new music + photo pairings
- Encourages re-visiting the app out of curiosity and nostalgia

### 🧠 Scope
- MVP includes: Spotify login → calendar → song list → montage
- Manageable and expandable (slideshow, music preview, sharing)

---

## 🛠 App Spec

### Required Features
- [x] Spotify login using PKCE
- [x] UIDatePicker to select a calendar day
- [x] Fetch recently played Spotify tracks
- [x] Filter tracks to match selected date (any year)
- [x] Tap a track to push to new screen
- [x] On that screen: fetch photos from any year that match the selected day/month
- [x] Display photos in a UICollectionView

### Optional Features
- [ ] Fullscreen slideshow with crossfade animations
- [ ] Play song preview while showing the montage
- [ ] Save montage or share to Instagram/Snapchat
- [ ] Filter photos by year
- [ ] Persist user’s last session / track selection

---

## 🖥 Screens

### 1. Login Screen
- Spotify authentication via `ASWebAuthenticationSession`

### 2. Calendar Screen
- `UIDatePicker` to select a day
- "Fetch Tracks" button
- `UITableView` with track name and artists

### 3. Montage Screen
- Label with `"Photos from [Track]'s Day"`
- `UICollectionView` of matching photo assets

---

## 🧭 Navigation Flow

[Login Screen] ↓ [Calendar + Tracks Screen] ↓ tap on a track [Montage Screen with photos from same month/day]


---

## 🖼 Wireframes

(Include scans/photos in a `wireframes/` folder of your repo and reference them here.)

- ![Calendar Screen](wireframes/calendar_screen.png)
- ![Montage Screen](wireframes/montage_screen.png)

---

## 📦 Final Repo Checklist

- [x] brainstorming.md
- [x] readme.md (this file)
- [x] wireframes (hand-drawn or digital)
- [ ] [BONUS] Digital mockup (e.g., in Figma)
- [ ] [BONUS] Interactive prototype (clickable flow)

---

💫 Let the nostalgia begin.

